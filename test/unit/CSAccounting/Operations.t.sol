// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "./_Base.t.sol";

// Combined operational tests: asset recovery, fees, penalties, scenarios

contract AssetRecovererTest is BaseTest {
    address recoverer;

    function setUp() public override {
        super.setUp();

        recoverer = nextAddress("RECOVERER");

        vm.startPrank(admin);
        accounting.grantRole(accounting.RECOVERER_ROLE(), recoverer);
        vm.stopPrank();
    }

    function test_recovererRole() public {
        bytes32 role = accounting.RECOVERER_ROLE();
        vm.prank(admin);
        accounting.grantRole(role, address(1337));

        vm.prank(address(1337));
        accounting.recoverEther();
    }

    function test_recovererRole_RevertWhen_Unauthorized() public {
        expectRoleRevert(stranger, accounting.RECOVERER_ROLE());
        vm.prank(stranger);
        accounting.recoverEther();
    }

    function test_recoverEtherHappyPath() public assertInvariants {
        uint256 amount = 42 ether;
        vm.deal(address(accounting), amount);

        vm.expectEmit(address(accounting));
        emit IAssetRecovererLib.EtherRecovered(recoverer, amount);

        vm.prank(recoverer);
        accounting.recoverEther();

        assertEq(address(accounting).balance, 0);
        assertEq(address(recoverer).balance, amount);
    }

    function test_recoverERC20HappyPath() public assertInvariants {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(accounting), 1000);

        vm.prank(recoverer);
        vm.expectEmit(address(accounting));
        emit IAssetRecovererLib.ERC20Recovered(address(token), recoverer, 1000);
        accounting.recoverERC20(address(token), 1000);

        assertEq(token.balanceOf(address(accounting)), 0);
        assertEq(token.balanceOf(recoverer), 1000);
    }

    function test_recoverERC20_RevertWhen_Unauthorized() public {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(accounting), 1000);

        expectRoleRevert(stranger, accounting.RECOVERER_ROLE());
        vm.prank(stranger);
        accounting.recoverERC20(address(token), 1000);
    }

    function test_recoverERC20_RevertWhen_StETH() public {
        vm.prank(recoverer);
        vm.expectRevert(IAssetRecovererLib.NotAllowedToRecover.selector);
        accounting.recoverERC20(address(stETH), 1000);
    }

    function test_recoverStETHShares() public assertInvariants {
        mock_getNodeOperatorsCount(1);

        vm.deal(address(stakingModule), 2 ether);
        vm.startPrank(address(stakingModule));
        stETH.submit{ value: 2 ether }(address(0));
        accounting.depositStETH(
            address(stakingModule),
            0,
            1 ether,
            ICSAccounting.PermitInput({
                value: 1 ether,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
        vm.stopPrank();

        uint256 sharesBefore = stETH.sharesOf(address(accounting));
        uint256 sharesToRecover = stETH.getSharesByPooledEth(0.3 ether);
        stETH.mintShares(address(accounting), sharesToRecover);

        vm.prank(recoverer);
        vm.expectEmit(address(accounting));
        emit IAssetRecovererLib.StETHSharesRecovered(
            recoverer,
            sharesToRecover
        );
        accounting.recoverStETHShares();

        assertEq(stETH.sharesOf(address(accounting)), sharesBefore);
        assertEq(stETH.sharesOf(recoverer), sharesToRecover);
    }

    function test_recoverStETHShares_RevertWhen_Unauthorized() public {
        expectRoleRevert(stranger, accounting.RECOVERER_ROLE());
        vm.prank(stranger);
        accounting.recoverStETHShares();
    }
}

contract ChargeFeeTest is BaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_chargeFee() public assertInvariants {
        uint256 bond = accounting.getBond(0);
        uint256 amountToCharge = bond / 2; // charge half of the bond
        uint256 shares = stETH.getSharesByPooledEth(amountToCharge);
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(address(stakingModule));
        bool fullyCharged = accounting.chargeFee(0, amountToCharge);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
        assertTrue(fullyCharged, "should be fully charged");
    }

    function test_chargeFee_onInsufficientBond() public assertInvariants {
        uint256 bond = accounting.getBond(0);
        uint256 amountToCharge = bond + 1 ether; // charge more than bond

        vm.prank(address(stakingModule));
        bool fullyCharged = accounting.chargeFee(0, amountToCharge);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            0,
            "bond shares should be zero after charging more than bond"
        );
        assertEq(
            accounting.totalBondShares(),
            0,
            "total bond shares should be zero"
        );
        assertFalse(fullyCharged, "should no be fully charged");
    }

    function test_chargeFee_RevertWhen_SenderIsNotModule() public {
        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        vm.prank(stranger);
        accounting.chargeFee(0, 20);
    }
}

contract FeeSplitsTest is BaseTest {
    function test_setFeeSplits() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: address(2),
            share: 5000
        });
        mock_getNodeOperatorOwner(user);

        vm.expectEmit(address(accounting));
        emit IFeeSplits.FeeSplitsSet(0, splits);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        ICSAccounting.FeeSplit[] memory actual = accounting.getFeeSplits(0);
        assertEq(actual.length, splits.length);
        for (uint256 i = 0; i < splits.length; i++) {
            assertEq(actual[i].recipient, splits[i].recipient);
            assertEq(actual[i].share, splits[i].share);
        }
    }

    function test_setFeeSplits_ZeroLength() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            0
        );
        mock_getNodeOperatorOwner(user);

        vm.expectEmit(address(accounting));
        emit IFeeSplits.FeeSplitsSet(0, splits);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        ICSAccounting.FeeSplit[] memory actual = accounting.getFeeSplits(0);
        assertEq(actual.length, 0);
    }

    function test_setFeeSplits_revertWhen_SenderIsNotEligible() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: address(2),
            share: 5000
        });
        mock_getNodeOperatorOwner(user);

        vm.expectRevert(ICSAccounting.SenderIsNotEligible.selector);
        vm.prank(stranger);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);
    }

    function test_setFeeSplits_revertWhen_TooManySplits() public {
        uint256 length = FeeSplits.MAX_FEE_SPLITS + 1;
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            length
        );
        for (uint256 i = 0; i < splits.length; i++) {
            splits[i].recipient = nextAddress();
            splits[i].share = 1000;
        }
        mock_getNodeOperatorOwner(user);

        vm.expectRevert(IFeeSplits.TooManySplits.selector);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);
    }

    function test_setFeeSplits_revertWhen_TooManySplitShares() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: address(2),
            share: 8000
        });
        mock_getNodeOperatorOwner(user);

        vm.expectRevert(IFeeSplits.TooManySplitShares.selector);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);
    }

    function test_setFeeSplits_revertWhen_ZeroSplitRecipient() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: address(0),
            share: 5000
        });
        mock_getNodeOperatorOwner(user);

        vm.expectRevert(IFeeSplits.ZeroSplitRecipient.selector);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);
    }

    function test_setFeeSplits_revertWhen_ZeroSplitShare() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({ recipient: address(2), share: 0 });
        mock_getNodeOperatorOwner(user);

        vm.expectRevert(IFeeSplits.ZeroSplitShare.selector);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);
    }

    function test_setFeeSplits_revertWhen_PendingOrUndistributedSharesExist_withPendingShares()
        public
    {
        ICSAccounting.FeeSplit[]
            memory initialSplits = new ICSAccounting.FeeSplit[](1);
        initialSplits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 5000
        });
        mock_getNodeOperatorOwner(user);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), initialSplits);

        uint256 feeShares = 1 ether;
        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);
        // Have some non-withdrawn keys that requires claimable shares to be > 0
        mock_getNodeOperatorNonWithdrawnKeys(1);

        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        // Now try to set new splits - should fail due to pending shares
        ICSAccounting.FeeSplit[]
            memory newSplits = new ICSAccounting.FeeSplit[](1);
        newSplits[0] = ICSAccounting.FeeSplit({
            recipient: address(2),
            share: 3000
        });

        vm.expectRevert(IFeeSplits.PendingOrUndistributedSharesExist.selector);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), newSplits);
    }

    function test_setFeeSplits_revertWhen_PendingOrUndistributedSharesExist_withUndistributedFees()
        public
    {
        uint256 feeShares = 1 ether;
        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorOwner(user);

        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            1
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 5000
        });

        vm.expectRevert(IFeeSplits.PendingOrUndistributedSharesExist.selector);
        vm.prank(user);
        accounting.setFeeSplits(0, feeShares, new bytes32[](0), splits);
    }

    function test_setFeeSplits_updateExistingSplits() public {
        ICSAccounting.FeeSplit[]
            memory initialSplits = new ICSAccounting.FeeSplit[](2);
        initialSplits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 3000
        });
        initialSplits[1] = ICSAccounting.FeeSplit({
            recipient: address(2),
            share: 2000
        });
        mock_getNodeOperatorOwner(user);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), initialSplits);

        ICSAccounting.FeeSplit[] memory current = accounting.getFeeSplits(0);
        assertEq(current.length, 2);
        assertEq(current[0].recipient, address(1));
        assertEq(current[0].share, 3000);

        ICSAccounting.FeeSplit[]
            memory newSplits = new ICSAccounting.FeeSplit[](1);
        newSplits[0] = ICSAccounting.FeeSplit({
            recipient: address(3),
            share: 4000
        });

        vm.expectEmit(address(accounting));
        emit IFeeSplits.FeeSplitsSet(0, newSplits);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), newSplits);

        ICSAccounting.FeeSplit[] memory updated = accounting.getFeeSplits(0);
        assertEq(updated.length, 1);
        assertEq(updated[0].recipient, address(3));
        assertEq(updated[0].share, 4000);
    }

    function test_setFeeSplits_maxTotalShare() public {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: address(1),
            share: 6000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: address(2),
            share: 4000
        });
        mock_getNodeOperatorOwner(user);

        vm.expectEmit(address(accounting));
        emit IFeeSplits.FeeSplitsSet(0, splits);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        ICSAccounting.FeeSplit[] memory actual = accounting.getFeeSplits(0);
        assertEq(actual.length, 2);
        assertEq(actual[0].share + actual[1].share, 10000);
    }
}

contract MiscTest is BaseTest {
    function test_getInitializedVersion() public view {
        assertEq(accounting.getInitializedVersion(), 3);
    }

    function test_totalBondShares() public assertInvariants {
        mock_getNodeOperatorsCount(2);
        vm.deal(address(stakingModule), 64 ether);
        vm.startPrank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);
        accounting.depositETH{ value: 32 ether }(user, 1);
        vm.stopPrank();
        uint256 totalDepositedShares = stETH.getSharesByPooledEth(32 ether) +
            stETH.getSharesByPooledEth(32 ether);
        assertEq(accounting.totalBondShares(), totalDepositedShares);
    }

    function test_setChargePenaltyRecipient() public {
        vm.prank(admin);
        vm.expectEmit(address(accounting));
        emit ICSAccounting.ChargePenaltyRecipientSet(address(1337));
        accounting.setChargePenaltyRecipient(address(1337));
        assertEq(accounting.chargePenaltyRecipient(), address(1337));
    }

    function test_setChargePenaltyRecipient_RevertWhen_DoesNotHaveRole()
        public
    {
        expectRoleRevert(stranger, accounting.DEFAULT_ADMIN_ROLE());
        vm.prank(stranger);
        accounting.setChargePenaltyRecipient(address(1337));
    }

    function test_setChargePenaltyRecipient_RevertWhen_Zero() public {
        vm.expectRevert();
        vm.prank(admin);
        accounting.setChargePenaltyRecipient(address(0));
    }

    function test_setBondLockPeriod() public assertInvariants {
        uint256 period = accounting.MIN_BOND_LOCK_PERIOD() + 1;
        vm.prank(admin);
        accounting.setBondLockPeriod(period);
        uint256 actual = accounting.getBondLockPeriod();
        assertEq(actual, period);
    }

    function test_renewBurnerAllowance() public assertInvariants {
        vm.prank(address(accounting));
        stETH.approve(address(burner), 0);

        assertEq(stETH.allowance(address(accounting), address(burner)), 0);

        accounting.renewBurnerAllowance();

        assertEq(
            stETH.allowance(address(accounting), address(burner)),
            type(uint256).max
        );
    }
}

contract NegativeRebaseTest is BaseTest {
    function test_negativeRebase_ValidatorBecomeUnbonded() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });

        // Record the initial ETH/share ratio
        uint256 totalPooledEtherBefore = stETH.totalPooledEther();
        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 bondETHBefore = accounting.getBond(0);

        // Simulate negative rebase: reduce totalPooledEther by 1%
        uint256 rebaseLoss = totalPooledEtherBefore / 100;
        vm.store(
            address(stETH),
            bytes32(uint256(0)), // totalPooledEther storage slot
            bytes32(totalPooledEtherBefore - rebaseLoss)
        );

        // Bond shares remain the same, but ETH value decreased
        assertEq(
            accounting.getBondShares(0),
            bondSharesBefore,
            "Bond shares should remain unchanged"
        );
        uint256 bondETHAfter = accounting.getBond(0);
        assertLt(
            bondETHAfter,
            bondETHBefore,
            "Bond ETH value should decrease after negative rebase"
        );

        // After 1% loss, 32 ETH becomes ~31.68 ETH, which covers 15 validators
        uint256 unbondedKeysAfter = accounting.getUnbondedKeysCountToEject(0);
        assertEq(
            unbondedKeysAfter,
            1,
            "Should have 1 unbonded validator after 1% negative rebase"
        );
    }

    function test_negativeRebase_SomeValidatorsBecomeUnbonded() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });

        // Simulate negative rebase: reduce totalPooledEther by 20%
        uint256 totalPooledEtherBefore = stETH.totalPooledEther();
        uint256 rebaseLoss = (totalPooledEtherBefore * 20) / 100;
        vm.store(
            address(stETH),
            bytes32(uint256(0)), // totalPooledEther storage slot
            bytes32(totalPooledEtherBefore - rebaseLoss)
        );

        // After 20% loss, 32 ETH becomes ~25.6 ETH, which covers only 12 validators
        uint256 unbondedKeysAfter = accounting.getUnbondedKeysCountToEject(0);
        assertEq(
            unbondedKeysAfter,
            4,
            "Should have 4 unbonded validators after 20% negative rebase"
        );
    }
}

contract PenalizeTest is BaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_penalize() public assertInvariants {
        uint256 bond = accounting.getBond(0);
        uint256 amountToBurn = bond / 2; // burn half of the bond
        uint256 shares = stETH.getSharesByPooledEth(amountToBurn);
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(accounting),
                shares
            )
        );

        vm.prank(address(stakingModule));
        bool fullyBurned = accounting.penalize(0, amountToBurn);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
        assertTrue(fullyBurned, "should be fully burned");
    }

    function test_penalize_onInsufficientBondWithLock()
        public
        assertInvariants
    {
        uint256 bond = accounting.getBond(0);
        uint256 bondShares = accounting.getBondShares(0);
        uint256 amountToBurn = bond + 1 ether; // burn more than bond

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether); // lock some bond
        uint256 bondLockBefore = accounting.getActualLockedBond(0);

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(accounting),
                bondShares
            )
        );

        vm.prank(address(stakingModule));
        bool fullyBurned = accounting.penalize(0, amountToBurn);
        uint256 bondSharesAfter = accounting.getBondShares(0);
        CSAccounting.BondLock memory bondLockAfter = accounting
            .getLockedBondInfo(0);

        assertEq(
            bondSharesAfter,
            0,
            "bond shares should be zero after burning more than bond"
        );
        assertEq(
            accounting.totalBondShares(),
            0,
            "total bond shares should be zero"
        );
        assertApproxEqAbs(bondLockAfter.amount, bondLockBefore + 1 ether, 1);
        assertEq(bondLockAfter.until, type(uint128).max);
        assertFalse(fullyBurned, "should no be fully burned");
    }

    function test_penalize_RevertWhen_SenderIsNotModule() public {
        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        vm.prank(stranger);
        accounting.penalize(0, 20);
    }

    function test_penalize_unburnedAmount_noExistingLock_createsInfiniteLock()
        public
        assertInvariants
    {
        uint256 bondBefore = accounting.getBond(0);
        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 amountToBurn = bondBefore + 1 ether;

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(accounting),
                bondSharesBefore
            )
        );

        vm.prank(address(stakingModule));
        bool fullyBurned = accounting.penalize(0, amountToBurn);

        CSAccounting.BondLock memory lockAfter = accounting.getLockedBondInfo(
            0
        );
        assertApproxEqAbs(lockAfter.amount, amountToBurn - bondBefore, 1);
        assertEq(lockAfter.until, type(uint128).max);
        assertFalse(fullyBurned);
    }

    function test_penalize_unburnedAmount_expiredLock_notAdded()
        public
        assertInvariants
    {
        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);
        CSAccounting.BondLock memory lockBefore = accounting.getLockedBondInfo(
            0
        );
        assertEq(accounting.getActualLockedBond(0), 1 ether);

        vm.warp(lockBefore.until);
        assertEq(accounting.getActualLockedBond(0), 0);

        uint256 bondBefore = accounting.getBond(0);
        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 amountToBurn = bondBefore + 1 ether;

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(accounting),
                bondSharesBefore
            )
        );

        vm.prank(address(stakingModule));
        accounting.penalize(0, amountToBurn);

        CSAccounting.BondLock memory lockAfter = accounting.getLockedBondInfo(
            0
        );
        assertApproxEqAbs(lockAfter.amount, amountToBurn - bondBefore, 1);
        assertEq(lockAfter.until, type(uint128).max);
    }

    function test_penalize_fullyBurned_keepsExistingLock()
        public
        assertInvariants
    {
        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 2 ether);
        CSAccounting.BondLock memory lockBefore = accounting.getLockedBondInfo(
            0
        );
        assertEq(accounting.getActualLockedBond(0), 2 ether);

        uint256 amountToBurn = accounting.getBond(0) / 2;

        vm.prank(address(stakingModule));
        bool fullyBurned = accounting.penalize(0, amountToBurn);
        CSAccounting.BondLock memory lockAfter = accounting.getLockedBondInfo(
            0
        );

        assertTrue(fullyBurned);
        assertEq(lockAfter.amount, lockBefore.amount);
        assertEq(lockAfter.until, lockBefore.until);
    }
}

contract PullFeeRewardsTest is BaseTest {
    function test_pullFeeRewards() public assertInvariants {
        uint256 feeShares = 1 ether;
        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore + feeShares);
        assertEq(totalBondSharesAfter, totalBondSharesBefore + feeShares);
    }

    function test_pullFeeRewards_zeroAmount() public assertInvariants {
        mock_getNodeOperatorsCount(1);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        accounting.pullFeeRewards(0, 0, new bytes32[](0));

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore);
        assertEq(totalBondSharesAfter, totalBondSharesBefore);
    }

    function test_pullFeeRewards_revertWhen_operatorDoesNotExits() public {
        mock_getNodeOperatorsCount(0);

        vm.expectRevert(ICSAccounting.NodeOperatorDoesNotExist.selector);
        accounting.pullFeeRewards(0, 0, new bytes32[](0));
    }

    function test_pullFeeRewards_withSplits() public assertInvariants {
        uint256 feeShares = 10 ether;

        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 5000
        });

        uint256[] memory sharesBefore = new uint256[](splits.length);
        for (uint8 i = 0; i < splits.length; i++) {
            sharesBefore[i] = stETH.sharesOf(splits[i].recipient);
        }

        mock_getNodeOperatorOwner(user);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        feeShares -= 8 ether; // remaining shares after splits

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore + feeShares);
        assertEq(totalBondSharesAfter, totalBondSharesBefore + feeShares);

        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore[0] + 3 ether,
            "fee split shares mismatch"
        );
        assertEq(
            stETH.sharesOf(splits[1].recipient),
            sharesBefore[1] + 5 ether,
            "fee split shares mismatch"
        );
    }

    function test_pullFeeRewards_withSplits_lowFeeAmount()
        public
        assertInvariants
    {
        uint256 feeShares = 3 wei;

        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 100
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 500
        });

        uint256[] memory sharesBefore = new uint256[](splits.length);
        for (uint8 i = 0; i < splits.length; i++) {
            sharesBefore[i] = stETH.sharesOf(splits[i].recipient);
        }

        mock_getNodeOperatorOwner(user);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore + feeShares);
        assertEq(totalBondSharesAfter, totalBondSharesBefore + feeShares);

        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore[0],
            "fee split shares mismatch"
        );
        assertEq(
            stETH.sharesOf(splits[1].recipient),
            sharesBefore[1],
            "fee split shares mismatch"
        );
    }

    function test_pullFeeRewards_withSplits_allBPSUsed_noReminderDueToRounding()
        public
        assertInvariants
    {
        uint256 feeShares = 1 ether;

        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 7000
        });

        uint256[] memory sharesBefore = new uint256[](splits.length);
        for (uint8 i = 0; i < splits.length; i++) {
            sharesBefore[i] = stETH.sharesOf(splits[i].recipient);
        }

        mock_getNodeOperatorOwner(user);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore);
        assertEq(totalBondSharesAfter, totalBondSharesBefore);

        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore[0] + 0.3 ether,
            "fee split shares mismatch"
        );
        assertEq(
            stETH.sharesOf(splits[1].recipient),
            sharesBefore[1] + 0.7 ether,
            "fee split shares mismatch"
        );
    }

    function test_pullFeeRewards_withSplits_ZeroFeeAmount()
        public
        assertInvariants
    {
        uint256 feeShares = 0;

        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 100
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 500
        });

        uint256[] memory sharesBefore = new uint256[](splits.length);
        for (uint8 i = 0; i < splits.length; i++) {
            sharesBefore[i] = stETH.sharesOf(splits[i].recipient);
        }

        mock_getNodeOperatorOwner(user);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore + feeShares);
        assertEq(totalBondSharesAfter, totalBondSharesBefore + feeShares);

        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore[0],
            "fee split shares mismatch"
        );
        assertEq(
            stETH.sharesOf(splits[1].recipient),
            sharesBefore[1],
            "fee split shares mismatch"
        );
    }

    function testFuzz_pullFeeRewards_withSplits(
        uint256 feeShares,
        uint8 splitsCount,
        uint256 shareSeed
    ) public assertInvariants {
        splitsCount = uint8(bound(splitsCount, 1, FeeSplits.MAX_FEE_SPLITS));
        feeShares = bound(feeShares, 0, 10 ether);

        uint256[] memory fees = new uint256[](splitsCount);
        uint256 totalFeeSharesForSplits;

        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            splitsCount
        );
        uint256 totalShare;
        for (uint8 i = 0; i < splitsCount; i++) {
            splits[i].recipient = nextAddress();
            uint256 remainingShare = 10_000 - totalShare;
            if (i == splitsCount - 1) {
                splits[i].share = remainingShare;
            } else {
                uint256 reserveForOthers = splitsCount - i - 1; // at least 1 share for remaining splits
                uint256 maxPossible = remainingShare - reserveForOthers;
                splits[i].share = ((shareSeed / (i + 1)) % maxPossible) + 1; // at least 1 share per split
            }
            totalShare += splits[i].share;
            fees[i] = (feeShares * splits[i].share) / 10_000;
            totalFeeSharesForSplits += fees[i];
        }

        uint256[] memory sharesBefore = new uint256[](splitsCount);

        for (uint8 i = 0; i < splitsCount; i++) {
            sharesBefore[i] = stETH.sharesOf(splits[i].recipient);
        }

        mock_getNodeOperatorOwner(user);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 totalBondSharesBefore = accounting.totalBondShares();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        feeShares -= totalFeeSharesForSplits; // remaining shares after splits

        uint256 bondSharesAfter = accounting.getBondShares(0);
        uint256 totalBondSharesAfter = accounting.totalBondShares();

        assertEq(bondSharesAfter, bondSharesBefore + feeShares);
        assertEq(totalBondSharesAfter, totalBondSharesBefore + feeShares);

        for (uint8 i = 0; i < splitsCount; i++) {
            assertEq(
                stETH.sharesOf(splits[i].recipient),
                sharesBefore[i] + fees[i],
                "fee split shares mismatch"
            );
        }
    }

    function test_pullFeeRewards_withSplits_claimableLessThanPending()
        public
        assertInvariants
    {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 5000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 3000
        });
        mock_getNodeOperatorOwner(user);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        uint256 feeShares = 2 ether;
        stETH.mintShares(address(feeDistributor), feeShares);
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(1);

        (, uint256 requiredShares) = accounting.getBondSummaryShares(0);
        assertGt(requiredShares, 0);
        assertLt(requiredShares, feeShares);

        uint256 expectedClaimableAfterPull = feeShares - requiredShares;

        uint256 pendingBefore = accounting.getPendingSharesToSplit(0);
        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));
        uint256 pendingAfter = accounting.getPendingSharesToSplit(0);

        uint256 expectedPendingIncrease = feeShares;
        uint256 expectedPendingDecrease = expectedClaimableAfterPull;
        uint256 expectedPendingAfter = pendingBefore +
            expectedPendingIncrease -
            expectedPendingDecrease;
        assertEq(pendingAfter, expectedPendingAfter);

        uint256 expectedSplit0 = (expectedClaimableAfterPull * 5000) / 10000;
        uint256 expectedSplit1 = (expectedClaimableAfterPull * 3000) / 10000;

        assertEq(stETH.sharesOf(splits[0].recipient), expectedSplit0);
        assertEq(stETH.sharesOf(splits[1].recipient), expectedSplit1);
    }

    function test_pullFeeRewards_withSplits_multipleCallsAccumulatePending()
        public
        assertInvariants
    {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            1
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 5000
        });
        mock_getNodeOperatorOwner(user);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(100500); // Required significantly more than we will pull

        // First pull with less than required - should be limited by claimable
        uint256 firstFeeShares = 0.5 ether;
        stETH.mintShares(address(feeDistributor), firstFeeShares);
        accounting.pullFeeRewards(0, firstFeeShares, new bytes32[](0));

        // Multiple small pulls to accumulate pending
        uint256 secondFeeShares = 0.1 ether;
        for (uint256 i = 0; i < 5; i++) {
            stETH.mintShares(address(feeDistributor), secondFeeShares);
            accounting.pullFeeRewards(0, secondFeeShares, new bytes32[](0));
        }

        mock_getNodeOperatorNonWithdrawnKeys(0); // Now claimable >= pending

        // One more pull should process accumulated pending
        stETH.mintShares(address(feeDistributor), secondFeeShares);
        accounting.pullFeeRewards(0, secondFeeShares, new bytes32[](0));

        uint256 expectedTransferred = (firstFeeShares +
            (5 * secondFeeShares) +
            secondFeeShares) / 2;

        uint256 recipientSharesAfter = stETH.sharesOf(splits[0].recipient);
        assertEq(recipientSharesAfter, expectedTransferred, "recipient shares");

        uint256 claimableAfter = accounting.getClaimableBondShares(0);
        assertEq(claimableAfter, expectedTransferred, "claimable mismatch");

        uint256 pendingAfter = accounting.getPendingSharesToSplit(0);
        assertEq(pendingAfter, 0);
    }

    function test_pullFeeRewards_withSplits_zeroClaimableShares()
        public
        assertInvariants
    {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            1
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 5000
        });
        mock_getNodeOperatorOwner(user);
        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(100500); // Required significantly more than we will pull

        uint256 feeShares = 1 ether;
        stETH.mintShares(address(feeDistributor), feeShares);

        uint256 sharesBefore = stETH.sharesOf(splits[0].recipient);
        uint256 bondSharesBefore = accounting.getBondShares(0);

        accounting.pullFeeRewards(0, feeShares, new bytes32[](0));

        assertEq(stETH.sharesOf(splits[0].recipient), sharesBefore);
        assertEq(accounting.getBondShares(0), bondSharesBefore);
        assertEq(accounting.getPendingSharesToSplit(0), feeShares);
    }
}

contract ClaimRewardsWithFeeSplitsTest is BaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        // Setup some bond to make claims possible
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_claimRewardsStETH_withFeeSplits() public assertInvariants {
        // Setup fee splits
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            2
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 3000
        });
        splits[1] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 2000
        });

        mock_getNodeOperatorOwner(user);
        mock_getNodeOperatorManagementProperties(user, user, false);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        // Setup fee rewards
        uint256 feeShares = 1 ether;
        stETH.mintShares(address(feeDistributor), feeShares);

        uint256[] memory sharesBefore = new uint256[](2);
        sharesBefore[0] = stETH.sharesOf(splits[0].recipient);
        sharesBefore[1] = stETH.sharesOf(splits[1].recipient);

        uint256 userBalanceBefore = stETH.balanceOf(user);

        // Claim rewards with fee splits
        vm.prank(user);
        uint256 claimedShares = accounting.claimRewardsStETH(
            0,
            0.5 ether,
            feeShares,
            new bytes32[](1)
        );

        // Verify fee splits were processed
        uint256 expectedSplit0 = (feeShares * 3000) / 10000;
        uint256 expectedSplit1 = (feeShares * 2000) / 10000;

        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore[0] + expectedSplit0
        );
        assertEq(
            stETH.sharesOf(splits[1].recipient),
            sharesBefore[1] + expectedSplit1
        );

        // Verify user got their claim
        assertGt(stETH.balanceOf(user), userBalanceBefore);
        assertGt(claimedShares, 0);
    }

    function test_claimRewardsWstETH_withFeeSplits() public assertInvariants {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            1
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 4000
        });

        mock_getNodeOperatorOwner(user);
        mock_getNodeOperatorManagementProperties(user, user, false);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        uint256 feeShares = 0.8 ether;
        stETH.mintShares(address(feeDistributor), feeShares);

        uint256 sharesBefore = stETH.sharesOf(splits[0].recipient);
        uint256 userWstBalanceBefore = wstETH.balanceOf(user);

        vm.prank(user);
        uint256 claimedWstETH = accounting.claimRewardsWstETH(
            0,
            0.3 ether,
            feeShares,
            new bytes32[](1)
        );

        uint256 expectedSplit = (feeShares * 4000) / 10000;
        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore + expectedSplit
        );

        assertGt(wstETH.balanceOf(user), userWstBalanceBefore);
        assertGt(claimedWstETH, 0);
    }

    function test_claimRewardsUnstETH_withFeeSplits() public assertInvariants {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            1
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 6000
        });

        mock_getNodeOperatorOwner(user);
        mock_getNodeOperatorManagementProperties(user, user, false);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        uint256 feeShares = 1.2 ether;
        stETH.mintShares(address(feeDistributor), feeShares);

        uint256 sharesBefore = stETH.sharesOf(splits[0].recipient);

        vm.prank(user);
        uint256 requestId = accounting.claimRewardsUnstETH(
            0,
            0.4 ether,
            feeShares,
            new bytes32[](1)
        );

        uint256 expectedSplit = (feeShares * 6000) / 10000;
        assertEq(
            stETH.sharesOf(splits[0].recipient),
            sharesBefore + expectedSplit
        );
    }

    function test_claimRewards_withEmptyProofButSplits()
        public
        assertInvariants
    {
        ICSAccounting.FeeSplit[] memory splits = new ICSAccounting.FeeSplit[](
            1
        );
        splits[0] = ICSAccounting.FeeSplit({
            recipient: nextAddress(),
            share: 5000
        });

        mock_getNodeOperatorOwner(user);
        mock_getNodeOperatorManagementProperties(user, user, false);

        vm.prank(user);
        accounting.setFeeSplits(0, 0, new bytes32[](0), splits);

        uint256 sharesBefore = stETH.sharesOf(splits[0].recipient);
        uint256 userBalanceBefore = stETH.balanceOf(user);

        // Claim with empty proof - should not process fee splits
        vm.prank(user);
        uint256 claimedShares = accounting.claimRewardsStETH(
            0,
            0.5 ether,
            0,
            new bytes32[](0)
        );

        // No rewards fee splits should have been processed
        assertEq(stETH.sharesOf(splits[0].recipient), sharesBefore);

        // But user should still get their claim
        assertGt(stETH.balanceOf(user), userBalanceBefore);
        assertGt(claimedShares, 0);
    }
}

contract ScenarioTest is BaseTest {
    function test_scenario_lock_curve_withdraw_reserve_settle()
        public
        assertInvariants
    {
        // 1) Initial operator with 16 ongoing, 0 withdrawn
        _operator({ ongoing: 16, withdrawn: 0 });

        // Required: 32 ether
        (uint256 curr0, uint256 req0) = accounting.getBondSummary(0);
        assertEq(curr0, 0);
        assertEq(req0, 32 ether);

        // 2) Deposit 40 ether bond, we have 8 ether excess claimable
        _deposit({ bond: 40 ether });
        (uint256 curr1, uint256 req1) = accounting.getBondSummary(0);
        assertApproxEqAbs(curr1, ethToSharesToEth(40 ether), 1);
        assertEq(req1, 32 ether);

        // 3) Apply a lock of 3 ether
        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 3 ether);
        (, uint256 req2) = accounting.getBondSummary(0);
        // required grows by locked amount
        assertEq(req2, 35 ether);

        // 4) Change curve to discounted: for 16 keys = 17 ether
        {
            ICSBondCurve.BondCurveIntervalInput[]
                memory curve = new ICSBondCurve.BondCurveIntervalInput[](2);
            curve[0] = ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: 1,
                trend: 2 ether
            });
            curve[1] = ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: 2,
                trend: 1 ether
            });
            vm.startPrank(admin);
            uint256 curveId = accounting.addBondCurve(curve);
            accounting.setBondCurve(0, curveId);
            vm.stopPrank();
        }
        (, uint256 req3) = accounting.getBondSummary(0);
        // lock is kept
        assertEq(req3, 20 ether);

        // 5) Withdraw 2 validators => non-withdrawn becomes 14, curve(14)=15 ether
        mock_getNodeOperatorNonWithdrawnKeys(14);
        (uint256 curr4, uint256 req4) = accounting.getBondSummary(0);
        // required: 15 + 3 locked = 18 ether
        assertEq(req4, 18 ether);

        // 6) Create reserve from current claimable (must be > 0)
        uint256 claimable = curr4 > req4 ? curr4 - req4 : 0;
        assertGt(claimable, 0);
        mock_getNodeOperatorManagementProperties(user, user, false);

        uint256 claimablePortion = claimable / 3;
        vm.prank(user);
        accounting.increaseBondReserve(0, claimablePortion);

        (uint256 curr5, uint256 req5) = accounting.getBondSummary(0);
        // current stays the same, required increases by reserve amount
        assertApproxEqAbs(curr5, curr4, 1);
        assertEq(req5, req4 + claimablePortion);

        vm.prank(user);
        accounting.increaseBondReserve(0, claimable);
        (curr5, req5) = accounting.getBondSummary(0);
        assertApproxEqAbs(curr5, curr4, 1);
        assertEq(req5, req4 + claimable);
        assertEq(accounting.getBondReserveInfo(0).amount, claimable);

        // 7) Check unbonded counts reflect reserve+lock when included
        uint256 unbondedAll = accounting.getUnbondedKeysCount(0); // include locked+reserve
        uint256 unbondedToEject = accounting.getUnbondedKeysCountToEject(0); // exclude locked
        // Since current >= required, all unbonded should be zero
        assertEq(unbondedAll, 0);
        assertEq(unbondedToEject, 0);

        // 7.a) Increase active keys to 15. With reserve excluded from coverage, we expect unbonded (include locked)
        _operator({ ongoing: 15, withdrawn: 0 });
        // include locked+reserve -> available = 15 ETH -> covers 14 keys -> 1 unbonded
        assertEq(accounting.getUnbondedKeysCount(0), 1);
        // exclude locked -> available = 18 ETH -> covers >=15 keys -> 0 unbonded
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);

        // 7.b) Penalize a small amount. Reserve should be untouched
        vm.prank(address(stakingModule));
        accounting.penalize(0, 1 ether);
        // after 1 ETH penalty: include locked -> available = 14 ETH -> covers 13 -> 2 unbonded
        assertEq(accounting.getUnbondedKeysCount(0), 2);
        // exclude locked -> available = 17 ETH -> covers >=15 -> 0 unbonded
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
        assertEq(accounting.getBondReserveInfo(0).amount, claimable);

        // 7.c) Penalize more than the reserve
        IBondReserve.BondReserveInfo memory rinfo = accounting
            .getBondReserveInfo(0);
        vm.prank(address(stakingModule));
        accounting.penalize(0, uint256(rinfo.amount) + 1 ether);
        // Reserve should now equal the (post-penalty) current bond
        rinfo = accounting.getBondReserveInfo(0);
        uint256 currentAfterPenalty = accounting.getBond(0);
        assertEq(uint256(rinfo.amount), currentAfterPenalty);
        // reserve equals current, available after excluding reserve is 0 -> 15 unbonded in both modes
        assertEq(accounting.getUnbondedKeysCount(0), 15);
        assertEq(accounting.getUnbondedKeysCountToEject(0), 15);

        // 8) Settle lock
        vm.prank(address(stakingModule));
        bool applied = accounting.settleLockedBondETH(0);
        assertTrue(applied);

        (uint256 curr6, uint256 req6) = accounting.getBondSummary(0);
        uint256 reserve6 = accounting.getBondReserveInfo(0).amount;

        assertApproxEqAbs(req6 - reserve6, 16 ether, 1);
        assertEq(reserve6, curr6);
        // after settling lock, locked=0 but available excluding reserve is still 0 -> 15 unbonded
        assertEq(accounting.getUnbondedKeysCount(0), 15);
        assertEq(accounting.getUnbondedKeysCountToEject(0), 15);

        // 9) Remove reserve after min period; unbonded decreases
        vm.warp(block.timestamp + 4 weeks + 1 seconds);
        vm.prank(user);
        accounting.removeBondReserve(0);
        assertEq(accounting.getBondReserveInfo(0).amount, 0);
        // With no reserve and no lock, available bond ~= 13 ETH -> covers 12 keys -> 3 unbonded
        assertEq(accounting.getUnbondedKeysCount(0), 3);
        assertEq(accounting.getUnbondedKeysCountToEject(0), 3);
    }
}
