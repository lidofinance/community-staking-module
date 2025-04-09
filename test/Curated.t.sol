// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { Curated, ICSModule } from "../src/Curated.sol";
import { CSAccounting } from "../src/CSAccounting.sol";

import { CSParametersRegistryMock } from "./helpers/mocks/CSParametersRegistryMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { CSMFixtures } from "./CSModule.t.sol";

contract CuratedTest is CSMFixtures {
    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        (locator, wstETH, stETH, , ) = initLido();

        parametersRegistry = new CSParametersRegistryMock();

        csm = new Curated({
            moduleType: "curated-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry)
        });
        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE;
        accounting = new CSAccounting(
            address(locator),
            address(csm),
            10,
            4 weeks,
            365 days
        );

        _enableInitializers(address(accounting));

        accounting.initialize({
            bondCurve: curve,
            admin: admin,
            _feeDistributor: address(new Stub()),
            bondLockPeriod: 8 weeks,
            _chargePenaltyRecipient: address(new Stub())
        });

        _enableInitializers(address(csm));
        csm.initialize({ _accounting: address(accounting), admin: admin });

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
    }
}
