// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/CommunityStakingBondManager.sol";
import { StETHMock } from "../src/test_helpers/StETHMock.sol";
import { LidoLocatorMock } from "../src/test_helpers/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "../src/test_helpers/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "../src/test_helpers/CommunityStakingFeeDistributorMock.sol";

contract CommunityStakingBondManagerTest is Test {
    CommunityStakingBondManager public bondManager;
    StETHMock public stETH;
    CommunityStakingModuleMock public communityStakingModule;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;
    LidoLocatorMock public locator;

    address internal stranger;
    address internal alice;
    address internal burner;

    function setUp() public {
        stranger = address(777);
        alice = address(1);
        burner = address(21);

        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        communityStakingModule = new CommunityStakingModuleMock();
        stETH = new StETHMock(8013386371917025835991984);
        stETH.mintShares(address(stETH), 7059313073779349112833523);
        locator = new LidoLocatorMock(address(stETH), burner);
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator)
        );
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(locator),
            address(communityStakingModule),
            address(communityStakingFeeDistributor),
            penalizeRoleMembers
        );
        communityStakingFeeDistributor.setBondManager(address(bondManager));
    }

    function test_totalBondShares() public {
        stETH.mintShares(address(bondManager), 32 * 10 ** 18);
        assertEq(bondManager.totalBondShares(), 32 * 10 ** 18);
    }

    function test_totalBondEth() public {
        stETH.mintShares(address(bondManager), 32 * 10 ** 18);
        assertEq(
            bondManager.totalBondEth(),
            stETH.getPooledEthByShares(32 * 10 ** 18)
        );
    }

    function test_deposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.prank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);

        assertEq(bondManager.getBondShares(0), 32 * 10 ** 18);
    }

    function test_getBondEth() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.prank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);

        assertEq(bondManager.getBondEth(0), 36324667688196920249);
    }

    function test_getRequiredBondEth_OneWithdrawnValidator() public {
        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Alice",
            _rewardAddress: alice,
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
            _name: "Alice",
            _rewardAddress: alice,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });
        assertEq(bondManager.getRequiredBondEth(0), 32 ether);
    }

    function test_claimRewards() public {
        stETH._submit(stranger, 32 ether);

        vm.startPrank(stranger);
        bondManager.deposit(0, stETH.sharesOf(stranger));

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Stranger",
            _rewardAddress: stranger,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        uint256 sharesAsFee = stETH._submit(
            address(communityStakingFeeDistributor),
            0.1 ether
        );

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewards(new bytes32[](1), 0, sharesAsFee);

        assertEq(stETH.sharesOf(address(stranger)), sharesAsFee);
        assertEq(
            bondManager.getBondShares(0),
            (bondSharesBefore + sharesAsFee) - sharesAsFee
        );
    }

    function test_claimRewards_WithDesirableValue() public {
        stETH._submit(stranger, 32 ether);

        vm.startPrank(stranger);
        bondManager.deposit(0, stETH.sharesOf(stranger));

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Stranger",
            _rewardAddress: stranger,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        uint256 sharesAsFee = stETH._submit(
            address(communityStakingFeeDistributor),
            0.1 ether
        );

        uint256 bondSharesBefore = bondManager.getBondShares(0);
        bondManager.claimRewards(
            new bytes32[](1),
            0,
            sharesAsFee,
            0.05 * 10 ** 18
        );

        assertEq(stETH.sharesOf(address(stranger)), 0.05 * 10 ** 18);
        assertEq(
            bondManager.getBondShares(0),
            (bondSharesBefore + sharesAsFee) - 0.05 * 10 ** 18
        );
    }

    function test_claimRewards_WhenAmountToClaimIsHigherThanRewards() public {
        stETH._submit(stranger, 32 ether);

        vm.startPrank(stranger);
        bondManager.deposit(0, stETH.sharesOf(stranger));

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Stranger",
            _rewardAddress: stranger,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        uint256 sharesAsFee = stETH._submit(
            address(communityStakingFeeDistributor),
            0.1 ether
        );

        uint256 requiredBondShares = bondManager.getRequiredBondShares(0);
        bondManager.claimRewards(
            new bytes32[](1),
            0,
            sharesAsFee,
            100 * 10 ** 18
        );
        uint256 bondSharesAfter = bondManager.getBondShares(0);

        assertEq(stETH.sharesOf(address(stranger)), sharesAsFee);
        assertEq(bondSharesAfter, requiredBondShares);
    }

    function test_claimRewards_RevertWhenNothingToClaim() public {
        stETH._submit(stranger, 30 ether);

        vm.startPrank(stranger);
        bondManager.deposit(0, stETH.sharesOf(stranger));

        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Stranger",
            _rewardAddress: stranger,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        uint256 sharesAsFee = stETH._submit(
            address(communityStakingFeeDistributor),
            0.1 ether
        );

        vm.expectRevert(CommunityStakingBondManager.NothingToClaim.selector);
        bondManager.claimRewards(
            new bytes32[](1),
            0,
            sharesAsFee,
            1 * 10 ** 18
        );
    }

    function test_claimRewards_RevertWhenCallerIsNotRewardAddress() public {
        communityStakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Stranger",
            _rewardAddress: stranger,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 0,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CommunityStakingBondManager.NotOwnerToClaim.selector,
                alice,
                stranger
            )
        );
        vm.startPrank(alice);
        bondManager.claimRewards(new bytes32[](1), 0, 1, 1 * 10 ** 18);
        vm.stopPrank();
    }

    function test_penalize_LessThanDeposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.prank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);

        vm.prank(alice);
        bondManager.penalize(0, 1 * 10 ** 18);

        assertEq(bondManager.getBondShares(0), 31 * 10 ** 18);
        assertEq(stETH.sharesOf(burner), 1 * 10 ** 18);
    }

    function test_penalize_MoreThanDeposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.prank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);

        vm.prank(alice);
        bondManager.penalize(0, 33 * 10 ** 18);

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(stETH.sharesOf(burner), 32 * 10 ** 18);
    }

    function test_penalize_EqualToDeposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.prank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);

        vm.prank(alice);
        bondManager.penalize(0, 32 * 10 ** 18);

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(stETH.sharesOf(burner), 32 * 10 ** 18);
    }

    function test_penalize_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000309 is missing role 0xf3c54f9b8dbd8c6d8596d09d52b61d4bdce01620000dd9d49c5017dca6e62158"
        );
        vm.prank(stranger);
        bondManager.penalize(0, 20);
    }
}
