// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../../src/CommunityStakingBondManager.sol";
import { LidoMock } from "../../src/test_helpers/LidoMock.sol";
import { WstETHMock } from "../../src/test_helpers/WstETHMock.sol";
import { LidoLocatorMock } from "../../src/test_helpers/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "../../src/test_helpers/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "../../src/test_helpers/CommunityStakingFeeDistributorMock.sol";

contract CommunityStakingBondManagerTest is Test {
    CommunityStakingBondManager public bondManager;
    LidoMock public lidoStETH;
    WstETHMock public wstETH;
    CommunityStakingModuleMock public communityStakingModule;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;
    LidoLocatorMock public locator;

    address internal admin;
    address internal user;
    address internal stranger;
    address internal burner;

    function setUp() public {
        admin = address(1);
        burner = address(21);

        user = address(2);
        stranger = address(777);

        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = admin;

        communityStakingModule = new CommunityStakingModuleMock();
        lidoStETH = new LidoMock(8013386371917025835991984);
        lidoStETH.mintShares(address(lidoStETH), 7059313073779349112833523);
        locator = new LidoLocatorMock(address(lidoStETH), burner);
        wstETH = new WstETHMock(address(lidoStETH));
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
        lidoStETH.mintShares(address(bondManager), 32 * 1e18);
        assertEq(bondManager.totalBondShares(), 32 * 1e18);
    }

    function test_totalBondEth() public {
        lidoStETH.mintShares(address(bondManager), 32 * 1e18);
        assertEq(
            bondManager.totalBondEth(),
            lidoStETH.getPooledEthByShares(32 * 1e18)
        );
    }

    function test_depositStETH() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 shares = lidoStETH.submit{ value: 32 ether }({
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

        assertEq(bondManager.getBondShares(0), shares);
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

        assertEq(bondManager.getBondShares(0), shares);
    }

    function test_depositWstETH() public {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });
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

        assertEq(bondManager.getBondShares(0), shares);
    }

    function test_deposit_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        bondManager.depositStETH(0, 32 ether);
    }

    function test_getBondEth() public {
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
        bondManager.depositETH{ value: 32 ether }(0);

        assertEq(bondManager.getBondEth(0), 32 ether - 1);
    }

    function test_getRequiredBondEth_OneWithdrawnValidator() public {
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
        assertEq(bondManager.getRequiredBondEth(0), 30 ether);
    }

    function test_getRequiredBondEth_NoWithdrawnValidators() public {
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
        assertEq(bondManager.getRequiredBondEth(0), 32 ether);
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
        assertEq(bondManager.getRequiredBondShares(0), 26428201809357774385);
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
        assertEq(bondManager.getRequiredBondShares(0), 28190081929981626011);
    }

    function test_getRequiredBondEthForKeys() public {
        assertEq(bondManager.getRequiredBondEthForKeys(1), 2 ether);
    }

    function test_getRequiredBondSharesForKeys() public {
        assertEq(
            bondManager.getRequiredBondSharesForKeys(1),
            1761880120623851625
        );
    }

    function test_claimRewards() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });

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
        uint256 sharesAsFee = lidoStETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewards(new bytes32[](1), 0, sharesAsFee);

        assertEq(lidoStETH.sharesOf(address(user)), sharesAsFee);
        assertEq(
            bondManager.getBondShares(0),
            (bondSharesBefore + sharesAsFee) - sharesAsFee
        );
    }

    function test_claimRewards_WithDesirableValue() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });

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
        uint256 sharesAsFee = lidoStETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewards(new bytes32[](1), 0, sharesAsFee, 0.05 * 1e18);

        assertEq(lidoStETH.sharesOf(address(user)), 0.05 * 1e18);
        assertEq(
            bondManager.getBondShares(0),
            (bondSharesBefore + sharesAsFee) - 0.05 * 1e18
        );
    }

    function test_claimRewards_WhenAmountToClaimIsHigherThanRewards() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });

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
        uint256 sharesAsFee = lidoStETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 32 ether);

        uint256 requiredBondShares = bondManager.getRequiredBondShares(0);
        bondManager.claimRewards(new bytes32[](1), 0, sharesAsFee, 100 * 1e18);
        uint256 bondSharesAfter = bondManager.getBondShares(0);

        assertEq(lidoStETH.sharesOf(address(user)), sharesAsFee);
        assertEq(bondSharesAfter, requiredBondShares);
    }

    function test_claimRewards_RevertWhenRequiredBondIsEqualActual() public {
        vm.deal(user, 31 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 31 ether }({ _referal: address(0) });

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
        uint256 sharesAsFee = lidoStETH.submit{ value: 1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 31 ether);

        vm.expectRevert(CommunityStakingBondManager.NothingToClaim.selector);
        bondManager.claimRewards(new bytes32[](1), 0, sharesAsFee, 1 * 1e18);
    }

    function test_claimRewards_RevertWhenNothingToClaim() public {
        vm.deal(user, 30 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 30 ether }({ _referal: address(0) });

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
        uint256 sharesAsFee = lidoStETH.submit{ value: 0.1 ether }(address(0));

        vm.startPrank(user);
        bondManager.depositStETH(0, 30 ether);

        vm.expectRevert(CommunityStakingBondManager.NothingToClaim.selector);
        bondManager.claimRewards(new bytes32[](1), 0, sharesAsFee, 1 * 1e18);
    }

    function test_claimRewards_RevertWhenCallerIsNotRewardAddress() public {
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
        bondManager.claimRewards(new bytes32[](1), 0, 1, 1 * 1e18);
        vm.stopPrank();
    }

    function test_penalize_LessThanDeposit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });

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

        vm.prank(admin);
        bondManager.penalize(0, 1 * 1e18);

        assertEq(bondManager.getBondEth(0), 30864848989106117958);
        assertEq(lidoStETH.sharesOf(burner), 1 * 1e18);
    }

    function test_penalize_MoreThanDeposit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });

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

        uint256 shares = lidoStETH.getSharesByPooledEth(32 ether);

        vm.prank(admin);
        bondManager.penalize(0, 32 * 1e18);

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(lidoStETH.sharesOf(burner), shares);
    }

    function test_penalize_EqualToDeposit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        lidoStETH.submit{ value: 32 ether }({ _referal: address(0) });

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

        uint256 shares = lidoStETH.getSharesByPooledEth(32 ether);
        vm.prank(admin);
        bondManager.penalize(0, shares);

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(lidoStETH.sharesOf(burner), shares);
    }

    function test_penalize_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000309 is missing role 0xf3c54f9b8dbd8c6d8596d09d52b61d4bdce01620000dd9d49c5017dca6e62158"
        );
        vm.prank(stranger);
        bondManager.penalize(0, 20);
    }
}
