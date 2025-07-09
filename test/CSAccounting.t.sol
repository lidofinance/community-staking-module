// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";

import { IBurner } from "../src/interfaces/IBurner.sol";
import { ICSModule, NodeOperatorManagementProperties } from "../src/interfaces/ICSModule.sol";
import { IStakingModule } from "../src/interfaces/IStakingModule.sol";
import { ICSFeeDistributor } from "../src/interfaces/ICSFeeDistributor.sol";
import { IWithdrawalQueue } from "../src/interfaces/IWithdrawalQueue.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";
import { ICSBondCore } from "../src/interfaces/ICSBondCore.sol";
import { ICSBondLock } from "../src/interfaces/ICSBondLock.sol";

import { CSAccounting } from "../src/CSAccounting.sol";
import { CSBondCore } from "../src/abstract/CSBondCore.sol";
import { CSBondLock } from "../src/abstract/CSBondLock.sol";
import { CSBondCurve } from "../src/abstract/CSBondCurve.sol";
import { IAssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { BurnerMock } from "./helpers/mocks/BurnerMock.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { InvariantAsserts } from "./helpers/InvariantAsserts.sol";
import { DistributorMock } from "./helpers/mocks/DistributorMock.sol";

contract FailedReceiverStub {
    receive() external payable {
        revert("receive failed");
    }
}

contract CSAccountingFixtures is Test, Fixtures, Utilities, InvariantAsserts {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    CSAccounting public accounting;
    Stub public stakingModule;
    DistributorMock public feeDistributor;
    BurnerMock internal burner;

    address internal admin;
    address internal user;
    address internal stranger;
    address internal testChargePenaltyRecipient;

    uint256 internal nodeOperatorsCount;

    event AssertInvariants();

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        emit AssertInvariants();
        assertAccountingTotalBondShares(nodeOperatorsCount, stETH, accounting);
        assertAccountingBurnerApproval(
            stETH,
            address(accounting),
            address(burner)
        );
        assertAccountingUnusedStorageSlots(accounting);
        vm.resumeGasMetering();
    }

    function mock_getNodeOperatorsCount(uint256 returnValue) internal {
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                IStakingModule.getNodeOperatorsCount.selector
            ),
            abi.encode(returnValue)
        );
        nodeOperatorsCount = returnValue;
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

    function mock_updateDepositableValidatorsCount() internal {
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            ),
            ""
        );
    }

    function mock_getNodeOperatorManagementProperties(
        address managerAddress,
        address rewardAddress,
        bool extendedManagerPermissions
    ) internal {
        vm.mockCall(
            address(stakingModule),
            abi.encodeWithSelector(
                ICSModule.getNodeOperatorManagementProperties.selector,
                0
            ),
            abi.encode(
                NodeOperatorManagementProperties(
                    managerAddress,
                    rewardAddress,
                    extendedManagerPermissions
                )
            )
        );
    }

    function addBond(uint256 nodeOperatorId, uint256 amount) internal {
        vm.deal(address(stakingModule), amount);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: amount }(user, nodeOperatorId);
    }

    function ethToSharesToEth(uint256 amount) internal view returns (uint256) {
        return stETH.getPooledEthByShares(stETH.getSharesByPooledEth(amount));
    }
}

contract CSAccountingBaseConstructorTest is CSAccountingFixtures {
    function setUp() public virtual {
        admin = nextAddress("ADMIN");

        user = nextAddress("USER");
        stranger = nextAddress("STRANGER");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, , ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new DistributorMock(address(stETH));
    }
}

contract CSAccountingConstructorTest is CSAccountingBaseConstructorTest {
    function test_constructor_happyPath() public {
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            address(feeDistributor),
            4 weeks,
            365 days
        );
        assertEq(address(accounting.MODULE()), address(stakingModule));
        assertEq(
            address(accounting.FEE_DISTRIBUTOR()),
            address(feeDistributor)
        );
        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
    }

    function test_constructor_RevertWhen_InitOnImpl() public {
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            address(feeDistributor),
            4 weeks,
            365 days
        );

        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        accounting.initialize(
            curve,
            admin,
            8 weeks,
            testChargePenaltyRecipient
        );
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSAccounting.ZeroModuleAddress.selector);
        accounting = new CSAccounting(
            address(locator),
            address(0),
            address(feeDistributor),
            4 weeks,
            365 days
        );
    }

    function test_constructor_RevertWhen_ZeroFeeDistributorAddress() public {
        vm.expectRevert(ICSAccounting.ZeroFeeDistributorAddress.selector);
        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            address(0),
            4 weeks,
            365 days
        );
    }

    function test_constructor_RevertWhen_InvalidBondLockPeriod_MinMoreThanMax()
        public
    {
        vm.expectRevert(ICSBondLock.InvalidBondLockPeriod.selector);
        accounting = new CSAccounting(
            address(locator),
            address(0),
            address(feeDistributor),
            4 weeks,
            2 weeks
        );
    }

    function test_constructor_RevertWhen_InvalidBondLockPeriod_MaxTooBig()
        public
    {
        vm.expectRevert(ICSBondLock.InvalidBondLockPeriod.selector);
        accounting = new CSAccounting(
            address(locator),
            address(0),
            address(feeDistributor),
            4 weeks,
            uint256(type(uint64).max) + 1
        );
    }
}

contract CSAccountingBaseInitTest is CSAccountingFixtures {
    function setUp() public virtual {
        admin = nextAddress("ADMIN");

        user = nextAddress("USER");
        stranger = nextAddress("STRANGER");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, burner, ) = initLido();

        stakingModule = new Stub();
        feeDistributor = new DistributorMock(address(stETH));

        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            address(feeDistributor),
            4 weeks,
            365 days
        );

        feeDistributor.setAccounting(address(accounting));
    }
}

contract CSAccountingInitTest is CSAccountingBaseInitTest {
    function test_initialize_happyPath() public assertInvariants {
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        _enableInitializers(address(accounting));

        vm.expectEmit(address(accounting));
        emit ICSBondCurve.BondCurveAdded(0, curve);
        vm.expectEmit(address(accounting));
        emit ICSBondLock.BondLockPeriodChanged(8 weeks);
        vm.expectEmit(address(accounting));
        emit ICSAccounting.ChargePenaltyRecipientSet(
            testChargePenaltyRecipient
        );
        accounting.initialize(
            curve,
            admin,
            8 weeks,
            testChargePenaltyRecipient
        );

        assertEq(accounting.getInitializedVersion(), 2);
    }

    function test_initialize_RevertWhen_zeroAdmin() public {
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        _enableInitializers(address(accounting));

        vm.expectRevert(ICSAccounting.ZeroAdminAddress.selector);
        accounting.initialize(
            curve,
            address(0),
            8 weeks,
            testChargePenaltyRecipient
        );
    }

    function test_initialize_RevertWhen_zeroChargePenaltyRecipient() public {
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        _enableInitializers(address(accounting));

        vm.expectRevert(
            ICSAccounting.ZeroChargePenaltyRecipientAddress.selector
        );
        accounting.initialize(curve, admin, 8 weeks, address(0));
    }

    function test_finalizeUpgradeV2_withLegacyCurves() public {
        _enableInitializers(address(accounting));

        bytes32 bondCurveStorageLocation = 0x8f22e270e477f5becb8793b61d439ab7ae990ed8eba045eb72061c0e6cfe1500;
        vm.store(
            address(accounting),
            bondCurveStorageLocation,
            bytes32(abi.encode(2))
        );

        ICSBondCurve.BondCurveIntervalInput[][]
            memory bondCurves = new ICSBondCurve.BondCurveIntervalInput[][](2);
        bondCurves[0] = new ICSBondCurve.BondCurveIntervalInput[](2);
        bondCurves[0][0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });
        bondCurves[0][1] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 2,
            trend: 1 ether
        });

        bondCurves[1] = new ICSBondCurve.BondCurveIntervalInput[](2);
        bondCurves[1][0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });
        bondCurves[1][1] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 2,
            trend: 1 ether
        });

        accounting.finalizeUpgradeV2(bondCurves);

        assertEq(accounting.getInitializedVersion(), 2);
    }

    function test_finalizeUpgradeV2_revertWhen_InvalidBondCurvesLength()
        public
    {
        _enableInitializers(address(accounting));

        ICSBondCurve.BondCurveIntervalInput[][]
            memory bondCurves = new ICSBondCurve.BondCurveIntervalInput[][](1);

        vm.expectRevert(ICSAccounting.InvalidBondCurvesLength.selector);
        accounting.finalizeUpgradeV2(bondCurves);
    }
}

contract CSAccountingBaseTest is CSAccountingFixtures {
    function setUp() public virtual {
        admin = nextAddress("ADMIN");

        user = nextAddress("USER");
        stranger = nextAddress("STRANGER");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, burner, ) = initLido();

        stakingModule = new Stub();
        mock_updateDepositableValidatorsCount();

        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        feeDistributor = new DistributorMock(address(stETH));

        accounting = new CSAccounting(
            address(locator),
            address(stakingModule),
            address(feeDistributor),
            4 weeks,
            365 days
        );

        feeDistributor.setAccounting(address(accounting));

        _enableInitializers(address(accounting));

        accounting.initialize(
            curve,
            admin,
            8 weeks,
            testChargePenaltyRecipient
        );

        vm.startPrank(admin);

        accounting.grantRole(accounting.PAUSE_ROLE(), admin);
        accounting.grantRole(accounting.RESUME_ROLE(), admin);
        accounting.grantRole(accounting.MANAGE_BOND_CURVES_ROLE(), admin);
        accounting.grantRole(accounting.SET_BOND_CURVE_ROLE(), admin);
        vm.stopPrank();
    }

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
}

contract CSAccountingPauseTest is CSAccountingBaseTest {
    function test_notPausedByDefault() public view {
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
        vm.prank(address(user));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.claimRewardsStETH(0, 1 ether, 1 ether, new bytes32[](1));
    }

    function test_claimRewardsWstETH_RevertWhen_Paused() public {
        vm.prank(address(user));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.claimRewardsWstETH(0, 1 ether, 1 ether, new bytes32[](1));
    }

    function test_claimRewardsUnstETH_RevertWhen_Paused() public {
        vm.prank(address(user));
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        accounting.claimRewardsUnstETH(0, 1 ether, 1 ether, new bytes32[](1));
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
    ICSBondCurve.BondCurveIntervalInput[] public curveWithDiscount;
    ICSBondCurve.BondCurveIntervalInput[] public individualCurve;

    constructor() {
        curveWithDiscount.push(
            ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: 1,
                trend: 2 ether
            })
        );
        curveWithDiscount.push(
            ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: 2,
                trend: 1 ether
            })
        );
        individualCurve.push(
            ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: 1,
                trend: 1.8 ether
            })
        );
        individualCurve.push(
            ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: 2,
                trend: 0.9 ether
            })
        );
    }

    function _curve(
        ICSBondCurve.BondCurveIntervalInput[] memory curve
    ) internal virtual {
        vm.startPrank(admin);
        uint256 curveId = accounting.addBondCurve(curve);
        accounting.setBondCurve(0, curveId);
        vm.stopPrank();
    }

    function _lock(uint256 amount) internal virtual {
        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, amount);
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
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 32 ether);
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 17 ether);
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 33 ether);
    }

    function test_WithLocked_MoreThanBond() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 100500 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 100532 ether);
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 18 ether);
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, 0 ether);
        assertEq(required, 30 ether);
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, ethToSharesToEth(32 ether));
        assertEq(required, 32 ether);
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, ethToSharesToEth(32 ether));
        assertEq(required, 30 ether);
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, ethToSharesToEth(33 ether));
        assertEq(required, 32 ether);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, ethToSharesToEth(33 ether));
        assertEq(required, 30 ether);
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, ethToSharesToEth(29 ether));
        assertEq(required, 32 ether);
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(current, ethToSharesToEth(29 ether));
        assertEq(required, 30 ether);
    }
}

contract CSAccountingGetBondSummarySharesTest is CSAccountingBondStateBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(32 ether));
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(17 ether));
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(33 ether));
    }

    function test_WithLocked_MoreThanBond() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 100500 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(100532 ether));
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(18 ether));
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, 0 ether);
        assertEq(required, stETH.getSharesByPooledEth(30 ether));
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, stETH.getSharesByPooledEth(32 ether));
        assertEq(required, stETH.getSharesByPooledEth(32 ether));
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, stETH.getSharesByPooledEth(32 ether));
        assertEq(required, stETH.getSharesByPooledEth(30 ether));
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, stETH.getSharesByPooledEth(33 ether));
        assertEq(required, stETH.getSharesByPooledEth(32 ether));
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, stETH.getSharesByPooledEth(33 ether));
        assertEq(required, stETH.getSharesByPooledEth(30 ether));
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, stETH.getSharesByPooledEth(29 ether));
        assertEq(required, stETH.getSharesByPooledEth(32 ether));
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 29 ether });
        (uint256 current, uint256 required) = accounting.getBondSummaryShares(
            0
        );
        assertEq(current, stETH.getSharesByPooledEth(29 ether));
        assertEq(required, stETH.getSharesByPooledEth(30 ether));
    }
}

contract CSAccountingGetUnbondedKeysCountTest is CSAccountingBondStateBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 11);
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        assertEq(accounting.getUnbondedKeysCount(0), 6);
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 11);
    }

    function test_WithLocked_MoreThanBond() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ amount: 100500 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 16);
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 7);
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 12.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 14);
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 13);
    }

    function test_WithCustomSmolCurve() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
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
        _curve(curve);
        _deposit({ bond: 2.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 15);
    }

    function test_WithCustomHugeCurve_1() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 1 ether
        });
        _curve(curve);
        _deposit({ bond: 3.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 13);
    }

    function test_WithCustomHugeCurve_2() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 1 ether
        });
        _curve(curve);
        _deposit({ bond: 8.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 8);
    }
}

contract CSAccountingGetUnbondedKeysCountToEjectTest is
    CSAccountingBondStateBaseTest
{
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        assertEq(accounting.getUnbondedKeysCountToEject(0), 6);
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        _lock({ amount: 2 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithLocked_MoreThanBond() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        _lock({ amount: 100500 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 6);
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 10);
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 11);
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 10);
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 14);
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 13);
    }
}

contract CSAccountingNegativeRebaseTest is CSAccountingBaseTest {
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
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 32 ether);
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 17 ether);
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 33 ether);
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 18 ether);
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 30 ether);
    }

    function test_OneWithdrawnOneAddedValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        assertEq(accounting.getRequiredBondForNextKeys(0, 1), 32 ether);
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeys(0, 0),
            required - current
        );
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
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
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeys(0, 1),
            2 ether - (current - required)
        );
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeys(0, 0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
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

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeys(0, 0),
            required - current
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeys(0, 0),
            required - current
        );
    }

    function test_WithMissingBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeys(0, 1),
            required - current + 2 ether
        );
    }
}

contract CSAccountingGetRequiredWstETHBondTest is
    CSAccountingGetRequiredBondBaseTest
{
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_OneWithdrawnOneAddedValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 1),
            wstETH.getWstETHByStETH(required - current + 2 ether)
        );
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
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
        assertEq(accounting.getRequiredBondForNextKeysWstETH(0, 1), 0);
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getRequiredBondForNextKeysWstETH(0, 0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
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

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 0),
            wstETH.getWstETHByStETH(required - current)
        );
    }

    function test_WithMissingBondAndOneWithdrawnAndOneAddedValidator()
        public
        override
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        (uint256 current, uint256 required) = accounting.getBondSummary(0);
        assertEq(
            accounting.getRequiredBondForNextKeysWstETH(0, 1),
            wstETH.getWstETHByStETH(required - current + 2 ether)
        );
    }
}

abstract contract CSAccountingGetRequiredBondForKeysBaseTest is
    CSAccountingBaseTest
{
    function _curve(
        ICSBondCurve.BondCurveIntervalInput[] memory curve
    ) internal virtual {
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
    function test_default() public override assertInvariants {
        assertEq(accounting.getBondAmountByKeysCountWstETH(0, 0), 0);
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(1, 0),
            wstETH.getWstETHByStETH(2 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(2, 0),
            wstETH.getWstETHByStETH(4 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(8, 0),
            wstETH.getWstETHByStETH(16 ether)
        );
    }

    function test_WithCurve() public override assertInvariants {
        ICSBondCurve.BondCurveIntervalInput[]
            memory defaultCurve = new ICSBondCurve.BondCurveIntervalInput[](2);
        defaultCurve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });
        defaultCurve[1] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 2,
            trend: 1 ether
        });

        vm.startPrank(admin);
        uint256 curveId = accounting.addBondCurve(defaultCurve);
        assertEq(accounting.getBondAmountByKeysCountWstETH(0, curveId), 0);
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(1, curveId),
            wstETH.getWstETHByStETH(2 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(2, curveId),
            wstETH.getWstETHByStETH(3 ether)
        );
        assertEq(
            accounting.getBondAmountByKeysCountWstETH(15, curveId),
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

    address internal rewardAddress;

    function setUp() public override {
        super.setUp();
        rewardAddress = nextAddress("reward address");
        mock_getNodeOperatorManagementProperties(user, rewardAddress, false);
    }

    function _rewards(uint256 fee) internal {
        vm.deal(address(feeDistributor), fee);
        vm.prank(address(feeDistributor));
        sharesAsFee = stETH.submit{ value: fee }(address(0));
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

    function test_SenderIsRewardAddress() public virtual;

    function test_RevertWhen_SenderIsNotEligible() public virtual;

    function test_RevertWhen_NodeOperatorDoesNotExist() public virtual;
}

contract CSAccountingClaimStETHRewardsTest is CSAccountingClaimRewardsBaseTest {
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
}

contract CSAccountingClaimWstETHRewardsTest is
    CSAccountingClaimRewardsBaseTest
{
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
}

contract CSAccountingClaimRewardsUnstETHTest is
    CSAccountingClaimRewardsBaseTest
{
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
}

contract CSAccountingClaimableBondTest is CSAccountingRewardsBaseTest {
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(15 ether),
            1 wei,
            "claimable bond shares should be equal to the curve discount"
        );
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ amount: 1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(14 ether),
            1 wei,
            "claimable bond shares should be equal to the curve discount minus locked"
        );
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "claimable bond shares should be equal to a single validator bond"
        );
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(2 ether),
            1 wei,
            "claimable bond shares should be equal to a single validator bond"
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(1 ether),
            1 wei,
            "claimable bond shares should be equal to the excess bond"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(3 ether),
            1 wei,
            "claimable bond shares should be equal to a single validator bond plus the excess bond"
        );
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting.getClaimableBondShares(0);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }
}

contract CSAccountingClaimableRewardsAndBondSharesTest is
    CSAccountingRewardsBaseTest
{
    function test_default() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertEq(
            claimableBondShares,
            stETH.getSharesByPooledEth(0.1 ether),
            "claimable bond shares should not be zero"
        );
    }

    function test_WithCurve() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(15.1 ether),
            1 wei,
            "claimable bond shares should be equal to the curve discount + rewards"
        );
    }

    function test_WithLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ amount: 1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertEq(
            claimableBondShares,
            stETH.getSharesByPooledEth(0.1 ether),
            "claimable bond shares should not be zero"
        );
    }

    function test_WithLockedMoreThanBondPlusRewards() public {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });
        _lock({ amount: 1.05 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertEq(
            claimableBondShares,
            stETH.getSharesByPooledEth(0.05 ether),
            "claimable bond shares should not be zero"
        );
    }

    function test_WithCurveAndLocked() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(14.1 ether),
            1 wei,
            "claimable bond shares should be equal to the curve discount + rewards - locked"
        );
    }

    function test_WithOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(2.1 ether),
            1 wei,
            "claimable bond shares should be equal to a single validator bond + rewards"
        );
    }

    function test_WithBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertEq(
            claimableBondShares,
            stETH.getSharesByPooledEth(0.1 ether),
            "claimable bond shares should be equal to rewards"
        );
    }

    function test_WithBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 32 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(2.1 ether),
            1 wei,
            "claimable bond shares should be equal to a single validator bond"
        );
    }

    function test_WithExcessBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(1.1 ether),
            1 wei,
            "claimable bond shares should be equal to the excess bond"
        );
    }

    function test_WithExcessBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertApproxEqAbs(
            claimableBondShares,
            stETH.getSharesByPooledEth(3.1 ether),
            1 wei,
            "claimable bond shares should be equal to a single validator bond + excess bond + rewards"
        );
    }

    function test_WithMissingBond() public override {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }

    function test_WithMissingBondAndOneWithdrawnValidator() public override {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 16 ether });
        _rewards({ fee: 0.1 ether });

        uint256 claimableBondShares = accounting
            .getClaimableRewardsAndBondShares(0, leaf.shares, leaf.proof);

        assertEq(
            claimableBondShares,
            0,
            "claimable bond shares should be zero"
        );
    }
}

contract CSAccountingDepositEthTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositETH() public assertInvariants {
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

    function test_depositETH_zeroAmount() public assertInvariants {
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

    function test_depositETH_revertWhen_SenderIsNotModule() public {
        vm.deal(stranger, 32 ether);
        vm.prank(stranger);

        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        accounting.depositETH{ value: 32 ether }(stranger, 0);
    }
}

contract CSAccountingDepositEthPermissionlessTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositETH() public assertInvariants {
        vm.deal(address(user), 32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        vm.prank(address(user));
        accounting.depositETH{ value: 32 ether }(0);

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

    function test_depositETH_zeroAmount() public assertInvariants {
        vm.prank(address(user));
        accounting.depositETH{ value: 0 ether }(0);

        assertEq(
            address(user).balance,
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

    function test_depositETH_revertWhen_OperatorDoesNotExist() public {
        mock_getNodeOperatorsCount(0);
        vm.deal(user, 32 ether);

        vm.expectRevert(ICSAccounting.NodeOperatorDoesNotExist.selector);
        accounting.depositETH{ value: 32 ether }(0);
    }
}

contract CSAccountingDepositStEthTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositStETH() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }(address(0));

        vm.prank(address(stakingModule));
        accounting.depositStETH(
            user,
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
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

    function test_depositStETH_zeroAmount() public assertInvariants {
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

    function test_depositStETH_withoutPermitButWithAllowance()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), type(uint256).max);
        vm.stopPrank();

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

    function test_depositStETH_withPermit() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }(address(0));

        vm.prank(address(stakingModule));
        vm.expectEmit(address(stETH));
        emit StETHMock.Approval(user, address(accounting), 32 ether);

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

    function test_depositStETH_withPermit_AlreadyPermittedWithLess()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), 1 ether);
        vm.stopPrank();

        vm.expectEmit(address(stETH));
        emit StETHMock.Approval(user, address(accounting), 32 ether);

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

    function test_depositStETH_withPermit_AlreadyPermittedWithInf()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), UINT256_MAX);
        vm.stopPrank();

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

    function test_depositStETH_withPermit_AlreadyPermittedWithTheSame()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), 32 ether);
        vm.stopPrank();

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

    function test_depositStETH_revertWhen_SenderIsNotModule() public {
        vm.prank(stranger);

        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        accounting.depositStETH(
            stranger,
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }
}

contract CSAccountingDepositStEthPermissionlessTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositStETH() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }(address(0));

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );

        vm.prank(user);
        accounting.depositStETH(
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
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

    function test_depositStETH_zeroAmount() public assertInvariants {
        vm.prank(address(user));
        accounting.depositStETH(
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

    function test_depositStETH_withoutPermitButWithAllowance()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), type(uint256).max);
        vm.stopPrank();

        vm.prank(address(user));
        accounting.depositStETH(
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

    function test_depositStETH_withPermit() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }(address(0));

        vm.prank(address(user));
        vm.expectEmit(address(stETH));
        emit StETHMock.Approval(user, address(accounting), 32 ether);

        accounting.depositStETH(
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

    function test_depositStETH_withPermit_AlreadyPermittedWithLess()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), 1 ether);
        vm.stopPrank();

        vm.expectEmit(address(stETH));
        emit StETHMock.Approval(user, address(accounting), 32 ether);

        vm.recordLogs();

        vm.prank(address(user));
        accounting.depositStETH(
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

    function test_depositStETH_withPermit_AlreadyPermittedWithInf()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), UINT256_MAX);
        vm.stopPrank();

        vm.prank(address(user));
        vm.recordLogs();

        accounting.depositStETH(
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

    function test_depositStETH_withPermit_AlreadyPermittedWithTheSame()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(accounting), 32 ether);
        vm.stopPrank();

        vm.recordLogs();

        vm.prank(address(user));
        accounting.depositStETH(
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

    function test_depositStETH_revertWhen_OperatorDoesNotExist() public {
        mock_getNodeOperatorsCount(0);
        vm.deal(user, 32 ether);

        vm.expectRevert(ICSAccounting.NodeOperatorDoesNotExist.selector);
        accounting.depositStETH(
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }
}

contract CSAccountingDepositWstEthTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositWstETH() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
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

    function test_depositWstETH_zeroAmount() public assertInvariants {
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

    function test_depositWstETH_withoutPermitButWithAllowance()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        wstETH.approve(address(accounting), UINT256_MAX);
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

    function test_depositWstETH_withPermit() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.expectEmit(address(wstETH));
        emit WstETHMock.Approval(user, address(accounting), 32 ether);

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

    function test_depositWstETH_withPermit_AlreadyPermittedWithLess()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        wstETH.approve(address(accounting), 1 ether);
        vm.stopPrank();

        vm.expectEmit(address(wstETH));
        emit WstETHMock.Approval(user, address(accounting), 32 ether);

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

    function test_depositWstETH_withPermit_AlreadyPermittedWithInf()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        wstETH.approve(address(accounting), UINT256_MAX);
        vm.stopPrank();

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
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        wstETH.approve(address(accounting), 32 ether);
        vm.stopPrank();

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

    function test_depositWstETH_revertWhen_SenderIsNotModule() public {
        vm.prank(stranger);
        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        accounting.depositWstETH(
            stranger,
            0,
            100,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }
}

contract CSAccountingDepositWstEthPermissionlessTest is CSAccountingBaseTest {
    function setUp() public override {
        super.setUp();
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
    }

    function test_depositWstETH() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );

        vm.prank(address(user));
        accounting.depositWstETH(
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

    function test_depositWstETH_zeroAmount() public assertInvariants {
        vm.prank(address(user));
        accounting.depositWstETH(
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

    function test_depositWstETH_withoutPermitButWithAllowance()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        wstETH.approve(address(accounting), UINT256_MAX);
        vm.stopPrank();

        vm.prank(address(user));
        accounting.depositWstETH(
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

    function test_depositWstETH_withPermit() public assertInvariants {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.expectEmit(address(wstETH));
        emit WstETHMock.Approval(user, address(accounting), 32 ether);

        vm.prank(address(user));
        accounting.depositWstETH(
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

    function test_depositWstETH_withPermit_AlreadyPermittedWithLess()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        wstETH.approve(address(accounting), 1 ether);
        vm.stopPrank();

        vm.expectEmit(address(wstETH));
        emit WstETHMock.Approval(user, address(accounting), 32 ether);

        vm.recordLogs();

        vm.prank(address(user));
        accounting.depositWstETH(
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

    function test_depositWstETH_withPermit_AlreadyPermittedWithInf()
        public
        assertInvariants
    {
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        wstETH.approve(address(accounting), UINT256_MAX);
        vm.stopPrank();

        vm.recordLogs();

        vm.prank(address(user));
        accounting.depositWstETH(
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
        stETH.submit{ value: 32 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        wstETH.approve(address(accounting), 32 ether);
        vm.stopPrank();

        vm.recordLogs();

        vm.prank(address(user));
        accounting.depositWstETH(
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

    function test_depositWstETH_revertWhen_OperatorDoesNotExist() public {
        mock_getNodeOperatorsCount(0);
        vm.deal(user, 32 ether);

        vm.expectRevert(ICSAccounting.NodeOperatorDoesNotExist.selector);
        accounting.depositWstETH(
            0,
            100,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
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
        mock_getNodeOperatorNonWithdrawnKeys(0);
        mock_getNodeOperatorsCount(1);
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, 0);
    }

    function test_penalize() public assertInvariants {
        uint256 amountToBurn = 1 ether;
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
        accounting.penalize(0, amountToBurn);
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(accounting.totalBondShares(), bondSharesAfter);
    }

    function test_penalize_RevertWhen_SenderIsNotModule() public {
        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
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

    function test_chargeFee() public assertInvariants {
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

    function test_chargeFee_RevertWhen_SenderIsNotModule() public {
        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        vm.prank(stranger);
        accounting.chargeFee(0, 20);
    }
}

contract CSAccountingLockBondETHTest is CSAccountingBaseTest {
    function test_setBondLockPeriod() public {
        vm.prank(admin);
        accounting.setBondLockPeriod(200 days);
        assertEq(accounting.getBondLockPeriod(), 200 days);
    }

    function test_setBondLockPeriod_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.DEFAULT_ADMIN_ROLE());
        vm.prank(stranger);
        accounting.setBondLockPeriod(200 days);
    }

    function test_lockBondETH() public assertInvariants {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);
        assertEq(accounting.getActualLockedBond(0), 1 ether);
    }

    function test_lockBondETH_RevertWhen_SenderIsNotModule() public {
        mock_getNodeOperatorsCount(1);

        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        vm.prank(stranger);
        accounting.lockBondETH(0, 1 ether);
    }

    function test_lockBondETH_RevertWhen_LockOverflow() public {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);
        assertEq(accounting.getActualLockedBond(0), 1 ether);

        vm.expectRevert();
        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, type(uint256).max);
    }

    function test_releaseLockedBondETH() public assertInvariants {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);

        vm.prank(address(stakingModule));
        accounting.releaseLockedBondETH(0, 0.4 ether);

        assertEq(accounting.getActualLockedBond(0), 0.6 ether);
    }

    function test_releaseLockedBondETH_RevertWhen_SenderIsNotModule() public {
        mock_getNodeOperatorsCount(1);

        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        vm.prank(stranger);
        accounting.releaseLockedBondETH(0, 1 ether);
    }

    function test_compensateLockedBondETH() public assertInvariants {
        mock_getNodeOperatorsCount(1);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);

        vm.expectEmit(address(accounting));
        emit ICSAccounting.BondLockCompensated(0, 0.4 ether);

        vm.deal(address(stakingModule), 0.4 ether);
        vm.prank(address(stakingModule));
        accounting.compensateLockedBondETH{ value: 0.4 ether }(0);

        assertEq(accounting.getActualLockedBond(0), 0.6 ether);
    }

    function test_compensateLockedBondETH_RevertWhen_ReceiveFailed()
        public
        assertInvariants
    {
        mock_getNodeOperatorsCount(1);
        FailedReceiverStub failedReceiver = new FailedReceiverStub();
        vm.mockCall(
            address(locator),
            abi.encodeWithSelector(locator.elRewardsVault.selector),
            abi.encode(address(failedReceiver))
        );

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);

        vm.deal(address(stakingModule), 0.4 ether);
        vm.prank(address(stakingModule));
        vm.expectRevert(ICSAccounting.ElRewardsVaultReceiveFailed.selector);
        accounting.compensateLockedBondETH{ value: 0.4 ether }(0);
    }

    function test_compensateLockedBondETH_RevertWhen_SenderIsNotModule()
        public
    {
        mock_getNodeOperatorsCount(1);
        vm.deal(stranger, 1 ether);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(0, 1 ether);

        vm.expectRevert(ICSAccounting.SenderIsNotModule.selector);
        vm.prank(stranger);
        accounting.compensateLockedBondETH{ value: 1 ether }(0);
    }

    function test_settleLockedBondETH() public assertInvariants {
        mock_getNodeOperatorsCount(1);
        uint256 noId = 0;
        uint256 amount = 1 ether;
        addBond(noId, amount);

        vm.prank(address(stakingModule));
        accounting.lockBondETH(noId, amount);
        assertEq(accounting.getActualLockedBond(noId), amount);

        vm.prank(address(stakingModule));
        bool applied = accounting.settleLockedBondETH(noId);
        assertEq(accounting.getActualLockedBond(noId), 0);
        assertTrue(applied);
    }

    function test_settleLockedBondETH_noLocked() public assertInvariants {
        mock_getNodeOperatorsCount(1);
        uint256 noId = 0;
        vm.deal(address(stakingModule), 32 ether);
        vm.prank(address(stakingModule));
        accounting.depositETH{ value: 32 ether }(user, noId);
        uint256 bond = accounting.getBondShares(noId);

        vm.prank(address(stakingModule));
        bool applied = accounting.settleLockedBondETH(noId);
        assertEq(accounting.getActualLockedBond(noId), 0);
        assertEq(accounting.getBondShares(noId), bond);
        assertFalse(applied);
    }

    function test_settleLockedBondETH_noBond() public assertInvariants {
        mock_getNodeOperatorsCount(1);
        uint256 noId = 0;
        uint256 amount = 1 ether;

        vm.startPrank(address(stakingModule));
        accounting.lockBondETH(noId, amount);

        expectNoCall(
            address(burner),
            abi.encodeWithSelector(IBurner.requestBurnShares.selector)
        );
        bool applied = accounting.settleLockedBondETH(noId);
        vm.stopPrank();

        assertEq(accounting.getActualLockedBond(noId), 0);
        assertEq(accounting.getBondShares(noId), 0);
        assertTrue(applied);
    }
}

contract CSAccountingBondCurveTest is CSAccountingBaseTest {
    function test_addBondCurve() public {
        ICSBondCurve.BondCurveIntervalInput[]
            memory curvePoints = new ICSBondCurve.BondCurveIntervalInput[](1);
        curvePoints[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });
        vm.prank(admin);
        uint256 addedId = accounting.addBondCurve(curvePoints);

        ICSBondCurve.BondCurve memory curve = accounting.getCurveInfo({
            curveId: addedId
        });

        assertEq(curve.intervals[0].minBond, 2 ether);
        assertEq(curve.intervals[0].trend, 2 ether);
    }

    function test_addBondCurve_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.MANAGE_BOND_CURVES_ROLE());
        vm.prank(stranger);
        accounting.addBondCurve(new ICSBondCurve.BondCurveIntervalInput[](0));
    }

    function test_updateBondCurve() public assertInvariants {
        ICSBondCurve.BondCurveIntervalInput[]
            memory curvePoints = new ICSBondCurve.BondCurveIntervalInput[](1);
        curvePoints[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        uint256 toUpdate = 0;

        vm.prank(admin);
        accounting.updateBondCurve(toUpdate, curvePoints);

        ICSBondCurve.BondCurve memory curve = accounting.getCurveInfo({
            curveId: toUpdate
        });

        assertEq(curve.intervals[0].minBond, 2 ether);
        assertEq(curve.intervals[0].trend, 2 ether);
    }

    function test_updateBondCurve_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.MANAGE_BOND_CURVES_ROLE());
        vm.prank(stranger);
        accounting.updateBondCurve(
            0,
            new ICSBondCurve.BondCurveIntervalInput[](0)
        );
    }

    function test_updateBondCurve_RevertWhen_InvalidBondCurveId() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        vm.prank(admin);
        accounting.updateBondCurve(
            1,
            new ICSBondCurve.BondCurveIntervalInput[](0)
        );
    }

    function test_setBondCurve() public assertInvariants {
        ICSBondCurve.BondCurveIntervalInput[]
            memory curvePoints = new ICSBondCurve.BondCurveIntervalInput[](1);
        curvePoints[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });

        mock_getNodeOperatorsCount(1);

        vm.startPrank(admin);

        uint256 addedId = accounting.addBondCurve(curvePoints);

        vm.expectCall(
            address(accounting.MODULE()),
            abi.encodeWithSelector(
                ICSModule.updateDepositableValidatorsCount.selector,
                0
            )
        );
        accounting.setBondCurve({ nodeOperatorId: 0, curveId: addedId });

        vm.stopPrank();

        ICSBondCurve.BondCurve memory curve = accounting.getBondCurve(0);

        assertEq(curve.intervals[0].minBond, 2 ether);
        assertEq(curve.intervals[0].trend, 2 ether);
    }

    function test_setBondCurve_RevertWhen_OperatorDoesNotExist() public {
        mock_getNodeOperatorsCount(0);
        vm.expectRevert(ICSAccounting.NodeOperatorDoesNotExist.selector);
        vm.prank(admin);
        accounting.setBondCurve({ nodeOperatorId: 0, curveId: 2 });
    }

    function test_setBondCurve_RevertWhen_DoesNotHaveRole() public {
        expectRoleRevert(stranger, accounting.SET_BOND_CURVE_ROLE());
        vm.prank(stranger);
        accounting.setBondCurve({ nodeOperatorId: 0, curveId: 2 });
    }
}

contract CSAccountingMiscTest is CSAccountingBaseTest {
    function test_getInitializedVersion() public view {
        assertEq(accounting.getInitializedVersion(), 2);
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

contract CSAccountingPullFeeRewardsTest is CSAccountingBaseTest {
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
}
