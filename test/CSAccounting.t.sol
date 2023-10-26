// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSAccountingBase, CSAccounting } from "../src/CSAccounting.sol";
import { PermitTokenBase } from "./helpers/Permit.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import { WithdrawalQueueMockBase, WithdrawalQueueMock } from "./helpers/mocks/WithdrawalQueueMock.sol";

import { Fixtures } from "./helpers/Fixtures.sol";

contract CSAccountingTest is
    Test,
    Fixtures,
    PermitTokenBase,
    CSAccountingBase,
    WithdrawalQueueMockBase
{
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;
    WithdrawalQueueMock internal wq;

    Stub internal burner;

    CSAccounting public accounting;
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
        accounting = new CSAccounting(
            2 ether,
            admin,
            address(locator),
            address(wstETH),
            address(stakingModule),
            8 weeks
        );
        feeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(accounting)
        );
        vm.startPrank(admin);
        accounting.setFeeDistributor(address(feeDistributor));
        accounting.grantRole(accounting.PENALIZE_BOND_ROLE(), admin);
        accounting.grantRole(
            accounting.EL_REWARDS_STEALING_PENALTY_ROLE(),
            admin
        );
        accounting.grantRole(accounting.EASY_TRACK_MOTION_AGENT_ROLE(), admin);
        vm.stopPrank();
    }

    function test_totalBondShares() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_getRequiredBondETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        assertEq(accounting.getRequiredBondETH(0, 0), 32 ether);
    }

    function test_getRequiredBondStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        assertEq(accounting.getRequiredBondStETH(0, 0), 32 ether);
    }

    function test_getRequiredBondWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        assertEq(
            accounting.getRequiredBondWstETH(0, 0),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_getRequiredBondETH_OneWithdrawnValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondETH(0, 0), 30 ether);
    }

    function test_getRequiredBondStETH_OneWithdrawnValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondStETH(0, 0), 30 ether);
    }

    function test_getRequiredBondWstETH_OneWithdrawnValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(
            accounting.getRequiredBondWstETH(0, 0),
            stETH.getSharesByPooledEth(30 ether)
        );
    }

    function test_getRequiredBondETH_OneWithdrawnOneAddedValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondETH(0, 1), 32 ether);
    }

    function test_getRequiredBondStETH_OneWithdrawnOneAddedValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondStETH(0, 1), 32 ether);
    }

    function test_getRequiredBondWstETH_OneWithdrawnOneAddedValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(
            accounting.getRequiredBondWstETH(0, 1),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_getRequiredBondETH_WithExcessBond() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);
        assertApproxEqAbs(
            accounting.getRequiredBondETH(0, 16),
            0,
            1, // max accuracy error
            "required ETH should be ~0 for the next 16 validators to deposit"
        );
    }

    function test_getRequiredBondStETH_WithExcessBond() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        stETH.submit{ value: 64 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 64 ether);
        assertApproxEqAbs(
            accounting.getRequiredBondStETH(0, 16),
            0,
            1, // max accuracy error
            "required stETH should be ~0 for the next 16 validators to deposit"
        );
    }

    function test_getRequiredBondWstETH_WithExcessBond() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        stETH.submit{ value: 64 ether }({ _referal: address(0) });
        uint256 amount = wstETH.wrap(64 ether);
        accounting.depositWstETH(user, 0, amount);
        assertApproxEqAbs(
            accounting.getRequiredBondWstETH(0, 16),
            0,
            1, // max accuracy error
            "required wstETH should be ~0 for the next 16 validators to deposit"
        );
    }

    function test_getRequiredBondETHForKeys() public {
        assertEq(accounting.getRequiredBondETHForKeys(1), 2 ether);
    }

    function test_getRequiredBondStETHForKeys() public {
        assertEq(accounting.getRequiredBondStETHForKeys(1), 2 ether);
    }

    function test_getRequiredBondWstETHForKeys() public {
        assertEq(
            accounting.getRequiredBondWstETHForKeys(1),
            stETH.getSharesByPooledEth(2 ether)
        );
    }

    function test_depositETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit ETHBondDeposited(0, user, 32 ether);

        vm.prank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);

        assertEq(
            address(user).balance,
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositETH_CoverSeveralValidators() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });
        vm.deal(user, 32 ether);

        uint256 required = accounting.getRequiredBondETHForKeys(1);
        vm.startPrank(user);
        accounting.depositETH{ value: required }(user, 0);

        assertApproxEqAbs(
            accounting.getRequiredBondETH(0, 0),
            0,
            1, // max accuracy error
            "required ETH should be ~0 for 1 deposited validator"
        );

        required = accounting.getRequiredBondETH(0, 1);
        accounting.depositETH{ value: required }(user, 0);
        stakingModule.addValidator(0, 1);

        assertApproxEqAbs(
            accounting.getRequiredBondETH(0, 0),
            0,
            1, // max accuracy error
            "required ETH should be ~0 for 2 deposited validators"
        );
    }

    function test_depositStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHBondDeposited(0, user, 32 ether);

        accounting.depositStETH(user, 0, 32 ether);

        assertEq(
            stETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositStETH_CoverSeveralValidators() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        uint256 required = accounting.getRequiredBondStETHForKeys(1);
        accounting.depositStETH(user, 0, required);

        assertApproxEqAbs(
            accounting.getRequiredBondStETH(0, 0),
            0,
            1, // max accuracy error
            "required stETH should be ~0 for 1 deposited validator"
        );

        required = accounting.getRequiredBondStETH(0, 1);
        accounting.depositStETH(user, 0, required);
        stakingModule.addValidator(0, 1);
        assertApproxEqAbs(
            accounting.getRequiredBondStETH(0, 0),
            0,
            1, // max accuracy error
            "required stETH should be ~0 for 2 deposited validators"
        );
    }

    function test_depositWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHBondDeposited(0, user, wstETHAmount);

        accounting.depositWstETH(user, 0, wstETHAmount);

        assertEq(
            wstETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositWstETH_CoverSeveralValidators() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        wstETH.wrap(32 ether);

        uint256 required = accounting.getRequiredBondWstETHForKeys(1);
        accounting.depositWstETH(user, 0, required);

        assertApproxEqAbs(
            accounting.getRequiredBondWstETH(0, 0),
            0,
            1, // max accuracy error
            "required wstETH should be ~0 for 1 deposited validator"
        );

        required = accounting.getRequiredBondStETH(0, 1);
        accounting.depositWstETH(user, 0, required);
        stakingModule.addValidator(0, 1);

        assertApproxEqAbs(
            accounting.getRequiredBondWstETH(0, 0),
            0,
            1, // max accuracy error
            "required wstETH should be ~0 for 2 deposited validators"
        );
    }

    function test_depositStETHWithPermit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.expectEmit(true, true, true, true, address(stETH));
        emit Approval(user, address(accounting), 32 ether);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHBondDeposited(0, user, 32 ether);

        vm.prank(stranger);
        accounting.depositStETHWithPermit(
            user,
            0,
            32 ether,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            stETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositWstETHWithPermit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.expectEmit(true, true, true, true, address(wstETH));
        emit Approval(user, address(accounting), 32 ether);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHBondDeposited(0, user, wstETHAmount);

        vm.prank(stranger);
        accounting.depositWstETHWithPermit(
            user,
            0,
            wstETHAmount,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            wstETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            accounting.totalBondShares(),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_deposit_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        accounting.depositStETH(user, 0, 32 ether);
    }

    function test_getTotalRewardsETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 ETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);

        // todo: should we think about simulate rebase?
        uint256 totalRewards = accounting.getTotalRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        assertEq(totalRewards, ETHAsFee);
    }

    function test_getTotalRewardsStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        // todo: should we think about simulate rebase?
        uint256 totalRewards = accounting.getTotalRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        assertEq(totalRewards, stETHAsFee);
    }

    function test_getTotalRewardsWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 wstETHAsFee = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesAsFee)
        );
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        // todo: should we think about simulate rebase?
        uint256 totalRewards = accounting.getTotalRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        assertEq(totalRewards, wstETHAsFee);
    }

    function test_getExcessBondETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);

        assertApproxEqAbs(accounting.getExcessBondETH(0), 32 ether, 1);
    }

    function test_getExcessBondStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);

        assertApproxEqAbs(accounting.getExcessBondStETH(0), 32 ether, 1);
    }

    function test_getExcessBondWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);

        assertApproxEqAbs(
            accounting.getExcessBondWstETH(0),
            wstETH.getWstETHByStETH(32 ether),
            1
        );
    }

    function test_getMissingBondETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 16 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 16 ether }(user, 0);

        assertApproxEqAbs(accounting.getMissingBondETH(0), 16 ether, 1);
    }

    function test_getMissingBondStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 16 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 16 ether }(user, 0);

        assertApproxEqAbs(accounting.getMissingBondStETH(0), 16 ether, 1);
    }

    function test_getMissingBondWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 16 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 16 ether }(user, 0);

        assertApproxEqAbs(
            accounting.getMissingBondWstETH(0),
            wstETH.getWstETHByStETH(16 ether),
            1
        );
    }

    function test_getUnbondedKeysCount() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 17.57 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 17.57 ether }(user, 0);

        assertEq(accounting.getUnbondedKeysCount(0), 7);
    }

    function test_claimRewardsStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(
            0,
            user,
            stETH.getPooledEthByShares(sharesAsFee)
        );

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to before"
        );
    }

    function test_claimRewardsStETH_WithDesirableValue() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 stETHToClaim = stETH.getPooledEthByShares(sharesToClaim);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, stETHToClaim);

        uint256 bondSharesBefore = accounting.getBondShares(0);

        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            0.05 ether
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHToClaim,
            "user balance should be equal to claimed"
        );
        assertEq(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - sharesToClaim,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after should be equal to before and fee minus claimed shares"
        );
    }

    function test_claimRewardsStETH_WhenAmountToClaimIsHigherThanRewards()
        public
    {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, stETHAsFee);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            100 * 1e18
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after should be equal to before"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after should be equal to before"
        );
    }

    function test_claimRewardsStETH_WhenRequiredBondIsEqualActual() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 1 ether }(address(0));

        vm.deal(user, 31 ether);
        vm.startPrank(user);
        stETH.submit{ value: 31 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 31 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, 0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.balanceOf(address(user)), 0, "user balance should be 0");
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be increased by fee"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager shares should be increased by fee"
        );
    }

    function test_claimRewardsStETH_WhenRequiredBondIsHigherActual() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.5 ether }(address(0));

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 31 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 31 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, 0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.balanceOf(address(user)), 0, "user balance should be 0");
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be increased by fee"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager shares should be increased by fee"
        );
    }

    function test_claimRewardsStETH_RevertWhenCallerIsNotRewardAddress()
        public
    {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(
                CSAccounting.NotOwnerToClaim.selector,
                stranger,
                user
            )
        );
        vm.prank(stranger);
        accounting.claimRewardsStETH(new bytes32[](1), 0, 1, 1 ether);
    }

    function test_claimRewardsWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 wstETHAsFee = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesAsFee)
        );
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHRewardsClaimed(0, user, wstETHAsFee);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHAsFee,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore + 1 wei,
            "bond shares after claim should contain wrapped fee accuracy error"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesBefore + 1 wei,
            "bond manager after claim should contain wrapped fee accuracy error"
        );
    }

    function test_claimRewardsWstETH_WithDesirableValue() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 wstETHToClaim = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesToClaim)
        );
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHRewardsClaimed(0, user, wstETHToClaim);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            stETH.getSharesByPooledEth(0.05 ether)
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHToClaim,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - wstETHToClaim,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            (bondSharesBefore + sharesAsFee) - wstETHToClaim,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
    }

    function test_claimRewardsWstETH_RevertWhenCallerIsNotRewardAddress()
        public
    {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(
                CSAccounting.NotOwnerToClaim.selector,
                stranger,
                user
            )
        );
        vm.prank(stranger);
        accounting.claimRewardsWstETH(new bytes32[](1), 0, 1, 1 ether);
    }

    function test_requestRewardsETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        uint256 requestedAsUnstETH = stETH.getPooledEthByShares(sharesAsFee);
        uint256 requestedAsUnstETHAsShares = stETH.getSharesByPooledEth(
            requestedAsUnstETH
        );

        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(locator.withdrawalQueue())
        );
        emit WithdrawalRequested(
            1,
            address(accounting),
            user,
            requestedAsUnstETH,
            requestedAsUnstETHAsShares
        );
        vm.expectEmit(true, true, true, true, address(accounting));
        emit ETHRewardsRequested(
            0,
            user,
            stETH.getPooledEthByShares(sharesAsFee)
        );

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256[] memory requestIds = accounting.requestRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(requestIds.length, 1, "request ids length should be 1");
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares should not change after request"
        );
        assertEq(
            stETH.sharesOf(address(locator.withdrawalQueue())),
            requestedAsUnstETHAsShares,
            "shares of withdrawal queue should be equal to requested shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
    }

    function test_requestRewardsETH_WithDesirableValue() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        uint256 requestedAsShares = stETH.getSharesByPooledEth(0.05 ether);
        uint256 requestedAsUnstETH = stETH.getPooledEthByShares(
            requestedAsShares
        );
        uint256 requestedAsUnstETHAsShares = stETH.getSharesByPooledEth(
            requestedAsUnstETH
        );

        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(locator.withdrawalQueue())
        );
        emit WithdrawalRequested(
            1,
            address(accounting),
            user,
            requestedAsUnstETH,
            requestedAsUnstETHAsShares
        );
        vm.expectEmit(true, true, true, true, address(accounting));
        emit ETHRewardsRequested(0, user, requestedAsUnstETH);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256[] memory requestIds = accounting.requestRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            0.05 ether
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(requestIds.length, 1, "request ids length should be 1");
        assertEq(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - requestedAsShares,
            "bond shares after should be equal to before and fee minus requested shares"
        );
        assertEq(
            stETH.sharesOf(address(locator.withdrawalQueue())),
            requestedAsUnstETHAsShares,
            "shares of withdrawal queue should be equal to requested shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
    }

    function test_penalize_LessThanDeposit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 penalized = stETH.getPooledEthByShares(shares);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(0, penalized, penalized);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(admin);
        accounting.penalize(0, 1 ether);

        assertEq(
            accounting.getBondShares(0),
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesBefore - shares,
            "bond manager shares should be decreased by penalty"
        );
        assertEq(
            stETH.sharesOf(address(burner)),
            shares,
            "burner shares should be equal to penalty"
        );
    }

    function test_penalize_MoreThanDeposit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 penaltyShares = stETH.getSharesByPooledEth(33 ether);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(
            0,
            stETH.getPooledEthByShares(penaltyShares),
            stETH.getPooledEthByShares(bondSharesBefore)
        );

        vm.prank(admin);
        accounting.penalize(0, 33 ether);

        assertEq(
            accounting.getBondShares(0),
            0,
            "bond shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(burner)),
            bondSharesBefore,
            "burner shares should be equal to bond shares"
        );
    }

    function test_penalize_EqualToDeposit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 shares = stETH.getSharesByPooledEth(32 ether);
        uint256 penalized = stETH.getPooledEthByShares(shares);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(0, penalized, penalized);

        vm.prank(admin);
        accounting.penalize(0, 32 ether);

        assertEq(
            accounting.getBondShares(0),
            0,
            "bond shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(burner)),
            shares,
            "burner shares should be equal to penalty"
        );
    }

    function test_penalize_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000309 is missing role 0xf3c54f9b8dbd8c6d8596d09d52b61d4bdce01620000dd9d49c5017dca6e62158"
        );
        vm.prank(stranger);
        accounting.penalize(0, 20);
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
