// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";

import { GIndex } from "../src/lib/GIndex.sol";

import { CSVerifier } from "../src/CSVerifier.sol";
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

contract CSVerifierBiForkTestConstructor is Test, Utilities {
    CSVerifier verifier;

    Stub module;
    address public admin;

    function setUp() public {
        module = new Stub();
        admin = nextAddress("ADMIN");
    }

    function test_constructor_HappyPath() public {
        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(8_192),
            pivotSlot: Slot.wrap(950_272),
            admin: admin
        });

        assertEq(
            verifier.WITHDRAWAL_ADDRESS(),
            0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36
        );
        assertEq(address(verifier.MODULE()), address(module));
        assertEq(verifier.SLOTS_PER_EPOCH(), 32);
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES_PREV()),
            GIndex.unwrap(pack(0x3b, 0))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES_CURR()),
            GIndex.unwrap(pack(0x3b, 0))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL_PREV()),
            GIndex.unwrap(pack(0x71c0, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL_CURR()),
            GIndex.unwrap(pack(0xe1c0, 4))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR_PREV()),
            GIndex.unwrap(pack(0x560000000000, 40))
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR_CURR()),
            GIndex.unwrap(pack(0x560000000000, 40))
        );
        assertEq(
            Slot.unwrap(verifier.FIRST_SUPPORTED_SLOT()),
            Slot.unwrap(Slot.wrap(8_192))
        );
        assertEq(
            Slot.unwrap(verifier.PIVOT_SLOT()),
            Slot.unwrap(Slot.wrap(950_272))
        );
    }

    function test_constructor_RevertWhen_InvalidChainConfig() public {
        vm.expectRevert(ICSVerifier.InvalidChainConfig.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 0, // <--
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(8_192),
            pivotSlot: Slot.wrap(950_272),
            admin: admin
        });
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSVerifier.ZeroModuleAddress.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(0), // <--
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(8_192),
            pivotSlot: Slot.wrap(950_272),
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
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(8_192),
            pivotSlot: Slot.wrap(950_272),
            admin: admin
        });
    }

    function test_constructor_RevertWhen_InvalidPivotSlot() public {
        vm.expectRevert(ICSVerifier.InvalidPivotSlot.selector);
        verifier = new CSVerifier({
            withdrawalAddress: nextAddress(),
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(200),
            pivotSlot: Slot.wrap(100),
            admin: admin
        });
    }
}

contract CSVerifierBiForkHistoricalTestShared is Utilities {
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

    HistoricalWithdrawalFixture public fixture;

    function _loadFixture() internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/test/fixtures/CSVerifier/historicalCrossForksWithdrawal.json"
        );
        string memory json = vm.readFile(path);
        bytes memory data = json.parseRaw("$");
        fixture = abi.decode(data, (HistoricalWithdrawalFixture));
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

contract CSVerifierBiForkHistoricalTest is
    CSVerifierBiForkHistoricalTestShared,
    Test
{
    function setUp() public virtual {
        _loadFixture();
        module = new Stub();
        admin = nextAddress("ADMIN");
        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(8_192),
            pivotSlot: fixture.beaconBlock.header.slot.dec(),
            admin: admin
        });
        _setMocksWithdrawal(fixture);
    }

    function test_processWithdrawalProof() public {
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
}

contract CSVerifierBiForkHistoricalAtPivotSlotTest is
    CSVerifierBiForkHistoricalTestShared,
    Test
{
    function setUp() public {
        _loadFixture();
        module = new Stub();
        admin = nextAddress("ADMIN");
        verifier = new CSVerifier({
            withdrawalAddress: 0xb3E29C46Ee1745724417C0C51Eb2351A1C01cF36,
            module: address(module),
            slotsPerEpoch: 32,
            gindices: ICSVerifier.GIndices({
                gIFirstWithdrawalPrev: pack(0x71c0, 4),
                gIFirstWithdrawalCurr: pack(0xe1c0, 4),
                gIFirstValidatorPrev: pack(0x560000000000, 40),
                gIFirstValidatorCurr: pack(0x560000000000, 40),
                gIHistoricalSummariesPrev: pack(0x3b, 0),
                gIHistoricalSummariesCurr: pack(0x3b, 0)
            }),
            firstSupportedSlot: Slot.wrap(8_192),
            pivotSlot: fixture.beaconBlock.header.slot,
            admin: admin
        });
        _setMocksWithdrawal(fixture);
    }

    function test_processWithdrawalProof() public {
        // solhint-disable-next-line func-named-parameters
        verifier.processHistoricalWithdrawalProof(
            fixture.beaconBlock,
            fixture.oldBlock,
            fixture.witness,
            0,
            0
        );
    }
}
