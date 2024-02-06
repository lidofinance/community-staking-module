// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";

import { CSVerifier } from "../src/CSVerifier.sol";

import { ForkSelectorMock } from "./helpers/mocks/ForkSelectorMock.sol";
import { GIProviderMock } from "./helpers/mocks/GIProviderMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

contract CSVerifierTest is Test {
    using stdJson for string;

    struct WithdrawalFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        address _withdrawalAddress;
        ICSVerifier.ProvableBeaconBlockHeader beaconBlock;
        ICSVerifier.WithdrawalProofContext ctx;
    }

    CSVerifier public verifier;
    ForkSelectorMock public forkSelector;
    GIProviderMock public gIprovider;
    Stub public locator;
    Stub public module;

    WithdrawalFixture public fixture;

    function setUp() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/test/fixtures/CSVerifier/withdrawal.json"
        );
        string memory json = vm.readFile(path);
        bytes memory data = json.parseRaw("$");
        fixture = abi.decode(data, (WithdrawalFixture));

        verifier = new CSVerifier({
            slotsPerEpoch: 32,
            secondsPerSlot: 12,
            genesisTime: 0
        });

        forkSelector = new ForkSelectorMock();
        gIprovider = new GIProviderMock();
        locator = new Stub();
        module = new Stub();

        forkSelector.usePrater();
        gIprovider.usePreset();

        verifier.initialize(
            address(forkSelector),
            address(gIprovider),
            address(locator),
            address(module)
        );
    }

    function test_processWithdrawalProof() public {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode(fixture._blockRoot)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(
                ICSModule.getNodeOperatorSigningKeys.selector,
                0,
                0
            ),
            abi.encode(fixture._pubkey)
        );

        vm.mockCall(
            address(locator),
            abi.encodeWithSelector(ILidoLocator.withdrawalVault.selector),
            abi.encode(fixture._withdrawalAddress)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawal.selector),
            ""
        );

        vm.warp(fixture.beaconBlock.blockHeader.slot * 12);

        verifier.processWithdrawalProof(fixture.beaconBlock, fixture.ctx, 0, 0);
    }
}
