// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { CSBondLock } from "../src/abstract/CSBondLock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSBondLockTestable is CSBondLock(4 weeks, 365 days) {
    function initialize(uint256 retentionPeriod) public initializer {
        CSBondLock.__CSBondLock_init(retentionPeriod);
    }

    function setBondLockRetentionPeriod(uint256 retention) external {
        _setBondLockRetentionPeriod(retention);
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

    function test_setBondLockRetentionPeriod() public {
        uint256 retention = 4 weeks;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockRetentionPeriodChanged(retention);

        bondLock.setBondLockRetentionPeriod(retention);

        uint256 _retention = bondLock.getBondLockRetentionPeriod();
        assertEq(_retention, retention);
    }

    function test_setBondLockRetentionPeriod_RevertWhen_RetentionLessThanMin()
        public
    {
        uint256 minRetention = bondLock.MIN_BOND_LOCK_RETENTION_PERIOD();
        vm.expectRevert(CSBondLock.InvalidBondLockRetentionPeriod.selector);
        bondLock.setBondLockRetentionPeriod(minRetention - 1 seconds);
    }

    function test_setBondLockRetentionPeriod_RevertWhen_RetentionGreaterThanMax()
        public
    {
        uint256 maxRetention = bondLock.MAX_BOND_LOCK_RETENTION_PERIOD();
        vm.expectRevert(CSBondLock.InvalidBondLockRetentionPeriod.selector);
        bondLock.setBondLockRetentionPeriod(maxRetention + 1 seconds);
    }

    function test_getActualLockedBond() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, amount);
    }

    function test_getActualLockedBond_WhenOnRetentionUntil() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        vm.warp(lock.retentionUntil);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, 0);
    }

    function test_getActualLockedBond_WhenRetentionPeriodIsPassed() public {
        uint256 retentionPeriod = bondLock.getBondLockRetentionPeriod();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        vm.warp(block.timestamp + retentionPeriod + 1 seconds);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, 0);
    }

    function test_lock() public {
        uint256 retentionPeriod = bondLock.getBondLockRetentionPeriod();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        uint256 retentionUntil = block.timestamp + retentionPeriod;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockChanged(noId, amount, retentionUntil);

        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, amount);
        assertEq(lock.retentionUntil, retentionUntil);
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
        assertEq(lock.retentionUntil, lockBefore.retentionUntil + 1 hours);
    }

    function test_lock_WhenSecondLockOnRetentionUntil() public {
        uint256 noId = 0;
        uint256 retentionPeriod = bondLock.getBondLockRetentionPeriod();

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(lockBefore.retentionUntil);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(
            lock.retentionUntil,
            lockBefore.retentionUntil + retentionPeriod
        );
    }

    function test_lock_WhenSecondLockAfterFirstExpired() public {
        uint256 noId = 0;
        uint256 retentionPeriod = bondLock.getBondLockRetentionPeriod();

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(lockBefore.retentionUntil + 1 hours);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.retentionUntil, block.timestamp + retentionPeriod);
    }

    function test_lock_RevertWhen_ZeroAmount() public {
        vm.expectRevert(CSBondLock.InvalidBondLockAmount.selector);
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

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockRemoved(noId);

        bondLock.reduceAmount(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, 0);
        assertEq(lock.retentionUntil, 0);
    }

    function test_reduceAmount_WhenPartial() public {
        uint256 retentionPeriod = bondLock.getBondLockRetentionPeriod();
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);
        uint256 retentionPeriodWhenLock = block.timestamp + retentionPeriod;

        uint256 toRelease = 10 ether;
        uint256 rest = amount - toRelease;

        vm.warp(block.timestamp + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockChanged(noId, rest, retentionPeriodWhenLock);

        bondLock.reduceAmount(noId, toRelease);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, rest);
        assertEq(lock.retentionUntil, retentionPeriodWhenLock);
    }

    function test_reduceAmount_RevertWhen_ZeroAmount() public {
        vm.expectRevert(CSBondLock.InvalidBondLockAmount.selector);
        bondLock.reduceAmount(0, 0);
    }

    function test_reduceAmount_RevertWhen_GreaterThanLock() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectRevert(CSBondLock.InvalidBondLockAmount.selector);
        bondLock.reduceAmount(noId, amount + 1 ether);
    }

    function test_remove() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockRemoved(noId);

        bondLock.remove(noId);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, 0);
        assertEq(lock.retentionUntil, 0);
    }
}
