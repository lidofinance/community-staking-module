// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "./_Base.t.sol";

// Combined claim rewards tests: stETH, wstETH, unstETH

contract ClaimStETHRewardsTest is ClaimRewardsBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(rewardAddress),
            stETHAsFee,
            "reward address balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesBefore,
            "bond manager after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee + 15 ether,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ amount: 1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee + 14 ether,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(14 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee + 2 ether,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee + 2 ether,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee + 1 ether,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(rewardAddress),
            stETHAsFee + 3 ether,
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithDesirableValue() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 stETHToClaim = stETH.getPooledEthByShares(sharesToClaim);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            0.05 ether,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(rewardAddress),
            stETHToClaim,
            "reward address balance should be equal to claimed"
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
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_WithZeroValue() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            0,
            leaf.shares,
            leaf.proof
        );
    }

    function test_ExcessBondWithoutProof() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            0,
            new bytes32[](0)
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares should be equal to before minus excess shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_SenderIsRewardAddress() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(rewardAddress);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(rewardAddress),
            stETHAsFee,
            "reward address balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesBefore,
            "bond manager after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_RevertWhen_SenderIsNotEligible() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(ICSAccounting.SenderIsNotEligible.selector)
        );
        vm.prank(stranger);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_RevertWhen_NodeOperatorDoesNotExist() public override {
        mock_getNodeOperatorManagementProperties(address(0), address(0), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICSAccounting.NodeOperatorDoesNotExist.selector
            )
        );
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(stETH.balanceOf(rewardAddress), stETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithCurveAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _deposit({ bond: 18 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(stETH.balanceOf(rewardAddress), stETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithLockedAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        _deposit({ bond: 34 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(stETH.balanceOf(rewardAddress), stETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithCurveAndLockedAndReserve()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        _deposit({ bond: 19 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(stETH.balanceOf(rewardAddress), stETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }
}

contract ClaimWstETHRewardsTest is ClaimRewardsBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee,
            1 wei,
            "reward address balance should be equal to fee reward"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETH.getWstETHByStETH(stETHAsFee + 15 ether),
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ amount: 1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETH.getWstETHByStETH(stETHAsFee + 14 ether),
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after curve minus locked"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(14 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve minus locked"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee + stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after one validator withdrawn"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee,
            1 wei,
            "reward address balance should be equal to fee reward"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee + stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "reward address balance should be equal to fee reward"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee + stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee + stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "reward address balance should be equal to fee reward plus excess bond after one validator withdrawn"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to bond shares after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to bond shares after"
        );
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithDesirableValue() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 wstETHToClaim = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesToClaim)
        );

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            sharesToClaim,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHToClaim,
            1 wei,
            "reward address balance should be equal to claimed"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - sharesToClaim,
            1 wei,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after should be equal to before and fee minus claimed shares"
        );
    }

    function test_WithZeroValue() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            0,
            leaf.shares,
            leaf.proof
        );
    }

    function test_ExcessBondWithoutProof() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            0,
            new bytes32[](0)
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares should be equal to before minus excess shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_SenderIsRewardAddress() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(rewardAddress);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(rewardAddress),
            wstETHAsFee,
            1 wei,
            "reward address balance should be equal to fee reward"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_RevertWhen_SenderIsNotEligible() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(ICSAccounting.SenderIsNotEligible.selector)
        );
        vm.prank(stranger);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_RevertWhen_NodeOperatorDoesNotExist() public override {
        mock_getNodeOperatorManagementProperties(address(0), address(0), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICSAccounting.NodeOperatorDoesNotExist.selector
            )
        );
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(wstETH.balanceOf(rewardAddress), wstETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithCurveAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _deposit({ bond: 18 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(wstETH.balanceOf(rewardAddress), wstETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithLockedAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        _deposit({ bond: 34 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(wstETH.balanceOf(rewardAddress), wstETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithCurveAndLockedAndReserve()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        _deposit({ bond: 19 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(wstETH.balanceOf(rewardAddress), wstETHAsFee, 1 wei);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }
}

contract ClaimRewardsUnstETHTest is ClaimRewardsBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should not change"
        );
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "bond shares should be changed after request minus excess bond after curve"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ amount: 1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(14 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after curve and locked"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithDesirableValue() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 sharesToRequest = stETH.getSharesByPooledEth(0.05 ether);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            0.05 ether,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee - sharesToRequest,
            1 wei,
            "bond shares should be equal to before plus fee shares minus requested shares"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "reward address shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithZeroValue() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            0,
            leaf.shares,
            leaf.proof
        );
    }

    function test_ExcessBondWithoutProof() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            0,
            new bytes32[](0)
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares should be equal to before minus excess shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_SenderIsRewardAddress() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(rewardAddress);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore,
            1 wei,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(rewardAddress),
            0,
            "rewardAddress shares should be 0"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should not change"
        );
    }

    function test_RevertWhen_SenderIsNotEligible() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(ICSAccounting.SenderIsNotEligible.selector)
        );
        vm.prank(stranger);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_RevertWhen_NodeOperatorDoesNotExist() public override {
        mock_getNodeOperatorManagementProperties(address(0), address(0), false);
        vm.expectRevert(
            abi.encodeWithSelector(
                ICSAccounting.NodeOperatorDoesNotExist.selector
            )
        );
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );
    }

    function test_WithReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether }); // 1 ether excess
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithCurveAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _deposit({ bond: 18 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithLockedAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        _deposit({ bond: 34 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }

    function test_WithCurveAndLockedAndReserve()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        _deposit({ bond: 19 ether });
        _rewards({ fee: 0.1 ether });

        (uint256 currentBefore, uint256 requiredBefore) = accounting
            .getBondSummary(0);
        uint256 bondClaimable = currentBefore - requiredBefore;
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.increaseBondReserve(0, bondClaimable);

        vm.prank(user);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            leaf.shares,
            leaf.proof
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);
        assertApproxEqAbs(bondSharesAfter, bondSharesBefore, 1 wei);
    }
}
