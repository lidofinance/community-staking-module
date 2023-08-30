// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/CommunityStakingBondManager.sol";
import { stETHMock } from "./mock_contracts/stETHMock.sol";
import { FeeReward } from "../src/interfaces/ICommunityStakingFeeDistributor.sol";

contract CommunityStakingBondManagerTest is Test {
    CommunityStakingBondManager public bondManager;
    stETHMock public stETH;

    address internal stranger;
    address internal alice;
    address internal locator;
    address internal burner;

    address internal communityStakingModule;
    address internal communityStakingFeeDistributor;

    function setUp() public {
        stranger = address(777);
        alice = address(1);
        locator = address(2);
        burner = address(21);
        communityStakingModule = address(4);
        communityStakingFeeDistributor = address(5);

        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        stETH = new stETHMock(8013386371917025835991984);
        stETH.mintShares(address(stETH), 7059313073779349112833523);
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            locator,
            communityStakingModule,
            communityStakingFeeDistributor,
            penalizeRoleMembers
        );
        vm.mockCall(
            locator,
            abi.encodeWithSelector(ILidoLocator.lido.selector),
            abi.encode(address(stETH))
        );
        vm.mockCall(
            locator,
            abi.encodeWithSelector(ILidoLocator.burner.selector),
            abi.encode(burner)
        );
    }

    function test_totalBondShares() public {
        stETH.mintShares(address(bondManager), 32 * 10 ** 18);
        assertEq(bondManager.totalBondShares(), 32 * 10 ** 18);
    }

    function test_totalBondEth() public {
        stETH.mintShares(address(bondManager), 32 * 10 ** 18);
        assertEq(bondManager.totalBondEth(), 36324667688196920249);
    }

    function test_deposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.startPrank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);
        vm.stopPrank();

        assertEq(bondManager.getBondShares(0), 32 * 10 ** 18);
    }

    function test_getBondEth() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.startPrank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);
        vm.stopPrank();

        assertEq(bondManager.getBondEth(0), 36324667688196920249);
    }

    function test_getRequiredBondEth_OneWithdrownValidator() public {
        _mock_getNodeOperator(0, alice, 1, 16);
        assertEq(bondManager.getRequiredBondEth(0), 30 ether);
    }

    function test_getRequiredBondEth_NoWithdrownValidators() public {
        _mock_getNodeOperator(0, alice, 0, 16);
        assertEq(bondManager.getRequiredBondEth(0), 32 ether);
    }

    function test_claimRewards() public {
        stETH.submit(stranger, 32 ether);

        vm.startPrank(stranger);
        bondManager.deposit(0, stETH.sharesOf(stranger));
        vm.stopPrank();

        _mock_getNodeOperator(0, stranger, 0, 16);

        uint256 sharesAsFee = stETH.submit(address(bondManager), 0.1 ether);
        _mock_distibuteFee(sharesAsFee);

        vm.startPrank(stranger);
        uint256 bondSharesBefore = bondManager.getBondShares(0);
        uint256 claimedShares = bondManager.claimRewards(
            new bytes32[](1),
            FeeReward(0, sharesAsFee),
            0.05 * 10 ** 18
        );
        vm.stopPrank();

        assertEq(claimedShares, 0.05 * 10 ** 18);
        assertEq(stETH.sharesOf(address(stranger)), claimedShares);
        assertEq(
            bondManager.getBondShares(0),
            (bondSharesBefore + sharesAsFee) - claimedShares
        );
    }

    function test_claimRewards_WhenAmountToClaimIsHigherThanRewards() public {
        stETH.submit(stranger, 32 ether);

        vm.startPrank(stranger);
        bondManager.deposit(0, stETH.sharesOf(stranger));
        vm.stopPrank();

        _mock_getNodeOperator(0, stranger, 0, 16);

        uint256 sharesAsFee = stETH.submit(address(bondManager), 0.1 ether);
        _mock_distibuteFee(sharesAsFee);

        vm.startPrank(stranger);
        uint256 requiredBondShares = bondManager.getRequiredBondShares(0);
        uint256 claimedShares = bondManager.claimRewards(
            new bytes32[](1),
            FeeReward(0, sharesAsFee),
            100 * 10 ** 18
        );
        uint256 bondSharesAfter = bondManager.getBondShares(0);
        vm.stopPrank();

        assertEq(claimedShares, sharesAsFee);
        assertEq(stETH.sharesOf(address(stranger)), claimedShares);
        assertEq(bondSharesAfter, requiredBondShares);
    }

    function test_claimRewards_RevertWhenCallerIsNotRewardAddress() public {
        vm.expectRevert("only reward address can claim rewards");
        _mock_getNodeOperator(0, stranger, 0, 16);

        vm.startPrank(alice);
        bondManager.claimRewards(
            new bytes32[](1),
            FeeReward(0, 1),
            1 * 10 ** 18
        );
        vm.stopPrank();
    }

    function test_penalize_LessThanDeposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.startPrank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(alice);
        bondManager.penalize(0, 1 * 10 ** 18);
        vm.stopPrank();

        assertEq(bondManager.getBondShares(0), 31 * 10 ** 18);
        assertEq(stETH.sharesOf(burner), 1 * 10 ** 18);
    }

    function test_penalize_MoreThanDeposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.startPrank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(alice);
        bondManager.penalize(0, 33 * 10 ** 18);
        vm.stopPrank();

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(stETH.sharesOf(burner), 32 * 10 ** 18);
    }

    function test_penalize_EqualToDeposit() public {
        stETH.mintShares(stranger, 32 * 10 ** 18);

        vm.startPrank(stranger);
        bondManager.deposit(0, 32 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(alice);
        bondManager.penalize(0, 32 * 10 ** 18);
        vm.stopPrank();

        assertEq(bondManager.getBondShares(0), 0);
        assertEq(stETH.sharesOf(burner), 32 * 10 ** 18);
    }

    function test_penalize_RevertWhenCallerHasNotRole() public {
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000309 is missing role 0xf3c54f9b8dbd8c6d8596d09d52b61d4bdce01620000dd9d49c5017dca6e62158"
        );
        vm.startPrank(stranger);
        bondManager.penalize(0, 20);
        vm.stopPrank();
    }

    function _mock_getNodeOperator(
        uint256 nodeOperatorId,
        address rewardAddress,
        uint64 totalWithdrawnValidators,
        uint64 totalAddedValidators
    ) internal {
        vm.mockCall(
            communityStakingModule,
            abi.encodeWithSelector(
                ICommunityStakingModule.getNodeOperator.selector,
                nodeOperatorId,
                false
            ),
            abi.encode(
                uint256(0),
                uint256(0),
                rewardAddress,
                uint256(0),
                totalWithdrawnValidators,
                totalAddedValidators,
                uint256(0),
                uint256(0)
            )
        );
    }

    function _mock_distibuteFee(uint256 shares) internal {
        vm.mockCall(
            communityStakingFeeDistributor,
            abi.encodeWithSelector(
                ICommunityStakingFeeDistributor.distributeFees.selector
            ),
            abi.encode(shares)
        );
    }
}
