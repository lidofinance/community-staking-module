// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule } from "../../../src/CSModule.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { IWstETH } from "../../../src/interfaces/IWstETH.sol";
import { ILido } from "../../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../../src/interfaces/ILidoLocator.sol";
import { IWithdrawalQueue } from "../../../src/interfaces/IWithdrawalQueue.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";
import { Utilities } from "../../helpers/Utilities.sol";
import { PermitHelper } from "../../helpers/Permit.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { MerkleTree } from "../../helpers/MerkleTree.sol";

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
        csm.grantRole(csm.MODULE_MANAGER_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(stakingRouter));
        vm.stopPrank();
        if (csm.isPaused()) csm.resume();
        if (!csm.publicRelease()) csm.activatePublicRelease();

        vm.startPrank(
            feeDistributor.getRoleMember(feeDistributor.DEFAULT_ADMIN_ROLE(), 0)
        );
        feeDistributor.grantRole(feeDistributor.ORACLE_ROLE(), address(this));
        vm.stopPrank();

        user = nextAddress("User");
        stranger = nextAddress("stranger");
        nodeOperator = nextAddress("NodeOperator");

        uint256 keysCount = 5;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
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

    function test_claimExcessBondStETH() public {
        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        uint256 sharesBefore = lido.sharesOf(nodeOperator);

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBond = current > required ? current - required : 0;
        assertTrue(excessBond > 0, "Excess bond should be > 0");

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

    function test_claimExcessBondWstETH() public {
        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        uint256 balanceBefore = wstETH.balanceOf(nodeOperator);

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBond = current > required ? current - required : 0;
        assertTrue(excessBond > 0, "Excess bond should be > 0");

        uint256 excessBondWstETH = wstETH.getWstETHByStETH(
            lido.getPooledEthByShares(excessBond)
        );

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

    function test_requestExcessBondETH() public {
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

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBond = current > required ? current - required : 0;
        assertTrue(excessBond > 0, "Excess bond should be > 0");

        vm.prank(nodeOperator);
        csm.claimRewardsUnstETH(
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

        assertEq(
            statuses[0].amountOfStETH,
            lido.getPooledEthByShares(excessBond)
        );
    }

    function test_claimRewardsStETH() public {
        uint256 sharesBefore = lido.sharesOf(nodeOperator);
        uint256 amount = 1 ether;

        // Supply funds to feeDistributor
        vm.startPrank(user);
        vm.deal(user, amount);
        uint256 shares = lido.submit{ value: amount }({ _referal: address(0) });
        lido.transferShares(address(feeDistributor), shares);
        vm.stopPrank();

        // Prepare and submit report data
        MerkleTree tree = new MerkleTree();
        tree.pushLeaf(abi.encode(defaultNoId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        feeDistributor.processOracleReport(root, "Qm", shares);

        vm.prank(nodeOperator);
        csm.claimRewardsStETH(defaultNoId, type(uint256).max, shares, proof);

        uint256 sharesAfter = lido.sharesOf(nodeOperator);

        assertEq(sharesAfter, sharesBefore + shares);
    }

    function test_claimRewardsWstETH() public {
        uint256 balanceBefore = wstETH.balanceOf(nodeOperator);
        uint256 amount = 1 ether;

        // Supply funds to feeDistributor
        vm.startPrank(user);
        vm.deal(user, amount);
        uint256 shares = lido.submit{ value: amount }({ _referal: address(0) });
        lido.transferShares(address(feeDistributor), shares);
        vm.stopPrank();

        uint256 rewardsWstETH = wstETH.getWstETHByStETH(
            lido.getPooledEthByShares(shares)
        );

        // Prepare and submit report data
        MerkleTree tree = new MerkleTree();
        tree.pushLeaf(abi.encode(defaultNoId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        feeDistributor.processOracleReport(root, "Qm", shares);

        vm.prank(nodeOperator);
        csm.claimRewardsWstETH(defaultNoId, type(uint256).max, shares, proof);

        uint256 balanceAfter = wstETH.balanceOf(nodeOperator);

        assertEq(balanceAfter, balanceBefore + rewardsWstETH);
    }

    function test_requestRewardsETH() public {
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

        // Supply funds to feeDistributor
        vm.startPrank(user);
        vm.deal(user, amount);
        uint256 shares = lido.submit{ value: amount }({ _referal: address(0) });
        lido.transferShares(address(feeDistributor), shares);
        vm.stopPrank();

        // Prepare and submit report data
        MerkleTree tree = new MerkleTree();
        tree.pushLeaf(abi.encode(defaultNoId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        feeDistributor.processOracleReport(root, "Qm", shares);

        vm.prank(nodeOperator);
        csm.claimRewardsUnstETH(defaultNoId, type(uint256).max, shares, proof);

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

        assertEq(statuses[0].amountOfStETH, lido.getPooledEthByShares(shares));
    }
}
