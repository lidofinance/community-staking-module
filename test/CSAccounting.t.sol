// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IBurner } from "../src/interfaces/IBurner.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { IStakingModule } from "../src/interfaces/IStakingModule.sol";
import { ICSFeeDistributor } from "../src/interfaces/ICSFeeDistributor.sol";
import { IWithdrawalQueue } from "../src/interfaces/IWithdrawalQueue.sol";

import { CSAccountingBase, CSAccounting } from "../src/CSAccounting.sol";
import { CSBondLock } from "../src/CSBondLock.sol";
import { CSBondCurve } from "../src/CSBondCurve.sol";
import { PermitTokenBase } from "./helpers/Permit.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

// TODO: non-existing node operator tests
// TODO: bond lock permission tests
// TODO: bond lock emit event tests

contract CSAccountingForTests is CSAccounting {
    constructor(
        uint256[] memory bondCurve,
        address admin,
        address lidoLocator,
        address wstETH,
        address communityStakingModule,
        uint256 lockedBondRetentionPeriod
    )
        CSAccounting(
            bondCurve,
            admin,
            lidoLocator,
            wstETH,
            communityStakingModule,
            lockedBondRetentionPeriod
        )
    {}

    function setBondCurve_ForTest(uint256 id, uint256[] memory curve) public {
        _setBondCurve(id, _addBondCurve(curve));
    }

    function setBondLock_ForTest(uint256 id, uint256 amount) public {
        CSBondLock._lock(id, amount);
    }
}

contract CSAccountingBaseTest is
    Test,
    Fixtures,
    Utilities,
    PermitTokenBase,
    CSAccountingBase
{
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    CSAccountingForTests public accounting;
    Stub public stakingModule;
    Stub public feeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;

    function setUp() public virtual {
        admin = address(1);

        user = address(2);
        stranger = address(777);

        (locator, wstETH, stETH, ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new Stub();

        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;
        accounting = new CSAccountingForTests(
            curve,
            admin,
            address(locator),
            address(wstETH),
            address(stakingModule),
            8 weeks
        );

        vm.startPrank(admin);
        accounting.setFeeDistributor(address(feeDistributor));
        accounting.grantRole(accounting.INSTANT_PENALIZE_BOND_ROLE(), admin);
        accounting.grantRole(accounting.SET_BOND_LOCK_ROLE(), admin);
        accounting.grantRole(accounting.RELEASE_BOND_LOCK_ROLE(), admin);
        accounting.grantRole(accounting.SETTLE_BOND_LOCK_ROLE(), admin);
        accounting.grantRole(accounting.ADD_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(accounting.SET_DEFAULT_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(accounting.SET_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(accounting.RESET_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(
            accounting.INSTANT_CHARGE_FEE_FROM_BOND_ROLE(),
            admin
        );
        vm.stopPrank();
    }

    function mock_getNodeOperatorsCount(uint256 returnValue) internal {
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                IStakingModule.getNodeOperatorsCount.selector
            ),
            abi.encode(returnValue)
        );
    }

    function mock_getNodeOperator(
        ICSModule.NodeOperatorInfo memory returnValue
    ) internal {
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(ICSModule.getNodeOperator.selector, 0),
            abi.encode(returnValue)
        );
    }

    function mock_requestWithdrawals(uint256[] memory returnValue) internal {
        vm.mockCall(
            address(locator.withdrawalQueue()),
            abi.encodeWithSelector(
                IWithdrawalQueue.requestWithdrawals.selector
            ),
            abi.encode(returnValue)
        );
    }

    function mock_getFeesToDistribute(uint256 returnValue) internal {
        vm.mockCall(
            address(feeDistributor),
            abi.encodeWithSelector(
                ICSFeeDistributor.getFeesToDistribute.selector
            ),
            abi.encode(returnValue)
        );
    }

    function mock_distributeFees(uint256 returnValue) internal {
        vm.mockCall(
            address(feeDistributor),
            abi.encodeWithSelector(ICSFeeDistributor.distributeFees.selector),
            abi.encode(returnValue)
        );
    }
}

abstract contract BondAmountModifiersTest {
    // 1 key  -> 2 ether
    // 2 keys -> 4 ether
    // n keys -> 2 + (n - 1) * 2 ether
    function test_default() public virtual;

    // 1 key  -> 2 ether
    // 2 keys -> 3 ether
    // n keys -> 2 + (n - 1) * 1 ether
    function test_WithCurve() public virtual;

    // 1 key  -> 2 ether + 1 ether
    // 2 keys -> 4 ether + 1 ether
    // n keys -> 2 + (n - 1) * 2 ether + 1 ether
    function test_WithLocked() public virtual;

    // 1 key  -> 2 ether + 1 ether
    // 2 keys -> 3 ether + 1 ether
    // n keys -> 2 + (n - 1) * 1 ether + 1 ether
    function test_WithCurveAndLocked() public virtual;
}

abstract contract CSAccountingBondStateBaseTest is
    BondAmountModifiersTest,
    CSAccountingBaseTest
{
    function _operator(uint256 ongoing, uint256 withdrawn) internal virtual {
        ICSModule.NodeOperatorInfo memory n;
        n.active = true;
        n.managerAddress = address(user);
        n.rewardAddress = address(user);
        n.totalVettedValidators = ongoing;
        n.totalExitedValidators = 0;
        n.totalWithdrawnValidators = withdrawn;
        n.totalAddedValidators = ongoing;
        n.totalDepositedValidators = ongoing;
        mock_getNodeOperator(n);
        mock_getNodeOperatorsCount(1);
    }

    function _deposit(uint256 bond) internal virtual {
        vm.deal(user, bond);
        vm.prank(user);
        accounting.depositETH{ value: bond }({
            from: address(0),
            nodeOperatorId: 0
        });
    }

    uint256[] public defaultCurve = [2 ether, 3 ether];
    uint256[] public individualCurve = [1.8 ether, 2.7 ether];

    function _curve(uint256[] memory curve) internal virtual {
        accounting.setBondCurve_ForTest(0, curve);
    }

    function _lock(uint256 id, uint256 amount) internal virtual {
        accounting.setBondLock_ForTest(id, amount);
    }

    function test_WithOneWithdrawnValidator() public virtual;

    function test_WithBond() public virtual;

    function test_WithBondAndOneWithdrawnValidator() public virtual;

    function test_WithExcessBond() public virtual;

    function test_WithExcessBondAndOneWithdrawnValidator() public virtual;

    function test_WithMissingBond() public virtual;

    function test_WithMissingBondAndOneWithdrawnValidator() public virtual;
}

contract CSAccountingGetBondSummaryTest is CSAccountingBondStateBaseTest {
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 32 ether);
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 17 ether);
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ id: 0, amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 33 ether);
    }

    function test_WithLocked_MoreThanBond() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ id: 0, amount: 100500 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 100532 ether);
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 18 ether);
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 30 ether);
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertApproxEqAbs(current, 32 ether, 1 wei);
        assertApproxEqAbs(required, 32 ether, 1 wei);
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertApproxEqAbs(current, 32 ether, 1 wei);
        assertApproxEqAbs(required, 30 ether, 1 wei);
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertApproxEqAbs(current, 33 ether, 1 wei);
        assertApproxEqAbs(required, 32 ether, 1 wei);
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertApproxEqAbs(current, 33 ether, 1 wei);
        assertApproxEqAbs(required, 30 ether, 1 wei);
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertApproxEqAbs(current, 29 ether, 1 wei);
        assertApproxEqAbs(required, 32 ether, 1 wei);
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertApproxEqAbs(current, 29 ether, 1 wei);
        assertApproxEqAbs(required, 30 ether, 1 wei);
    }
}

contract CSAccountingGetBondSummarySharesTest is CSAccountingBondStateBaseTest {
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(32 ether));
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(17 ether));
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ id: 0, amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(33 ether));
    }

    function test_WithLocked_MoreThanBond() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ id: 0, amount: 100500 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(100532 ether));
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(18 ether));
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(30 ether));
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertApproxEqAbs(current, stETH.getSharesByPooledEth(32 ether), 1 wei);
        assertApproxEqAbs(
            required,
            stETH.getSharesByPooledEth(32 ether),
            1 wei
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertApproxEqAbs(current, stETH.getSharesByPooledEth(32 ether), 1 wei);
        assertApproxEqAbs(
            required,
            stETH.getSharesByPooledEth(30 ether),
            1 wei
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertApproxEqAbs(current, stETH.getSharesByPooledEth(33 ether), 1 wei);
        assertApproxEqAbs(
            required,
            stETH.getSharesByPooledEth(32 ether),
            1 wei
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertApproxEqAbs(current, stETH.getSharesByPooledEth(33 ether), 1 wei);
        assertApproxEqAbs(
            required,
            stETH.getSharesByPooledEth(30 ether),
            1 wei
        );
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertApproxEqAbs(current, stETH.getSharesByPooledEth(29 ether), 1 wei);
        assertApproxEqAbs(
            required,
            stETH.getSharesByPooledEth(32 ether),
            1 wei
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertApproxEqAbs(current, stETH.getSharesByPooledEth(29 ether), 1 wei);
        assertApproxEqAbs(
            required,
            stETH.getSharesByPooledEth(30 ether),
            1 wei
        );
    }
}

contract CSAccountingGetUnbondedKeysCountTest is CSAccountingBondStateBaseTest {
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(defaultCurve);
        assertEq(accounting.getUnbondedKeysCount(0), 5);
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ id: 0, amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithLocked_MoreThanBond() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ id: 0, amount: 100500 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 16);
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 6);
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 9);
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 9);
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 13);
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 12);
    }
}

abstract contract CSAccountingGetRequiredBondBaseTest is
    CSAccountingBondStateBaseTest
{
    function test_OneWithdrawnOneAddedValidator() public virtual;

    function test_WithBondAndOneWithdrawnAndOneAddedValidator() public virtual;

    function test_WithExcessBondAndOneWithdrawnAndOneAddedValidator()
        public
        virtual;

    function test_WithMissingBondAndOneWithdrawnAndOneAddedValidator()
        public
        virtual;
}

contract CSAccountingGetRequiredETHBondTest is
    CSAccountingGetRequiredBondBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 32 ether);
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 17 ether);
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ id: 0, amount: 1 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 33 ether);
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 18 ether);
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 30 ether);
    }

    function test_OneWithdrawnOneAddedValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        assertEq(accounting.getRequiredBondForNextKeys(0, 1), 32 ether);
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeys(0, 0),
            0,
            1 wei
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 0);
    }

    function test_WithBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        assertApproxEqAbs(accounting.getRequiredBondForNextKeys(0, 1), 0, 1);
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 1), 0);
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeys(0, 0),
            16 ether,
            1 wei
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeys(0, 0),
            14 ether,
            1 wei
        );
    }

    function test_WithMissingBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeys(0, 1),
            16 ether,
            1 wei
        );
    }
}

contract CSAccountingGetRequiredWstETHBondTest is
    CSAccountingGetRequiredBondBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(17 ether)
        );
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ id: 0, amount: 1 ether });
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(33 ether)
        );
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(18 ether)
        );
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(30 ether)
        );
    }

    function test_OneWithdrawnOneAddedValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 1),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            0,
            1 wei
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        assertEq(accounting.getRequiredBondForNextKeysWstETH(0, 0), 0);
    }

    function test_WithBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeysWstETH(0, 1),
            0,
            1
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeysWstETH(0, 0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeysWstETH(0, 0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeysWstETH(0, 1), 0);
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(16 ether),
            1 wei
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            stETH.getSharesByPooledEth(14 ether)
        );
    }

    function test_WithMissingBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        assertApproxEqAbs(
            accounting.getRequiredBondForNextKeysWstETH(0, 1),
            stETH.getSharesByPooledEth(16 ether),
            1 wei
        );
    }
}

abstract contract CSAccountingGetRequiredBondForKeysBaseTest is
    CSAccountingBaseTest
{
    uint256[] public defaultCurve = [2 ether, 3 ether];

    function _curve(uint256[] memory curve) internal virtual {
        accounting.setBondCurve_ForTest(0, curve);
    }

    function test_default() public virtual;

    function test_WithCurve() public virtual;
}

contract CSAccountingGetBondAmountByKeysCountWstETHTest is
    CSAccountingGetRequiredBondForKeysBaseTest
{
    function test_default() public override {
        assertEq(accounting.getBondAmountByKeysCountWstETH(0), 0);
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(1),
            wstETH.getWstETHByStETH(2 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(2),
            wstETH.getWstETHByStETH(4 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(8),
            wstETH.getWstETHByStETH(16 ether)
        );
    }

    function test_WithCurve() public override {
        CSBondCurve.BondCurve memory curve = CSBondCurve.BondCurve({
            id: 0,
            points: defaultCurve,
            trend: 1 ether
        });
        assertEq(accounting.getBondAmountByKeysCountWstETH(0, curve), 0);
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(1, curve),
            wstETH.getWstETHByStETH(2 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(2, curve),
            wstETH.getWstETHByStETH(3 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(15, curve),
            wstETH.getWstETHByStETH(16 ether)
        );
    }
}

abstract contract CSAccountingRewardsBaseTest is CSAccountingBondStateBaseTest {
    struct RewardsLeaf {
        bytes32[] proof;
        uint256 nodeOperatorId;
        uint256 shares;
    }

    RewardsLeaf leaf;

    uint256 sharesAsFee;
    uint256 stETHAsFee;
    uint256 wstETHAsFee;
    uint256 unstETHAsFee;
    uint256 unstETHSharesAsFee;

    function _rewards(uint256 fee) internal {
        vm.deal(address(accounting), fee);
        vm.prank(address(accounting));
        sharesAsFee = stETH.submit{ value: fee }(address(0));
        mock_getFeesToDistribute(sharesAsFee);
        mock_distributeFees(sharesAsFee);
        stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        wstETHAsFee = wstETH.getWstETHByStETH(stETHAsFee);
        unstETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        unstETHSharesAsFee = stETH.getSharesByPooledEth(unstETHAsFee);
        leaf = RewardsLeaf({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: sharesAsFee
        });
    }
}

abstract contract CSAccountingClaimRewardsBaseTest is
    CSAccountingRewardsBaseTest
{
    function test_WithDesirableValue() public virtual;

    function test_RevertWhen_NotOwner() public virtual;
}

contract CSAccountingClaimStETHExcessBondTest is
    CSAccountingClaimRewardsBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            1 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _curve(defaultCurve);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            16 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(16 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
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

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            15 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            2 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
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

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            2 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 64 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            32 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(32 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 64 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            34 ether,
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(34 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
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

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
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

    function test_WithDesirableValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, 0.5 ether);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            0.5 ether,
            1 wei,
            "user balance should be equal to claimed"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(0.5 ether),
            1 wei,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_RevertWhen_NotOwner() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
    }
}

contract CSAccountingClaimStETHRewardsTest is CSAccountingClaimRewardsBaseTest {
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
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
            bondSharesBefore,
            "bond manager after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(defaultCurve);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee + 15 ether,
            "user balance should be equal to fee reward plus excess bond after curve"
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

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            1 wei,
            "bond shares after claim should be equal to before plus fee shares"
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

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            stETHAsFee + 14 ether,
            1 wei,
            "user balance should be equal to fee reward plus excess bond after curve minus locked"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(14 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after curve minus locked"
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

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            stETHAsFee + 2 ether,
            1 wei,
            "user balance should be equal to fee reward plus excess bond after one validator withdrawn"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after one validator withdrawn"
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

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee + 2 ether,
            "user balance should be equal to fee reward plus excess bond after one validator withdrawn"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after one validator withdrawn"
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

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee + 1 ether,
            "user balance should be equal to fee reward plus excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
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

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            stETHAsFee + 3 ether,
            1 wei,
            "user balance should be equal to fee reward plus excess bond after one validator withdrawn"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond after one validator withdrawn"
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

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares after claim should be equal to before plus fee shares"
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

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares after claim should be equal to before plus fee shares"
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

    function test_WithDesirableValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 stETHToClaim = stETH.getPooledEthByShares(sharesToClaim);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
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
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_RevertWhen_NotOwner() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.claimRewardsStETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
    }
}

contract CSAccountingClaimWstETHExcessBondTest is
    CSAccountingClaimRewardsBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "user balance should be equal to fee reward"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
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

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _curve(defaultCurve);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(16 ether),
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(16 ether),
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
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

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "user balance should be equal to excess bond after one validator withdrawn"
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
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

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "user balance should be equal to excess bond after one validator withdrawn"
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 64 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(32 ether),
            "user balance should be equal to excess bond"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(32 ether),
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 64 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            stETH.getSharesByPooledEth(34 ether),
            1 wei,
            "user balance should be equal to excess bond after one validator withdrawn"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(34 ether),
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
            "bond manager after claim should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
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

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimExcessBondStETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
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

    function test_WithDesirableValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 toClaim = stETH.getSharesByPooledEth(0.5 ether);
        vm.prank(user);
        accounting.claimExcessBondWstETH(0, toClaim);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            toClaim,
            1 wei,
            "user balance should be equal to claimed"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - toClaim,
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
            "bond manager after should be equal to after"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_RevertWhen_NotOwner() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.claimExcessBondWstETH(0, UINT256_MAX);
    }
}

contract CSAccountingClaimWstETHRewardsTest is
    CSAccountingClaimRewardsBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHAsFee,
            "user balance should be equal to fee reward"
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

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(defaultCurve);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETH.getWstETHByStETH(stETHAsFee + 15 ether),
            "user balance should be equal to fee reward plus excess bond after curve"
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

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            1 wei,
            "bond shares after claim should be equal to before plus fee shares"
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

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            wstETH.getWstETHByStETH(stETHAsFee + 14 ether),
            1 wei,
            "user balance should be equal to fee reward plus excess bond after curve minus locked"
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

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            wstETHAsFee + stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "user balance should be equal to fee reward plus excess bond after one validator withdrawn"
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

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHAsFee,
            "user balance should be equal to fee reward"
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

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            wstETHAsFee + stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "user balance should be equal to fee reward"
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

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            wstETHAsFee + stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "user balance should be equal to fee reward plus excess bond"
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

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            wstETHAsFee + stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "user balance should be equal to fee reward plus excess bond after one validator withdrawn"
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

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares after claim should be equal to before plus fee shares"
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

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares after claim should be equal to before plus fee shares"
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

    function test_WithDesirableValue() public override {
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
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            sharesToClaim
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHToClaim,
            "user balance should be equal to claimed"
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

    function test_RevertWhen_NotOwner() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.claimRewardsWstETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
    }
}

contract CSAccountingRequestRewardsETHExcessBondTest is
    CSAccountingClaimRewardsBaseTest
{
    uint256[] public mockedRequestIds = [1];

    function setUp() public override {
        super.setUp();
        mock_requestWithdrawals(mockedRequestIds);
    }

    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares should not change after request"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should not change"
        );
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _curve(defaultCurve);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(16 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 64 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(32 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 64 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(34 ether),
            1 wei,
            "bond shares after claim should be equal to before minus excess bond"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, UINT256_MAX);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesBefore,
            "total bond shares after claim should be equal to before"
        );
    }

    function test_WithDesirableValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestExcessBondETH(0, 0.5 ether);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            0,
            "user balance should be equal to zero"
        );
        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(0.5 ether),
            1 wei,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares after claim should be equal to after"
        );
    }

    function test_RevertWhen_NotOwner() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.requestExcessBondETH(0, UINT256_MAX);
    }
}

contract CSAccountingRequestRewardsETHRewardsTest is
    CSAccountingClaimRewardsBaseTest
{
    uint256[] public mockedRequestIds = [1];

    function setUp() public override {
        super.setUp();
        mock_requestWithdrawals(mockedRequestIds);
    }

    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares should not change after request"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should not change"
        );
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(defaultCurve);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "bond shares should be changed after request minus excess bond after curve"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be equal to before plus fee shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(14 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after curve and locked"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares should not change after request"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertApproxEqAbs(
            bondSharesAfter,
            bondSharesBefore - stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "bond shares should be equal to before minus excess bond after one validator withdrawn"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be equal to before plus fee shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );

        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be equal to before plus fee shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_WithDesirableValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 sharesToRequest = stETH.getSharesByPooledEth(0.05 ether);
        uint256 unstETHToRequest = stETH.getPooledEthByShares(sharesToRequest);
        uint256 unstETHSharesToRequest = stETH.getSharesByPooledEth(
            unstETHToRequest
        );

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(user);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            0.05 ether
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee - sharesToRequest,
            "bond shares should be equal to before plus fee shares minus requested shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_RevertWhen_NotOwner() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.requestRewardsETH(
            leaf.proof,
            leaf.nodeOperatorId,
            leaf.shares,
            UINT256_MAX
        );
    }
}

contract CSAccountingDepositsTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        ICSModule.NodeOperatorInfo memory n;
        n.active = true;
        n.managerAddress = address(user);
        n.rewardAddress = address(user);
        n.totalVettedValidators = 0;
        n.totalExitedValidators = 0;
        n.totalWithdrawnValidators = 0;
        n.totalAddedValidators = 0;
        n.totalDepositedValidators = 0;
        mock_getNodeOperator(n);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositETH() public {
        vm.deal(user, 32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);

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
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_depositStETH() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.prank(user);
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
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_depositWstETH() public {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.prank(user);
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
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_depositStETHWithPermit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.expectEmit(true, true, true, true, address(stETH));
        emit Approval(user, address(accounting), 32 ether);

        vm.prank(user);
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
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_depositStETHWithPermit_AlreadyPermittedWithLess() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        vm.mockCall(
            address(stETH),
            abi.encodeWithSelector(
                stETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(1 ether)
        );

        vm.expectEmit(true, true, true, true, address(stETH));
        emit Approval(user, address(accounting), 32 ether);

        vm.recordLogs();

        vm.prank(user);
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
            vm.getRecordedLogs().length,
            2,
            "should emit only one event about approve and deposit"
        );
    }

    function test_depositStETHWithPermit_AlreadyPermittedWithInf() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        vm.mockCall(
            address(stETH),
            abi.encodeWithSelector(
                stETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(UINT256_MAX)
        );

        vm.recordLogs();

        vm.prank(user);
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
            vm.getRecordedLogs().length,
            1,
            "should emit only one event about deposit"
        );
    }

    function test_depositStETHWithPermit_AlreadyPermittedWithTheSame() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        vm.mockCall(
            address(stETH),
            abi.encodeWithSelector(
                stETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(32 ether)
        );

        vm.recordLogs();

        vm.prank(user);
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
            vm.getRecordedLogs().length,
            1,
            "should emit only one event about deposit"
        );
    }

    function test_depositWstETHWithPermit() public {
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

        vm.prank(user);
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
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_depositWstETHWithPermit_AlreadyPermittedWithLess() public {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.mockCall(
            address(wstETH),
            abi.encodeWithSelector(
                wstETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(1 ether)
        );

        vm.expectEmit(true, true, true, true, address(wstETH));
        emit Approval(user, address(accounting), 32 ether);

        vm.recordLogs();

        vm.prank(user);
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
            vm.getRecordedLogs().length,
            2,
            "should emit only one event about approve and deposit"
        );
    }

    function test_depositWstETHWithPermit_AlreadyPermittedWithInf() public {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        vm.stopPrank();

        vm.mockCall(
            address(wstETH),
            abi.encodeWithSelector(
                wstETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(UINT256_MAX)
        );

        vm.recordLogs();

        vm.prank(user);
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
            vm.getRecordedLogs().length,
            1,
            "should emit only one event about deposit"
        );
    }

    function test_depositWstETHWithPermit_AlreadyPermittedWithTheSame() public {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        vm.stopPrank();

        vm.mockCall(
            address(wstETH),
            abi.encodeWithSelector(
                wstETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(32 ether)
        );

        vm.recordLogs();

        vm.prank(user);
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
            vm.getRecordedLogs().length,
            1,
            "should emit only one event about deposit"
        );
    }

    function test_depositETH_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        vm.prank(user);
        accounting.depositETH{ value: 0 }(user, 1);
    }

    function test_depositStETH_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        vm.prank(user);
        accounting.depositStETH(user, 1, 0 ether);
    }

    function test_depositWstETH_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        vm.prank(user);
        accounting.depositWstETH(user, 1, 0 ether);
    }

    function test_depositETH_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositETH{ value: 0 }(user, 0);
    }

    function test_depositStETH_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositStETH(user, 0, 32 ether);
    }

    function test_depositStETHWithPermit_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
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
    }

    function test_depositWstETH_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositWstETH(user, 0, 32 ether);
    }

    function test_depositWstETHWithPermit_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositWstETHWithPermit(
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
    }
}

contract CSAccountingPenalizeTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        ICSModule.NodeOperatorInfo memory n;
        n.active = true;
        n.managerAddress = address(user);
        n.rewardAddress = address(user);
        n.totalVettedValidators = 0;
        n.totalExitedValidators = 0;
        n.totalWithdrawnValidators = 0;
        n.totalAddedValidators = 0;
        n.totalDepositedValidators = 0;
        mock_getNodeOperator(n);
        mock_getNodeOperatorsCount(1);
        vm.deal(user, 32 ether);
        vm.prank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_penalize() public {
        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(accounting),
                shares
            )
        );

        vm.prank(admin);
        accounting.penalize(0, 1 ether);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_penalize_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.INSTANT_PENALIZE_BOND_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.penalize(0, 20);
    }
}

contract CSAccountingChargeFeeTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        ICSModule.NodeOperatorInfo memory n;
        n.active = true;
        n.managerAddress = address(user);
        n.rewardAddress = address(user);
        n.totalVettedValidators = 0;
        n.totalExitedValidators = 0;
        n.totalWithdrawnValidators = 0;
        n.totalAddedValidators = 0;
        n.totalDepositedValidators = 0;
        mock_getNodeOperator(n);
        mock_getNodeOperatorsCount(1);
        vm.deal(user, 32 ether);
        vm.prank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_chargeFee() public {
        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(admin);
        accounting.chargeFee(0, 1 ether);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_chargeFee_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.INSTANT_CHARGE_FEE_FROM_BOND_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.chargeFee(0, 20);
    }
}

contract CSAccountingLockBondETHTest is CSAccountingBaseTest {
    function setLockedBondRetentionPeriod() public {
        vm.prank(admin);
        accounting.setLockedBondRetentionPeriod(200 days);
        assertEq(accounting.getBondLockRetentionPeriod(), 200 days);
    }

    function setLockedBondRetentionPeriod_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.DEFAULT_ADMIN_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.setLockedBondRetentionPeriod(200 days);
    }

    function test_lockBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(admin);
        accounting.lockBondETH(0, 1 ether);
        assertEq(accounting.getActualLockedBond(0), 1 ether);
    }

    function test_lockBondETH_RevertWhen_DoesNotHaveRole() public {
        mock_getNodeOperatorsCount(1);

        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.SET_BOND_LOCK_ROLE()
                )
            )
        );
        vm.prank(stranger);
        accounting.lockBondETH(0, 1 ether);
    }

    function test_releaseLockedBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.startPrank(admin);
        accounting.lockBondETH(0, 1 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockReleased(0, 0.4 ether);

        accounting.releaseLockedBondETH(0, 0.4 ether);
        vm.stopPrank();

        assertEq(accounting.getActualLockedBond(0), 0.6 ether);
    }

    function test_releaseLockedBondETH_RevertWhen_DoesNotHaveRole() public {
        mock_getNodeOperatorsCount(1);

        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.RELEASE_BOND_LOCK_ROLE()
                )
            )
        );
        vm.prank(stranger);
        accounting.releaseLockedBondETH(0, 1 ether);
    }

    function test_compensateLockedBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(admin);
        accounting.lockBondETH(0, 1 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondLockCompensated(0, 0.4 ether);

        vm.deal(user, 0.4 ether);
        vm.prank(user);
        accounting.compensateLockedBondETH{ value: 0.4 ether }(0);

        assertEq(accounting.getActualLockedBond(0), 0.6 ether);
    }
}

contract CSAccountingBondCurveTest is CSAccountingBaseTest {
    function test_addBondCurve() public {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 2 ether;
        curvePoints[1] = 4 ether;

        vm.prank(admin);
        accounting.addBondCurve(curvePoints);

        CSBondCurve.BondCurve memory curve = accounting.getCurveInfo({
            curveId: 2
        });

        assertEq(curve.points[0], 2 ether);
        assertEq(curve.points[1], 4 ether);
    }

    function test_addBondCurve_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.ADD_BOND_CURVE_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.addBondCurve(new uint256[](0));
    }

    function test_setDefaultBondCurve() public {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 2 ether;
        curvePoints[1] = 4 ether;

        vm.startPrank(admin);
        accounting.addBondCurve(curvePoints);
        accounting.setDefaultBondCurve(2);
        vm.stopPrank();

        assertEq(accounting.defaultBondCurveId(), 2);
    }

    function test_setDefaultBondCurve_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.SET_DEFAULT_BOND_CURVE_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.setDefaultBondCurve(2);
    }

    function test_setBondCurve() public {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 2 ether;
        curvePoints[1] = 4 ether;

        vm.startPrank(admin);
        accounting.addBondCurve(curvePoints);
        accounting.setBondCurve({ nodeOperatorId: 0, curveId: 2 });
        vm.stopPrank();

        CSBondCurve.BondCurve memory curve = accounting.getBondCurve(0);

        assertEq(curve.points[0], 2 ether);
        assertEq(curve.points[1], 4 ether);
    }

    function test_setBondCurve_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.SET_BOND_CURVE_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.setBondCurve({ nodeOperatorId: 0, curveId: 2 });
    }

    function test_resetBondCurve() public {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 1 ether;
        curvePoints[1] = 2 ether;

        vm.startPrank(admin);
        accounting.addBondCurve(curvePoints);
        accounting.setBondCurve({ nodeOperatorId: 0, curveId: 2 });
        accounting.resetBondCurve({ nodeOperatorId: 0 });
        vm.stopPrank();

        CSBondCurve.BondCurve memory curve = accounting.getBondCurve(0);

        uint256[] memory defaultPoints = accounting.getBondCurve(1).points;

        assertEq(curve.points[0], defaultPoints[0]);
    }

    function test_resetBondCurve_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.RESET_BOND_CURVE_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.resetBondCurve({ nodeOperatorId: 0 });
    }
}

contract CSAccountingMiscTest is CSAccountingBaseTest {
    function test_totalBondShares() public {
        mock_getNodeOperatorsCount(2);
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);
        accounting.depositETH{ value: 32 ether }(user, 1);
        vm.stopPrank();
        uint256 totalDepositedShares = stETH.getSharesByPooledEth(32 ether) +
            stETH.getSharesByPooledEth(32 ether);
        assertEq(accounting.totalBondShares(), totalDepositedShares);
    }

    function test_setFeeDistributor() public {
        vm.prank(admin);
        accounting.setFeeDistributor(address(1337));
        assertEq(accounting.FEE_DISTRIBUTOR(), address(1337));
    }

    function test_setFeeDistributor_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            bytes(
                Utilities.accessErrorString(
                    stranger,
                    accounting.DEFAULT_ADMIN_ROLE()
                )
            )
        );

        vm.prank(stranger);
        accounting.setFeeDistributor(address(1337));
    }
}
