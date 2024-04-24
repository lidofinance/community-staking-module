// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IWithdrawalQueue } from "../../src/interfaces/IWithdrawalQueue.sol";
import { ICSAccounting } from "../../src/interfaces/ICSAccounting.sol";
import { Utilities } from "../helpers/Utilities.sol";
import { PermitHelper } from "../helpers/Permit.sol";
import { DeploymentFixtures } from "../helpers/Fixtures.sol";

contract ClaimIntegrationTest is
    Test,
    Utilities,
    PermitHelper,
    DeploymentFixtures
{
    address internal user;
    address internal stranger;
    address internal nodeOperator;
    uint256 internal defaultNoId;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        vm.stopPrank();
        csm.resume();

        user = nextAddress("User");
        stranger = nextAddress("stranger");
        nodeOperator = nextAddress("NodeOperator");

        uint256 keysCount = 5;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount);
        vm.deal(nodeOperator, amount);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: amount }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
        defaultNoId = csm.getNodeOperatorsCount() - 1;
    }

    function test_claimExessBondStETH() public {
        uint256 sharesBefore = lido.sharesOf(nodeOperator);

        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBond = current > required ? current - required : 0;

        vm.prank(nodeOperator);
        csm.claimRewardsStETH(
            defaultNoId,
            type(uint256).max,
            0,
            new bytes32[](0)
        );

        uint256 sharesAfter = lido.sharesOf(nodeOperator);

        assertEq(sharesAfter, sharesBefore + excessBond);
    }

    function test_claimExessBondWstETH() public {
        uint256 balanceBefore = wstETH.balanceOf(nodeOperator);

        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        (uint256 current, uint256 required) = accounting.getBondSummary(
            defaultNoId
        );

        uint256 excessBond = current > required ? current - required : 0;
        uint256 excessBondWstETH = wstETH.getWstETHByStETH(excessBond);

        vm.prank(nodeOperator);
        csm.claimRewardsWstETH(
            defaultNoId,
            type(uint256).max,
            0,
            new bytes32[](0)
        );

        uint256 balanceAfter = wstETH.balanceOf(nodeOperator);

        assertEq(balanceAfter, balanceBefore + excessBondWstETH);
    }

    function test_requestExessBondETH() public {
        IWithdrawalQueue wq = IWithdrawalQueue(locator.withdrawalQueue());
        uint256[] memory requestsIdsBefore = wq.getWithdrawalRequests(
            nodeOperator
        );
        assertEq(
            requestsIdsBefore.length,
            0,
            "should be no wd requests for the Node Operator"
        );

        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        (uint256 current, uint256 required) = accounting.getBondSummary(
            defaultNoId
        );

        uint256 excessBond = current > required ? current - required : 0;

        vm.prank(nodeOperator);
        csm.requestRewardsETH(
            defaultNoId,
            type(uint256).max,
            0,
            new bytes32[](0)
        );

        uint256[] memory requestsIdsAfter = wq.getWithdrawalRequests(
            nodeOperator
        );
        assertEq(
            requestsIdsAfter.length,
            1,
            "should be 1 wd request for the Node Operator"
        );

        IWithdrawalQueue.WithdrawalRequestStatus[] memory statuses = wq
            .getWithdrawalStatus(requestsIdsAfter);
    }
}
