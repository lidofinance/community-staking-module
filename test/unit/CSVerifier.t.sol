// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { PausableUntil } from "src/lib/utils/PausableUntil.sol";
import { CSVerifier } from "src/CSVerifier.sol";
import { pack } from "src/lib/GIndex.sol";
import { Slot, BeaconBlockHeader } from "src/lib/Types.sol";
import { GIndex } from "src/lib/GIndex.sol";

import { ICSVerifier } from "src/interfaces/ICSVerifier.sol";
import { ICSModule, ValidatorWithdrawalInfo } from "src/interfaces/ICSModule.sol";

import { GIndices } from "script/constants/GIndices.sol";

import { Utilities } from "test/helpers/Utilities.sol";
import { Stub } from "test/helpers/mocks/Stub.sol";

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

function add(Slot self, uint64 v) pure returns (Slot slot) {
    assembly ("memory-safe") {
        slot := add(self, v)
    }
}

using { dec, inc, add } for Slot;

GIndex constant NULL_GINDEX = GIndex.wrap(0);

contract CSVerifierTestBase is Test, Utilities {
    using stdJson for string;

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
                gIFirstBlockRootInSummaryCurr: pack(0x4001, 13),
                gIFirstBalanceNodePrev: pack(0x160000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x160000000001, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200001, 18)
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
            GIndex.unwrap(verifier.GI_FIRST_BALANCES_NODE_PREV()),
            GIndex.unwrap(pack(0x160000000000, 40))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_BALANCES_NODE_CURR()),
            GIndex.unwrap(pack(0x160000000001, 40))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_PENDING_CONSOLIDATION_PREV()),
            GIndex.unwrap(pack(0x3200000, 18))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_PENDING_CONSOLIDATION_CURR()),
            GIndex.unwrap(pack(0x3200001, 18))
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
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
                gIFirstBlockRootInSummaryCurr: pack(0x4000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x260000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x3200000, 18)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            capellaSlot: firstSupportedSlot,
            admin: address(0)
        });
    }
}

contract CSVerifierWithdrawalTest is CSVerifierTestBase {
    struct WithdrawalFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        ICSVerifier.RecentHeaderWitness beaconBlock;
        ICSVerifier.WithdrawalWitness witness;
    }

    WithdrawalFixture internal fixture;

    function setUp() public {
        module = new Stub();
        admin = nextAddress("ADMIN");

        fixture = abi.decode(
            _readFixture("withdrawal.json"),
            (WithdrawalFixture)
        );

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
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
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

        _setMocksWithdrawal(fixture);
    }

    function test_processWithdrawalProof_HappyPath() public {
        ValidatorWithdrawalInfo[]
            memory withdrawals = new ValidatorWithdrawalInfo[](1);
        withdrawals[0] = ValidatorWithdrawalInfo({
            nodeOperatorId: 0,
            keyIndex: 0,
            exitBalance: uint256(fixture.witness.amount) * 1e9,
            slashingPenalty: 0
        });

        vm.expectCall(
            address(module),
            abi.encodeWithSelector(
                ICSModule.submitWithdrawals.selector,
                withdrawals
            )
        );

        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_ZeroWithdrawalIndex() public {
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_UnsupportedSlot() public {
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
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode(hex"deadbeef")
        );

        vm.expectRevert(ICSVerifier.InvalidBlockHeader.selector);
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
        fixture.witness.withdrawalCredentials = bytes32(0);

        vm.expectRevert(ICSVerifier.InvalidWithdrawalAddress.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processHistoricalWithdrawalProof_RevertWhen_ValidatorSlashed()
        public
    {
        fixture.witness.slashed = true;

        vm.expectRevert(ICSVerifier.ValidatorIsSlashed.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_ValidatorIsNotWithdrawable()
        public
    {
        fixture.witness.withdrawableEpoch =
            fixture.beaconBlock.header.slot.unwrap() /
            32 +
            154;

        vm.expectRevert(ICSVerifier.ValidatorIsNotWithdrawable.selector);
        verifier.processWithdrawalProof(
            fixture.beaconBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_PartialWitdrawal() public {
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
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
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
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
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
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
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

    function _setMocksWithdrawal(WithdrawalFixture memory f) internal {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(f.beaconBlock.rootsTimestamp),
            abi.encode(f._blockRoot)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector, 0, 0),
            abi.encode(f._pubkey)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawals.selector),
            ""
        );
    }
}

contract CSVerifierConsolidationTest is CSVerifierTestBase {
    struct Fixture {
        bytes32 blockRoot;
        uint256 balanceWei;
        ICSVerifier.ProcessConsolidationInput data;
    }

    Fixture internal fixture;

    function setUp() public {
        _loadFixture();

        module = new Stub();
        admin = nextAddress("ADMIN");

        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            slotsPerHistoricalRoot: 8192,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: NULL_GINDEX,
                gIFirstWithdrawalCurr: NULL_GINDEX,
                gIFirstValidatorPrev: GIndices.FIRST_VALIDATOR_ELECTRA,
                gIFirstValidatorCurr: GIndices.FIRST_VALIDATOR_ELECTRA,
                gIFirstHistoricalSummaryPrev: GIndices
                    .FIRST_HISTORICAL_SUMMARY_ELECTRA,
                gIFirstHistoricalSummaryCurr: GIndices
                    .FIRST_HISTORICAL_SUMMARY_ELECTRA,
                gIFirstBlockRootInSummaryPrev: GIndices
                    .FIRST_BLOCK_ROOT_IN_SUMMARY_ELECTRA,
                gIFirstBlockRootInSummaryCurr: GIndices
                    .FIRST_BLOCK_ROOT_IN_SUMMARY_ELECTRA,
                gIFirstBalanceNodePrev: GIndices.FIRST_BALANCE_NODE_ELECTRA,
                gIFirstBalanceNodeCurr: GIndices.FIRST_BALANCE_NODE_ELECTRA,
                gIFirstPendingConsolidationPrev: GIndices
                    .FIRST_PENDING_CONSOLIDATION_ELECTRA,
                gIFirstPendingConsolidationCurr: GIndices
                    .FIRST_PENDING_CONSOLIDATION_ELECTRA
            }),
            firstSupportedSlot: Slot.wrap(8192),
            pivotSlot: Slot.wrap(8192),
            capellaSlot: Slot.wrap(0),
            admin: admin
        });

        pauseRole = verifier.PAUSE_ROLE();
        resumeRole = verifier.RESUME_ROLE();

        vm.startPrank(admin);
        verifier.grantRole(pauseRole, admin);
        verifier.grantRole(resumeRole, admin);
        vm.stopPrank();

        _setMocks();

        assertGt(
            verifier.FIRST_SUPPORTED_SLOT().unwrap(),
            0,
            "Non-zero slot needed for tests"
        );
    }

    function test_processConsolidationProof_HappyPath() public {
        ValidatorWithdrawalInfo[]
            memory withdrawals = new ValidatorWithdrawalInfo[](1);
        withdrawals[0] = ValidatorWithdrawalInfo({
            nodeOperatorId: fixture.data.validator.nodeOperatorId,
            keyIndex: fixture.data.validator.keyIndex,
            exitBalance: fixture.balanceWei,
            slashingPenalty: 0
        });

        vm.expectCall(
            address(module),
            abi.encodeWithSelector(
                ICSModule.submitWithdrawals.selector,
                withdrawals
            )
        );

        verifier.processConsolidation(fixture.data);
    }

    function test_processWithdrawalProof_RevertWhenPaused() public {
        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_RecentBlockSlotUnsupported()
        public
    {
        fixture.data.recentBlock.header.slot = verifier
            .FIRST_SUPPORTED_SLOT()
            .dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICSVerifier.UnsupportedSlot.selector,
                fixture.data.recentBlock.header.slot
            )
        );
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_WithdrawableBlockSlotUnsupported()
        public
    {
        fixture.data.withdrawableBlock.header.slot = verifier
            .FIRST_SUPPORTED_SLOT()
            .dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICSVerifier.UnsupportedSlot.selector,
                fixture.data.withdrawableBlock.header.slot
            )
        );
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_ConsolidationBlockSlotUnsupported()
        public
    {
        fixture.data.consolidationBlock.header.slot = verifier
            .FIRST_SUPPORTED_SLOT()
            .dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICSVerifier.UnsupportedSlot.selector,
                fixture.data.consolidationBlock.header.slot
            )
        );
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_Slashed() public {
        fixture.data.validator.object.slashed = true;

        vm.expectRevert(ICSVerifier.ValidatorIsSlashed.selector);
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_InvalidPublicKey() public {
        fixture.data.validator.object.pubkey = hex"deadbeef";

        vm.expectRevert(ICSVerifier.InvalidPublicKey.selector);
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_ValidatorIsNotWithdrawable()
        public
    {
        fixture.data.validator.object.withdrawableEpoch =
            fixture.data.withdrawableBlock.header.slot.unwrap() *
            32 +
            1;
        vm.expectRevert(ICSVerifier.ValidatorIsNotWithdrawable.selector);
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_InvalidConsolidationSource()
        public
    {
        fixture.data.consolidation.object.sourceIndex =
            fixture.data.validator.index +
            1;
        vm.expectRevert(ICSVerifier.InvalidConsolidationSource.selector);
        verifier.processConsolidation(fixture.data);
    }

    function test_processConsolidation_RevertWhen_InvalidBlockHeader() public {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.data.recentBlock.rootsTimestamp),
            abi.encode(hex"deadbeef")
        );

        vm.expectRevert(ICSVerifier.InvalidBlockHeader.selector);
        verifier.processConsolidation(fixture.data);
    }

    function _setMocks() internal {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.data.recentBlock.rootsTimestamp),
            abi.encode(fixture.blockRoot)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(
                ICSModule.getSigningKeys.selector,
                fixture.data.validator.nodeOperatorId,
                fixture.data.validator.keyIndex
            ),
            abi.encode(fixture.data.validator.object.pubkey)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawals.selector),
            ""
        );
    }

    function _loadFixture() internal {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "--no-warnings";
        cmd[2] = "test/fixtures/CSVerifier/consolidations.mjs";
        bytes memory res = vm.ffi(cmd);
        fixture = abi.decode(res, (Fixture));
    }

    function ffi_interface(Fixture memory) external {}
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
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
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
            ICSVerifier.RecentHeaderWitness({
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
            ICSVerifier.RecentHeaderWitness({
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

    function getValidatorBalanceGI(
        uint256 offset,
        Slot stateSlot
    ) external view returns (GIndex) {
        return _getValidatorBalanceGI(offset, stateSlot);
    }

    function getPendingConsolidationGI(
        uint256 offset,
        Slot stateSlot
    ) external view returns (GIndex) {
        return _getPendingConsolidationGI(offset, stateSlot);
    }

    function getHistoricalBlockRootGI(
        Slot recentSlot,
        Slot targetSlot
    ) external view returns (GIndex) {
        return _getHistoricalBlockRootGI(recentSlot, targetSlot);
    }

    function verifyValidatorBalance(
        uint256 validatorIndex,
        bytes32 balanceNode,
        bytes32 stateRoot,
        Slot stateSlot,
        bytes32[] calldata proof
    ) external view returns (uint256) {
        return
            _verifyValidatorBalance(
                validatorIndex,
                balanceNode,
                stateRoot,
                stateSlot,
                proof
            );
    }

    function getValidatorBalanceNodeInfo(
        bytes32 balanceNode,
        uint256 validatorIndex,
        Slot stateSlot
    ) external view returns (GIndex gI, uint256 balance) {
        return
            _getValidatorBalanceNodeInfo(
                balanceNode,
                validatorIndex,
                stateSlot
            );
    }

    function getParentBlockRoot(
        uint64 blockTimestamp
    ) external view returns (bytes32) {
        return _getParentBlockRoot(blockTimestamp);
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
                gIFirstBlockRootInSummaryCurr: pack(0x6000, 13),
                gIFirstBalanceNodePrev: pack(0x260000000000, 40),
                gIFirstBalanceNodeCurr: pack(0x360000000000, 40),
                gIFirstPendingConsolidationPrev: pack(0x3200000, 18),
                gIFirstPendingConsolidationCurr: pack(0x4200000, 18)
            }),
            firstSupportedSlot: Slot.wrap(8192),
            pivotSlot: Slot.wrap(8192 * 13),
            capellaSlot: Slot.wrap(8192),
            admin: admin
        });

        assertTrue(verifier.PIVOT_SLOT() > verifier.FIRST_SUPPORTED_SLOT());
    }

    function test_getValidatorGI_BeforeForkChange() public view {
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.FIRST_SUPPORTED_SLOT();
        slots[1] = verifier.FIRST_SUPPORTED_SLOT().inc();
        slots[2] = verifier.PIVOT_SLOT().dec();

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

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
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.PIVOT_SLOT();
        slots[1] = verifier.PIVOT_SLOT().inc();
        slots[2] = Slot.wrap(type(uint64).max);

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

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
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.FIRST_SUPPORTED_SLOT();
        slots[1] = verifier.FIRST_SUPPORTED_SLOT().inc();
        slots[2] = verifier.PIVOT_SLOT().dec();

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

            gI = verifier.getWithdrawalGI(0, slot);
            assertEq(gI.unwrap(), pack(0xe1c0, 4).unwrap());

            gI = verifier.getWithdrawalGI(1, slot);
            assertEq(gI.unwrap(), pack(0xe1c1, 4).unwrap());

            gI = verifier.getWithdrawalGI(15, slot);
            assertEq(gI.unwrap(), pack(0xe1cf, 4).unwrap());
        }
    }

    function test_getWithdrawalGI_AfterForkChange() public view {
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.PIVOT_SLOT();
        slots[1] = verifier.PIVOT_SLOT().inc();
        slots[2] = Slot.wrap(type(uint64).max);

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

            gI = verifier.getWithdrawalGI(0, slot);
            assertEq(gI.unwrap(), pack(0x161c0, 4).unwrap());

            gI = verifier.getWithdrawalGI(1, slot);
            assertEq(gI.unwrap(), pack(0x161c1, 4).unwrap());

            gI = verifier.getWithdrawalGI(15, slot);
            assertEq(gI.unwrap(), pack(0x161cf, 4).unwrap());
        }
    }

    function test_getValidatorBalanceGI_BeforeForkChange() public view {
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.FIRST_SUPPORTED_SLOT();
        slots[1] = verifier.FIRST_SUPPORTED_SLOT().inc();
        slots[2] = verifier.PIVOT_SLOT().dec();

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

            gI = verifier.getValidatorBalanceGI(0, slot);
            assertEq(gI.unwrap(), pack(0x260000000000, 40).unwrap());

            gI = verifier.getValidatorBalanceGI(1, slot);
            assertEq(gI.unwrap(), pack(0x260000000001, 40).unwrap());

            gI = verifier.getValidatorBalanceGI(16, slot);
            assertEq(gI.unwrap(), pack(0x260000000010, 40).unwrap());

            gI = verifier.getValidatorBalanceGI(17, slot);
            assertEq(gI.unwrap(), pack(0x260000000011, 40).unwrap());

            gI = verifier.getValidatorBalanceGI((2 ** 40) - 1, slot);
            assertEq(gI.unwrap(), pack(0x26ffffffffff, 40).unwrap());
        }
    }

    function test_getValidatorBalanceGI_AfterForkChange() public view {
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.PIVOT_SLOT();
        slots[1] = verifier.PIVOT_SLOT().inc();
        slots[2] = Slot.wrap(type(uint64).max);

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

            gI = verifier.getValidatorBalanceGI(0, slot);
            assertEq(gI.unwrap(), pack(0x360000000000, 40).unwrap());

            gI = verifier.getValidatorBalanceGI(1, slot);
            assertEq(gI.unwrap(), pack(0x360000000001, 40).unwrap());

            gI = verifier.getValidatorBalanceGI(16, slot);
            assertEq(gI.unwrap(), pack(0x360000000010, 40).unwrap());

            gI = verifier.getValidatorBalanceGI(17, slot);
            assertEq(gI.unwrap(), pack(0x360000000011, 40).unwrap());

            gI = verifier.getValidatorBalanceGI((2 ** 40) - 1, slot);
            assertEq(gI.unwrap(), pack(0x36ffffffffff, 40).unwrap());
        }
    }

    function test_getPendingConsolidationGI_BeforeForkChange() public view {
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.FIRST_SUPPORTED_SLOT();
        slots[1] = verifier.FIRST_SUPPORTED_SLOT().inc();
        slots[2] = verifier.PIVOT_SLOT().dec();

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

            gI = verifier.getPendingConsolidationGI(0, slot);
            assertEq(gI.unwrap(), pack(0x3200000, 18).unwrap());

            gI = verifier.getPendingConsolidationGI(1, slot);
            assertEq(gI.unwrap(), pack(0x3200001, 18).unwrap());

            gI = verifier.getPendingConsolidationGI(16, slot);
            assertEq(gI.unwrap(), pack(0x3200010, 18).unwrap());

            gI = verifier.getPendingConsolidationGI(17, slot);
            assertEq(gI.unwrap(), pack(0x3200011, 18).unwrap());

            gI = verifier.getPendingConsolidationGI((2 ** 18) - 1, slot);
            assertEq(gI.unwrap(), pack(0x323ffff, 18).unwrap());
        }
    }

    function test_getPendingConsolidationGI_AfterForkChange() public view {
        Slot[] memory slots = new Slot[](3);

        slots[0] = verifier.PIVOT_SLOT();
        slots[1] = verifier.PIVOT_SLOT().inc();
        slots[2] = Slot.wrap(type(uint64).max);

        GIndex gI;

        for (uint256 i = 0; i < slots.length; i++) {
            Slot slot = slots[i];

            gI = verifier.getPendingConsolidationGI(0, slot);
            assertEq(gI.unwrap(), pack(0x4200000, 18).unwrap());

            gI = verifier.getPendingConsolidationGI(1, slot);
            assertEq(gI.unwrap(), pack(0x4200001, 18).unwrap());

            gI = verifier.getPendingConsolidationGI(16, slot);
            assertEq(gI.unwrap(), pack(0x4200010, 18).unwrap());

            gI = verifier.getPendingConsolidationGI(17, slot);
            assertEq(gI.unwrap(), pack(0x4200011, 18).unwrap());

            gI = verifier.getPendingConsolidationGI((2 ** 18) - 1, slot);
            assertEq(gI.unwrap(), pack(0x423ffff, 18).unwrap());
        }
    }

    function test_getHistoricalBlockRootGI_BeforePivot() public view {
        Slot recentSlot = verifier.PIVOT_SLOT().dec();
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
        Slot recentSlot = verifier.PIVOT_SLOT().add(8192);
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

        // NOTE: targetSlot < PIVOT, but historicalSummary was built for slot >= PIVOT.
        targetSlot = Slot.wrap(100499);
        // historicalSummaries[11].blockRoots[2195]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d800002e893, 13).unwrap());

        // NOTE: Similar to the previous test case.
        targetSlot = verifier.PIVOT_SLOT().dec();
        // historicalSummaries[11].blockRoots[8191]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d800002ffff, 13).unwrap());

        targetSlot = verifier.PIVOT_SLOT();
        // historicalSummaries[12].blockRoots[0]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000032000, 13).unwrap());

        targetSlot = verifier.PIVOT_SLOT().inc();
        // historicalSummaries[X].blockRoots[1]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000032001, 13).unwrap());

        targetSlot = verifier.PIVOT_SLOT().add(42);
        // historicalSummaries[X].blockRoots[1]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d800003202a, 13).unwrap());
    }

    function test_getHistoricalBlockRootGI_RevertWhen_SummaryCannotExist()
        public
    {
        Slot recentSlot;
        Slot targetSlot;

        targetSlot = Slot.wrap(8192);
        recentSlot = Slot.wrap(8192);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);

        targetSlot = Slot.wrap(8192);
        recentSlot = Slot.wrap(8193);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);

        targetSlot = Slot.wrap(8192);
        recentSlot = Slot.wrap(8192 + 8191);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);

        targetSlot = Slot.wrap(8192);
        recentSlot = Slot.wrap(8191);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
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
                gIFirstBlockRootInSummaryCurr: pack(0x6000, 13),
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
            }),
            firstSupportedSlot: Slot.wrap(0),
            pivotSlot: Slot.wrap(8192 * 13),
            capellaSlot: Slot.wrap(0),
            admin: admin
        });
    }

    function test_getHistoricalBlockRootGI_BeforePivot() public view {
        Slot recentSlot = verifier.PIVOT_SLOT().dec();
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
        Slot recentSlot = verifier.PIVOT_SLOT().add(8192);
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

        // NOTE: targetSlot < PIVOT, but historicalSummary was built for slot > PIVOT.
        targetSlot = verifier.PIVOT_SLOT().dec();
        // historicalSummaries[12].blockRoots[8191]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000033fff, 13).unwrap());

        targetSlot = verifier.PIVOT_SLOT().add(2197);
        // historicalSummaries[13].blockRoots[2197]
        gI = verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
        assertEq(gI.unwrap(), pack(0x2d8000036895, 13).unwrap());
    }

    function test_getHistoricalBlockRootGI_RevertWhen_SummaryCannotExist()
        public
    {
        Slot recentSlot;
        Slot targetSlot;

        targetSlot = Slot.wrap(0);
        recentSlot = Slot.wrap(0);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);

        targetSlot = Slot.wrap(0);
        recentSlot = Slot.wrap(8191);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);

        targetSlot = Slot.wrap(8191);
        recentSlot = Slot.wrap(8191);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);

        targetSlot = Slot.wrap(8192);
        recentSlot = Slot.wrap(8191);
        vm.expectRevert(ICSVerifier.HistoricalSummaryDoesNotExist.selector);
        verifier.getHistoricalBlockRootGI(recentSlot, targetSlot);
    }
}

contract CSVerifierValidatorBalanceTest is Test, Utilities {
    // @see ../script/ssz_list_uint64.mjs

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
                gIFirstWithdrawalPrev: NULL_GINDEX,
                gIFirstWithdrawalCurr: NULL_GINDEX,
                gIFirstValidatorPrev: NULL_GINDEX,
                gIFirstValidatorCurr: NULL_GINDEX,
                gIFirstHistoricalSummaryPrev: NULL_GINDEX,
                gIFirstHistoricalSummaryCurr: NULL_GINDEX,
                gIFirstBlockRootInSummaryPrev: NULL_GINDEX,
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: pack(0x8, 4),
                gIFirstBalanceNodeCurr: pack(0x8, 4),
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
            }),
            firstSupportedSlot: Slot.wrap(8192),
            pivotSlot: Slot.wrap(8192 * 13),
            capellaSlot: Slot.wrap(8192),
            admin: admin
        });
    }

    function test_validatorBalance_Index_0() public view {
        bytes32[] memory proof = new bytes32[](3);

        // prettier-ignore
        {
            proof[0] = 0xe39ab07307000000000000000000000000000000000000002120b07307000000;
            proof[1] = 0xd7b8f9581adbdd02f99ab10acdbccd05a694d6f1d98a118c8422d91c151c4aac;
            proof[2] = 0x0a00000000000000000000000000000000000000000000000000000000000000;
        }

        uint256 balance = verifier.verifyValidatorBalance({
            validatorIndex: 0,
            balanceNode: 0x93f5317407000000dc7c7a7607000000dd7c7a76070000000aa1b07307000000,
            stateRoot: 0xf0b08e19548a9c618b163e30c63453c721b18c6e246ac0b742464c3adb43189e,
            stateSlot: verifier.PIVOT_SLOT(),
            proof: proof
        });

        assertEq(balance, 32014202259);
    }

    function test_validatorBalance_Index_1() public view {
        bytes32[] memory proof = new bytes32[](3);

        // prettier-ignore
        {
            proof[0] = 0xe39ab07307000000000000000000000000000000000000002120b07307000000;
            proof[1] = 0xd7b8f9581adbdd02f99ab10acdbccd05a694d6f1d98a118c8422d91c151c4aac;
            proof[2] = 0x0a00000000000000000000000000000000000000000000000000000000000000;
        }

        uint256 balance = verifier.verifyValidatorBalance({
            validatorIndex: 1,
            balanceNode: 0x93f5317407000000dc7c7a7607000000dd7c7a76070000000aa1b07307000000,
            stateRoot: 0xf0b08e19548a9c618b163e30c63453c721b18c6e246ac0b742464c3adb43189e,
            stateSlot: verifier.PIVOT_SLOT(),
            proof: proof
        });

        assertEq(balance, 32052509916);
    }

    function test_validatorBalance_Index_7() public view {
        bytes32[] memory proof = new bytes32[](3);

        // prettier-ignore
        {
            proof[0] = 0x93f5317407000000dc7c7a7607000000dd7c7a76070000000aa1b07307000000;
            proof[1] = 0xd7b8f9581adbdd02f99ab10acdbccd05a694d6f1d98a118c8422d91c151c4aac;
            proof[2] = 0x0a00000000000000000000000000000000000000000000000000000000000000;
        }

        uint256 balance = verifier.verifyValidatorBalance({
            validatorIndex: 7,
            balanceNode: 0xe39ab07307000000000000000000000000000000000000002120b07307000000,
            stateRoot: 0xf0b08e19548a9c618b163e30c63453c721b18c6e246ac0b742464c3adb43189e,
            stateSlot: verifier.PIVOT_SLOT(),
            proof: proof
        });

        assertEq(balance, 32005693473);
    }

    function test_validatorBalance_ZeroBalance() public view {
        bytes32[] memory proof = new bytes32[](3);

        // prettier-ignore
        {
            proof[0] = 0x93f5317407000000dc7c7a7607000000dd7c7a76070000000aa1b07307000000;
            proof[1] = 0xd7b8f9581adbdd02f99ab10acdbccd05a694d6f1d98a118c8422d91c151c4aac;
            proof[2] = 0x0a00000000000000000000000000000000000000000000000000000000000000;
        }

        uint256 balance = verifier.verifyValidatorBalance({
            validatorIndex: 5,
            balanceNode: 0xe39ab07307000000000000000000000000000000000000002120b07307000000,
            stateRoot: 0xf0b08e19548a9c618b163e30c63453c721b18c6e246ac0b742464c3adb43189e,
            stateSlot: verifier.PIVOT_SLOT(),
            proof: proof
        });

        assertEq(balance, 0);
    }

    function test_validatorBalance_MaxBalance() public view {
        bytes32[] memory proof = new bytes32[](3);

        // prettier-ignore
        {
            proof[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
            proof[1] = 0x12a77241a7a0d3da9ef754d436b3bd52aa4be3d914857bc5ae6e744ffafc44e7;
            proof[2] = 0x0b00000000000000000000000000000000000000000000000000000000000000;
        }

        uint256 balance = verifier.verifyValidatorBalance({
            validatorIndex: 10,
            balanceNode: 0x0a51b073070000001cb8b07307000000ffffffffffffffff0000000000000000,
            stateRoot: 0x9b11d3d9b44c0b3c53df36e2e132adee11e9da0d70451d1e3271f638019883b5,
            stateSlot: verifier.PIVOT_SLOT(),
            proof: proof
        });

        assertEq(balance, type(uint64).max);
    }

    function test_validatorBalance_NodeInfo_Balance() public {
        uint256 balance;

        for (uint i = 0; i < 4; ++i) {
            (, balance) = verifier.getValidatorBalanceNodeInfo(
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0,
                verifier.PIVOT_SLOT()
            );
            assertEq(balance, 0);
        }

        (, balance) = verifier.getValidatorBalanceNodeInfo(
            0x1112131415161718ffffffffffffffffffffffffffffffffffffffffffffffff,
            0,
            verifier.PIVOT_SLOT()
        );
        assertEq(balance, 0x1817161514131211);

        (, balance) = verifier.getValidatorBalanceNodeInfo(
            0xffffffffffffffff1112131415161718ffffffffffffffffffffffffffffffff,
            1,
            verifier.PIVOT_SLOT()
        );
        assertEq(balance, 0x1817161514131211);

        (, balance) = verifier.getValidatorBalanceNodeInfo(
            0xffffffffffffffffffffffffffffffff1112131415161718ffffffffffffffff,
            2,
            verifier.PIVOT_SLOT()
        );
        assertEq(balance, 0x1817161514131211);

        (, balance) = verifier.getValidatorBalanceNodeInfo(
            0xffffffffffffffffffffffffffffffffffffffffffffffff1112131415161718,
            3,
            verifier.PIVOT_SLOT()
        );
        assertEq(balance, 0x1817161514131211);

        (, balance) = verifier.getValidatorBalanceNodeInfo(
            0x1112131415161718ffffffffffffffffffffffffffffffffffffffffffffffff,
            4,
            verifier.PIVOT_SLOT()
        );
        assertEq(balance, 0x1817161514131211);
    }
}

contract CSVerifierParentBlockRootTest is Test, Utilities {
    CSVerifierTestable public verifier;
    address public admin;
    Stub public module;

    // @see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-4788.md
    // The code is obtained via `cast code 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`
    bytes internal BEACON_ROOTS_CODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604d57602036146024575f5ffd5b5f35801560495762001fff810690815414603c575f5ffd5b62001fff01545f5260205ff35b5f5ffd5b62001fff42064281555f359062001fff015500";
    address internal SYSTEM_ADDRESS =
        0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    function setUp() public virtual {
        module = new Stub();
        admin = nextAddress("ADMIN");

        verifier = new CSVerifierTestable({
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
                gIFirstBlockRootInSummaryCurr: NULL_GINDEX,
                gIFirstBalanceNodePrev: NULL_GINDEX,
                gIFirstBalanceNodeCurr: NULL_GINDEX,
                gIFirstPendingConsolidationPrev: NULL_GINDEX,
                gIFirstPendingConsolidationCurr: NULL_GINDEX
            }),
            firstSupportedSlot: Slot.wrap(8192),
            pivotSlot: Slot.wrap(8192 * 13),
            capellaSlot: Slot.wrap(8192),
            admin: admin
        });
    }

    function testFuzz_getParentBlockRoot_HappyPath(
        bytes32 expected,
        uint64 ts
    ) public {
        vm.assume(ts > 0); // The EIP-4788 reverts with 0 as an input.

        vm.etch(verifier.BEACON_ROOTS(), BEACON_ROOTS_CODE);

        // Sets the block root for the timestamp.
        {
            vm.startPrank(SYSTEM_ADDRESS);
            vm.warp(ts);
            verifier.BEACON_ROOTS().call(abi.encode(expected));
            vm.stopPrank();
        }

        bytes32 actual = verifier.getParentBlockRoot(ts);
        assertEq(actual, expected);
    }

    function test_getParentBlockRoot_RevertWhen_NoCodeAt4788Contract() public {
        vm.etch(verifier.BEACON_ROOTS(), hex"");
        vm.expectRevert(ICSVerifier.RootNotFound.selector);
        verifier.getParentBlockRoot(42);
    }

    function test_getParentBlockRoot_RevertWhen_4788ContractReverts() public {
        vm.etch(verifier.BEACON_ROOTS(), hex"5F5FFD"); // revert(0,0)
        vm.expectRevert(ICSVerifier.RootNotFound.selector);
        verifier.getParentBlockRoot(42);
    }

    function test_getParentBlockRoot_RevertWhen_RootNotFound() public {
        vm.etch(verifier.BEACON_ROOTS(), BEACON_ROOTS_CODE);
        vm.expectRevert(ICSVerifier.RootNotFound.selector);
        verifier.getParentBlockRoot(42);
    }
}
