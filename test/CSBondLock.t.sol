// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSAccountingBase, CSAccounting } from "../src/CSAccounting.sol";
import { CSBondLockBase, CSBondLock } from "../src/CSBondLock.sol";
import { PermitTokenBase } from "./helpers/Permit.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import { WithdrawalQueueMockBase, WithdrawalQueueMock } from "./helpers/mocks/WithdrawalQueueMock.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSAccounting_revealed is CSAccounting {
    constructor(
        uint256[] memory bondCurve,
        address admin,
        address lidoLocator,
        address wstETH,
        address communityStakingModule,
        uint256 blockedBondRetentionPeriod,
        uint256 blockedBondManagementPeriod
    )
        CSAccounting(
            bondCurve,
            admin,
            lidoLocator,
            wstETH,
            communityStakingModule,
            blockedBondRetentionPeriod,
            blockedBondManagementPeriod
        )
    {}

    function _bondShares_set_value(
        uint256 nodeOperatorId,
        uint256 value
    ) public {
        _bondShares[nodeOperatorId] = value;
    }

    function _blockedBondEther_get_value(
        uint256 nodeOperatorId
    ) public view returns (BondLock memory) {
        return _bondLock[nodeOperatorId];
    }

    function _blockedBondEther_set_value(
        uint256 nodeOperatorId,
        BondLock memory value
    ) public {
        _bondLock[nodeOperatorId] = value;
    }

    function _changeBlockedBondState_revealed(
        uint256 nodeOperatorId,
        uint256 ETHAmount,
        uint256 retentionUntil
    ) public {
        _changeBondLock(nodeOperatorId, ETHAmount, retentionUntil);
    }

    function _reduceBlockedBondETH_revealed(
        uint256 nodeOperatorId,
        uint256 ETHAmount
    ) public {
        _reduceAmount(nodeOperatorId, ETHAmount);
    }
}

contract CSAccounting_BlockedBondTest is
    Test,
    Fixtures,
    Utilities,
    CSBondLockBase,
    CSAccountingBase
{
    using stdStorage for StdStorage;

    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    Stub internal burner;

    CSAccounting_revealed public accounting;
    CommunityStakingModuleMock public stakingModule;
    CommunityStakingFeeDistributorMock public feeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;

    function setUp() public {
        admin = address(1);

        user = address(2);
        stranger = address(777);

        (locator, wstETH, stETH, burner) = initLido();

        stakingModule = new CommunityStakingModuleMock();
        uint256[] memory curve = new uint256[](2);
        curve[0] = 2 ether;
        curve[1] = 4 ether;
        accounting = new CSAccounting_revealed(
            curve,
            admin,
            address(locator),
            address(wstETH),
            address(stakingModule),
            8 weeks,
            1 days
        );
        feeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(accounting)
        );
        vm.startPrank(admin);
        accounting.setFeeDistributor(address(feeDistributor));
        accounting.grantRole(accounting.INSTANT_PENALIZE_BOND_ROLE(), admin);
        accounting.grantRole(
            accounting.EL_REWARDS_STEALING_PENALTY_INIT_ROLE(),
            admin
        );
        accounting.grantRole(
            accounting.EL_REWARDS_STEALING_PENALTY_SETTLE_ROLE(),
            admin
        );
        vm.stopPrank();
    }

    function test_private_changeBlockedBondState() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        uint256 retentionUntil = block.timestamp + 1 weeks;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(noId, amount, retentionUntil);
        accounting._changeBlockedBondState_revealed({
            nodeOperatorId: noId,
            ETHAmount: amount,
            retentionUntil: retentionUntil
        });

        CSBondLock.BondLock memory value = accounting
            ._blockedBondEther_get_value(noId);

        assertEq(value.amount, amount);
        assertEq(value.retentionUntil, retentionUntil);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(noId, 0, 0);

        accounting._changeBlockedBondState_revealed({
            nodeOperatorId: noId,
            ETHAmount: 0,
            retentionUntil: 0
        });

        value = accounting._blockedBondEther_get_value(noId);

        assertEq(value.amount, 0);
        assertEq(value.retentionUntil, 0);
    }

    function test_initELRewardsStealingPenalty() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        uint256 noId = 0;
        uint256 proposedBlockNumber = 100500;
        uint256 firstStolenAmount = 1 ether;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit ELRewardsStealingPenaltyInitiated(
            noId,
            proposedBlockNumber,
            firstStolenAmount
        );
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(
            noId,
            firstStolenAmount,
            block.timestamp + 8 weeks
        );

        vm.prank(admin);
        accounting.initELRewardsStealingPenalty({
            nodeOperatorId: noId,
            blockNumber: proposedBlockNumber,
            amount: firstStolenAmount
        });

        assertEq(
            accounting._blockedBondEther_get_value(noId).amount,
            firstStolenAmount
        );
        assertEq(
            accounting._blockedBondEther_get_value(noId).retentionUntil,
            block.timestamp + 8 weeks
        );

        // new block and new stealing
        vm.warp(block.timestamp + 12 seconds);

        uint256 secondStolenAmount = 2 ether;
        proposedBlockNumber = 100501;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit ELRewardsStealingPenaltyInitiated(
            noId,
            proposedBlockNumber,
            secondStolenAmount
        );
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(
            noId,
            firstStolenAmount + secondStolenAmount,
            block.timestamp + 8 weeks
        );

        vm.prank(admin);
        accounting.initELRewardsStealingPenalty({
            nodeOperatorId: noId,
            blockNumber: proposedBlockNumber,
            amount: secondStolenAmount
        });

        assertEq(
            accounting._blockedBondEther_get_value(noId).amount,
            firstStolenAmount + secondStolenAmount
        );
        assertEq(
            accounting._blockedBondEther_get_value(noId).retentionUntil,
            block.timestamp + 8 weeks
        );
    }

    function test_initELRewardsStealingPenalty_revertWhenNonExistingOperator()
        public
    {
        vm.expectRevert("node operator does not exist");

        vm.prank(admin);
        accounting.initELRewardsStealingPenalty({
            nodeOperatorId: 0,
            blockNumber: 100500,
            amount: 100 ether
        });
    }

    function test_initELRewardsStealingPenalty_revertWhenZero() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        vm.expectRevert(InvalidBondLockAmount.selector);

        vm.prank(admin);
        accounting.initELRewardsStealingPenalty({
            nodeOperatorId: 0,
            blockNumber: 100500,
            amount: 0
        });
    }

    function test_initELRewardsStealingPenalty_revertWhenNoRole() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    address(stranger),
                    accounting.EL_REWARDS_STEALING_PENALTY_INIT_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.initELRewardsStealingPenalty({
            nodeOperatorId: 0,
            blockNumber: 100500,
            amount: 100 ether
        });
    }

    function test_settleBlockedBondETH() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        vm.deal(user, 12 ether);
        vm.startPrank(user);
        stETH.submit{ value: 12 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 12 ether);
        vm.stopPrank();

        uint256[] memory nosToPenalize = new uint256[](2);
        nosToPenalize[0] = 0;
        // non-existing node operator should be skipped in the loop
        nosToPenalize[1] = 100500;

        uint256 retentionUntil = block.timestamp + 8 weeks;

        accounting._blockedBondEther_set_value(
            0,
            CSBondLock.BondLock({
                amount: 1 ether,
                retentionUntil: retentionUntil
            })
        );

        // less than 1 day after penalty init
        vm.warp(block.timestamp + 20 hours);

        vm.prank(admin);
        accounting.settleBlockedBondETH(nosToPenalize);

        CSBondLock.BondLock memory value = accounting
            ._blockedBondEther_get_value(0);

        assertEq(value.amount, 1 ether);
        assertEq(value.retentionUntil, retentionUntil);

        // penalty amount is less than the bond
        vm.warp(block.timestamp + 2 days);

        uint256 penalty = stETH.getPooledEthByShares(
            stETH.getSharesByPooledEth(1 ether)
        );
        uint256 covering = penalty;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(0, penalty, covering);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(0, 0, 0);

        vm.prank(admin);
        accounting.settleBlockedBondETH(nosToPenalize);

        value = accounting._blockedBondEther_get_value(0);
        assertEq(value.amount, 0);
        assertEq(value.retentionUntil, 0);

        // penalty amount is greater than the bond
        accounting._blockedBondEther_set_value(
            0,
            CSBondLock.BondLock({
                amount: 100 ether,
                retentionUntil: retentionUntil
            })
        );

        penalty = stETH.getPooledEthByShares(
            stETH.getSharesByPooledEth(100 ether)
        );
        covering = 11 ether;
        uint256 uncovered = penalty - covering;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(0, penalty, covering);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(0, uncovered, retentionUntil);

        vm.prank(admin);
        accounting.settleBlockedBondETH(nosToPenalize);

        value = accounting._blockedBondEther_get_value(0);
        assertEq(value.amount, uncovered);
        assertEq(value.retentionUntil, retentionUntil);

        // retention period expired
        accounting._blockedBondEther_set_value(
            0,
            CSBondLock.BondLock({
                amount: 100 ether,
                retentionUntil: retentionUntil
            })
        );
        vm.warp(retentionUntil + 12);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(0, 0, 0);

        vm.prank(admin);
        accounting.settleBlockedBondETH(nosToPenalize);

        value = accounting._blockedBondEther_get_value(0);
        assertEq(value.amount, 0);
        assertEq(value.retentionUntil, 0);
    }

    function test_private_reduceBlockedBondETH() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;
        uint256 retentionUntil = block.timestamp + 1 weeks;

        accounting._blockedBondEther_set_value(
            noId,
            CSBondLock.BondLock({
                amount: amount,
                retentionUntil: retentionUntil
            })
        );

        // part of blocked bond is released
        uint256 toReduce = 10 ether;
        uint256 rest = amount - toReduce;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(noId, rest, retentionUntil);

        accounting._reduceBlockedBondETH_revealed(noId, toReduce);

        CSBondLock.BondLock memory value = accounting
            ._blockedBondEther_get_value(noId);

        assertEq(value.amount, rest);
        assertEq(value.retentionUntil, retentionUntil);

        // all blocked bond is released
        toReduce = rest;
        rest = 0;
        retentionUntil = 0;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(noId, rest, retentionUntil);

        accounting._reduceBlockedBondETH_revealed(noId, toReduce);

        value = accounting._blockedBondEther_get_value(noId);

        assertEq(value.amount, rest);
        assertEq(value.retentionUntil, retentionUntil);
    }

    function test_private_reduceBlockedBondETH_revertWhenNoBlocked() public {
        vm.expectRevert(InvalidBondLockAmount.selector);
        accounting._reduceBlockedBondETH_revealed(0, 1 ether);
    }

    function test_private_reduceBlockedBondETH_revertWhenAmountGreaterThanBlocked()
        public
    {
        uint256 noId = 0;
        uint256 amount = 100 ether;
        uint256 retentionUntil = block.timestamp + 1 weeks;

        accounting._blockedBondEther_set_value(
            noId,
            CSBondLock.BondLock({
                amount: amount,
                retentionUntil: retentionUntil
            })
        );

        vm.expectRevert(InvalidBondLockAmount.selector);
        accounting._reduceBlockedBondETH_revealed(0, 101 ether);
    }

    function test_releaseBlockedBondETH() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        uint256 noId = 0;
        uint256 amount = 100 ether;
        uint256 retentionUntil = block.timestamp + 1 weeks;

        accounting._blockedBondEther_set_value(
            noId,
            CSBondLock.BondLock({
                amount: amount,
                retentionUntil: retentionUntil
            })
        );

        uint256 toRelease = 10 ether;
        uint256 rest = amount - toRelease;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockReleased(noId, toRelease);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(noId, rest, retentionUntil);

        vm.prank(admin);
        accounting.releaseBlockedBondETH(noId, toRelease);
    }

    function test_releaseBlockedBondETH_revertWhenNonExistingOperator() public {
        vm.expectRevert("node operator does not exist");

        vm.prank(admin);
        accounting.releaseBlockedBondETH(0, 1 ether);
    }

    function test_releaseBlockedBondETH_revertWhenNoRole() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    address(stranger),
                    accounting.EL_REWARDS_STEALING_PENALTY_INIT_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.releaseBlockedBondETH(0, 1 ether);
    }

    function test_compensateBlockedBondETH() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        uint256 noId = 0;
        uint256 amount = 100 ether;
        uint256 retentionUntil = block.timestamp + 1 weeks;

        accounting._blockedBondEther_set_value(
            noId,
            CSBondLock.BondLock({
                amount: amount,
                retentionUntil: retentionUntil
            })
        );

        uint256 toCompensate = 10 ether;
        uint256 rest = amount - toCompensate;

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockCompensated(noId, toCompensate);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockChanged(noId, rest, retentionUntil);

        vm.deal(user, toCompensate);
        vm.prank(user);
        accounting.compensateBlockedBondETH{ value: toCompensate }(noId);

        assertEq(address(locator.elRewardsVault()).balance, toCompensate);
    }

    function test_compensateBlockedBondETH_revertWhenZero() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });

        vm.expectRevert(InvalidBondLockAmount.selector);
        accounting.compensateBlockedBondETH{ value: 0 }(0);
    }

    function test_compensateBlockedBondETH_revertWhenNonExistingOperator()
        public
    {
        vm.expectRevert("node operator does not exist");
        accounting.compensateBlockedBondETH{ value: 1 ether }(0);
    }

    function _createNodeOperator(
        uint64 ongoingVals,
        uint64 withdrawnVals
    ) internal {
        stakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _rewardAddress: user,
            _totalVettedValidators: ongoingVals,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: withdrawnVals,
            _totalAddedValidators: ongoingVals,
            _totalDepositedValidators: ongoingVals
        });
    }
}
