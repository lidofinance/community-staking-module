// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";

import { GIndex } from "../src/lib/GIndex.sol";

import { CSVerifier } from "../src/CSVerifier.sol";
import { pack } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";

import { Stub } from "./helpers/mocks/Stub.sol";

contract CSVerifierHistoricalTest is Test {
    using stdJson for string;

    struct HistoricalWithdrawalFixture {
        bytes32 _blockRoot;
        bytes _pubkey;
        address _withdrawalAddress;
        ICSVerifier.ProvableBeaconBlockHeader beaconBlock;
        ICSVerifier.HistoricalHeaderWitness oldBlock;
        ICSVerifier.WithdrawalWitness witness;
    }

    // On **prater**, see https://github.com/eth-clients/goerli/blob/main/prater/config.yaml.
    uint64 public constant DENEB_FORK_EPOCH = 231680;

    CSVerifier public verifier;
    Stub public locator;
    Stub public module;

    HistoricalWithdrawalFixture public fixture;

    function setUp() public {
        verifier = new CSVerifier({
            slotsPerEpoch: 32,
            gIHistoricalSummaries: pack(0x3b, 5),
            gIFirstWithdrawal: pack(0xe1c0, 4),
            gIFirstValidator: pack(0x560000000000, 40),
            firstSupportedSlot: Slot.wrap(DENEB_FORK_EPOCH * 32)
        });

        locator = new Stub();
        module = new Stub();

        verifier.initialize(address(locator), address(module));
    }

    function _get_fixture() internal {
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
        _get_fixture();
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
        _get_fixture();
        _setMocksWithdrawal(fixture);

        fixture.beaconBlock.header.slot =
            verifier.FIRST_SUPPORTED_SLOT().unwrap() -
            1;

        vm.expectRevert(
            abi.encodeWithSelector(
                CSVerifier.UnsupportedSlot.selector,
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
        _get_fixture();
        _setMocksWithdrawal(fixture);

        fixture.oldBlock.header.slot =
            verifier.FIRST_SUPPORTED_SLOT().unwrap() -
            1;

        vm.expectRevert(
            abi.encodeWithSelector(
                CSVerifier.UnsupportedSlot.selector,
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
        _get_fixture();
        _setMocksWithdrawal(fixture);

        vm.mockCall(
            verifier.BEACON_ROOTS(),
            abi.encode(fixture.beaconBlock.rootsTimestamp),
            abi.encode("lol")
        );

        vm.expectRevert(CSVerifier.InvalidBlockHeader.selector);
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
        _get_fixture();
        _setMocksWithdrawal(fixture);

        fixture.oldBlock.rootGIndex = GIndex.wrap(bytes32(0));

        vm.expectRevert(CSVerifier.InvalidGIndex.selector);
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
            abi.encodeWithSelector(
                ICSModule.getNodeOperatorSigningKeys.selector,
                0,
                0
            ),
            abi.encode(_fixture._pubkey)
        );

        vm.mockCall(
            address(locator),
            abi.encodeWithSelector(ILidoLocator.withdrawalVault.selector),
            abi.encode(_fixture._withdrawalAddress)
        );

        vm.mockCall(
            address(module),
            abi.encodeWithSelector(ICSModule.submitWithdrawal.selector),
            ""
        );
    }
}
