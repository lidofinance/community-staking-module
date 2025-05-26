// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { GIndex } from "../src/lib/GIndex.sol";

import { CSVerifier } from "../src/CSVerifier.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { pack } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

function dec(Slot self) pure returns (Slot slot) {
    assembly ("memory-safe") {
        slot := sub(self, 1)
    }
}

using { dec } for Slot;

contract CSVerifierHistoricalTest is Test, Utilities {
    using stdJson for string;

    struct HistoricalWithdrawalFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        ICSVerifier.ProvableBeaconBlockHeader beaconBlock;
        ICSVerifier.HistoricalHeaderWitness oldBlock;
        ICSVerifier.WithdrawalWitness witness;
    }

    CSVerifier public verifier;
    Stub public module;
    address public admin;

    bytes32 public pauseRole;
    bytes32 public resumeRole;

    HistoricalWithdrawalFixture public fixture;

    function setUp() public {
        _loadFixture();
        module = new Stub();
        admin = nextAddress("ADMIN");
        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0),
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

    function _loadFixture() internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/test/fixtures/CSVerifier/historicalWithdrawal.json"
        );
        string memory json = vm.readFile(path);
        bytes memory data = json.parseRaw("$");
        fixture = abi.decode(data, (HistoricalWithdrawalFixture));
    }

    function test_processWithdrawalProof() public {
        _setMocksWithdrawal(fixture);

        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_UnsupportedSlot() public {
        _setMocksWithdrawal(fixture);

        fixture.beaconBlock.header.slot = verifier.FIRST_SUPPORTED_SLOT().dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICSVerifier.UnsupportedSlot.selector,
                fixture.beaconBlock.header.slot
            )
        );

        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_UnsupportedSlot_OldBlock()
        public
    {
        _setMocksWithdrawal(fixture);

        fixture.oldBlock.header.slot = verifier.FIRST_SUPPORTED_SLOT().dec();

        vm.expectRevert(
            abi.encodeWithSelector(
                ICSVerifier.UnsupportedSlot.selector,
                fixture.oldBlock.header.slot
            )
        );

        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_InvalidBlockHeader()
        public
    {
        _setMocksWithdrawal(fixture);

        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode("lol")
        );

        vm.expectRevert(ICSVerifier.InvalidBlockHeader.selector);
        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhen_InvalidGI() public {
        _setMocksWithdrawal(fixture);

        fixture.oldBlock.rootGIndex = GIndex.wrap(bytes32(0));

        vm.expectRevert(ICSVerifier.InvalidGIndex.selector);
        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }

    function test_processWithdrawalProof_RevertWhenPaused() public {
        _setMocksWithdrawal(fixture);

        vm.prank(admin);
        verifier.pauseFor(100_500);
        assertTrue(verifier.isPaused());

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }

    function _setMocksWithdrawal(
        HistoricalWithdrawalFixture memory _fixture
    ) internal {
        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(_fixture.beaconBlock.rootsTimestamp),
            abi.encode(_fixture._blockRoot)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector, 0, 0),
            abi.encode(_fixture._pubkey)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawals.selector),
            ""
        );
    }
}
