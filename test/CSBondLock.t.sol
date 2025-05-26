// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { CSBondLock } from "../src/abstract/CSBondLock.sol";
import { ICSBondLock } from "../src/interfaces/ICSBondLock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSBondLockTestable is CSBondLock(4 weeks, 365 days) {
    function initialize(uint256 period) public initializer {
        CSBondLock.__CSBondLock_init(period);
    }

    function setBondLockPeriod(uint256 period) external {
        _setBondLockPeriod(period);
    }

    function lock(uint256 nodeOperatorId, uint256 amount) external {
        _lock(nodeOperatorId, amount);
    }

    function reduceAmount(uint256 nodeOperatorId, uint256 amount) external {
        _reduceAmount(nodeOperatorId, amount);
    }

    function remove(uint256 nodeOperatorId) external {
        _remove(nodeOperatorId);
    }
}

contract CSBondLockTest is Test {
    CSBondLockTestable public bondLock;

    function setUp() public {
        bondLock = new CSBondLockTestable();
        bondLock.initialize(8 weeks);
    }

    function test_setBondLockPeriod() public {
        uint256 period = 4 weeks;

        vm.expectEmit(address(bondLock));
        emit ICSBondLock.BondLockPeriodChanged(period);

        bondLock.setBondLockPeriod(period);

        uint256 _period = bondLock.getBondLockPeriod();
        assertEq(_period, period);
    }

    function test_setBondLockPeriod_RevertWhen_LessThanMin() public {
        uint256 min = bondLock.MIN_BOND_LOCK_PERIOD();
        vm.expectRevert(ICSBondLock.InvalidBondLockPeriod.selector);
        bondLock.setBondLockPeriod(min - 1 seconds);
    }

    function test_setBondLockPeriod_RevertWhen_GreaterThanMax() public {
        uint256 max = bondLock.MAX_BOND_LOCK_PERIOD();
        vm.expectRevert(ICSBondLock.InvalidBondLockPeriod.selector);
        bondLock.setBondLockPeriod(max + 1 seconds);
    }

    function test_getActualLockedBond() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, amount);
    }

    function test_getActualLockedBond_WhenOnUntil() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        vm.warp(lock.until);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, 0);
    }

    function test_getActualLockedBond_WhenPeriodIsPassed() public {
        uint256 period = bondLock.getBondLockPeriod();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        vm.warp(block.timestamp + period + 1 seconds);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, 0);
    }

    function test_lock() public {
        uint256 period = bondLock.getBondLockPeriod();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        uint256 until = block.timestamp + period;

        vm.expectEmit(address(bondLock));
        emit ICSBondLock.BondLockChanged(noId, amount, until);

        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, amount);
        assertEq(lock.until, until);
    }

    function test_lock_secondLock() public {
        uint256 noId = 0;

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(block.timestamp + 1 hours);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 2 ether);
        assertEq(lock.until, lockBefore.until + 1 hours);
    }

    function test_lock_WhenSecondLockOnUntil() public {
        uint256 noId = 0;
        uint256 period = bondLock.getBondLockPeriod();

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(lockBefore.until);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.until, lockBefore.until + period);
    }

    function test_lock_WhenSecondLockAfterFirstExpired() public {
        uint256 noId = 0;
        uint256 period = bondLock.getBondLockPeriod();

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(lockBefore.until + 1 hours);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.until, block.timestamp + period);
    }

    function test_lock_RevertWhen_ZeroAmount() public {
        vm.expectRevert(ICSBondLock.InvalidBondLockAmount.selector);
        bondLock.lock(0, 0);
    }

    function test_lock_RevertWhen_AmountExceedsMax() public {
        uint256 lock = uint256(type(uint128).max) + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                SafeCast.SafeCastOverflowedUintDowncast.selector,
                128,
                lock
            )
        );
        bondLock.lock(0, lock);
    }

    function test_reduceAmount_WhenFull() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectEmit(address(bondLock));
        emit ICSBondLock.BondLockRemoved(noId);

        bondLock.reduceAmount(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, 0);
        assertEq(lock.until, 0);
    }

    function test_reduceAmount_WhenPartial() public {
        uint256 period = bondLock.getBondLockPeriod();
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);
        uint256 periodWhenLock = block.timestamp + period;

        uint256 toRelease = 10 ether;
        uint256 rest = amount - toRelease;

        vm.warp(block.timestamp + 1 seconds);

        vm.expectEmit(address(bondLock));
        emit ICSBondLock.BondLockChanged(noId, rest, periodWhenLock);

        bondLock.reduceAmount(noId, toRelease);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, rest);
        assertEq(lock.until, periodWhenLock);
    }

    function test_reduceAmount_RevertWhen_ZeroAmount() public {
        vm.expectRevert(ICSBondLock.InvalidBondLockAmount.selector);
        bondLock.reduceAmount(0, 0);
    }

    function test_reduceAmount_RevertWhen_GreaterThanLock() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectRevert(ICSBondLock.InvalidBondLockAmount.selector);
        bondLock.reduceAmount(noId, amount + 1 ether);
    }

    function test_remove() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectEmit(address(bondLock));
        emit ICSBondLock.BondLockRemoved(noId);

        bondLock.remove(noId);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, 0);
        assertEq(lock.until, 0);
    }
}
