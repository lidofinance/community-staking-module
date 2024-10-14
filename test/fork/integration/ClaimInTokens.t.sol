// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { NodeOperatorManagementProperties } from "../../../src/interfaces/ICSModule.sol";
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
import { InvariantAsserts } from "../../helpers/InvariantAsserts.sol";

contract ClaimIntegrationTest is
    Test,
    Utilities,
    PermitHelper,
    DeploymentFixtures,
    InvariantAsserts
{
    address internal user;
    address internal stranger;
    address internal nodeOperator;
    uint256 internal defaultNoId;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertCSMKeys(csm);
        assertCSMEnqueuedCount(csm);
        assertCSMEarlyAdoptionMaxKeys(csm);
        assertAccountingTotalBondShares(noCount, lido, accounting);
        assertAccountingBurnerApproval(
            lido,
            address(accounting),
            locator.burner()
        );
        assertFeeDistributorClaimableShares(lido, feeDistributor);
        assertFeeDistributorTree(feeDistributor);
        vm.resumeGasMetering();
    }

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

        handleStakingLimit();
        handleBunkerMode();

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
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            new bytes32[](0),
            address(0)
        );
        defaultNoId = csm.getNodeOperatorsCount() - 1;
    }

    function test_claimExcessBondStETH() public assertInvariants {
        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        uint256 noSharesBefore = lido.sharesOf(nodeOperator);
        uint256 accountingSharesBefore = lido.sharesOf(address(accounting));
        uint256 accountingNOBondSharesBefore = accounting.getBondShares(
            defaultNoId
        );

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBondShares = current > required ? current - required : 0;
        assertTrue(excessBondShares > 0, "Excess bond should be > 0");

        vm.prank(nodeOperator);
        csm.claimRewardsStETH(
            defaultNoId,
            type(uint256).max,
            0,
            new bytes32[](0)
        );

        uint256 noSharesAfter = lido.sharesOf(nodeOperator);
        uint256 accountingSharesAfter = lido.sharesOf(address(accounting));
        uint256 accountingNOBondSharesAfter = accounting.getBondShares(
            defaultNoId
        );
        uint256 accountingTotalBondSharesAfter = accounting.totalBondShares();

        assertEq(
            noSharesAfter,
            noSharesBefore + excessBondShares,
            "Node Operator stETH shares should be increased by excess bond"
        );
        assertEq(
            accountingNOBondSharesAfter,
            accountingNOBondSharesBefore -
                (accountingSharesBefore - accountingSharesAfter),
            "NO bond shares should be decreased by real transferred shares"
        );
        assertEq(
            accountingTotalBondSharesAfter,
            accountingSharesAfter,
            "Total bond shares should be equal to real shares"
        );
    }

    function test_claimExcessBondWstETH() public assertInvariants {
        uint256 amount = 1 ether;
        vm.startPrank(user);
        vm.deal(user, amount);

        csm.depositETH{ value: amount }(defaultNoId);
        vm.stopPrank();

        uint256 balanceBefore = wstETH.balanceOf(nodeOperator);
        uint256 accountingSharesBefore = lido.sharesOf(address(accounting));
        uint256 accountingNOBondSharesBefore = accounting.getBondShares(
            defaultNoId
        );

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBondShares = current > required ? current - required : 0;
        assertTrue(excessBondShares > 0, "Excess bond should be > 0");

        uint256 excessBondWstETH = wstETH.getWstETHByStETH(
            lido.getPooledEthByShares(excessBondShares)
        );

        vm.prank(nodeOperator);
        csm.claimRewardsWstETH(
            defaultNoId,
            type(uint256).max,
            0,
            new bytes32[](0)
        );

        uint256 balanceAfter = wstETH.balanceOf(nodeOperator);
        uint256 accountingSharesAfter = lido.sharesOf(address(accounting));
        uint256 accountingNOBondSharesAfter = accounting.getBondShares(
            defaultNoId
        );
        uint256 accountingTotalBondSharesAfter = accounting.totalBondShares();

        assertEq(
            balanceAfter,
            balanceBefore + excessBondWstETH,
            "Node Operator wstETH balance should be increased by excess bond"
        );
        assertEq(
            accountingNOBondSharesAfter,
            accountingNOBondSharesBefore -
                (accountingSharesBefore - accountingSharesAfter),
            "NO bond shares should be decreased by real transferred shares"
        );
        assertEq(
            accountingTotalBondSharesAfter,
            accountingSharesAfter,
            "Total bond shares should be equal to real shares"
        );
    }

    function test_requestExcessBondETH() public assertInvariants {
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

        uint256 accountingSharesBefore = lido.sharesOf(address(accounting));
        uint256 accountingNOBondSharesBefore = accounting.getBondShares(
            defaultNoId
        );

        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );

        uint256 excessBondShares = current > required ? current - required : 0;
        assertTrue(excessBondShares > 0, "Excess bond should be > 0");

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

        uint256 accountingSharesAfter = lido.sharesOf(address(accounting));
        uint256 accountingNOBondSharesAfter = accounting.getBondShares(
            defaultNoId
        );
        uint256 accountingTotalBondSharesAfter = accounting.totalBondShares();

        assertEq(
            statuses[0].amountOfStETH,
            lido.getPooledEthByShares(excessBondShares),
            "Withdrawal request should be equal to excess bond"
        );
        assertEq(
            accountingNOBondSharesAfter,
            accountingNOBondSharesBefore -
                (accountingSharesBefore - accountingSharesAfter),
            "NO bond shares should be decreased by real transferred shares"
        );
        assertEq(
            accountingTotalBondSharesAfter,
            accountingSharesAfter,
            "Total bond shares should be equal to real shares"
        );
    }

    function test_claimRewardsStETH() public assertInvariants {
        uint256 noSharesBefore = lido.sharesOf(nodeOperator);
        uint256 accountingSharesBefore = lido.sharesOf(address(accounting));
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

        vm.prank(feeDistributor.ORACLE());
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares
        );

        vm.prank(nodeOperator);
        csm.claimRewardsStETH(defaultNoId, type(uint256).max, shares, proof);

        uint256 noSharesAfter = lido.sharesOf(nodeOperator);
        uint256 accountingSharesAfter = lido.sharesOf(address(accounting));
        assertEq(
            noSharesAfter,
            noSharesBefore +
                (accountingSharesBefore + shares - accountingSharesAfter),
            "Node Operator stETH shares should be increased by real shares"
        );
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );
        assertEq(current, required, "NO bond shares should be equal required");
        assertEq(
            accounting.totalBondShares(),
            accountingSharesAfter,
            "Total bond shares should be equal to real shares"
        );
    }

    function test_claimRewardsWstETH() public assertInvariants {
        uint256 balanceBefore = wstETH.balanceOf(nodeOperator);
        uint256 accountingSharesBefore = lido.sharesOf(address(accounting));
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

        vm.prank(feeDistributor.ORACLE());
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares
        );

        vm.prank(nodeOperator);
        csm.claimRewardsWstETH(defaultNoId, type(uint256).max, shares, proof);

        uint256 accountingSharesAfter = lido.sharesOf(address(accounting));

        assertEq(
            wstETH.balanceOf(nodeOperator),
            balanceBefore +
                (accountingSharesBefore + shares - accountingSharesAfter),
            "Node Operator wstETH balance should be increased by real rewards"
        );
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );
        // Approx due to wstETH claim mechanics shares -> stETH -> wstETH
        assertApproxEqAbs(
            current,
            required,
            1 wei,
            "NO bond shares should be equal required"
        );
        assertEq(
            accounting.totalBondShares(),
            accountingSharesAfter,
            "Total bond shares should be equal to real shares"
        );
    }

    function test_requestRewardsETH() public assertInvariants {
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

        vm.prank(feeDistributor.ORACLE());
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares
        );

        uint256 accountingSharesBefore = lido.sharesOf(address(accounting));

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

        uint256 accountingSharesAfter = lido.sharesOf(address(accounting));
        assertApproxEqAbs(
            statuses[0].amountOfStETH,
            lido.getPooledEthByShares(
                (accountingSharesBefore + shares) - accountingSharesAfter
            ),
            2 wei,
            "Withdrawal request should be equal to real rewards"
        );
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            defaultNoId
        );
        // Approx due to unstETH claim mechanics shares -> stETH -> unstETH
        assertApproxEqAbs(
            current,
            required,
            2 wei,
            "NO bond shares should be equal required"
        );
        assertEq(
            accounting.totalBondShares(),
            accountingSharesAfter,
            "Total bond shares should be equal to real shares"
        );
    }
}
