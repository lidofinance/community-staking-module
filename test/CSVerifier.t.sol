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
import { Slot } from "../src/lib/Types.sol";
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

    function test_constructor() public {
        address withdrawalAddress = nextAddress("WITHDRAWAL_ADDRESS");

        verifier = new CSVerifier({
            withdrawalAddress: withdrawalAddress,
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: pack(0xfff0, 4),
                gIHistoricalSummariesCurr: pack(0xffff, 4),
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c1, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000001, 40)
            }),
            firstSupportedSlot: firstSupportedSlot,
            pivotSlot: Slot.wrap(100_501),
            admin: admin
        });

        assertEq(address(verifier.WITHDRAWAL_ADDRESS()), withdrawalAddress);
        assertEq(address(verifier.MODULE()), address(module));
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
        vm.expectRevert(ICSVerifier.InvalidChainConfig.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 0,
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSVerifier.ZeroModuleAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(0),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroWithdrawalAddress() public {
        vm.expectRevert(ICSVerifier.ZeroWithdrawalAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: address(0),
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroAdminAddress() public {
        vm.expectRevert(ICSVerifier.ZeroAdminAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: firstSupportedSlot, // Any value less than the slots from the fixtures.
            pivotSlot: firstSupportedSlot,
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
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: Slot.wrap(100_500), // Any value less than the slots from the fixtures.
            pivotSlot: Slot.wrap(100_500),
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
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0xe1c0, 4),
                gIFirstWithdrawalCurr: pack(0x0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x0, 40)
            }),
            firstSupportedSlot: fixture.beaconBlock.header.slot.dec(),
            pivotSlot: fixture.beaconBlock.header.slot.inc(),
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
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0x0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x0, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: fixture.beaconBlock.header.slot.dec(),
            pivotSlot: fixture.beaconBlock.header.slot,
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
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: pack(0x0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x0, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40)
            }),
            firstSupportedSlot: fixture.beaconBlock.header.slot.dec(),
            pivotSlot: fixture.beaconBlock.header.slot.dec(),
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
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: NULL_GINDEX,
                gIHistoricalSummariesCurr: NULL_GINDEX,
                gIFirstWithdrawalPrev: NULL_GINDEX,
                gIFirstWithdrawalCurr: NULL_GINDEX,
                gIFirstValidatorPrev: NULL_GINDEX,
                gIFirstValidatorCurr: NULL_GINDEX
            }),
            firstSupportedSlot: Slot.wrap(100_500), // Any value less than the slots from the fixtures.
            pivotSlot: Slot.wrap(100_500),
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
}
