// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { BondReserve } from "../src/abstract/BondReserve.sol";
import { IBondReserve } from "../src/interfaces/IBondReserve.sol";

contract BondReserveTestable is BondReserve {
    function initialize(uint256 minPeriod) public initializer {
        __BondReserve_init(minPeriod);
    }

    function setBondReserveMinPeriod(uint256 period) external {
        _setBondReserveMinPeriod(period);
    }

    function setBondReserve(uint256 nodeOperatorId, uint256 amount) external {
        _setBondReserve(nodeOperatorId, amount);
    }
}

contract BondReserveTest is Test {
    BondReserveTestable public reserve;

    function setUp() public {
        reserve = new BondReserveTestable();
        reserve.initialize(8 weeks);
    }

    function test_setBondReserveMinPeriod() public {
        uint256 period = 4 weeks;

        vm.expectEmit(address(reserve));
        emit IBondReserve.BondReserveMinPeriodChanged(period);

        reserve.setBondReserveMinPeriod(period);

        uint256 _period = reserve.getBondReserveMinPeriod();
        assertEq(_period, period);
    }

    function test_setBondReserveMinPeriod_RevertWhen_Zero() public {
        vm.expectRevert(IBondReserve.InvalidBondReserveMinPeriod.selector);
        reserve.setBondReserveMinPeriod(0);
    }

    function test_getBondReserveInfo_default() public view {
        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            0
        );
        assertEq(info.amount, 0);
        assertEq(info.removableAt, 0);
    }

    function test_setBondReserve() public {
        uint256 noId = 0;
        uint256 amount = 1 ether;
        uint256 minPeriod = reserve.getBondReserveMinPeriod();
        uint256 expectedRemovableAt = block.timestamp + minPeriod;

        vm.expectEmit(address(reserve));
        emit IBondReserve.BondReserveChanged(noId, amount, expectedRemovableAt);

        reserve.setBondReserve(noId, amount);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, amount);
        assertEq(info.removableAt, expectedRemovableAt);
    }

    function test_setBondReserve_WhenSecondIncrease() public {
        uint256 noId = 0;
        reserve.setBondReserve(noId, 1 ether);
        IBondReserve.BondReserveInfo memory beforeInfo = reserve
            .getBondReserveInfo(noId);

        uint256 delay = 1 hours;
        vm.warp(block.timestamp + delay);
        reserve.setBondReserve(noId, reserve.getReservedBond(noId) + 1 ether);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, 2 ether);
        assertEq(info.removableAt, beforeInfo.removableAt + delay);
    }

    function test_setBondReserve_WhenSecondIncreaseOnRemovableAt() public {
        uint256 noId = 0;
        reserve.setBondReserve(noId, 1 ether);
        IBondReserve.BondReserveInfo memory beforeInfo = reserve
            .getBondReserveInfo(noId);

        vm.warp(uint256(beforeInfo.removableAt));
        uint256 minPeriod = reserve.getBondReserveMinPeriod();
        reserve.setBondReserve(noId, reserve.getReservedBond(noId) + 1 ether);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, 2 ether);
        assertEq(info.removableAt, uint256(beforeInfo.removableAt) + minPeriod);
    }

    function test_setBondReserve_WhenSecondIncreaseAfterExpired() public {
        uint256 noId = 0;
        reserve.setBondReserve(noId, 1 ether);
        IBondReserve.BondReserveInfo memory beforeInfo = reserve
            .getBondReserveInfo(noId);

        vm.warp(uint256(beforeInfo.removableAt) + 1);
        uint256 minPeriod = reserve.getBondReserveMinPeriod();
        uint256 expectedRemovableAt = block.timestamp + minPeriod;
        reserve.setBondReserve(noId, reserve.getReservedBond(noId) + 1 ether);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, 2 ether);
        assertEq(info.removableAt, expectedRemovableAt);
    }

    function test_setBondReserve_RevertWhen_AmountExceedsMax() public {
        uint256 tooBig = uint256(type(uint128).max) + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                SafeCast.SafeCastOverflowedUintDowncast.selector,
                128,
                tooBig
            )
        );
        reserve.setBondReserve(0, tooBig);
    }

    function test_setBondReserve_WhenFullReduce() public {
        uint256 noId = 0;
        uint256 amount = 100 ether;
        reserve.setBondReserve(noId, amount);

        vm.expectEmit(address(reserve));
        emit IBondReserve.BondReserveRemoved(noId);

        reserve.setBondReserve(noId, 0);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, 0);
        assertEq(info.removableAt, 0);
    }

    function test_setBondReserve_WhenPartialReduce() public {
        uint256 noId = 0;
        reserve.setBondReserve(noId, 100 ether);
        IBondReserve.BondReserveInfo memory beforeInfo = reserve
            .getBondReserveInfo(noId);

        uint256 rest = 90 ether;

        vm.warp(block.timestamp + 1 seconds);
        vm.expectEmit(address(reserve));
        emit IBondReserve.BondReserveChanged(
            noId,
            rest,
            beforeInfo.removableAt
        );

        reserve.setBondReserve(noId, rest);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, rest);
        assertEq(info.removableAt, beforeInfo.removableAt);
    }

    function test_setBondReserve_NoOpWhenZeroReduce() public {
        uint256 noId = 0;
        reserve.setBondReserve(noId, 0);
        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, 0);
        assertEq(info.removableAt, 0);
    }

    function test_setBondReserve_NoOpWhenSameAmount() public {
        uint256 noId = 0;
        reserve.setBondReserve(noId, 3 ether);
        IBondReserve.BondReserveInfo memory beforeInfo = reserve
            .getBondReserveInfo(noId);

        vm.warp(block.timestamp + 1 days);
        reserve.setBondReserve(noId, 3 ether);

        IBondReserve.BondReserveInfo memory info = reserve.getBondReserveInfo(
            noId
        );
        assertEq(info.amount, beforeInfo.amount);
        assertEq(info.removableAt, beforeInfo.removableAt);
    }
}
