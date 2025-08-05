// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { CSAccounting } from "../src/CSAccounting.sol";
import { CSAccountingMock } from "./helpers/mocks/CSAccountingMock.sol";

import { CSMFixtures } from "./CSModule.t.sol";
import { CSParametersRegistryMock } from "./helpers/mocks/CSParametersRegistryMock.sol";
import { Curated, ICSModule } from "../src/Curated.sol";
import { ExitPenaltiesMock } from "./helpers/mocks/ExitPenaltiesMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { Test } from "forge-std/Test.sol";

contract CuratedTest is CSMFixtures {
    uint64 internal constant PUBKEY_LENGTH = 48;
    uint64 internal constant SIGNATURE_LENGTH = 96;

    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        (locator, wstETH, stETH, , ) = initLido();

        parametersRegistry = new CSParametersRegistryMock();

        accounting = new CSAccountingMock(
            BOND_SIZE,
            address(wstETH),
            address(stETH)
        );

        exitPenalties = new ExitPenaltiesMock();

        csm = new Curated({
            moduleType: "csm-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        accounting.setCSM(address(csm));

        _enableInitializers(address(csm));
        csm.initialize(admin);

        vm.startPrank(admin);
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(this));
        vm.stopPrank();

        csm.resume();
    }

    function test_obtainDepositData_EmptyModule() public assertInvariants {
        createNodeOperator(100);
        createNodeOperator(50);
        createNodeOperator(20);
        createNodeOperator(0);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(0, 40);

            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(1, 39);

            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(2, 20);
        }
        csm.obtainDepositData(99, "");

        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(0, 60);

            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(1, 50);
        }
        csm.obtainDepositData(31, "");

        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(0, 100);
        }
        csm.obtainDepositData(40, "");
    }

    function test_obtainDepositData_UsesTheLeastActiveKeysFirst()
        public
        assertInvariants
    {
        createNodeOperator(100);
        createNodeOperator(100);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(0, 50);

            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(1, 50);
        }
        csm.obtainDepositData(100, "");

        setExited({ noId: 1, to: 18 }); // -> NO{id: 1, active: 32}
        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(0, 50 + 1);

            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(1, 50 + 18 + 1);
        }
        csm.obtainDepositData(20, "");
    }

    function test_obtainDepositData_TakesIntoAccountDepositable()
        public
        assertInvariants
    {
        createNodeOperator(100);
        createNodeOperator(100);

        unvetKeys({ noId: 1, to: 30 });
        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(0, 70);

            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(1, 30);
        }
        csm.obtainDepositData(100, "");
    }

    function test_obtainDepositData_SkipsNonDepositable()
        public
        assertInvariants
    {
        createNodeOperator(0);
        createNodeOperator(1);
        createNodeOperator(1);

        unvetKeys({ noId: 1, to: 0 });
        {
            vm.expectEmit(address(csm));
            emit ICSModule.DepositedSigningKeysCountChanged(2, 1);
        }
        csm.obtainDepositData(1, "");
    }

    function test_obtainDepositData_ReturnsCorrectDepositData()
        public
        assertInvariants
    {
        (bytes memory keys, bytes memory signatures) = keysSignatures(15);

        createNodeOperator(
            nodeOperator,
            5,
            slice(keys, PUBKEY_LENGTH * 0, PUBKEY_LENGTH * 5),
            slice(signatures, SIGNATURE_LENGTH * 0, SIGNATURE_LENGTH * 5)
        );
        createNodeOperator(
            nodeOperator,
            5,
            slice(keys, PUBKEY_LENGTH * 5, PUBKEY_LENGTH * 5),
            slice(signatures, SIGNATURE_LENGTH * 5, SIGNATURE_LENGTH * 5)
        );
        createNodeOperator(
            nodeOperator,
            5,
            slice(keys, PUBKEY_LENGTH * 10, PUBKEY_LENGTH * 5),
            slice(signatures, SIGNATURE_LENGTH * 10, SIGNATURE_LENGTH * 5)
        );

        (keys, signatures) = csm.obtainDepositData(3, "");
        // prettier-ignore
        {
            assertEq(keys.length, PUBKEY_LENGTH * 3);
            assertEq(keys[PUBKEY_LENGTH * 1 - 1], bytes1(uint8(1)), "Unexpected key from noId=0");
            assertEq(keys[PUBKEY_LENGTH * 2 - 1], bytes1(uint8(6)), "Unexpected key from noId=1");
            assertEq(keys[PUBKEY_LENGTH * 3 - 1], bytes1(uint8(11)), "Unexpected key from noId=2");
        }

        (keys, signatures) = csm.obtainDepositData(1, "");
        // prettier-ignore
        {
            assertEq(keys.length, PUBKEY_LENGTH * 1);
            assertEq(keys[PUBKEY_LENGTH * 1 - 1], bytes1(uint8(2)), "Unexpected key from noId=0");
        }

        (keys, signatures) = csm.obtainDepositData(4, "");
        // prettier-ignore
        {
            assertEq(keys.length, PUBKEY_LENGTH * 4);
            assertEq(keys[PUBKEY_LENGTH * 1 - 1], bytes1(uint8(3)), "Unexpected key from noId=0");
            assertEq(keys[PUBKEY_LENGTH * 2 - 1], bytes1(uint8(7)), "Unexpected key from noId=1");
            assertEq(keys[PUBKEY_LENGTH * 3 - 1], bytes1(uint8(8)), "Unexpected key from noId=1");
            assertEq(keys[PUBKEY_LENGTH * 4 - 1], bytes1(uint8(12)), "Unexpected key from noId=2");
        }
    }

    function test_obtainDepositData_ZeroCountOfDeposits()
        public
        assertInvariants
    {
        createNodeOperator(20);

        (bytes memory publicKeys, bytes memory signatures) = csm
            .obtainDepositData(0, "");

        assertEq(publicKeys.length, 0, "Expected no keys returned");
        assertEq(signatures.length, 0, "Expected no signatures returned");
    }

    function test_obtainDepositData_RevertsIfNotEnoughKeys() public {
        createNodeOperator(20);
        createNodeOperator(0);

        vm.expectRevert(ICSModule.NotEnoughKeys.selector);
        csm.obtainDepositData(21, "");
    }
}
