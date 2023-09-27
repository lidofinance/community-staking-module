// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { CommunityStakingBondManager } from "../src/CommunityStakingBondManager.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CommunityStakingBondManagerTest is Test, Fixtures {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;
    Stub internal burner;

    CommunityStakingBondManager public bondManager;
    CommunityStakingModuleMock public communityStakingModule;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;

    function setUp() public {
        admin = address(1);

        user = address(2);
        stranger = address(777);

        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = admin;

        (locator, wstETH, stETH, burner) = initLido();

        communityStakingModule = new CommunityStakingModuleMock();
        bondManager = new CommunityStakingBondManager(
            2 ether,
            admin,
            address(locator),
            address(wstETH),
            address(communityStakingModule),
            penalizeRoleMembers
        );
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(bondManager)
        );
        vm.prank(admin);
        bondManager.setFeeDistributor(address(communityStakingFeeDistributor));
    }

    function test_totalBondShares() public {
        stETH.mintShares(address(bondManager), 32 * 1e18);
        assertEq(bondManager.totalBondShares(), 32 * 1e18);
    }

    function test_depositStETH() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 shares = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(user);
        bondManager.depositStETH(0, 32 ether);

        assertEq(stETH.balanceOf(user), 0);
        assertEq(bondManager.getBondShares(0), shares);
        assertEq(stETH.sharesOf(address(bondManager)), shares);
    }

    function test_depositETH() public {
        vm.deal(user, 32 ether);

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(user);
        uint256 shares = bondManager.depositETH{ value: 32 ether }(0);

        assertEq(address(user).balance, 0);
        assertEq(bondManager.getBondShares(0), shares);
        assertEq(stETH.sharesOf(address(bondManager)), shares);
    }

    function test_depositWstETH() public {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        uint256 shares = bondManager.depositWstETH(0, wstETHAmount);

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(bondManager.getBondShares(0), shares);
        assertEq(stETH.sharesOf(address(bondManager)), shares);
    }

    function test_deposit_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        bondManager.depositStETH(0, 32 ether);
    }

    function test_getRequiredBondShares_OneWithdrawnValidator() public {
        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });
        assertEq(
            bondManager.getRequiredBondShares(0),
            stETH.getSharesByPooledEth(30 ether)
        );
    }

    function test_getRequiredBondShares_NoWithdrawnValidators() public {
        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });
        assertEq(
            bondManager.getRequiredBondShares(0),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_getRequiredBondSharesForKeys() public {
        assertEq(
            bondManager.getRequiredBondSharesForKeys(1),
            stETH.getSharesByPooledEth(2 ether)
        );
    }

    function test_claimRewardsWstETH() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.deal(address(communityStakingFeeDistributor), 0.1 ether);
        vm.prank(address(communityStakingFeeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewardsWstETH(new bytes32[](1), 0, sharesAsFee);
        uint256 bondSharesAfter = bondManager.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETH.getWstETHByStETH(stETH.getPooledEthByShares(sharesAsFee))
        );
        assertEq(bondSharesAfter, bondSharesBefore);
    }

    function test_claimRewardsStETH() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.deal(address(communityStakingFeeDistributor), 0.1 ether);
        vm.prank(address(communityStakingFeeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewardsStETH(new bytes32[](1), 0, sharesAsFee);
        uint256 bondSharesAfter = bondManager.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), sharesAsFee);
        assertEq(bondSharesAfter, bondSharesBefore);
    }

    function test_claimRewardsStETH_WithDesirableValue() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.deal(address(communityStakingFeeDistributor), 0.1 ether);
        vm.prank(address(communityStakingFeeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            0.05 ether
        );
        uint256 claimedShares = stETH.getSharesByPooledEth(0.05 ether);

        assertEq(stETH.sharesOf(address(user)), claimedShares);
        assertEq(
            bondManager.getBondShares(0),
            (bondSharesBefore + sharesAsFee) - claimedShares
        );
    }

    function test_claimRewardsStETH_WhenAmountToClaimIsHigherThanRewards()
        public
    {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.deal(address(communityStakingFeeDistributor), 0.1 ether);
        vm.prank(address(communityStakingFeeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            100 * 1e18
        );
        uint256 bondSharesAfter = bondManager.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), sharesAsFee);
        assertEq(bondSharesAfter, bondSharesBefore);
    }

    function test_claimRewardsStETH_WhenRequiredBondIsEqualActual() public {
        vm.deal(user, 31 ether);
        vm.prank(user);
        stETH.submit{ value: 31 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.deal(address(communityStakingFeeDistributor), 1 ether);
        vm.prank(address(communityStakingFeeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 31 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewardsStETH(new bytes32[](1), 0, sharesAsFee);
        uint256 bondSharesAfter = bondManager.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), 0);
        assertEq(bondSharesAfter, bondSharesBefore + sharesAsFee);
    }

    function test_claimRewardsWstETH_RevertWhenCallerIsNotRewardAddress()
        public
    {
        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CommunityStakingBondManager.NotOwnerToClaim.selector,
                stranger,
                user
            )
        );
        vm.startPrank(stranger);
        bondManager.claimRewardsWstETH(new bytes32[](1), 0, 1, 1 ether);
        vm.stopPrank();
    }

    function test_claimRewardsStETH_RevertWhenCallerIsNotRewardAddress()
        public
    {
        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CommunityStakingBondManager.NotOwnerToClaim.selector,
                stranger,
                user
            )
        );
        vm.startPrank(stranger);
        bondManager.claimRewardsStETH(new bytes32[](1), 0, 1, 1 ether);
        vm.stopPrank();
    }

    function test_penalize_LessThanDeposit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        vm.prank(admin);
        bondManager.penalize(0, 1 * 1e18);

        assertEq(bondManager.getBondShares(0), bondSharesBefore - 1 * 1e18);
        assertEq(stETH.sharesOf(address(burner)), 1 * 1e18);
    }

    function test_penalize_MoreThanDeposit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 shares = stETH.getSharesByPooledEth(32 ether);

        vm.prank(admin);
        bondManager.penalize(0, 32 * 1e18);

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(stETH.sharesOf(address(burner)), shares);
    }

    function test_penalize_EqualToDeposit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 shares = stETH.getSharesByPooledEth(32 ether);
        vm.prank(admin);
        bondManager.penalize(0, shares);

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(stETH.sharesOf(address(burner)), shares);
    }

    function test_penalize_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000309 is missing role 0xf3c54f9b8dbd8c6d8596d09d52b61d4bdce01620000dd9d49c5017dca6e62158"
        );
        vm.prank(stranger);
        bondManager.penalize(0, 20);
    }
}
