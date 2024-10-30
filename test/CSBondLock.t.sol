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
    function initialize(uint256 freezePeriod) public initializer {
        CSBondLock.__CSBondLock_init(freezePeriod);
    }

    function setBondLockFreezePeriod(uint256 freeze) external {
        _setBondLockFreezePeriod(freeze);
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

    function test_setBondLockFreezePeriod() public {
        uint256 freeze = 4 weeks;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockFreezePeriodChanged(freeze);

        bondLock.setBondLockFreezePeriod(freeze);

        uint256 _freeze = bondLock.getBondLockFreezePeriod();
        assertEq(_freeze, freeze);
    }

    function test_setBondLockFreezePeriod_RevertWhen_FreezeLessThanMin()
        public
    {
        uint256 minFreeze = bondLock.MIN_BOND_LOCK_FREEZE_PERIOD();
        vm.expectRevert(CSBondLock.InvalidBondLockFreezePeriod.selector);
        bondLock.setBondLockFreezePeriod(minFreeze - 1 seconds);
    }

    function test_setBondLockFreezePeriod_RevertWhen_FreezeGreaterThanMax()
        public
    {
        uint256 maxFreeze = bondLock.MAX_BOND_LOCK_FREEZE_PERIOD();
        vm.expectRevert(CSBondLock.InvalidBondLockFreezePeriod.selector);
        bondLock.setBondLockFreezePeriod(maxFreeze + 1 seconds);
    }

    function test_getActualLockedBond() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, amount);
    }

    function test_getActualLockedBond_WhenOnFreezeUntil() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        vm.warp(lock.freezeUntil);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, 0);
    }

    function test_getActualLockedBond_WhenFreezePeriodIsPassed() public {
        uint256 freezePeriod = bondLock.getBondLockFreezePeriod();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        vm.warp(block.timestamp + freezePeriod + 1 seconds);

        uint256 value = bondLock.getActualLockedBond(noId);
        assertEq(value, 0);
    }

    function test_lock() public {
        uint256 freezePeriod = bondLock.getBondLockFreezePeriod();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        uint256 freezeUntil = block.timestamp + freezePeriod;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockChanged(noId, amount, freezeUntil);

        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, amount);
        assertEq(lock.freezeUntil, freezeUntil);
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
        assertEq(lock.freezeUntil, lockBefore.freezeUntil + 1 hours);
    }

    function test_lock_WhenSecondLockOnFreezeUntil() public {
        uint256 noId = 0;
        uint256 freezePeriod = bondLock.getBondLockFreezePeriod();

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(lockBefore.freezeUntil);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.freezeUntil, lockBefore.freezeUntil + freezePeriod);
    }

    function test_lock_WhenSecondLockAfterFirstExpired() public {
        uint256 noId = 0;
        uint256 freezePeriod = bondLock.getBondLockFreezePeriod();

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lockBefore = bondLock.getLockedBondInfo(
            noId
        );
        vm.warp(lockBefore.freezeUntil + 1 hours);

        bondLock.lock(noId, 1 ether);
        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.freezeUntil, block.timestamp + freezePeriod);
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
        assertEq(lock.freezeUntil, 0);
    }

    function test_reduceAmount_WhenPartial() public {
        uint256 freezePeriod = bondLock.getBondLockFreezePeriod();
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);
        uint256 freezePeriodWhenLock = block.timestamp + freezePeriod;

        uint256 toRelease = 10 ether;
        uint256 rest = amount - toRelease;

        vm.warp(block.timestamp + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit CSBondLock.BondLockChanged(noId, rest, freezePeriodWhenLock);

        bondLock.reduceAmount(noId, toRelease);

        CSBondLock.BondLock memory lock = bondLock.getLockedBondInfo(0);
        assertEq(lock.amount, rest);
        assertEq(lock.freezeUntil, freezePeriodWhenLock);
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
        assertEq(lock.freezeUntil, 0);
    }
}
