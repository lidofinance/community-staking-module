// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { CSVerifier } from "../src/CSVerifier.sol";
import { pack } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";
import { GIndex } from "../src/lib/GIndex.sol";

import { Stub } from "./helpers/mocks/Stub.sol";

function dec(Slot self) pure returns (Slot slot) {
    assembly ("memory-safe") {
        slot := sub(self, 1)
    }
}

using { dec } for Slot;

contract CSVerifierTestBase is Test {
    struct WithdrawalFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        address _withdrawalAddress;
        ICSVerifier.ProvableBeaconBlockHeader beaconBlock;
        ICSVerifier.WithdrawalWitness witness;
    }

    struct SlashingFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        ICSVerifier.ProvableBeaconBlockHeader beaconBlock;
        ICSVerifier.SlashingWitness witness;
    }

    CSVerifier public verifier;
    Stub public locator;
    Stub public module;
    Slot public firstSupportedSlot;

    string internal fixturesPath = "./test/fixtures/CSVerifier/";
}

contract CSVerifierTestConstructor is CSVerifierTestBase {
    function setUp() public {
        locator = new Stub();
        module = new Stub();
        firstSupportedSlot = Slot.wrap(100_500);
    }

    function test_constructor() public {
        verifier = new CSVerifier({
            locator: address(locator),
            module: address(module),
            slotsPerEpoch: 32,
            gIHistoricalSummariesPrev: pack(0xfff0, 4),
            gIHistoricalSummariesCurr: pack(0xffff, 4),
            gIFirstWithdrawalPrev: pack(0xe1c0, 4),
            gIFirstWithdrawalCurr: pack(0xe1c1, 4),
            gIFirstValidatorPrev: pack(0x560000000000, 40),
            gIFirstValidatorCurr: pack(0x560000000001, 40),
            firstSupportedSlot: firstSupportedSlot,
            pivotSlot: Slot.wrap(100_501)
        });

        assertEq(address(verifier.MODULE()), address(module));
        assertEq(address(verifier.LOCATOR()), address(locator));
        assertEq(verifier.SLOTS_PER_EPOCH(), 32);
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES_PREV()),
            GIndex.unwrap(pack(0xfff0, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES_CURR()),
            GIndex.unwrap(pack(0xffff, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL_PREV()),
            GIndex.unwrap(pack(0xe1c0, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL_CURR()),
            GIndex.unwrap(pack(0xe1c1, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR_PREV()),
            GIndex.unwrap(pack(0x560000000000, 40))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR_CURR()),
            GIndex.unwrap(pack(0x560000000001, 40))
        );
        assertEq(
            Slot.unwrap(verifier.FIRST_SUPPORTED_SLOT()),
            Slot.unwrap(firstSupportedSlot)
        );
        assertEq(
            Slot.unwrap(verifier.PIVOT_SLOT()),
            Slot.unwrap(Slot.wrap(100_501))
        );
    }

    function test_constructor_RevertWhen_InvalidChainConfig() public {
        vm.expectRevert(CSVerifier.InvalidChainConfig.selector);
        verifier = new CSVerifier({
            locator: address(locator),
            module: address(module),
            slotsPerEpoch: 0,
            gIHistoricalSummariesPrev: pack(0x0, 0), // We don't care of the value for this test.
            gIHistoricalSummariesCurr: pack(0x0, 0), // We don't care of the value for this test.
            gIFirstWithdrawalPrev: pack(0xe1c0, 4),
            gIFirstWithdrawalCurr: pack(0xe1c0, 4),
            gIFirstValidatorPrev: pack(0x560000000000, 40),
            gIFirstValidatorCurr: pack(0x560000000000, 40),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot
        });
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(CSVerifier.ZeroModuleAddress.selector);
        verifier = new CSVerifier({
            locator: address(locator),
            module: address(0),
            slotsPerEpoch: 32,
            gIHistoricalSummariesPrev: pack(0x0, 0), // We don't care of the value for this test.
            gIHistoricalSummariesCurr: pack(0x0, 0), // We don't care of the value for this test.
            gIFirstWithdrawalPrev: pack(0xe1c0, 4),
            gIFirstWithdrawalCurr: pack(0xe1c0, 4),
            gIFirstValidatorPrev: pack(0x560000000000, 40),
            gIFirstValidatorCurr: pack(0x560000000000, 40),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot
        });
    }

    function test_constructor_RevertWhen_ZeroLocatorAddress() public {
        vm.expectRevert(CSVerifier.ZeroLocatorAddress.selector);
        verifier = new CSVerifier({
            locator: address(0),
            module: address(module),
            slotsPerEpoch: 32,
            gIHistoricalSummariesPrev: pack(0x0, 0), // We don't care of the value for this test.
            gIHistoricalSummariesCurr: pack(0x0, 0), // We don't care of the value for this test.
            gIFirstWithdrawalPrev: pack(0xe1c0, 4),
            gIFirstWithdrawalCurr: pack(0xe1c0, 4),
            gIFirstValidatorPrev: pack(0x560000000000, 40),
            gIFirstValidatorCurr: pack(0x560000000000, 40),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot
        });
    }
}

contract CSVerifierTest is CSVerifierTestBase {
    using stdJson for string;

    function setUp() public {
        locator = new Stub();
        module = new Stub();

        verifier = new CSVerifier({
            locator: address(locator),
            module: address(module),
            slotsPerEpoch: 32,
            gIHistoricalSummariesPrev: pack(0x0, 0), // We don't care of the value for this test.
            gIHistoricalSummariesCurr: pack(0x0, 0), // We don't care of the value for this test.
            gIFirstWithdrawalPrev: pack(0xe1c0, 4),
            gIFirstWithdrawalCurr: pack(0xe1c0, 4),
            gIFirstValidatorPrev: pack(0x560000000000, 40),
            gIFirstValidatorCurr: pack(0x560000000000, 40),
            firstSupportedSlot: Slot.wrap(100_500), // Any value less than the slots from the fixtures.
            pivotSlot: Slot.wrap(100_500)
        });
    }

    function test_processSlashingProof() public {
        SlashingFixture memory fixture = abi.decode(
            _readFixture("slashing.json"),
            (SlashingFixture)
        );

        _setMocksSlashing(fixture);

        verifier.processSlashingProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processSlashingProof_RevertWhen_UnsupportedSlot() public {
        SlashingFixture memory fixture = abi.decode(
            _readFixture("slashing.json"),
            (SlashingFixture)
        );

        _setMocksSlashing(fixture);

        fixture.beaconBlock.header.slot = verifier.FIRST_SUPPORTED_SLOT().dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                CSVerifier.UnsupportedSlot.selector,
                fixture.beaconBlock.header.slot
            )
        );
        verifier.processSlashingProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processSlashingProof_RevertWhen_InvalidBlockHeader() public {
        SlashingFixture memory fixture = abi.decode(
            _readFixture("slashing.json"),
            (SlashingFixture)
        );

        _setMocksSlashing(fixture);

        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode("lol")
        );

        vm.expectRevert(CSVerifier.InvalidBlockHeader.selector);
        verifier.processSlashingProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_ZeroWithdrawalIndex() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal_zero_index.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_UnsupportedSlot() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        fixture.beaconBlock.header.slot = verifier.FIRST_SUPPORTED_SLOT().dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                CSVerifier.UnsupportedSlot.selector,
                fixture.beaconBlock.header.slot
            )
        );
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_InvalidBlockHeader()
        public
    {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode("lol")
        );

        vm.expectRevert(CSVerifier.InvalidBlockHeader.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_No4788Contract() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector, 0, 0),
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

        vm.etch(verifier.BEACON_ROOTS(), new bytes(0));

        vm.expectRevert(CSVerifier.RootNotFound.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_revertFrom4788() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        vm.mockCallRevert(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            ""
        );

        vm.expectRevert(CSVerifier.RootNotFound.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function _readFixture(
        string memory filename
    ) internal noGasMetering returns (bytes memory data) {
        string memory path = string.concat(fixturesPath, filename);
        string memory json = vm.readFile(path);
        data = json.parseRaw("$");
    }

    function _setMocksSlashing(SlashingFixture memory fixture) internal {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode(fixture._blockRoot)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector, 0, 0),
            abi.encode(fixture._pubkey)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.submitInitialSlashing.selector),
            ""
        );
    }

    function test_processWithdrawalProof_RevertWhen_InvalidWithdrawalAddress()
        public
    {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        fixture.witness.withdrawalCredentials = bytes32(0);

        vm.expectRevert(CSVerifier.InvalidWithdrawalAddress.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_ValidatorNotWithdrawn()
        public
    {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        fixture.witness.withdrawableEpoch =
            fixture.beaconBlock.header.slot.unwrap() /
            32 +
            154;

        vm.expectRevert(CSVerifier.ValidatorNotWithdrawn.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_PartialWitdrawal() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        fixture.witness.amount = 154;

        vm.expectRevert(CSVerifier.PartialWithdrawal.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function _setMocksWithdrawal(WithdrawalFixture memory fixture) internal {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode(fixture._blockRoot)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector, 0, 0),
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
    }
}
