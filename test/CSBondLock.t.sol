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

    function get(uint256 nodeOperatorId) external view returns (uint256) {
        return _get(nodeOperatorId);
    }

    function lock(uint256 nodeOperatorId, uint256 amount) external {
        _lock(nodeOperatorId, amount);
    }

    function settle(uint256[] memory nodeOperatorIds) external {
        _settle(nodeOperatorIds);
    }

    function release(uint256 nodeOperatorId, uint256 amount) external {
        _release(nodeOperatorId, amount);
    }

    function compensate(uint256 nodeOperatorId, uint256 amount) external {
        _compensate(nodeOperatorId, amount);
    }

    uint256 internal _mockedBondAmountForPenalize;

    function _penalize(
        uint256 nodeOperatorId,
        uint256 amount
    ) internal override returns (uint256) {
        uint256 toPenalize = amount < _mockedBondAmountForPenalize
            ? amount
            : _mockedBondAmountForPenalize;
        emit BondPenalized(nodeOperatorId, amount, toPenalize);
        return amount - toPenalize;
    }

    function mock_bondAmount(uint256 amount) external {
        _mockedBondAmountForPenalize = amount;
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

        bondLock.setBondLockPeriods(retention, management);

        (uint256 _retention, uint256 _management) = bondLock
            .getBondLockPeriods();
        assertEq(_retention, retention);
        assertEq(_management, management);
    }

    function test_setBondLockPeriods_RevertWhen_RetentionLessThanMin() public {
        vm.expectRevert(InvalidBondLockRetentionPeriod.selector);
        bondLock.setBondLockPeriods(3 weeks, 1 days);
    }

    function test_setBondLockPeriods_RevertWhen_RetentionGreaterThanMax()
        public
    {
        vm.expectRevert(InvalidBondLockRetentionPeriod.selector);
        bondLock.setBondLockPeriods(366 days, 1 days);
    }

    function test_setBondLockPeriods_RevertWhen_ManagementLessThanMin() public {
        vm.expectRevert(InvalidBondLockRetentionPeriod.selector);
        bondLock.setBondLockPeriods(8 weeks, 23 hours);
    }

    function test_setBondLockPeriods_RevertWhen_ManagementGreaterThanMax()
        public
    {
        vm.expectRevert(InvalidBondLockRetentionPeriod.selector);
        bondLock.setBondLockPeriods(8 weeks, 8 days);
    }

    function test_get() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 value = bondLock.get(noId);
        assertEq(value, amount);
    }

    function test_get_WhenRetentionPeriodIsPassed() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        vm.warp(block.timestamp + 8 weeks + 1 seconds);

        uint256 value = bondLock.get(noId);
        assertEq(value, 0);
    }

    function test_lock() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, amount, block.timestamp + 8 weeks);

        bondLock.lock(noId, amount);

        uint256 value = bondLock.get(noId);
        assertEq(value, amount);
    }

    function test_lock_WhenSecondTime() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        bondLock.lock(noId, amount);

        uint256 newBlockTimestamp = block.timestamp + 1 seconds;
        vm.warp(newBlockTimestamp);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(
            noId,
            amount + 1.5 ether,
            newBlockTimestamp + 8 weeks
        );
        bondLock.lock(noId, 1.5 ether);

        uint256 value = bondLock.get(noId);
        assertEq(value, amount + 1.5 ether);
    }

    function test_lock_RevertWhen_ZeroAmount() public {
        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.lock(0, 0);
    }

    function test_settle() public {
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = 0;
        bondLock.lock(0, 1 ether);
        bondLock.mock_bondAmount(1 ether);

        // more than 1 day (management period) after penalty init
        // eligible to settle
        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(0, 1 ether, 1 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(0, 0, 0);

        bondLock.settle(idsToSettle);

        uint256 value = bondLock.get(0);
        assertEq(value, 0 ether);
    }

    function test_settle_WhenLockIsLessThanBond() public {
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = 0;
        bondLock.lock(0, 0.7 ether);
        bondLock.mock_bondAmount(1 ether);

        // more than 1 day (management period) after penalty init
        // eligible to settle
        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(0, 0.7 ether, 0.7 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(0, 0, 0);

        bondLock.settle(idsToSettle);

        uint256 value = bondLock.get(0);
        assertEq(value, 0);
    }

    function test_settle_WhenLockIsGreaterThanBond() public {
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = 0;
        bondLock.lock(0, 1 ether);
        uint256 retentionPeriodWhenLock = block.timestamp + 8 weeks;
        bondLock.mock_bondAmount(0.7 ether);

        // more than 1 day (management period) after penalty init
        // eligible to settle
        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(0, 1 ether, 0.7 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(0, 0.3 ether, retentionPeriodWhenLock);

        bondLock.settle(idsToSettle);

        uint256 value = bondLock.get(0);
        assertEq(value, 0.3 ether);
    }

    function test_settle_WhenRetentionPeriodIsExpired() public {
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = 0;
        bondLock.lock(0, 1 ether);

        // more than 8 weeks (retention period) after penalty init
        // not eligible already
        vm.warp(block.timestamp + 8 weeks + 1 seconds);

        vm.recordLogs();

        bondLock.settle(idsToSettle);

        uint256 value = bondLock.get(0);
        assertEq(value, 0 ether);

        assertEq(
            vm.getRecordedLogs().length,
            1,
            "should not emit BondPenalized event"
        );
    }

    function test_settle_WhenInManagementPeriod() public {
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = 0;
        bondLock.lock(0, 1 ether);

        // less than 1 day (management period) after penalty init
        // not eligible to settle yet
        vm.warp(block.timestamp + 20 hours);

        vm.recordLogs();

        bondLock.settle(idsToSettle);

        uint256 value = bondLock.get(0);
        assertEq(value, 1 ether);

        assertEq(vm.getRecordedLogs().length, 0, "should not emit any events");
    }

    function test_settle_WhenDifferentStates() public {
        // one eligible, one expired, one in management period
        uint256[] memory idsToSettle = new uint256[](3);
        idsToSettle[0] = 0;
        idsToSettle[1] = 1;
        idsToSettle[2] = 2;

        // more than 8 weeks (retention period) after penalty init
        // not eligible already
        bondLock.lock(0, 1 ether);
        vm.warp(block.timestamp + 8 weeks + 1 seconds);

        // more than 1 day (management period) after penalty init
        // eligible to settle
        bondLock.lock(1, 1 ether);
        bondLock.mock_bondAmount(1 ether);
        vm.warp(block.timestamp + 1 days + 1 seconds);

        // less than 1 day (management period) after penalty init
        // not eligible to settle yet
        bondLock.lock(2, 1 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(0, 0, 0);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondPenalized(1, 1 ether, 1 ether);

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(1, 0, 0);

        vm.recordLogs();

        bondLock.settle(idsToSettle);

        uint256 value = bondLock.get(0);
        assertEq(value, 0 ether);

        value = bondLock.get(1);
        assertEq(value, 0 ether);

        value = bondLock.get(2);
        assertEq(value, 1 ether);

        assertEq(vm.getRecordedLogs().length, 3, "should emit 3 events");
    }

    function test_release() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        uint256 toRelease = 10 ether;
        uint256 rest = amount - toRelease;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockReleased(noId, toRelease);
        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, rest, block.timestamp + 8 weeks);

        bondLock.release(noId, toRelease);

        uint256 value = bondLock.get(noId);
        assertEq(value, rest);

        vm.warp(block.timestamp + 8 weeks + 1 seconds);
        value = bondLock.get(noId);
        assertEq(value, 0);
    }

    function test_release_RevertWhen_ZeroAmount() public {
        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.release(0, 0);
    }

    function test_release_RevertWhen_GreaterThanLock() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.release(noId, amount + 1 ether);
    }

    function test_compensate() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        uint256 toCompensate = 10 ether;
        uint256 rest = amount - toCompensate;

        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockCompensated(noId, toCompensate);
        vm.expectEmit(true, true, true, true, address(bondLock));
        emit BondLockChanged(noId, rest, block.timestamp + 8 weeks);

        bondLock.compensate(noId, toCompensate);

        uint256 value = bondLock.get(noId);
        assertEq(value, rest);

        vm.warp(block.timestamp + 8 weeks + 1 seconds);
        value = bondLock.get(noId);
        assertEq(value, 0);
    }

    function test_compensate_RevertWhen_ZeroAmount() public {
        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.compensate(0, 0);
    }

    function test_compensate_RevertWhen_GreaterThanLock() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;

        bondLock.lock(noId, amount);

        vm.expectRevert(InvalidBondLockAmount.selector);
        bondLock.compensate(noId, amount + 1 ether);
    }
}
