// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSBondCurve } from "../src/abstract/CSBondCurve.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

contract CSBondCurveTestable is CSBondCurve(10) {
    function initialize(uint256[] calldata bondCurve) public initializer {
        __CSBondCurve_init(bondCurve);
    }

    function addBondCurve(
        uint256[] calldata _bondCurve
    ) external returns (uint256) {
        return _addBondCurve(_bondCurve);
    }

    function updateBondCurve(
        uint256 curveId,
        uint256[] calldata _bondCurve
    ) external {
        _updateBondCurve(curveId, _bondCurve);
    }

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external {
        _setBondCurve(nodeOperatorId, curveId);
    }

    function resetBondCurve(uint256 nodeOperatorId) external {
        _resetBondCurve(nodeOperatorId);
    }
}

contract CSBondCurveInitTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        bondCurve = new CSBondCurveTestable();
    }

    function test_initialize_revertWhen_InvalidInitialisationCurveId() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        bondCurve.addBondCurve(_bondCurve);

        vm.expectRevert(ICSBondCurve.InvalidInitialisationCurveId.selector);
        bondCurve.initialize(_bondCurve);
    }
}

contract CSBondCurveTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        uint256[] memory _bondCurve = new uint256[](3);
        _bondCurve[0] = 2 ether;
        _bondCurve[1] = 4 ether;
        _bondCurve[2] = 5 ether;
        bondCurve = new CSBondCurveTestable();
        bondCurve.initialize(_bondCurve);
    }

    function test_getCurveInfo() public view {
        ICSBondCurve.BondCurve memory curve = bondCurve.getCurveInfo(0);

        assertEq(curve.points.length, 3);
        assertEq(curve.points[0], 2 ether);
        assertEq(curve.points[1], 4 ether);
        assertEq(curve.points[2], 5 ether);
        assertEq(curve.trend, 1 ether);
    }

    function test_getCurveInfo_RevertWhen_InvalidBondCurveId() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.getCurveInfo(1337);
    }

    function test_addBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveAdded(_bondCurve);

        uint256 addedId = bondCurve.addBondCurve(_bondCurve);

        ICSBondCurve.BondCurve memory added = bondCurve.getCurveInfo(addedId);

        assertEq(addedId, 1);
        assertEq(added.points.length, 2);
        assertEq(added.points[0], 16 ether);
        assertEq(added.points[1], 32 ether);
        assertEq(added.trend, 16 ether);
    }

    function test_addBondCurve_RevertWhen_LessThanMinBondCurveLength() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new uint256[](0));
    }

    function test_addBondCurve_RevertWhen_MoreThanMaxBondCurveLength() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new uint256[](21));
    }

    function test_addBondCurve_RevertWhen_ZeroValue() public {
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 0 ether;

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(curvePoints);
    }

    function test_addBondCurve_RevertWhen_NextValueIsLessThanPrevious() public {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 16 ether;
        curvePoints[1] = 8 ether;

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(curvePoints);
    }

    function test_updateBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        uint256 toUpdateId = 0;

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveUpdated(toUpdateId, _bondCurve);

        bondCurve.updateBondCurve(toUpdateId, _bondCurve);

        ICSBondCurve.BondCurve memory updated = bondCurve.getCurveInfo(
            toUpdateId
        );

        assertEq(updated.points.length, 2);
        assertEq(updated.points[0], 16 ether);
        assertEq(updated.points[1], 32 ether);
        assertEq(updated.trend, 16 ether);
    }

    function test_updateBondCurve_RevertWhen_LessThanMinBondCurveLength()
        public
    {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.updateBondCurve(0, new uint256[](0));
    }

    function test_updateBondCurve_RevertWhen_MoreThanMaxBondCurveLength()
        public
    {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.updateBondCurve(0, new uint256[](21));
    }

    function test_updateBondCurve_RevertWhen_ZeroValue() public {
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 0 ether;

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.updateBondCurve(0, curvePoints);
    }

    function test_updateBondCurve_RevertWhen_NextValueIsLessThanPrevious()
        public
    {
        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 16 ether;
        curvePoints[1] = 8 ether;

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.updateBondCurve(0, curvePoints);
    }

    function test_updateBondCurve_RevertWhen_InvalidBondCurveId() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.updateBondCurve(1, _bondCurve);
    }

    function test_setBondCurve() public {
        uint256 noId = 0;
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 16 ether;
        uint256 addedId = bondCurve.addBondCurve(curvePoints);

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveSet(noId, addedId);
        bondCurve.setBondCurve(noId, addedId);

        assertEq(bondCurve.getBondCurveId(noId), addedId);
    }

    function test_setBondCurve_RevertWhen_NoExistingCurveId() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.setBondCurve(0, 100500);
    }

    function test_resetBondCurve() public {
        uint256 noId = 0;
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 16 ether;
        uint256 addedId = bondCurve.addBondCurve(curvePoints);
        bondCurve.setBondCurve(noId, addedId);

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveSet(noId, 0);

        bondCurve.resetBondCurve(noId);
        assertEq(bondCurve.getBondCurveId(noId), 0);
    }

    function test_resetBondCurve_nothingToChange() public {
        uint256 noId = 0;
        assertEq(bondCurve.getBondCurveId(noId), 0);

        vm.recordLogs();
        bondCurve.resetBondCurve(noId);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
        assertEq(bondCurve.getBondCurveId(noId), 0);
    }

    function test_curveExists_curveExists() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        uint256 addedId = bondCurve.addBondCurve(_bondCurve);

        assertTrue(bondCurve.curveExists(addedId));
    }

    function test_curveExists_curveNotExists() public view {
        assertFalse(bondCurve.curveExists(1));
    }

    function test_getKeysCountByBondAmount_default() public view {
        assertEq(bondCurve.getKeysCountByBondAmount(0, 0), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.9 ether, 0), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, 0), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2.1 ether, 0), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether, 0), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether, 0), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(5.1 ether, 0), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(6 ether, 0), 4);
    }

    function test_getKeysCountByBondAmount_noOverflowWithMaxUint() public view {
        ICSBondCurve.BondCurve memory curve = bondCurve.getBondCurve(0);
        uint256 len = curve.points.length;
        uint256 maxCurveAmount = curve.points[len - 1];
        uint256 amount = type(uint256).max;

        assertEq(
            bondCurve.getKeysCountByBondAmount(amount, 0),
            len + (amount - maxCurveAmount) / curve.trend
        );
    }

    function test_getKeysCountByBondAmount_noOverflowWithMinUint() public {
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 1 wei;
        uint256 curveId = bondCurve.addBondCurve(curvePoints);

        uint256 amount = type(uint256).max;

        assertEq(
            bondCurve.getKeysCountByBondAmount(amount, curveId),
            type(uint256).max
        );
    }

    function test_getBondAmountByKeysCount_default() public view {
        assertEq(bondCurve.getBondAmountByKeysCount(0, 0), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, 0), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, 0), 4 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, 0), 5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4, 0), 6 ether);
    }

    function test_getKeysCountByCurveValue_individual() public view {
        ICSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](2);
        points[0] = 1 ether;
        points[1] = 2 ether;
        curve.points = points;
        curve.trend = 1 ether;

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curve), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curve), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curve), 2);

        points[0] = 1.8 ether;
        points[1] = 3.6 ether;
        curve.points = points;
        curve.trend = 1.8 ether;

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curve), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.8 ether, curve), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(5.39 ether, curve), 2);
    }

    function test_getKeysCountByBondAmount_singlePointCurve() public view {
        ICSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](1);
        points[0] = 2 ether;
        curve.points = points;
        curve.trend = 2 ether;

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curve), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curve), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curve), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether, curve), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether, curve), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether, curve), 2);
    }

    function test_getKeysCountByBondAmount_twoPointsCurve() public view {
        ICSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](2);
        points[0] = 2 ether;
        points[1] = 3.5 ether;
        curve.points = points;
        curve.trend = 1.5 ether;

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curve), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curve), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curve), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether, curve), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3.5 ether, curve), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether, curve), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether, curve), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(6 ether, curve), 3);
    }

    function test_getKeysCountByBondAmount_tenPointsCurve() public view {
        ICSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](10);
        points[0] = 1 ether;
        points[1] = 2 ether;
        points[2] = 3 ether;
        points[3] = 4 ether;
        points[4] = 5 ether;
        points[5] = 6 ether;
        points[6] = 7 ether;
        points[7] = 8 ether;
        points[8] = 9 ether;
        points[9] = 10 ether;
        curve.points = points;
        curve.trend = 1 ether;

        for (uint256 i = 0; i < 10; i++) {
            assertEq(bondCurve.getKeysCountByBondAmount(i * 1 ether, curve), i);
            assertEq(
                bondCurve.getKeysCountByBondAmount(
                    i * 1 ether + 0.5 ether,
                    curve
                ),
                i
            );
        }
    }

    function test_getBondAmountByKeysCount_individual() public view {
        ICSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](2);
        points[0] = 1 ether;
        points[1] = 2 ether;
        curve.points = points;
        curve.trend = 1 ether;

        assertEq(bondCurve.getBondAmountByKeysCount(0, curve), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curve), 1 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curve), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curve), 3 ether);

        points[0] = 1.8 ether;
        points[1] = 3.6 ether;
        curve.points = points;
        curve.trend = 1.8 ether;

        assertEq(bondCurve.getBondAmountByKeysCount(0, curve), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curve), 1.8 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curve), 3.6 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curve), 5.4 ether);
    }

    function test_getBondAmountByKeysCount_bigCurve() public view {
        ICSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](4);
        points[0] = 1.5 ether;
        points[1] = 2.5 ether;
        points[2] = 3.5 ether;
        points[3] = 4 ether;
        curve.points = points;
        curve.trend = 0.5 ether;

        assertEq(bondCurve.getBondAmountByKeysCount(0, curve), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curve), 1.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curve), 2.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curve), 3.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4, curve), 4 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(16, curve), 10 ether);
    }
}
