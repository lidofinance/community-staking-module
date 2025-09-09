// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "./_Base.t.sol";

// Combined bond reserve tests: disabled, increase, remove, reconcile

contract BondReserveDisabledTest is Test, Fixtures, Utilities {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    CSAccounting public accounting;
    Stub public stakingModule;
    DistributorMock public feeDistributor;

    address internal admin;
    address internal testChargePenaltyRecipient;

    function setUp() public {
        admin = nextAddress("ADMIN");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, , ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new DistributorMock(address(stETH));

        // Deploy with bond reserve feature disabled
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            address(feeDistributor),
            4 weeks,
            365 days,
            false
        );

        feeDistributor.setAccounting(address(accounting));

        // Initialize implementation for tests
        _enableInitializers(address(accounting));

        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        accounting.initialize(
            curve,
            admin,
            8 weeks,
            4 weeks,
            testChargePenaltyRecipient
        );
    }

    function test_increaseBondReserve_RevertWhen_FeatureDisabled() public {
        vm.expectRevert(ICSAccounting.BondReserveFeatureDisabled.selector);
        accounting.increaseBondReserve(0, 1 ether);
    }

    function test_removeBondReserve_RevertWhen_FeatureDisabled() public {
        vm.expectRevert(ICSAccounting.BondReserveFeatureDisabled.selector);
        accounting.removeBondReserve(0);
    }
}

contract IncreaseBondReserve is BaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorManagementProperties(user, user, false);
    }

    function test_increaseBondReserve_SetExactClaimable() public {
        mock_getNodeOperatorNonWithdrawnKeys(1);
        vm.deal(address(stakingModule), 3 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 3 ether }(user, 0);

        vm.prank(user);
        accounting.increaseBondReserve(0, 1 ether - 1 wei);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertApproxEqAbs(uint256(info.amount), 1 ether, 1 wei);
    }

    function test_increaseBondReserve_IncreaseAmount() public {
        mock_getNodeOperatorNonWithdrawnKeys(1);
        vm.deal(address(stakingModule), 4 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 4 ether }(user, 0);

        vm.prank(user);
        accounting.increaseBondReserve(0, 1 ether - 1 wei);

        vm.prank(user);
        accounting.increaseBondReserve(0, 2 ether - 1 wei);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertApproxEqAbs(uint256(info.amount), 2 ether, 1 wei);
    }

    function test_increaseBondReserve_RevertWhen_ZeroAmount() public {
        vm.expectRevert(IBondReserve.InvalidBondReserveAmount.selector);
        vm.prank(user);
        accounting.increaseBondReserve(0, 0);
    }

    function test_increaseBondReserve_RevertWhen_NoClaimable() public {
        mock_getNodeOperatorNonWithdrawnKeys(1);
        vm.deal(address(stakingModule), 2 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 2 ether }(user, 0);

        vm.expectRevert(IBondReserve.InvalidBondReserveAmount.selector);
        vm.prank(user);
        accounting.increaseBondReserve(0, 1 wei);
    }

    function test_increaseBondReserve_RevertWhen_AmountExceedsClaimable()
        public
    {
        mock_getNodeOperatorNonWithdrawnKeys(1);
        vm.deal(address(stakingModule), 3 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 3 ether }(user, 0);

        vm.expectRevert(IBondReserve.InvalidBondReserveAmount.selector);
        vm.prank(user);
        accounting.increaseBondReserve(0, 2 ether);
    }

    function test_increaseBondReserve_RevertWhen_LessThanPrevReserve() public {
        mock_getNodeOperatorNonWithdrawnKeys(1);
        vm.deal(address(stakingModule), 4 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 4 ether }(user, 0);

        vm.prank(user);
        accounting.increaseBondReserve(0, 1 ether);

        vm.expectRevert(IBondReserve.InvalidBondReserveAmount.selector);
        vm.prank(user);
        accounting.increaseBondReserve(0, 0.5 ether);
    }

    function test_increaseBondReserve_RevertWhen_EqualToPrevReserve() public {
        mock_getNodeOperatorNonWithdrawnKeys(1);
        vm.deal(address(stakingModule), 4 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 4 ether }(user, 0);

        vm.prank(user);
        accounting.increaseBondReserve(0, 1 ether - 1 wei);

        vm.expectRevert(IBondReserve.InvalidBondReserveAmount.selector);
        vm.prank(user);
        accounting.increaseBondReserve(0, 1 ether - 1 wei);
    }
}

contract RemoveBondReserveTest is BaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorManagementProperties(user, user, false);

        vm.deal(address(stakingModule), 36 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 36 ether }(user, 0);

        vm.prank(admin);
        accounting.setBondReserveMinPeriod(1 days);
    }

    function _reserve(uint256 amount) internal {
        vm.prank(user);
        accounting.increaseBondReserve(0, amount);
    }

    function test_removeBondReserve_nothingWhenZero() public assertInvariants {
        vm.prank(user);
        accounting.removeBondReserve(0);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 0);
    }

    function test_removeBondReserve_NoActiveNoDepositable()
        public
        assertInvariants
    {
        _reserve(1 ether);
        NodeOperator memory no = NodeOperator({
            totalAddedKeys: 0,
            totalWithdrawnKeys: 0,
            totalDepositedKeys: 0,
            totalVettedKeys: 0,
            stuckValidatorsCount: 0,
            depositableValidatorsCount: 0,
            targetLimit: 0,
            targetLimitMode: 0,
            totalExitedKeys: 0,
            enqueuedCount: 0,
            managerAddress: user,
            proposedManagerAddress: address(0),
            rewardAddress: user,
            proposedRewardAddress: address(0),
            extendedManagerPermissions: false,
            usedPriorityQueue: false
        });
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(ICSModule.getNodeOperator.selector, 0),
            abi.encode(no)
        );
        vm.prank(user);
        accounting.removeBondReserve(0);
        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 0, "removed early");
    }

    function test_removeBondReserve_afterCooldown() public assertInvariants {
        _reserve(2 ether);
        vm.warp(block.timestamp + 2 days);
        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        vm.prank(user);
        accounting.removeBondReserve(0);
        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 0, "removed after cooldown");
    }

    function test_removeBondReserve_RevertWhen_TooEarly()
        public
        assertInvariants
    {
        _reserve(1 ether);

        vm.warp(block.timestamp + 1 hours);
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                ICSModule.getNodeOperatorNonWithdrawnKeys.selector,
                0
            ),
            abi.encode(1)
        );

        vm.expectRevert(ICSAccounting.MinReserveTimeHasNotPassed.selector);
        vm.prank(user);
        accounting.removeBondReserve(0);
    }

    function test_removeBondReserve_RevertWhen_AnyActive()
        public
        assertInvariants
    {
        _reserve(1 ether);

        vm.warp(block.timestamp + 1 hours);
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                ICSModule.getNodeOperatorNonWithdrawnKeys.selector,
                0
            ),
            abi.encode(1)
        );

        vm.prank(user);
        vm.expectRevert(ICSAccounting.MinReserveTimeHasNotPassed.selector);
        accounting.removeBondReserve(0);
    }
}

contract ReserveReconcileTest is BaseTest {
    function setUp() public override {
        super.setUp();
        vm.prank(admin);
        accounting.setBondReserveMinPeriod(1 days);
        mock_getNodeOperatorsCount(1);
        mock_getNodeOperatorNonWithdrawnKeys(0);

        vm.deal(address(stakingModule), 20 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 20 ether }(user, 0);

        mock_getNodeOperatorManagementProperties(user, user, false);
    }

    function _reserve(uint256 amount) internal {
        vm.prank(address(user));
        accounting.increaseBondReserve(0, amount);
    }

    function test_adjustReserve_penalizePartial() public assertInvariants {
        _reserve(5 ether);
        (uint256 current, , ) = _bondState();
        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 5 ether);

        vm.prank(address(stakingModule));
        accounting.penalize(0, 17 ether);

        info = accounting.getBondReserveInfo(0);
        assertEq(uint256(info.amount), 3 ether);
        (uint256 afterCurrent, , ) = _bondState();
        assertApproxEqAbs(afterCurrent, current - 17 ether, 1);
    }

    function test_adjustReserve_penalizeFullRemoval() public assertInvariants {
        _reserve(5 ether);

        vm.prank(address(stakingModule));
        accounting.penalize(0, 20 ether);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 0);
    }

    function test_adjustReserve_chargeFee() public assertInvariants {
        _reserve(5 ether);

        vm.prank(address(stakingModule));
        accounting.chargeFee(0, 1 ether);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 5 ether);

        vm.prank(address(stakingModule));
        accounting.chargeFee(0, 18 ether);

        info = accounting.getBondReserveInfo(0);
        assertApproxEqAbs(uint256(info.amount), 1 ether, 1);
    }

    function test_adjustReserve_onSettleLockedBond() public assertInvariants {
        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 8 ether);
        _reserve(6 ether);

        vm.prank(address(stakingModule));
        accounting.penalize(0, 12 ether);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 6 ether);

        vm.prank(address(stakingModule));
        accounting.settleLockedBondETH(0);

        info = accounting.getBondReserveInfo(0);
        assertApproxEqAbs(uint256(info.amount), 0, 1);
    }

    function test_adjustReserve_penalizeLessThanReserve()
        public
        assertInvariants
    {
        _reserve(4 ether);

        vm.prank(address(stakingModule));
        accounting.penalize(0, 2 ether);

        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        assertEq(uint256(info.amount), 4 ether);
    }

    function _bondState()
        internal
        view
        returns (uint256 current, uint256 required, uint256 reserved)
    {
        (current, required) = accounting.getBondSummary(0);
        IBondReserve.BondReserveInfo memory info = accounting
            .getBondReserveInfo(0);
        reserved = info.amount;
    }
}
