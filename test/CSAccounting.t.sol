// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";

import { IBurner } from "../src/interfaces/IBurner.sol";
import { ICSModule, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { IStakingModule } from "../src/interfaces/IStakingModule.sol";
import { ICSFeeDistributor } from "../src/interfaces/ICSFeeDistributor.sol";
import { IWithdrawalQueue } from "../src/interfaces/IWithdrawalQueue.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

import { CSAccounting } from "../src/CSAccounting.sol";
import { CSBondCore } from "../src/abstract/CSBondCore.sol";
import { CSBondLock } from "../src/abstract/CSBondLock.sol";
import { CSBondCurve } from "../src/abstract/CSBondCurve.sol";
import { AssetRecoverer } from "../src/abstract/AssetRecoverer.sol";
import { AssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { PermitTokenBase } from "./helpers/Permit.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";

// TODO: non-existing node operator tests
// TODO: bond lock permission tests
// TODO: bond lock emit event tests

contract CSAccountingBaseConstructorTest is Test, Fixtures, Utilities {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    CSAccounting public accounting;
    Stub public stakingModule;
    Stub public feeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;
    address internal testChargeRecipient;

    function setUp() public virtual {
        admin = nextAddress("ADMIN");

        user = nextAddress("USER");
        stranger = nextAddress("STRANGER");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new Stub();
    }
}

contract CSAccountingConstructorTest is CSAccountingBaseConstructorTest {
    function test_constructor_happyPath() public {
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            10,
            4 weeks,
            365 days
        );
        assertEq(address(accounting.CSM()), address(stakingModule));
    }

    function test_constructor_canNotInit() public {
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            10,
            4 weeks,
            365 days
        );

        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        accounting.initialize(
            curve,
            admin,
            address(feeDistributor),
            8 weeks,
            testChargeRecipient
        );
    }

    function test_initialize_revertWhen_ZeroModuleAddress() public {
        vm.expectRevert(CSAccounting.ZeroModuleAddress.selector);
        accounting = new CSAccounting(
            address(locator),
            address(0),
            10,
            4 weeks,
            365 days
        );
    }
}

contract CSAccountingBaseInitTest is Test, Fixtures, Utilities {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    CSAccounting public accounting;
    Stub public stakingModule;
    Stub public feeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;
    address internal testChargeRecipient;

    function setUp() public virtual {
        admin = nextAddress("ADMIN");

        user = nextAddress("USER");
        stranger = nextAddress("STRANGER");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new Stub();

        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            10,
            4 weeks,
            365 days
        );
    }
}

contract CSAccountingInitTest is CSAccountingBaseInitTest {
    function test_initialize_happyPath() public {
        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;

        _enableInitializers(address(accounting));

        vm.expectEmit(true, false, false, true, address(accounting));
        emit CSBondCurve.BondCurveAdded(curve);
        vm.expectEmit(true, false, false, true, address(accounting));
        emit CSBondCurve.DefaultBondCurveChanged(1);
        vm.expectEmit(true, false, false, true, address(accounting));
        emit CSBondLock.BondLockRetentionPeriodChanged(8 weeks);
        vm.expectEmit(true, false, false, true, address(accounting));
        emit CSAccounting.ChargeRecipientSet(testChargeRecipient);
        accounting.initialize(
            curve,
            admin,
            address(feeDistributor),
            8 weeks,
            testChargeRecipient
        );

        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
    }

    function test_initialize_revertWhen_zeroAdmin() public {
        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;

        _enableInitializers(address(accounting));

        vm.expectRevert(CSAccounting.ZeroAdminAddress.selector);
        accounting.initialize(
            curve,
            address(0),
            address(feeDistributor),
            8 weeks,
            testChargeRecipient
        );
    }

    function test_initialize_revertWhen_zeroFeeDistributor() public {
        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;

        _enableInitializers(address(accounting));

        vm.expectRevert(CSAccounting.ZeroFeeDistributorAddress.selector);
        accounting.initialize(
            curve,
            admin,
            address(0),
            8 weeks,
            testChargeRecipient
        );
    }

    function test_initialize_revertWhen_zeroChargeRecipient() public {
        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;

        _enableInitializers(address(accounting));

        vm.expectRevert(CSAccounting.ZeroChargeRecipientAddress.selector);
        accounting.initialize(
            curve,
            admin,
            address(feeDistributor),
            8 weeks,
            address(0)
        );
    }
}

contract CSAccountingBaseTest is Test, Fixtures, Utilities, PermitTokenBase {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    CSAccounting public accounting;
    Stub public stakingModule;
    Stub public feeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;
    address internal testChargeRecipient;

    function setUp() public virtual {
        admin = nextAddress("ADMIN");

        user = nextAddress("USER");
        stranger = nextAddress("STRANGER");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new Stub();

        uint256[] memory curve = new uint256[](1);
        curve[0] = 2 ether;
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            10,
            4 weeks,
            365 days
        );

        _enableInitializers(address(accounting));

        accounting.initialize(
            curve,
            admin,
            address(feeDistributor),
            8 weeks,
            testChargeRecipient
        );

        vm.startPrank(admin);

        accounting.grantRole(accounting.ACCOUNTING_MANAGER_ROLE(), admin);
        accounting.grantRole(accounting.PAUSE_ROLE(), admin);
        accounting.grantRole(accounting.RESUME_ROLE(), admin);
        accounting.grantRole(accounting.ADD_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(accounting.SET_DEFAULT_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(accounting.SET_BOND_CURVE_ROLE(), admin);
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

    function mock_getNodeOperatorNonWithdrawnKeys(
        uint256 returnValue
    ) internal {
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                ICSModule.getNodeOperatorNonWithdrawnKeys.selector,
                0
            ),
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

contract CSAccountingPauseTest is CSAccountingBaseTest {
    function test_notPausedByDefault() public {
        assertFalse(accounting.isPaused());
    }

    function test_pauseFor() public {
        vm.prank(admin);
        accounting.pauseFor(1 days);
        assertTrue(accounting.isPaused());
    }

    function test_resume() public {
        vm.prank(admin);
        accounting.pauseFor(1 days);

        vm.prank(admin);
        accounting.resume();
        assertFalse(accounting.isPaused());
    }

    function test_auto_resume() public {
        vm.prank(admin);
        accounting.pauseFor(1 days);
        assertTrue(accounting.isPaused());
        vm.warp(block.timestamp + 1 days + 1 seconds);
        assertFalse(accounting.isPaused());
    }

    function test_pause_RevertWhen_notAdmin() public {
        expectRoleRevert(stranger, accounting.PAUSE_ROLE());
        vm.prank(stranger);
        accounting.pauseFor(1 days);
    }

    function test_resume_RevertWhen_notAdmin() public {
        vm.prank(admin);
        accounting.pauseFor(1 days);

        expectRoleRevert(stranger, accounting.RESUME_ROLE());
        vm.prank(stranger);
        accounting.resume();
    }
}

contract CSAccountingPauseAffectingTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        vm.prank(admin);
        accounting.pauseFor(1 days);
    }

    function test_depositETH_RevertWhen_Paused() public {
        vm.deal(address(stakingModule), 1 ether);
        vm.prank(address(stakingModule));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.depositETH{ value: 1 ether }(address(user), 0);
    }

    function test_depositStETH_RevertWhen_Paused() public {
        vm.prank(address(stakingModule));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.depositStETH(
            address(user),
            0,
            1 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_depositWstETH_RevertWhen_Paused() public {
        vm.prank(address(stakingModule));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.depositWstETH(
            address(user),
            0,
            1 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_claimRewardsStETH_RevertWhen_Paused() public {
        vm.prank(address(stakingModule));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.claimRewardsStETH(
            0,
            1 ether,
            address(0),
            1 ether,
            new bytes32[](1)
        );
    }

    function test_claimRewardsWstETH_RevertWhen_Paused() public {
        vm.prank(address(stakingModule));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.claimRewardsWstETH(
            0,
            1 ether,
            address(0),
            1 ether,
            new bytes32[](1)
        );
    }

    function test_claimRewardsUnstETH_RevertWhen_Paused() public {
        vm.prank(address(stakingModule));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.claimRewardsUnstETH(
            0,
            1 ether,
            address(0),
            1 ether,
            new bytes32[](1)
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
        mock_getNodeOperatorNonWithdrawnKeys(ongoing - withdrawn);
        mock_getNodeOperatorsCount(1);
    }

    function _deposit(uint256 bond) internal virtual {
        vm.deal(address(stakingModule), bond);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: bond }({
            from: address(0),
            nodeOperatorId: 0
        });
    }

    uint256[] public defaultCurve = [2 ether, 3 ether];
    uint256[] public individualCurve = [1.8 ether, 2.7 ether];

    function _curve(uint256[] memory curve) internal virtual {
        vm.startPrank(admin);
        uint256 curveId = accounting.addBondCurve(curve);
        accounting.setBondCurve(0, curveId);
        vm.stopPrank();
    }

    function _lock(uint256 id, uint256 amount) internal virtual {
        vm.prank(address(stakingModule));
        accounting.lockBondETH(id, amount);
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
        assertEq(accounting.getUnbondedKeysCount(0), 11);
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(defaultCurve);
        assertEq(accounting.getUnbondedKeysCount(0), 6);
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ id: 0, amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 11);
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
        assertEq(accounting.getUnbondedKeysCount(0), 7);
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 12.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
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
        assertEq(accounting.getUnbondedKeysCount(0), 14);
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 13);
    }
}

contract CSAccountingGetUnbondedKeysCountToEjectTest is
    CSAccountingBondStateBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(defaultCurve);
        assertEq(accounting.getUnbondedKeysCountToEject(0), 6);
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        _lock({ id: 0, amount: 2 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithLocked_MoreThanBond() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        _lock({ id: 0, amount: 100500 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(defaultCurve);
        _lock({ id: 0, amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 6);
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 10);
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 11);
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 10);
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 14);
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 13);
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
        vm.startPrank(admin);
        uint256 curveId = accounting.addBondCurve(curve);
        accounting.setBondCurve(0, curveId);
        vm.stopPrank();
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
        ICSBondCurve.BondCurve memory curve = ICSBondCurve.BondCurve({
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

    function test_WithZeroValue() public virtual;

    function test_ExcessBondWithoutProof() public virtual;

    function test_RevertWhen_SenderIsNotCSM() public virtual;
}

contract CSAccountingClaimStETHRewardsTest is CSAccountingClaimRewardsBaseTest {
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            0.05 ether,
            address(user),
            leaf.shares,
            leaf.proof
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

    function test_WithZeroValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            0,
            address(user),
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + leaf.shares,
            "bond shares should be equal to before plus rewards shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_ExcessBondWithoutProof() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

    function test_RevertWhen_SenderIsNotCSM() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(CSAccounting.SenderIsNotCSM.selector)
        );
        vm.prank(stranger);
        accounting.claimRewardsStETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
        );
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            sharesToClaim,
            address(user),
            leaf.shares,
            leaf.proof
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

    function test_WithZeroValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            0,
            address(user),
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + leaf.shares,
            "bond shares should be equal to before plus rewards shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_ExcessBondWithoutProof() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

    function test_RevertWhen_SenderIsNotCSM() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(CSAccounting.SenderIsNotCSM.selector)
        );
        vm.prank(stranger);
        accounting.claimRewardsWstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
        );
    }
}

contract CSAccountingclaimRewardsUnstETHTest is
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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

        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
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

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            0.05 ether,
            address(user),
            leaf.shares,
            leaf.proof
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

    function test_WithZeroValue() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            0,
            address(user),
            leaf.shares,
            leaf.proof
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore + leaf.shares,
            "bond shares should be equal to before plus rewards shares"
        );
        assertEq(
            accounting.totalBondShares(),
            bondSharesAfter,
            "total bond shares should be equal to after"
        );
    }

    function test_ExcessBondWithoutProof() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(address(stakingModule));
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
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

    function test_RevertWhen_SenderIsNotCSM() public override {
        _operator({ ongoing: 16, withdrawn: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(CSAccounting.SenderIsNotCSM.selector)
        );
        vm.prank(stranger);
        accounting.claimRewardsUnstETH(
            leaf.nodeOperatorId,
            UINT256_MAX,
            address(user),
            leaf.shares,
            leaf.proof
        );
    }
}

contract CSAccountingDepositsTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositETH() public {
        vm.deal(address(stakingModule), 32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);

        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);

        assertEq(
            address(stakingModule).balance,
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

    function test_depositETH_zeroAmount() public {
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 0 ether }(user, 0);

        assertEq(
            address(stakingModule).balance,
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            0,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be equal to deposited shares"
        );
        assertEq(accounting.totalBondShares(), 0);
    }

    function test_depositStETH() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.prank(address(stakingModule));
        accounting.depositStETH(
            user,
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
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

    function test_depositStETH_zeroAmount() public {
        vm.prank(address(stakingModule));
        accounting.depositStETH(
            user,
            0,
            0 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
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
            0,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be equal to deposited shares"
        );
        assertEq(accounting.totalBondShares(), 0);
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

        vm.prank(address(stakingModule));
        accounting.depositWstETH(
            user,
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
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
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_depositWstETH_zeroAmount() public {
        vm.prank(address(stakingModule));
        accounting.depositWstETH(
            user,
            0,
            0 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
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
            0,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be equal to deposited shares"
        );
        assertEq(accounting.totalBondShares(), 0);
    }

    function test_depositStETH_withPermit() public {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.prank(address(stakingModule));
        vm.expectEmit(true, true, true, true, address(stETH));
        emit Approval(user, address(accounting), 32 ether);

        accounting.depositStETH(
            user,
            0,
            32 ether,
            ICSAccounting.PermitInput({
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

    function test_depositStETH_withPermit_AlreadyPermittedWithLess() public {
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

        vm.prank(address(stakingModule));
        accounting.depositStETH(
            user,
            0,
            32 ether,
            ICSAccounting.PermitInput({
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

    function test_depositStETH_withPermit_AlreadyPermittedWithInf() public {
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

        vm.prank(address(stakingModule));

        vm.recordLogs();

        accounting.depositStETH(
            user,
            0,
            32 ether,
            ICSAccounting.PermitInput({
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

    function test_depositStETH_withPermit_AlreadyPermittedWithTheSame() public {
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

        vm.prank(address(stakingModule));
        accounting.depositStETH(
            user,
            0,
            32 ether,
            ICSAccounting.PermitInput({
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

    function test_depositWstETH_withPermit() public {
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

        vm.prank(address(stakingModule));
        accounting.depositWstETH(
            user,
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
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

    function test_depositWstETH_withPermit_AlreadyPermittedWithLess() public {
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
            abi.encode(1 ether)
        );

        vm.expectEmit(true, true, true, true, address(wstETH));
        emit Approval(user, address(accounting), 32 ether);

        vm.recordLogs();

        vm.prank(address(stakingModule));
        accounting.depositWstETH(
            user,
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
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

    function test_depositWstETH_withPermit_AlreadyPermittedWithInf() public {
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

        vm.prank(address(stakingModule));
        accounting.depositWstETH(
            user,
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
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

    function test_depositWstETH_withPermit_AlreadyPermittedWithTheSame()
        public
    {
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

        vm.prank(address(stakingModule));
        accounting.depositWstETH(
            user,
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
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
}

contract CSAccountingPenalizeTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
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

        vm.prank(address(stakingModule));
        accounting.penalize(0, 1 ether);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_penalize_RevertWhenSenderIsNotCSM() public {
        vm.expectRevert(CSAccounting.SenderIsNotCSM.selector);
        vm.prank(stranger);
        accounting.penalize(0, 20);
    }
}

contract CSAccountingChargeFeeTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_chargeFee() public {
        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 bondSharesBefore = accounting.getBondShares(0);

        vm.prank(address(stakingModule));
        accounting.chargeFee(0, 1 ether);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_chargeFee_RevertWhenSenderIsNotCSM() public {
        vm.expectRevert(CSAccounting.SenderIsNotCSM.selector);
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
        expectRoleRevert(stranger, accounting.ACCOUNTING_MANAGER_ROLE());
        vm.prank(stranger);
        accounting.setLockedBondRetentionPeriod(200 days);
    }

    function test_lockBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);
        assertEq(accounting.getActualLockedBond(0), 1 ether);
    }

    function test_lockBondETH_RevertWhen_SenderIsNotCSM() public {
        mock_getNodeOperatorsCount(1);

        vm.expectRevert(CSAccounting.SenderIsNotCSM.selector);
        vm.prank(stranger);
        accounting.lockBondETH(0, 1 ether);
    }

    function test_releaseLockedBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);

        vm.prank(address(stakingModule));
        accounting.releaseLockedBondETH(0, 0.4 ether);

        assertEq(accounting.getActualLockedBond(0), 0.6 ether);
    }

    function test_releaseLockedBondETH_RevertWhen_SenderIsNotCSM() public {
        mock_getNodeOperatorsCount(1);

        vm.expectRevert(CSAccounting.SenderIsNotCSM.selector);
        vm.prank(stranger);
        accounting.releaseLockedBondETH(0, 1 ether);
    }

    function test_compensateLockedBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit CSAccounting.BondLockCompensated(0, 0.4 ether);

        vm.deal(address(stakingModule), 0.4 ether);
        vm.prank(address(stakingModule));
        accounting.compensateLockedBondETH{ value: 0.4 ether }(0);

        assertEq(accounting.getActualLockedBond(0), 0.6 ether);
    }

    function test_settleLockedBondETH() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);
        assertEq(accounting.getActualLockedBond(0), 1 ether);

        vm.prank(address(stakingModule));
        uint256 settled = accounting.settleLockedBondETH(0);
        assertEq(settled, 1 ether);
        assertEq(accounting.getActualLockedBond(0), 0);
    }
}

contract CSAccountingBondCurveTest is CSAccountingBaseTest {
    function test_addBondCurve() public {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 2 ether;
        curvePoints[1] = 4 ether;

        vm.prank(admin);
        accounting.addBondCurve(curvePoints);

        ICSBondCurve.BondCurve memory curve = accounting.getCurveInfo({
            curveId: 2
        });

        assertEq(curve.points[0], 2 ether);
        assertEq(curve.points[1], 4 ether);
    }

    function test_addBondCurve_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.ADD_BOND_CURVE_ROLE());
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
        expectRoleRevert(stranger, accounting.SET_DEFAULT_BOND_CURVE_ROLE());
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

        ICSBondCurve.BondCurve memory curve = accounting.getBondCurve(0);

        assertEq(curve.points[0], 2 ether);
        assertEq(curve.points[1], 4 ether);
    }

    function test_setBondCurve_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.SET_BOND_CURVE_ROLE());
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
        vm.stopPrank();
        vm.prank(address(stakingModule));
        accounting.resetBondCurve({ nodeOperatorId: 0 });

        ICSBondCurve.BondCurve memory curve = accounting.getBondCurve(0);

        uint256[] memory defaultPoints = accounting.getBondCurve(1).points;

        assertEq(curve.points[0], defaultPoints[0]);
    }

    function test_resetBondCurve_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.RESET_BOND_CURVE_ROLE());
        vm.prank(stranger);
        accounting.resetBondCurve({ nodeOperatorId: 0 });
    }
}

contract CSAccountingMiscTest is CSAccountingBaseTest {
    function test_totalBondShares() public {
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

    function test_setChargeRecipient() public {
        vm.prank(admin);
        vm.expectEmit(true, false, false, true, address(accounting));
        emit CSAccounting.ChargeRecipientSet(address(1337));
        accounting.setChargeRecipient(address(1337));
        assertEq(accounting.chargeRecipient(), address(1337));
    }

    function test_setChargeRecipient_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.ACCOUNTING_MANAGER_ROLE());
        vm.prank(stranger);
        accounting.setChargeRecipient(address(1337));
    }

    function test_setChargeRecipient_RevertWhen_Zero() public {
        vm.expectRevert();
        vm.prank(admin);
        accounting.setChargeRecipient(address(0));
    }

    function test_setLockedBondRetentionPeriod() public {
        uint256 retention = accounting.MIN_BOND_LOCK_RETENTION_PERIOD() + 1;
        vm.prank(admin);
        accounting.setLockedBondRetentionPeriod(retention);
        uint256 actualRetention = accounting.getBondLockRetentionPeriod();
        assertEq(actualRetention, retention);
    }
}

contract CSAccountingAssetRecovererTest is CSAccountingBaseTest {
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

    function test_recoverEtherHappyPath() public {
        uint256 amount = 42 ether;
        vm.deal(address(accounting), amount);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit AssetRecovererLib.EtherRecovered(recoverer, amount);

        vm.prank(recoverer);
        accounting.recoverEther();

        assertEq(address(accounting).balance, 0);
        assertEq(address(recoverer).balance, amount);
    }

    function test_recoverERC20HappyPath() public {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(accounting), 1000);

        vm.prank(recoverer);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit AssetRecovererLib.ERC20Recovered(address(token), recoverer, 1000);
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

    function test_recoverERC20_RevertWhenStETH() public {
        vm.prank(recoverer);
        vm.expectRevert(AssetRecoverer.NotAllowedToRecover.selector);
        accounting.recoverERC20(address(stETH), 1000);
    }

    function test_recoverStETHShares() public {
        mock_getNodeOperatorsCount(1);

        vm.deal(address(stakingModule), 2 ether);
        vm.startPrank(address(stakingModule));
        stETH.submit{ value: 2 ether }(address(0));
        accounting.depositStETH(
            address(stakingModule),
            0,
            1 ether,
            ICSAccounting.PermitInput({
                value: 0,
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
        vm.expectEmit(true, true, true, true, address(accounting));
        emit AssetRecovererLib.StETHSharesRecovered(recoverer, sharesToRecover);
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
