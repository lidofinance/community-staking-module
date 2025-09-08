// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { CSVerifier } from "../src/CSVerifier.sol";
import { pack } from "../src/lib/GIndex.sol";
import { Slot, BeaconBlockHeader } from "../src/lib/Types.sol";
import { GIndex } from "../src/lib/GIndex.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

function dec(Slot self) pure returns (Slot slot) {
    assembly ("memory-safe") {
        slot := sub(self, 1)
    }
}

function inc(Slot self) pure returns (Slot slot) {
    assembly ("memory-safe") {
        slot := add(self, 1)
    }
}

using { dec, inc } for Slot;

GIndex constant NULL_GINDEX = GIndex.wrap(0);

contract CSVerifierTestBase is Test, Utilities {
    using stdJson for string;

    struct WithdrawalFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        ICSVerifier.ProvableBeaconBlockHeader beaconBlock;
        ICSVerifier.WithdrawalWitness witness;
    }

    CSVerifier public verifier;
    Stub public module;
    Slot public firstSupportedSlot;
    address public admin;
    address public stranger;

    bytes32 public pauseRole;
    bytes32 public resumeRole;

    string internal fixturesPath = "./test/fixtures/CSVerifier/";

    function _readFixture(
        string memory filename
    ) internal noGasMetering returns (bytes memory data) {
        string memory path = string.concat(fixturesPath, filename);
        string memory json = vm.readFile(path);
        data = json.parseRaw("$");
    }
}

contract CSVerifierTestConstructor is CSVerifierTestBase {
    function setUp() public {
        module = new Stub();
        firstSupportedSlot = Slot.wrap(100_500);
        admin = nextAddress("ADMIN");
    }

    function test_constructor_HappyPath() public {
        address withdrawalAddress = nextAddress("WITHDRAWAL_ADDRESS");

        verifier = new CSVerifier({
            withdrawalAddress: withdrawalAddress,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c1, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000001, 40),
                gIFirstHistoricalSummaryPrev: pack(0xfff0, 4),
                gIFirstHistoricalSummaryCurr: pack(0xffff, 4),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4001, 13)
            }),
            firstSupportedSlot: firstSupportedSlot,
            pivotSlot: Slot.wrap(100_501),
            capellaSlot: Slot.wrap(42),
            admin: admin
        });

        assertEq(address(verifier.WITHDRAWAL_ADDRESS()), withdrawalAddress);
        assertEq(address(verifier.MODULE()), address(module));
        assertEq(verifier.SLOTS_PER_EPOCH(), 32);
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
            GIndex.unwrap(verifier.GI_FIRST_HISTORICAL_SUMMARY_PREV()),
            GIndex.unwrap(pack(0xfff0, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_HISTORICAL_SUMMARY_CURR()),
            GIndex.unwrap(pack(0xffff, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_BLOCK_ROOT_IN_SUMMARY_PREV()),
            GIndex.unwrap(pack(0x4000, 13))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_BLOCK_ROOT_IN_SUMMARY_CURR()),
            GIndex.unwrap(pack(0x4001, 13))
        );
        assertEq(
            Slot.unwrap(verifier.FIRST_SUPPORTED_SLOT()),
            Slot.unwrap(firstSupportedSlot)
        );
        assertEq(
            Slot.unwrap(verifier.PIVOT_SLOT()),
            Slot.unwrap(Slot.wrap(100_501))
        );
        assertEq(
            Slot.unwrap(verifier.CAPELLA_SLOT()),
            Slot.unwrap(Slot.wrap(42))
        );
    }

    function test_constructor_RevertWhen_InvalidChainConfig_SlotsPerEpoch()
        public
    {
        vm.expectRevert(ICSVerifier.InvalidChainConfig.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 0,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x3b, 0),
                gIFirstHistoricalSummaryCurr: pack(0x3b, 0),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_InvalidChainConfig_SlotsPerHistoricalRoot()
        public
    {
        vm.expectRevert(ICSVerifier.InvalidChainConfig.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 0,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x3b, 0),
                gIFirstHistoricalSummaryCurr: pack(0x3b, 0),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_InvalidPivotSlot() public {
        vm.expectRevert(ICSVerifier.InvalidPivotSlot.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x3b, 0),
                gIFirstHistoricalSummaryCurr: pack(0x3b, 0),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot,
            pivotSlot: firstSupportedSlot.dec(),
            capellaSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_InvalidCapellaSlot() public {
        vm.expectRevert(ICSVerifier.InvalidCapellaSlot.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x3b, 0),
                gIFirstHistoricalSummaryCurr: pack(0x3b, 0),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot,
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot.inc(),
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSVerifier.ZeroModuleAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(0),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x3b, 0),
                gIFirstHistoricalSummaryCurr: pack(0x3b, 0),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroWithdrawalAddress() public {
        vm.expectRevert(ICSVerifier.ZeroWithdrawalAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: address(0),
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x3b, 0),
                gIFirstHistoricalSummaryCurr: pack(0x3b, 0),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroAdminAddress() public {
        vm.expectRevert(ICSVerifier.ZeroAdminAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot,
            admin: address(0)
        });
    }
}

contract CSVerifierWithdrawalTest is CSVerifierTestBase {
    function setUp() public {
        module = new Stub();
        admin = nextAddress("ADMIN");

        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: NULL_GINDEX,
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX
            }),
            firstSupportedSlot: Slot.wrap(100_500), // Any value less than the slots from the fixtures.
            pivotSlot: Slot.wrap(100_500),
            capellaSlot: Slot.wrap(100_500),
            admin: admin
        });

        pauseRole = verifier.PAUSE_ROLE();
        resumeRole = verifier.RESUME_ROLE();

        vm.startPrank(admin);
        verifier.grantRole(pauseRole, admin);
        verifier.grantRole(resumeRole, admin);
        vm.stopPrank();
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
                ICSVerifier.UnsupportedSlot.selector,
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

        vm.expectRevert(ICSVerifier.InvalidBlockHeader.selector);
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
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawals.selector),
            ""
        );

        vm.etch(verifier.BEACON_ROOTS(), new bytes(0));

        vm.expectRevert(ICSVerifier.RootNotFound.selector);
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

        vm.expectRevert(ICSVerifier.RootNotFound.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
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

        vm.expectRevert(ICSVerifier.InvalidWithdrawalAddress.selector);
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

        vm.expectRevert(ICSVerifier.ValidatorNotWithdrawn.selector);
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

        vm.expectRevert(ICSVerifier.PartialWithdrawal.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhenPaused() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_ForkBeforePivot() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0x0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x0, 40),
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: NULL_GINDEX,
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX
            }),
            firstSupportedSlot: fixture.beaconBlock.header.slot.dec(),
            pivotSlot: fixture.beaconBlock.header.slot.inc(),
            capellaSlot: Slot.wrap(0),
            admin: admin
        });

        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_ForkAtPivot() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x0, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: NULL_GINDEX,
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX
            }),
            firstSupportedSlot: fixture.beaconBlock.header.slot.dec(),
            pivotSlot: fixture.beaconBlock.header.slot,
            capellaSlot: Slot.wrap(0),
            admin: admin
        });

        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_ForkAfterPivot() public {
        WithdrawalFixture memory fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

        _setMocksWithdrawal(fixture);

        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x0, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: NULL_GINDEX,
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX
            }),
            firstSupportedSlot: fixture.beaconBlock.header.slot.dec(),
            pivotSlot: fixture.beaconBlock.header.slot.dec(),
            capellaSlot: Slot.wrap(0),
            admin: admin
        });

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
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawals.selector),
            ""
        );
    }
}

contract CSVerifierPauseTest is CSVerifierTestBase {
    function setUp() public {
        module = new Stub();
        admin = nextAddress("ADMIN");
        stranger = nextAddress("STRANGER");

        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: NULL_GINDEX,
                gIFirstWithdrawalCurr: NULL_GINDEX,
                gIFirstValidatorPrev: NULL_GINDEX,
                gIFirstValidatorCurr: NULL_GINDEX,
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: NULL_GINDEX,
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX
            }),
            firstSupportedSlot: Slot.wrap(100_500), // Any value less than the slots from the fixtures.
            pivotSlot: Slot.wrap(100_500),
            capellaSlot: Slot.wrap(0),
            admin: admin
        });

        pauseRole = verifier.PAUSE_ROLE();
        resumeRole = verifier.RESUME_ROLE();

        vm.startPrank(admin);
        verifier.grantRole(pauseRole, admin);
        verifier.grantRole(resumeRole, admin);
        vm.stopPrank();
    }

    function test_pause() public {
        assertFalse(verifier.isPaused());
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());
    }

    function test_pause_RevertWhenNoRole() public {
        expectRoleRevert(stranger, pauseRole);
        vm.prank(stranger);
        verifier.pauseFor(100_500);
    }

    function test_pause_RevertWhenPaused() public {
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vm.prank(admin);
        verifier.pauseFor(100_500);
    }

    function test_resume() public {
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.prank(admin);
        verifier.resume();
        assertFalse(verifier.isPaused());
    }

    function test_resume_RevertWhenNoRole() public {
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        expectRoleRevert(stranger, resumeRole);
        vm.prank(stranger);
        verifier.resume();
    }

    function test_resume_RevertWhenNotPaused() public {
        vm.expectRevert(PausableUntil.PausedExpected.selector);
        vm.prank(admin);
        verifier.resume();
    }

    function test_processWithdrawalProof_RevertWhenPaused() public {
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        verifier.processWithdrawalProof(
            ICSVerifier.ProvableBeaconBlockHeader({
                header: BeaconBlockHeader({
                    slot: Slot.wrap(0),
                    proposerIndex: 0,
                    parentRoot: bytes32(0),
                    stateRoot: bytes32(0),
                    bodyRoot: bytes32(0)
                }),
                rootsTimestamp: 0
            }),
            ICSVerifier.WithdrawalWitness({
                withdrawalOffset: 0,
                withdrawalIndex: 0,
                validatorIndex: 0,
                amount: 0,
                withdrawalCredentials: bytes32(0),
                effectiveBalance: 0 ether,
                slashed: false,
                activationEligibilityEpoch: 0,
                activationEpoch: 0,
                exitEpoch: 0,
                withdrawableEpoch: 0,
                withdrawalProof: new bytes32[](0),
                validatorProof: new bytes32[](0)
            }),
            0,
            0
        );
    }

    function test_processHistoricalWithdrawalProof_RevertWhenPaused() public {
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        verifier.processHistoricalWithdrawalProof(
            ICSVerifier.ProvableBeaconBlockHeader({
                header: BeaconBlockHeader({
                    slot: Slot.wrap(0),
                    proposerIndex: 0,
                    parentRoot: bytes32(0),
                    stateRoot: bytes32(0),
                    bodyRoot: bytes32(0)
                }),
                rootsTimestamp: 0
            }),
            ICSVerifier.HistoricalHeaderWitness({
                header: BeaconBlockHeader({
                    slot: Slot.wrap(0),
                    proposerIndex: 0,
                    parentRoot: bytes32(0),
                    stateRoot: bytes32(0),
                    bodyRoot: bytes32(0)
                }),
                proof: new bytes32[](0)
            }),
            ICSVerifier.WithdrawalWitness({
                withdrawalOffset: 0,
                withdrawalIndex: 0,
                validatorIndex: 0,
                amount: 0,
                withdrawalCredentials: bytes32(0),
                effectiveBalance: 0 ether,
                slashed: false,
                activationEligibilityEpoch: 0,
                activationEpoch: 0,
                exitEpoch: 0,
                withdrawableEpoch: 0,
                withdrawalProof: new bytes32[](0),
                validatorProof: new bytes32[](0)
            }),
            0,
            0
        );
    }
}

contract CSVerifierTestable is CSVerifier {
    constructor(
        address withdrawalAddress,
        address module,
        uint64 slotsPerEpoch,
        uint64 slotsPerHistoricalRoot,
        ICSVerifier.GIndices memory gindices,
        Slot firstSupportedSlot,
        Slot pivotSlot,
        Slot capellaSlot,
        address admin
    )
        CSVerifier(
            withdrawalAddress,
            module,
            slotsPerEpoch,
            slotsPerHistoricalRoot,
            gindices,
            firstSupportedSlot,
            pivotSlot,
            capellaSlot,
            admin
        )
    {}

    function getValidatorGI(
        uint256 offset,
        Slot stateSlot
    ) external view returns (GIndex) {
        return _getValidatorGI(offset, stateSlot);
    }

    function getWithdrawalGI(
        uint256 offset,
        Slot stateSlot
    ) external view returns (GIndex) {
        return _getWithdrawalGI(offset, stateSlot);
    }

    function getHistoricalBlockRootGI(
        Slot recentSlot,
        Slot targetSlot
    ) external view returns (GIndex) {
        return _getHistoricalBlockRootGI(recentSlot, targetSlot);
    }
}

contract CSVerifierGIndexTest is Test, Utilities {
    CSVerifierTestable public verifier;
    address public admin;
    Stub public module;

    function setUp() public virtual {
        module = new Stub();
        admin = nextAddress("ADMIN");

        verifier = new CSVerifierTestable({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0x161c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x960000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x76000000, 24),
                gIFirstHistoricalSummaryCurr: pack(0xb6000000, 24),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4001, 13)
            }),
            firstSupportedSlot: Slot.wrap(8192),
            pivotSlot: Slot.wrap(100500),
            capellaSlot: Slot.wrap(8192),
            admin: admin
        });
    }

    function test_getValidatorGI_BeforeForkChange() public view {
        uint256[] memory slots = UintArr(8192, 8193, 100499);
        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = Slot.wrap(uint64(slots[i]));

            gI = verifier.getValidatorGI(0, slot);
            assertEq(gI.unwrap(), pack(0x560000000000, 40).unwrap());

            gI = verifier.getValidatorGI(1, slot);
            assertEq(gI.unwrap(), pack(0x560000000001, 40).unwrap());

            gI = verifier.getValidatorGI(16, slot);
            assertEq(gI.unwrap(), pack(0x560000000010, 40).unwrap());

            gI = verifier.getValidatorGI(17, slot);
            assertEq(gI.unwrap(), pack(0x560000000011, 40).unwrap());

            gI = verifier.getValidatorGI((2 ** 40) - 1, slot);
            assertEq(gI.unwrap(), pack(0x56ffffffffff, 40).unwrap());
        }
    }

    function test_getValidatorGI_AfterForkChange() public view {
        uint256[] memory slots = UintArr(100500, 100501, 999999);
        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = Slot.wrap(uint64(slots[i]));

            gI = verifier.getValidatorGI(0, slot);
            assertEq(gI.unwrap(), pack(0x960000000000, 40).unwrap());

            gI = verifier.getValidatorGI(1, slot);
            assertEq(gI.unwrap(), pack(0x960000000001, 40).unwrap());

            gI = verifier.getValidatorGI(16, slot);
            assertEq(gI.unwrap(), pack(0x960000000010, 40).unwrap());

            gI = verifier.getValidatorGI(17, slot);
            assertEq(gI.unwrap(), pack(0x960000000011, 40).unwrap());

            gI = verifier.getValidatorGI((2 ** 40) - 1, slot);
            assertEq(gI.unwrap(), pack(0x96ffffffffff, 40).unwrap());
        }
    }

    function test_getWithdrawalGI_BeforeForkChange() public view {
        uint256[] memory slots = UintArr(8192, 8193, 100499);
        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = Slot.wrap(uint64(slots[i]));

            gI = verifier.getWithdrawalGI(0, slot);
            assertEq(gI.unwrap(), pack(0xe1c0, 4).unwrap());

            gI = verifier.getWithdrawalGI(1, slot);
            assertEq(gI.unwrap(), pack(0xe1c1, 4).unwrap());

            gI = verifier.getWithdrawalGI(15, slot);
            assertEq(gI.unwrap(), pack(0xe1cf, 4).unwrap());
        }
    }

    function test_getWithdrawalGI_AfterForkChange() public view {
        uint256[] memory slots = UintArr(100500, 100501, 999999);
        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = Slot.wrap(uint64(slots[i]));

            gI = verifier.getWithdrawalGI(0, slot);
            assertEq(gI.unwrap(), pack(0x161c0, 4).unwrap());

            gI = verifier.getWithdrawalGI(1, slot);
            assertEq(gI.unwrap(), pack(0x161c1, 4).unwrap());

            gI = verifier.getWithdrawalGI(15, slot);
            assertEq(gI.unwrap(), pack(0x161cf, 4).unwrap());
        }
    }

    function test_getHistoricalBlockRootGI_BeforePivot() public view {
        Slot recentSlot = Slot.wrap(100499);
        Slot targetSlot;

        GIndex gI;

        targetSlot = Slot.wrap(8192);
        // historicalSummaries[0].blockRoots[0]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000000000, 13).unwrap());

        targetSlot = Slot.wrap(8193);
        // historicalSummaries[0].blockRoots[1]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000000001, 13).unwrap());

        targetSlot = Slot.wrap(49042);
        // historicalSummaries[4].blockRoots[8082]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000011f92, 13).unwrap());
    }

    function test_getHistoricalBlockRootGI_AfterPivot() public view {
        Slot recentSlot = Slot.wrap(100502);
        Slot targetSlot;

        GIndex gI;

        targetSlot = Slot.wrap(8192);
        // historicalSummaries[0].blockRoots[0]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000000000, 13).unwrap());

        targetSlot = Slot.wrap(8193);
        // historicalSummaries[0].blockRoots[1]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000000001, 13).unwrap());

        targetSlot = Slot.wrap(49042);
        // historicalSummaries[4].blockRoots[8082]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000011f92, 13).unwrap());

        targetSlot = Slot.wrap(100500);
        // historicalSummaries[11].blockRoots[2196]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d800002c894 + 1, 13).unwrap());

        targetSlot = Slot.wrap(100501);
        // historicalSummaries[11].blockRoots[2197]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d800002c895 + 1, 13).unwrap());
    }
}

contract CSVerifierGIndexCapellaZeroTest is Test, Utilities {
    CSVerifierTestable public verifier;
    address public admin;
    Stub public module;

    function setUp() public {
        module = new Stub();
        admin = nextAddress("ADMIN");

        verifier = new CSVerifierTestable({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0x161c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x960000000000, 40),
                gIFirstHistoricalSummaryPrev: pack(0x76000000, 24),
                gIFirstHistoricalSummaryCurr: pack(0xb6000000, 24),
                gIFirstBlockRootInSummaryPrev: pack(0x4000, 13),
                gIFirstBlockRootInSummaryCurr: pack(0x4001, 13)
            }),
            firstSupportedSlot: Slot.wrap(0),
            pivotSlot: Slot.wrap(100500),
            capellaSlot: Slot.wrap(0),
            admin: admin
        });
    }

    function test_getHistoricalBlockRootGI_BeforePivot() public view {
        Slot recentSlot = Slot.wrap(100499);
        Slot targetSlot;

        GIndex gI;

        targetSlot = Slot.wrap(8191);
        // historicalSummaries[0].blockRoots[8191]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000001fff, 13).unwrap());

        targetSlot = Slot.wrap(8192);
        // historicalSummaries[1].blockRoots[0]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000004000, 13).unwrap());

        targetSlot = Slot.wrap(8193);
        // historicalSummaries[1].blockRoots[1]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000004001, 13).unwrap());

        targetSlot = Slot.wrap(49042);
        // historicalSummaries[5].blockRoots[8082]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x1d8000015f92, 13).unwrap());
    }

    function test_getHistoricalBlockRootGI_AfterPivot() public view {
        Slot recentSlot = Slot.wrap(100501);
        Slot targetSlot;

        GIndex gI;

        targetSlot = Slot.wrap(8191);
        // historicalSummaries[0].blockRoots[8191]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000001fff, 13).unwrap());

        targetSlot = Slot.wrap(8192);
        // historicalSummaries[1].blockRoots[0]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000004000, 13).unwrap());

        targetSlot = Slot.wrap(8193);
        // historicalSummaries[1].blockRoots[1]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000004001, 13).unwrap());

        targetSlot = Slot.wrap(49042);
        // historicalSummaries[5].blockRoots[8082]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000015f92, 13).unwrap());

        targetSlot = Slot.wrap(100501);
        // historicalSummaries[12].blockRoots[2197]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000030895 + 1, 13).unwrap());
    }
}
