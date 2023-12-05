// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSBondLockBase, CSBondLock } from "../src/CSBondLock.sol";
import { PermitTokenBase } from "./helpers/Permit.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import { WithdrawalQueueMockBase, WithdrawalQueueMock } from "./helpers/mocks/WithdrawalQueueMock.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

abstract contract CSBondLockTestableBase {
    event BondPenalized(
        uint256 nodeOperatorId,
        uint256 penaltyEth,
        uint256 coveringEth
    );
}

contract CSBondLockTestable is CSBondLockTestableBase, CSBondLock {
    constructor(
        uint256 retentionPeriod,
        uint256 managementPeriod
    ) CSBondLock(retentionPeriod, managementPeriod) {}

    function setBondLockPeriods(
        uint256 retention,
        uint256 management
    ) external {
        _setBondLockPeriods(retention, management);
    }

    function get(
        uint256 nodeOperatorId
    ) external view returns (CSBondLock.BondLock memory) {
        return _get(nodeOperatorId);
    }

    function getActualAmount(uint256 amount) external view returns (uint256) {
        return _getActualAmount(amount);
    }

    function lock(uint256 nodeOperatorId, uint256 amount) external {
        _lock(nodeOperatorId, amount);
    }

    function settle(uint256[] memory nodeOperatorIds) external {
        _settle(nodeOperatorIds);
    }

    function reduceAmount(uint256 nodeOperatorId, uint256 amount) external {
        _reduceAmount(nodeOperatorId, amount);
    }

    uint256 internal _mockedUncoveredPenalty;

    function _penalize(
        uint256 nodeOperatorId,
        uint256 amount
    ) internal override returns (uint256) {
        emit BondPenalized(
            nodeOperatorId,
            amount,
            amount - _mockedUncoveredPenalty
        );
        return _mockedUncoveredPenalty;
    }

    function mock_uncoveredPenalty(uint256 amount) external {
        _mockedUncoveredPenalty = amount;
    }
}

contract CSBondLockTest is Test, CSBondLockBase, CSBondLockTestableBase {
    CSBondLockTestable public bondLock;

    function setUp() public {
        bondLock = new CSBondLockTestable(8 weeks, 1 days);
    }

    function test_setBondLockPeriods() public {
        uint256 retention = 4 weeks;
        uint256 management = 2 days;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockPeriodsChanged(retention, management);

        bondLock.setBondLockPeriods(retention, management);

        (uint256 _retention, uint256 _management) = bondLock
            .getBondLockPeriods();
        assertEq(_retention, retention);
        assertEq(_management, management);
    }

    function test_setBondLockPeriods_RevertWhen_RetentionLessThanMin() public {
        uint256 minRetention = bondLock.MIN_BOND_LOCK_RETENTION_PERIOD();
        uint256 minManagement = bondLock.MIN_BOND_LOCK_MANAGEMENT_PERIOD();
        vm.expectRevert(InvalidBondLockPeriods.selector);
        bondLock.setBondLockPeriods(minRetention - 1 seconds, minManagement);
    }

    function test_setBondLockPeriods_RevertWhen_RetentionGreaterThanMax()
        public
    {
        uint256 maxRetention = bondLock.MAX_BOND_LOCK_RETENTION_PERIOD();
        uint256 minManagement = bondLock.MIN_BOND_LOCK_MANAGEMENT_PERIOD();
        vm.expectRevert(InvalidBondLockPeriods.selector);
        bondLock.setBondLockPeriods(maxRetention + 1 seconds, minManagement);
    }

    function test_setBondLockPeriods_RevertWhen_ManagementLessThanMin() public {
        uint256 minRetention = bondLock.MIN_BOND_LOCK_RETENTION_PERIOD();
        uint256 minManagement = bondLock.MIN_BOND_LOCK_MANAGEMENT_PERIOD();
        vm.expectRevert(InvalidBondLockPeriods.selector);
        bondLock.setBondLockPeriods(minRetention, minManagement - 1 seconds);
    }

    function test_setBondLockPeriods_RevertWhen_ManagementGreaterThanMax()
        public
    {
        uint256 minRetention = bondLock.MIN_BOND_LOCK_RETENTION_PERIOD();
        uint256 maxManagement = bondLock.MAX_BOND_LOCK_MANAGEMENT_PERIOD();
        vm.expectRevert(InvalidBondLockPeriods.selector);
        bondLock.setBondLockPeriods(minRetention, maxManagement + 1 seconds);
    }

    function test_getActualAmount() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 value = bondLock.getActualAmount(noId);
        assertEq(value, amount);
    }

    function test_getActualAmount_WhenRetentionPeriodIsPassed() public {
        (uint256 retentionPeriod, ) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        vm.warp(block.timestamp + retentionPeriod + 1 seconds);

        uint256 value = bondLock.getActualAmount(noId);
        assertEq(value, 0);
    }

    function test_lock() public {
        (uint256 retentionPeriod, ) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        uint256 retentionUntil = block.timestamp + retentionPeriod;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, amount, retentionUntil);

        bondLock.lock(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.get(noId);
        assertEq(lock.amount, amount);
        assertEq(lock.retentionUntil, retentionUntil);
    }

    function test_lock_WhenSecondTime() public {
        (uint256 retentionPeriod, ) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 newBlockTimestamp = block.timestamp + 1 seconds;
        vm.warp(newBlockTimestamp);
        uint256 newRetentionUntil = newBlockTimestamp + retentionPeriod;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, amount + 1.5 ether, newRetentionUntil);
        bondLock.lock(noId, 1.5 ether);

        CSBondLock.BondLock memory lock = bondLock.get(noId);
        assertEq(lock.amount, amount + 1.5 ether);
        assertEq(lock.retentionUntil, newRetentionUntil);
    }

    function test_lock_RevertWhen_ZeroAmount() public {
        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.lock(0, 0);
    }

    function test_settle() public {
        (, uint256 managementPeriod) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        bondLock.lock(0, 1 ether);
        bondLock.mock_uncoveredPenalty(0 ether);

        // more than management period after penalty init
        // eligible to settle
        vm.warp(block.timestamp + managementPeriod + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(noId, 1 ether, 1 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, 0, 0);

        bondLock.settle(idsToSettle);

        CSBondLock.BondLock memory lock = bondLock.get(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }

    function test_settle_WhenUncovered() public {
        (, uint256 managementPeriod) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        bondLock.lock(noId, 1 ether);
        uint256 retentionPeriodWhenLock = block.timestamp + 8 weeks;
        bondLock.mock_uncoveredPenalty(0.3 ether);

        // more than management period after penalty init
        // eligible to settle
        vm.warp(block.timestamp + managementPeriod + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(noId, 1 ether, 0.7 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, 0.3 ether, retentionPeriodWhenLock);

        bondLock.settle(idsToSettle);

        CSBondLock.BondLock memory lock = bondLock.get(noId);
        assertEq(lock.amount, 0.3 ether);
        assertEq(lock.retentionUntil, retentionPeriodWhenLock);
    }

    function test_settle_WhenRetentionPeriodIsExpired() public {
        (uint256 retentionPeriod, ) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = 0;
        bondLock.lock(0, 1 ether);

        // more than retention period after penalty init
        // not eligible already
        vm.warp(block.timestamp + retentionPeriod + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, 0, 0);

        vm.recordLogs();

        bondLock.settle(idsToSettle);

        CSBondLock.BondLock memory lock = bondLock.get(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);

        assertEq(
            vm.getRecordedLogs().length,
            1,
            "should NOT emit BondPenalized event"
        );
    }

    function test_settle_WhenInManagementPeriod() public {
        (uint256 retentionPeriod, uint256 managementPeriod) = bondLock
            .getBondLockPeriods();
        uint256 noId = 0;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        bondLock.lock(noId, 1 ether);
        uint256 retentionPeriodWhenLock = block.timestamp + retentionPeriod;

        // less than management period after penalty init
        // not eligible to settle yet
        vm.warp(block.timestamp + managementPeriod - 1 hours);

        vm.recordLogs();

        bondLock.settle(idsToSettle);

        CSBondLock.BondLock memory lock = bondLock.get(noId);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.retentionUntil, retentionPeriodWhenLock);

        assertEq(vm.getRecordedLogs().length, 0, "should not emit any events");
    }

    function test_settle_WhenDifferentStates() public {
        (uint256 retentionPeriod, uint256 managementPeriod) = bondLock
            .getBondLockPeriods();
        // one eligible, one expired, one in management period
        uint256[] memory idsToSettle = new uint256[](3);
        idsToSettle[0] = 0;
        idsToSettle[1] = 1;
        idsToSettle[2] = 2;

        // more than retention period after penalty init
        // not eligible already
        bondLock.lock(0, 1 ether);
        vm.warp(block.timestamp + retentionPeriod + 1 seconds);

        // more than management period after penalty init
        // eligible to settle
        bondLock.lock(1, 1 ether);
        bondLock.mock_uncoveredPenalty(0 ether);
        vm.warp(block.timestamp + managementPeriod + 1 seconds);

        // less than management period after penalty init
        // not eligible to settle yet
        bondLock.lock(2, 1 ether);
        uint256 retentionPeriodWhenLockTheLast = block.timestamp +
            retentionPeriod;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(0, 0, 0);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(1, 1 ether, 1 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(1, 0, 0);

        vm.recordLogs();

        bondLock.settle(idsToSettle);

        CSBondLock.BondLock memory lock = bondLock.get(0);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);

        lock = bondLock.get(1);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);

        lock = bondLock.get(2);
        assertEq(lock.amount, 1 ether);
        assertEq(lock.retentionUntil, retentionPeriodWhenLockTheLast);

        assertEq(vm.getRecordedLogs().length, 3, "should emit 3 events");
    }

    function test_reduceAmount_WhenFull() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, 0, 0);

        bondLock.reduceAmount(noId, amount);

        CSBondLock.BondLock memory lock = bondLock.get(0);
        assertEq(lock.amount, 0);
        assertEq(lock.retentionUntil, 0);
    }

    function test_reduceAmount_WhenPartial() public {
        (uint256 retentionPeriod, ) = bondLock.getBondLockPeriods();
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);
        uint256 retentionPeriodWhenLock = block.timestamp + retentionPeriod;

        uint256 toRelease = 10 ether;
        uint256 rest = amount - toRelease;

        vm.warp(block.timestamp + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, rest, retentionPeriodWhenLock);

        bondLock.reduceAmount(noId, toRelease);

        CSBondLock.BondLock memory lock = bondLock.get(0);
        assertEq(lock.amount, rest);
        assertEq(lock.retentionUntil, retentionPeriodWhenLock);
    }

    function test_reduceAmount_RevertWhen_ZeroAmount() public {
        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.reduceAmount(0, 0);
    }

    function test_reduceAmount_RevertWhen_GreaterThanLock() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.reduceAmount(noId, amount + 1 ether);
    }
}
