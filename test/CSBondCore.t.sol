// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSBondCore } from "../src/abstract/CSBondCore.sol";

import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { BurnerMock } from "./helpers/mocks/BurnerMock.sol";
import { WithdrawalQueueMock } from "./helpers/mocks/WithdrawalQueueMock.sol";

import { IStETH } from "../src/interfaces/IStETH.sol";
import { IBurner } from "../src/interfaces/IBurner.sol";
import { IWithdrawalQueue } from "../src/interfaces/IWithdrawalQueue.sol";
import { ICSBondCore } from "../src/interfaces/ICSBondCore.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSBondCoreTestable is CSBondCore {
    constructor(address lidoLocator) CSBondCore(lidoLocator) {}

    function depositETH(address from, uint256 nodeOperatorId) external payable {
        _depositETH(from, nodeOperatorId);
    }

    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 amount
    ) external {
        _depositStETH(from, nodeOperatorId, amount);
    }

    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 amount
    ) external {
        _depositWstETH(from, nodeOperatorId, amount);
    }

    function claimUnstETH(
        uint256 nodeOperatorId,
        uint256 amountToClaim,
        address to
    ) external returns (uint256) {
        return _claimUnstETH(nodeOperatorId, amountToClaim, to);
    }

    function claimStETH(
        uint256 nodeOperatorId,
        uint256 amountToClaim,
        address to
    ) external returns (uint256) {
        return _claimStETH(nodeOperatorId, amountToClaim, to);
    }

    function claimWstETH(
        uint256 nodeOperatorId,
        uint256 amountToClaim,
        address to
    ) external returns (uint256) {
        return _claimWstETH(nodeOperatorId, amountToClaim, to);
    }

    function getClaimableBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256) {
        return _getClaimableBondShares(nodeOperatorId);
    }

    function burn(uint256 nodeOperatorId, uint256 amount) external {
        _burn(nodeOperatorId, amount);
    }

    function charge(
        uint256 nodeOperatorId,
        uint256 amount,
        address recipient
    ) external {
        _charge(nodeOperatorId, amount, recipient);
    }
}

abstract contract CSBondCoreTestBase is Test, Fixtures, Utilities {
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;
    WithdrawalQueueMock internal wq;

    BurnerMock internal burner;

    CSBondCoreTestable public bondCore;

    address internal user;
    address internal testChargePenaltyRecipient;

    function setUp() public {
        (locator, wstETH, stETH, burner, wq) = initLido();

        user = nextAddress("USER");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        bondCore = new CSBondCoreTestable(address(locator));

        vm.startPrank(address(bondCore));
        stETH.approve(address(burner), UINT256_MAX);
        stETH.approve(address(wstETH), UINT256_MAX);
        stETH.approve(address(wq), UINT256_MAX);
        vm.stopPrank();
    }

    function _deposit(uint256 bond) internal {
        vm.deal(user, bond);
        bondCore.depositETH{ value: bond }(user, 0);
    }

    function ethToSharesToEth(uint256 amount) internal view returns (uint256) {
        return stETH.getPooledEthByShares(stETH.getSharesByPooledEth(amount));
    }

    function sharesToEthToShares(
        uint256 amount
    ) internal view returns (uint256) {
        return stETH.getSharesByPooledEth(stETH.getPooledEthByShares(amount));
    }
}

contract CSBondCoreConstructorTest is CSBondCoreTestBase {
    function test_constructor() public view {
        assertEq(address(bondCore.LIDO_LOCATOR()), address(locator));
        assertEq(address(bondCore.LIDO()), locator.lido());
        assertEq(address(bondCore.WSTETH()), address(wstETH));
        assertEq(address(bondCore.WITHDRAWAL_QUEUE()), address(wq));
    }

    function test_constructor_RevertIf_ZeroLocator() public {
        vm.expectRevert(ICSBondCore.ZeroLocatorAddress.selector);
        new CSBondCoreTestable(address(0));
    }
}

contract CSBondCoreBondGettersTest is CSBondCoreTestBase {
    function test_getBondShares() public {
        _deposit(1 ether);
        assertEq(
            bondCore.getBondShares(0),
            stETH.getSharesByPooledEth(1 ether)
        );
    }

    function test_getBond() public {
        _deposit(1 ether);
        assertEq(bondCore.getBond(0), ethToSharesToEth(1 ether));
    }
}

contract CSBondCoreETHTest is CSBondCoreTestBase {
    function test_depositETH() public {
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondDepositedETH(0, user, 1 ether);

        bondCore.depositETH{ value: 1 ether }(user, 0);
        uint256 shares = stETH.getSharesByPooledEth(1 ether);

        assertEq(bondCore.getBondShares(0), shares);
        assertEq(bondCore.totalBondShares(), shares);
        assertEq(stETH.sharesOf(address(bondCore)), shares);
    }

    function test_claimUnstETH() public {
        _deposit(1 ether);

        uint256 claimableShares = bondCore.getClaimableBondShares(0);
        uint256 claimableETH = stETH.getPooledEthByShares(claimableShares);
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedUnstETH(0, user, claimableETH, 0);
        uint256 requestId = bondCore.claimUnstETH(0, claimableETH + 1, user);

        assertEq(requestId, 0);
        assertEq(
            bondCore.getBondShares(0),
            bondSharesBefore - sharesToEthToShares(claimableShares)
        );
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - sharesToEthToShares(claimableShares)
        );
    }

    function test_claimUnstETH_WhenClaimableIsZero() public {
        assertEq(bondCore.getBondShares(0), 0);

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        bondCore.claimUnstETH(0, 100, user);
    }

    function test_claimUnstETH_WhenToClaimIsZero() public {
        _deposit(2 ether);

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        bondCore.claimUnstETH(0, 0, user);
    }

    function test_claimUnstETH_WhenToClaimIsMoreThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = bondCore.getClaimableBondShares(0);
        uint256 claimableETH = stETH.getPooledEthByShares(claimableShares);
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedUnstETH(0, user, claimableETH, 0);
        bondCore.claimUnstETH(0, 2 ether, user);

        assertEq(
            bondCore.getBondShares(0),
            bondSharesBefore - sharesToEthToShares(claimableShares)
        );
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - sharesToEthToShares(claimableShares)
        );
    }

    function test_claimUnstETH_WhenToClaimIsLessThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.25 ether);
        uint256 claimableETH = stETH.getPooledEthByShares(claimableShares);
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedUnstETH(0, user, claimableETH, 0);
        bondCore.claimUnstETH(0, 0.25 ether, user);

        assertEq(
            bondCore.getBondShares(0),
            bondSharesBefore - sharesToEthToShares(claimableShares)
        );
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - sharesToEthToShares(claimableShares)
        );
    }
}

contract CSBondCoreStETHTest is CSBondCoreTestBase {
    function test_depositStETH() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        stETH.submit{ value: 1 ether }(address(0));
        stETH.approve(address(bondCore), 1 ether);
        vm.stopPrank();

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondDepositedStETH(0, user, 1 ether);

        bondCore.depositStETH(user, 0, 1 ether);
        uint256 shares = stETH.getSharesByPooledEth(1 ether);

        assertEq(bondCore.getBondShares(0), shares);
        assertEq(bondCore.totalBondShares(), shares);
        assertEq(stETH.sharesOf(address(bondCore)), shares);
    }

    function test_claimStETH() public {
        _deposit(1 ether);

        uint256 claimableShares = bondCore.getClaimableBondShares(0);
        uint256 claimableETH = stETH.getPooledEthByShares(claimableShares);
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedStETH(0, user, claimableETH);
        uint256 claimedShares = bondCore.claimStETH(0, claimableETH, user);

        assertEq(claimedShares, claimableShares);
        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
        assertEq(stETH.sharesOf(user), claimableShares);
    }

    function test_claimStETH_WhenClaimableIsZero() public {
        assertEq(bondCore.getBondShares(0), 0);

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        bondCore.claimStETH(0, 100, user);
    }

    function test_claimStETH_WhenToClaimIsZero() public {
        _deposit(2 ether);

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        bondCore.claimStETH(0, 0, user);
    }

    function test_claimStETH_WhenToClaimIsMoreThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = bondCore.getClaimableBondShares(0);
        uint256 claimableETH = stETH.getPooledEthByShares(claimableShares);
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedStETH(0, user, claimableETH);
        uint256 claimedShares = bondCore.claimStETH(0, 2 ether, user);

        assertEq(claimedShares, claimableShares);
        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
        assertEq(stETH.sharesOf(user), claimableShares);
    }

    function test_claimStETH_WhenToClaimIsLessThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.25 ether);
        uint256 claimableETH = stETH.getPooledEthByShares(claimableShares);
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedStETH(0, user, claimableETH);
        uint256 claimedShares = bondCore.claimStETH(0, 0.25 ether, user);

        assertEq(claimedShares, claimableShares);
        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
        assertEq(stETH.sharesOf(user), claimableShares);
    }
}

contract CSBondCoreWstETHTest is CSBondCoreTestBase {
    function test_depositWstETH() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        stETH.submit{ value: 1 ether }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(1 ether);
        vm.stopPrank();

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondDepositedWstETH(0, user, wstETHAmount);

        bondCore.depositWstETH(user, 0, wstETHAmount);

        uint256 shares = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        assertEq(bondCore.getBondShares(0), shares);
        assertEq(bondCore.totalBondShares(), shares);
        assertEq(stETH.sharesOf(address(bondCore)), shares);
    }

    function test_claimWstETH() public {
        _deposit(1 ether);

        uint256 claimableShares = bondCore.getClaimableBondShares(0);
        uint256 claimableWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimableShares)
        );
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedWstETH(0, user, claimableWstETH);
        uint256 claimedWstETH = bondCore.claimWstETH(0, claimableShares, user);

        assertEq(claimedWstETH, claimableWstETH);
        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableWstETH);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableWstETH
        );
        assertEq(wstETH.balanceOf(user), claimableWstETH);
    }

    function test_claimWstETH_WhenClaimableIsZero() public {
        assertEq(bondCore.getBondShares(0), 0);

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        bondCore.claimWstETH(0, 100, user);
    }

    function test_claimWstETH_WhenToClaimIsZero() public {
        _deposit(2 ether);

        vm.expectRevert(ICSBondCore.NothingToClaim.selector);
        bondCore.claimWstETH(0, 0, user);
    }

    function test_claimWstETH_WhenToClaimIsMoreThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = bondCore.getClaimableBondShares(0);
        uint256 claimableWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimableShares)
        );
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedWstETH(0, user, claimableWstETH);
        uint256 claimedWstETH = bondCore.claimWstETH(
            0,
            claimableShares + 1,
            user
        );

        assertEq(claimedWstETH, claimableWstETH);
        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableWstETH);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableWstETH
        );
        assertEq(wstETH.balanceOf(user), claimableWstETH);
    }

    function test_claimWstETH_WhenToClaimIsLessThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.25 ether);
        uint256 claimableWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimableShares)
        );
        uint256 bondSharesBefore = bondCore.getBondShares(0);

        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondClaimedWstETH(0, user, claimableWstETH);
        uint256 claimedWstETH = bondCore.claimWstETH(0, claimableShares, user);

        assertEq(claimedWstETH, claimableWstETH);
        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableWstETH);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableWstETH
        );
        assertEq(wstETH.balanceOf(user), claimableWstETH);
    }
}

contract CSBondCoreBurnTest is CSBondCoreTestBase {
    function test_burn_LessThanDeposit() public {
        _deposit(32 ether);

        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 burned = stETH.getPooledEthByShares(shares);
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondBurned(0, burned, burned);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(bondCore),
                shares
            )
        );
        bondCore.burn(0, 1 ether);
        uint256 bondSharesAfter = bondCore.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by burning"
        );
        assertEq(bondCore.totalBondShares(), bondSharesAfter);
    }

    function test_burn_MoreThanDeposit() public {
        _deposit(32 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        uint256 burnShares = stETH.getSharesByPooledEth(33 ether);
        uint256 amountToBurn = 32 ether;
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondBurned(
            0,
            stETH.getPooledEthByShares(burnShares),
            stETH.getPooledEthByShares(bondSharesBefore)
        );

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(bondCore),
                stETH.getSharesByPooledEth(amountToBurn)
            )
        );

        bondCore.burn(0, 33 ether);

        assertEq(
            bondCore.getBondShares(0),
            0,
            "bond shares should be 0 after burning"
        );
        assertEq(bondCore.totalBondShares(), 0);
    }

    function test_burn_EqualToDeposit() public {
        _deposit(32 ether);

        uint256 shares = stETH.getSharesByPooledEth(32 ether);
        uint256 burned = stETH.getPooledEthByShares(shares);
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondBurned(0, burned, burned);

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(bondCore),
                shares
            )
        );

        bondCore.burn(0, 32 ether);

        assertEq(
            bondCore.getBondShares(0),
            0,
            "bond shares should be 0 after burning"
        );
        assertEq(bondCore.totalBondShares(), 0);
    }

    function test_burn_ZeroAmount() public {
        _deposit(32 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        uint256 totalBondSharesBefore = bondCore.totalBondShares();

        // Should not emit any events for zero burn
        vm.recordLogs();
        bondCore.burn(0, 0);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Verify no events were emitted
        assertEq(logs.length, 0, "no events should be emitted for zero burn");

        // Verify no state changes
        assertEq(
            bondCore.getBondShares(0),
            bondSharesBefore,
            "bond shares should remain unchanged for zero burn"
        );
        assertEq(
            bondCore.totalBondShares(),
            totalBondSharesBefore,
            "total bond shares should remain unchanged for zero burn"
        );
    }
}

contract CSBondCoreChargeTest is CSBondCoreTestBase {
    function test_charge_LessThanDeposit() public {
        _deposit(32 ether);

        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 charged = stETH.getPooledEthByShares(shares);
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondCharged(0, charged, charged);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        vm.expectCall(
            locator.lido(),
            abi.encodeWithSelector(
                IStETH.transferShares.selector,
                testChargePenaltyRecipient,
                shares
            )
        );
        bondCore.charge(0, 1 ether, testChargePenaltyRecipient);
        uint256 bondSharesAfter = bondCore.getBondShares(0);

        assertEq(
            bondSharesAfter,
            bondSharesBefore - shares,
            "bond shares should be decreased by charging"
        );
        assertEq(bondCore.totalBondShares(), bondSharesAfter);
    }

    function test_charge_MoreThanDeposit() public {
        _deposit(32 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        uint256 chargeShares = stETH.getSharesByPooledEth(33 ether);
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondCharged(
            0,
            stETH.getPooledEthByShares(chargeShares),
            stETH.getPooledEthByShares(bondSharesBefore)
        );

        vm.expectCall(
            locator.lido(),
            abi.encodeWithSelector(
                IStETH.transferShares.selector,
                testChargePenaltyRecipient,
                stETH.getSharesByPooledEth(32 ether)
            )
        );
        bondCore.charge(0, 33 ether, testChargePenaltyRecipient);

        assertEq(
            bondCore.getBondShares(0),
            0,
            "bond shares should be 0 after charging"
        );
        assertEq(bondCore.totalBondShares(), 0);
    }

    function test_charge_EqualToDeposit() public {
        _deposit(32 ether);

        uint256 shares = stETH.getSharesByPooledEth(32 ether);
        uint256 charged = stETH.getPooledEthByShares(shares);
        vm.expectEmit(address(bondCore));
        emit ICSBondCore.BondCharged(0, charged, charged);

        vm.expectCall(
            locator.lido(),
            abi.encodeWithSelector(
                IStETH.transferShares.selector,
                testChargePenaltyRecipient,
                shares
            )
        );

        bondCore.charge(0, 32 ether, testChargePenaltyRecipient);

        assertEq(
            bondCore.getBondShares(0),
            0,
            "bond shares should be 0 after charging"
        );
        assertEq(bondCore.totalBondShares(), 0);
    }

    function test_charge_ZeroAmount() public {
        _deposit(32 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        uint256 totalBondSharesBefore = bondCore.totalBondShares();

        // Should not emit any events for zero charge
        vm.recordLogs();
        bondCore.charge(0, 0, testChargePenaltyRecipient);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Verify no events were emitted
        assertEq(logs.length, 0, "no events should be emitted for zero charge");

        // Verify no state changes
        assertEq(
            bondCore.getBondShares(0),
            bondSharesBefore,
            "bond shares should remain unchanged for zero charge"
        );
        assertEq(
            bondCore.totalBondShares(),
            totalBondSharesBefore,
            "total bond shares should remain unchanged for zero charge"
        );
    }
}
