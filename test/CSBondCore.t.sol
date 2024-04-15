// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSBondCore, CSBondCoreBase } from "../src/abstract/CSBondCore.sol";

import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { BurnerMock } from "./helpers/mocks/BurnerMock.sol";

import { IStETH } from "../src/interfaces/IStETH.sol";
import { IBurner } from "../src/interfaces/IBurner.sol";
import { IWithdrawalQueue } from "../src/interfaces/IWithdrawalQueue.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSBondCoreTestable is CSBondCore {
    constructor(
        address lidoLocator,
        address wstETH
    ) CSBondCore(lidoLocator, wstETH) {}

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

    function requestETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) external {
        _requestETH(nodeOperatorId, claimableShares, amountToClaim, to);
    }

    function claimStETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) external {
        _claimStETH(nodeOperatorId, claimableShares, amountToClaim, to);
    }

    function claimWstETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) external {
        _claimWstETH(nodeOperatorId, claimableShares, amountToClaim, to);
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

abstract contract CSBondCoreTestBase is
    Test,
    Fixtures,
    Utilities,
    CSBondCoreBase
{
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;

    BurnerMock internal burner;

    CSBondCoreTestable public bondCore;

    address internal user;
    address internal testChargeRecipient;

    function setUp() public {
        (locator, wstETH, stETH, burner) = initLido();

        user = nextAddress("USER");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        bondCore = new CSBondCoreTestable(address(locator), address(wstETH));
    }

    uint256[] public mockedRequestIds = [1];

    function mock_requestWithdrawals(uint256[] memory returnValue) internal {
        vm.mockCall(
            address(locator.withdrawalQueue()),
            abi.encodeWithSelector(
                IWithdrawalQueue.requestWithdrawals.selector
            ),
            abi.encode(returnValue)
        );
    }

    function _deposit(uint256 bond) internal {
        vm.deal(user, bond);
        bondCore.depositETH{ value: bond }(user, 0);
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
        assertApproxEqAbs(bondCore.getBond(0), 1 ether, 1 wei);
    }
}

contract CSBondCoreETHTest is CSBondCoreTestBase {
    function test_depositETH() public {
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondDeposited(0, user, 1 ether);

        bondCore.depositETH{ value: 1 ether }(user, 0);
        uint256 shares = stETH.getSharesByPooledEth(1 ether);

        assertEq(bondCore.getBondShares(0), shares);
        assertEq(bondCore.totalBondShares(), shares);
        assertEq(stETH.sharesOf(address(bondCore)), shares);
    }

    function test_requestETH() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimableShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(0, claimableShares, 0.5 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
    }

    function test_requestETH_WhenClaimableIsZero() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(0, 0, 0, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
    }

    function test_requestETH_WhenToClaimIsZero() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(2 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(0, 1 ether, 0, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
    }

    function test_requestETH_WhenToClaimIsMoreThanClaimable() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimableShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(0, claimableShares, 1 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
    }

    function test_requestETH_WhenToClaimIsEqualToClaimable() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimableShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(0, claimableShares, 0.5 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
    }

    function test_requestETH_WhenToClaimIsLessThanClaimable() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedShares = stETH.getSharesByPooledEth(0.25 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimedShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(0, claimableShares, 0.25 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimedShares);
        assertEq(bondCore.totalBondShares(), bondSharesBefore - claimedShares);
    }

    function test_requestETH_RevertWhen_ClaimableSharesIsMoreThanBondShares()
        public
    {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        vm.expectRevert(InvalidClaimableShares.selector);
        bondCore.requestETH(0, 2 ether, 0.5 ether, user);
    }

    function test_requestETH_RequestedLessThanMinWithdrawal() public {
        mock_requestWithdrawals(mockedRequestIds);
        _deposit(1 ether);

        uint256 minWithdrawal = IWithdrawalQueue(locator.withdrawalQueue())
            .MIN_STETH_WITHDRAWAL_AMOUNT();

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.requestETH(
            0,
            0.5 ether,
            stETH.getPooledEthByShares(minWithdrawal) - 10 wei,
            user
        );

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
    }
}

contract CSBondCoreStETHTest is CSBondCoreTestBase {
    function test_depositStETH() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        stETH.submit{ value: 1 ether }(address(0));

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondDeposited(0, user, 1 ether);

        bondCore.depositStETH(user, 0, 1 ether);
        uint256 shares = stETH.getSharesByPooledEth(1 ether);

        assertEq(bondCore.getBondShares(0), shares);
        assertEq(bondCore.totalBondShares(), shares);
        assertEq(stETH.sharesOf(address(bondCore)), shares);
    }

    function test_claimStETH() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimableShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimStETH(0, claimableShares, 0.5 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
        assertEq(stETH.sharesOf(user), claimableShares);
    }

    function test_claimStETH_WhenClaimableIsZero() public {
        _deposit(1 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimStETH(0, 0, 0, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
        assertEq(stETH.sharesOf(user), 0);
    }

    function test_claimStETH_WhenToClaimIsZero() public {
        _deposit(2 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimStETH(0, 1 ether, 0, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
        assertEq(stETH.sharesOf(user), 0);
    }

    function test_claimStETH_WhenToClaimIsMoreThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimableShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimStETH(0, claimableShares, 1 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
        assertEq(stETH.sharesOf(user), claimableShares);
    }

    function test_claimStETH_WhenToClaimIsEqualToClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimableShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimStETH(0, claimableShares, 0.5 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimableShares);
        assertEq(
            bondCore.totalBondShares(),
            bondSharesBefore - claimableShares
        );
        assertEq(stETH.sharesOf(user), claimableShares);
    }

    function test_claimStETH_WhenToClaimIsLessThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedShares = stETH.getSharesByPooledEth(0.25 ether);
        uint256 claimedETH = stETH.getPooledEthByShares(claimedShares);

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimed(0, user, claimedETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimStETH(0, claimableShares, 0.25 ether, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimedShares);
        assertEq(bondCore.totalBondShares(), bondSharesBefore - claimedShares);
        assertEq(stETH.sharesOf(user), claimedShares);
    }

    function test_claimStETH_RevertWhen_ClaimableSharesIsMoreThanBondShares()
        public
    {
        _deposit(1 ether);

        vm.expectRevert(InvalidClaimableShares.selector);
        bondCore.claimStETH(0, 2 ether, 0.5 ether, user);
    }
}

contract CSBondCoreWstETHTest is CSBondCoreTestBase {
    function test_depositWstETH() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        stETH.submit{ value: 1 ether }(address(0));
        uint256 wstETHAmount = wstETH.wrap(1 ether);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondDepositedWstETH(0, user, wstETHAmount);

        bondCore.depositWstETH(user, 0, wstETHAmount);

        assertApproxEqAbs(bondCore.getBondShares(0), wstETHAmount, 1 wei);
        assertApproxEqAbs(bondCore.totalBondShares(), wstETHAmount, 1 wei);
        assertApproxEqAbs(
            stETH.sharesOf(address(bondCore)),
            wstETHAmount,
            1 wei
        );
    }

    function test_claimWstETH() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimableShares)
        );

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimedWstETH(0, user, claimedWstETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimWstETH(0, claimableShares, claimableShares, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimedWstETH);
        assertEq(bondCore.totalBondShares(), bondSharesBefore - claimedWstETH);
        assertEq(wstETH.balanceOf(user), claimedWstETH);
    }

    function test_claimWstETH_WhenClaimableIsZero() public {
        _deposit(1 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimWstETH(0, 0, 0, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
        assertEq(wstETH.balanceOf(user), 0);
    }

    function test_claimWstETH_WhenToClaimIsZero() public {
        _deposit(2 ether);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimWstETH(0, 1 ether, 0, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore);
        assertEq(bondCore.totalBondShares(), bondSharesBefore);
        assertEq(wstETH.balanceOf(user), 0);
    }

    function test_claimWstETH_WhenToClaimIsMoreThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimableShares)
        );

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimedWstETH(0, user, claimedWstETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimWstETH(0, claimableShares, claimableShares, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimedWstETH);
        assertEq(bondCore.totalBondShares(), bondSharesBefore - claimedWstETH);
        assertEq(wstETH.balanceOf(user), claimedWstETH);
    }

    function test_claimWstETH_WhenToClaimIsEqualToClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimableShares)
        );

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimedWstETH(0, user, claimedWstETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimWstETH(0, claimableShares, claimableShares, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimedWstETH);
        assertEq(bondCore.totalBondShares(), bondSharesBefore - claimedWstETH);
        assertEq(wstETH.balanceOf(user), claimedWstETH);
    }

    function test_claimWstETH_WhenToClaimIsLessThanClaimable() public {
        _deposit(1 ether);

        uint256 claimableShares = stETH.getSharesByPooledEth(0.5 ether);
        uint256 claimedShares = stETH.getSharesByPooledEth(0.25 ether);
        uint256 claimedWstETH = stETH.getSharesByPooledEth(
            stETH.getPooledEthByShares(claimedShares)
        );

        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondClaimedWstETH(0, user, claimedWstETH);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        bondCore.claimWstETH(0, claimableShares, claimedShares, user);

        assertEq(bondCore.getBondShares(0), bondSharesBefore - claimedWstETH);
        assertEq(bondCore.totalBondShares(), bondSharesBefore - claimedWstETH);
        assertEq(wstETH.balanceOf(user), claimedWstETH);
    }

    function test_claimWstETH_RevertWhen_ClaimableSharesIsMoreThanBondShares()
        public
    {
        _deposit(1 ether);

        vm.expectRevert(InvalidClaimableShares.selector);
        bondCore.claimWstETH(0, 2 ether, 0.5 ether, user);
    }
}

contract CSBondCoreBurnTest is CSBondCoreTestBase {
    function test_burn_LessThanDeposit() public {
        _deposit(32 ether);

        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 burned = stETH.getPooledEthByShares(shares);
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondBurned(0, burned, burned);

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
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondBurned(
            0,
            stETH.getPooledEthByShares(burnShares),
            stETH.getPooledEthByShares(bondSharesBefore)
        );

        vm.expectCall(
            locator.burner(),
            abi.encodeWithSelector(
                IBurner.requestBurnShares.selector,
                address(bondCore),
                stETH.getSharesByPooledEth(32 ether)
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
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondBurned(0, burned, burned);

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
}

contract CSBondCoreChargeTest is CSBondCoreTestBase {
    function test_charge_LessThanDeposit() public {
        _deposit(32 ether);

        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 charged = stETH.getPooledEthByShares(shares);
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondCharged(0, charged, charged);

        uint256 bondSharesBefore = bondCore.getBondShares(0);
        vm.expectCall(
            locator.lido(),
            abi.encodeWithSelector(
                IStETH.transferSharesFrom.selector,
                address(bondCore),
                testChargeRecipient,
                shares
            )
        );
        bondCore.charge(0, 1 ether, testChargeRecipient);
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
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondCharged(
            0,
            stETH.getPooledEthByShares(chargeShares),
            stETH.getPooledEthByShares(bondSharesBefore)
        );

        vm.expectCall(
            locator.lido(),
            abi.encodeWithSelector(
                IStETH.transferSharesFrom.selector,
                address(bondCore),
                testChargeRecipient,
                stETH.getSharesByPooledEth(32 ether)
            )
        );
        bondCore.charge(0, 33 ether, testChargeRecipient);

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
        vm.expectEmit(true, true, true, true, address(bondCore));
        emit BondCharged(0, charged, charged);

        vm.expectCall(
            locator.lido(),
            abi.encodeWithSelector(
                IStETH.transferSharesFrom.selector,
                address(bondCore),
                testChargeRecipient,
                shares
            )
        );

        bondCore.charge(0, 32 ether, testChargeRecipient);

        assertEq(
            bondCore.getBondShares(0),
            0,
            "bond shares should be 0 after charging"
        );
        assertEq(bondCore.totalBondShares(), 0);
    }
}
