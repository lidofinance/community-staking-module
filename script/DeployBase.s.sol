// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { OssifiableProxy } from "../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";

struct DeployParams {
    // Lido addresses
    address lidoLocatorAddress;
    address votingAddress;
    // Oracle
    uint256 secondsPerSlot;
    uint256 slotsPerEpoch;
    uint256 clGenesisTime;
    uint256 oracleReportEpochsPerFrame;
    uint256 fastLaneLengthSlots;
    uint256 consensusVersion;
    uint256 performanceThresholdBP;
    // Verifier
    GIndex gIHistoricalSummaries;
    GIndex gIFirstWithdrawal;
    GIndex gIFirstValidator;
    uint256 verifierSupportedEpoch;
    // Accounting
    uint256[] bondCurve;
    uint256 bondLockRetentionPeriod;
    // Module
    bytes32 moduleType;
    uint256 elRewardsStealingFine;
    uint256 maxKeysPerOperatorEA;
    uint256 keyRemovalCharge;
}

abstract contract DeployBase is Script {
    DeployParams internal config;
    string private chainName;
    uint256 private chainId;
    ILidoLocator private locator;

    address private deployer;
    uint256 private pk;
    CSModule public csm;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;
    CSVerifier public verifier;
    HashConsensus public hashConsensus;

    error ChainIdMismatch(uint256 actual, uint256 expected);

    constructor(string memory _chainName, uint256 _chainId) {
        chainName = _chainName;
        chainId = _chainId;
    }

    function _setUp() internal {
        vm.label(config.votingAddress, "VOTING_ADDRESS");
        vm.label(config.lidoLocatorAddress, "LIDO_LOCATOR");
        locator = ILidoLocator(config.lidoLocatorAddress);
    }

    function run() external {
        if (chainId != block.chainid) {
            revert ChainIdMismatch({
                actual: block.chainid,
                expected: chainId
            });
        }

        pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(pk);
        vm.label(deployer, "DEPLOYER");

        vm.startBroadcast(pk);
        {
            address treasury = locator.treasury();
            CSModule csmImpl = new CSModule({
                moduleType: config.moduleType,
                elRewardsStealingFine: config.elRewardsStealingFine,
                maxKeysPerOperatorEA: config.maxKeysPerOperatorEA,
                lidoLocator: config.lidoLocatorAddress
            });
            csm = CSModule(
                _deployProxy(config.votingAddress, address(csmImpl))
            );

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                communityStakingModule: address(csm)
            });
            accounting = CSAccounting(
                _deployProxy(config.votingAddress, address(accountingImpl))
            );

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime
            });
            oracle = CSFeeOracle(
                _deployProxy(config.votingAddress, address(oracleImpl))
            );

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting)
            });
            feeDistributor = CSFeeDistributor(
                _deployProxy(config.votingAddress, address(feeDistributorImpl))
            );

            verifier = new CSVerifier({
                slotsPerEpoch: uint64(config.slotsPerEpoch),
                // NOTE: Deneb fork gIndexes. Should be updated according to `config.verifierSupportedEpoch` fork epoch if needed
                gIHistoricalSummaries: config.gIHistoricalSummaries,
                gIFirstWithdrawal: config.gIFirstWithdrawal,
                gIFirstValidator: config.gIFirstValidator,
                firstSupportedSlot: Slot.wrap(
                    uint64(config.verifierSupportedEpoch * config.slotsPerEpoch)
                )
            });

            /// @dev initialize contracts
            csm.initialize({
                _accounting: address(accounting),
                _earlyAdoption: address(0),
                verifier: address(verifier),
                _keyRemovalCharge: config.keyRemovalCharge,
                admin: address(deployer)
            });
            accounting.initialize({
                bondCurve: config.bondCurve,
                admin: config.votingAddress,
                _feeDistributor: address(feeDistributor),
                bondLockRetentionPeriod: config.bondLockRetentionPeriod,
                _chargeRecipient: treasury
            });
            feeDistributor.initialize({
                admin: config.votingAddress,
                oracle: address(oracle)
            });
            verifier.initialize(address(locator), address(csm));

            // TODO: deploy early adoption contract
            csm.grantRole(csm.MODULE_MANAGER_ROLE(), address(deployer));
            csm.activatePublicRelease();
            csm.revokeRole(csm.MODULE_MANAGER_ROLE(), address(deployer));

            hashConsensus = new HashConsensus({
                slotsPerEpoch: config.slotsPerEpoch,
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime,
                epochsPerFrame: config.oracleReportEpochsPerFrame,
                fastLaneLengthSlots: config.fastLaneLengthSlots,
                admin: config.votingAddress,
                reportProcessor: address(oracle)
            });

            oracle.initialize({
                admin: config.votingAddress,
                feeDistributorContract: address(feeDistributor),
                consensusContract: address(hashConsensus),
                consensusVersion: config.consensusVersion,
                _perfThresholdBP: config.performanceThresholdBP
            });

            // TODO: remove these lines after early adoption deployment
            csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), config.votingAddress);
            csm.revokeRole(csm.DEFAULT_ADMIN_ROLE(), address(deployer));

            // TODO: these roles might be granted to multisig for testing purposes
            //            csm.grantRole(csm.PAUSE_ROLE(), address(0)); GateSeal or multisig

            //            csm.grantRole(csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(), address(0)); EOA or multisig
            //            csm.grantRole(csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(), address(0)); multisig or EasyTrack

            //            accounting.grantRole(accounting.PAUSE_ROLE(), address(0)); GateSeal or multisig

            //            accounting.grantRole(accounting.SET_BOND_CURVE_ROLE(), address(0)); multisig
            //            accounting.grantRole(accounting.RESET_BOND_CURVE_ROLE(), address(0)); multisig

            //            oracle.grantRole(oracle.PAUSE_ROLE(), address(0)); GateSeal or multisig

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("ChainId", chainId);
            deployJson.set("CSModule", address(csm));
            deployJson.set("CSAccounting", address(accounting));
            deployJson.set("CSFeeOracle", address(oracle));
            deployJson.set("CSFeeDistributor", address(feeDistributor));
            deployJson.set("HashConsensus", address(hashConsensus));
            deployJson.set("CSVerifier", address(verifier));
            deployJson.set("LidoLocator", config.lidoLocatorAddress);
            vm.writeJson(deployJson.str, _deployJsonFilename());
            vm.writeJson(deployJson.str, "./out/latest.json");
        }

        vm.stopBroadcast();
    }

    function _deployProxy(
        address admin,
        address implementation
    ) internal returns (address) {
        OssifiableProxy proxy = new OssifiableProxy({
            implementation_: implementation,
            data_: new bytes(0),
            admin_: admin
        });

        return address(proxy);
    }

    function _deployGateSeal() internal returns (address) {
        // PAUSE_ROLE for some contracts should be granted to GateSeals
        revert("Not yet implemented");
    }

    function _deployJsonFilename() internal view returns (string memory) {
        return
            string(abi.encodePacked("./out/", "deploy-", chainName, ".json"));
    }
}
