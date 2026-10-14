// SPDX-FileCopyrightText: 2026 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.33;

import { console } from "forge-std/Script.sol";

import { Verifier } from "../src/Verifier.sol";
import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { Slot } from "../src/lib/Types.sol";
import { WCType, toWC } from "./utils/WithdrawalCredentials.sol";
import { JsonBindings } from "./utils/JsonBindings.sol";
import { DeployConfirmation } from "./utils/DeployConfirmation.sol";

struct GloasVerifierParams {
    address lidoLocatorAddress;
    address aragonAgent;
    uint64 slotsPerEpoch;
    uint64 verifierFirstSupportedSlot;
    uint64 capellaSlot;
    uint256 minWithdrawalRatio;
    WCType verifierWcType;
    address circuitBreaker;
    address resealManager;
    address secondAdminAddress;
}

abstract contract DeployGloasVerifierBase is DeployConfirmation {
    string public chainName;
    uint64 public verifierGloasSlot;
    address internal deployer;

    error ChainIdMismatch(uint256 actual, uint256 expected);
    error GloasSlotNotSet();
    error CannotBeUsedInMainnet();
    error InvalidSecondAdmin();

    constructor(string memory _chainName) {
        chainName = _chainName;
    }

    function run(string memory gitRef) external {
        string memory path = vm.envString("DEPLOY_CONFIG");
        string memory json = vm.readFile(path);

        uint256 chainId = vm.parseJsonUint(json, ".ChainId");
        if (chainId != block.chainid) revert ChainIdMismatch({ actual: block.chainid, expected: chainId });
        if (verifierGloasSlot == type(uint64).max) revert GloasSlotNotSet();

        string memory params = vm.keyExistsJson(json, ".DeployParams") ? ".DeployParams" : ".CuratedDeployParams";
        GloasVerifierParams memory p = JsonBindings.deserializeGloasVerifierParams(json, params);
        address module = vm.parseJsonAddress(
            json,
            vm.keyExistsJson(json, ".CSModule") ? ".CSModule" : ".CuratedModule"
        );

        _logParams(p, module);

        _confirmDeploy("Deploy the Gloas Verifier with the params above?");

        vm.startBroadcast();
        (, deployer, ) = vm.readCallers();
        vm.label(deployer, "DEPLOYER");

        Verifier verifier = _deployVerifier(p, module);

        vm.stopBroadcast();

        // writeJson with a key only upserts that key, leaving the rest of the artifact intact
        vm.writeJson(vm.toString(address(verifier)), path, ".VerifierGloas");
        vm.writeJson(vm.toString(verifierGloasSlot), path, string.concat(params, ".verifierGloasSlot"));
        vm.writeJson(string.concat('"', gitRef, '"'), path, ".git-ref");
    }

    function _logParams(GloasVerifierParams memory p, address module) internal view {
        console.log("module:", module);
        console.log("lidoLocator:", p.lidoLocatorAddress);
        console.log(
            "withdrawalCredentials:",
            vm.toString(toWC(ILidoLocator(p.lidoLocatorAddress).withdrawalVault(), p.verifierWcType))
        );
        console.log("slotsPerEpoch:", p.slotsPerEpoch);
        console.log("firstSupportedSlot:", p.verifierFirstSupportedSlot);
        console.log("capellaSlot:", p.capellaSlot);
        console.log("gloasSlot:", verifierGloasSlot);
        console.log("minWithdrawalRatio:", p.minWithdrawalRatio);
        console.log("aragonAgent:", p.aragonAgent);
        console.log("circuitBreaker:", p.circuitBreaker);
        console.log("resealManager:", p.resealManager);
        console.log("secondAdmin:", p.secondAdminAddress);
    }

    function _deployVerifier(GloasVerifierParams memory p, address module) internal returns (Verifier verifier) {
        verifier = new Verifier({
            withdrawalCredentials: toWC(ILidoLocator(p.lidoLocatorAddress).withdrawalVault(), p.verifierWcType),
            module: module,
            slotsPerEpoch: p.slotsPerEpoch,
            firstSupportedSlot: Slot.wrap(p.verifierFirstSupportedSlot),
            gloasSlot: Slot.wrap(verifierGloasSlot),
            capellaSlot: Slot.wrap(p.capellaSlot),
            minWithdrawalRatio: p.minWithdrawalRatio,
            admin: deployer
        });

        if (p.secondAdminAddress != address(0)) {
            if (p.secondAdminAddress == deployer) revert InvalidSecondAdmin();
            if (keccak256(abi.encodePacked(chainName)) == keccak256("mainnet")) revert CannotBeUsedInMainnet();
            verifier.grantRole(verifier.DEFAULT_ADMIN_ROLE(), p.secondAdminAddress);
        }

        verifier.grantRole(verifier.PAUSE_ROLE(), p.resealManager);
        verifier.grantRole(verifier.RESUME_ROLE(), p.resealManager);
        verifier.grantRole(verifier.PAUSE_ROLE(), p.circuitBreaker);
        verifier.grantRole(verifier.DEFAULT_ADMIN_ROLE(), p.aragonAgent);
        verifier.revokeRole(verifier.DEFAULT_ADMIN_ROLE(), deployer);
    }
}
