// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSBondCurve, CSBondCurveBase } from "../src/CSBondCurve.sol";

contract CSBondCurveTestable is CSBondCurve {
    constructor(uint256[] memory bondCurve) CSBondCurve(bondCurve) {}

    function addBondCurve(
        uint256[] memory _bondCurve
    ) external returns (uint256) {
        return _addBondCurve(_bondCurve);
    }

    function setDefaultBondCurve(uint256 curveId) external {
        _setDefaultBondCurve(curveId);
    }

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external {
        _setBondCurve(nodeOperatorId, curveId);
    }

    function resetBondCurve(uint256 nodeOperatorId) external {
        _resetBondCurve(nodeOperatorId);
    }
}

contract CSBondCurveTest is Test, CSBondCurveBase {
    // todo: add gas-cost test for _searchKeysCount

    CSBondCurveTestable public bondCurve;

    function setUp() public {
        uint256[] memory _bondCurve = new uint256[](3);
        _bondCurve[0] = 2 ether;
        _bondCurve[1] = 4 ether;
        _bondCurve[2] = 5 ether;
        bondCurve = new CSBondCurveTestable(_bondCurve);
    }

    function test_addBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        vm.expectEmit(true, true, true, true, address(bondCurve));
        emit BondCurveAdded(_bondCurve);

        uint256 addedId = bondCurve.addBondCurve(_bondCurve);

        CSBondCurve.BondCurve memory added = bondCurve.getCurveInfo(addedId);

        assertEq(added.id, 2);
        assertEq(added.points.length, 2);
        assertEq(added.points[0], 16 ether);
        assertEq(added.points[1], 32 ether);
        assertEq(added.trend, 16 ether);
    }

    function test_addBondCurve_RevertWhen_LessThanMinBondCurveLength() public {
        vm.expectRevert(InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new uint256[](0));
    }

    function test_addBondCurve_RevertWhen_MoreThanMaxBondCurveLength() public {
        vm.expectRevert(InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new uint256[](21));
    }

    function test_addBondCurve_RevertWhen_ZeroValue() public {
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 0 ether;

        vm.expectRevert(InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(curvePoints);
    }

    function test_setDefaultBondCurve() public {
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 16 ether;
        uint256 addedId = bondCurve.addBondCurve(curvePoints);
        CSBondCurve.BondCurve memory added = bondCurve.getCurveInfo(addedId);

        vm.expectEmit(true, true, true, true, address(bondCurve));
        emit DefaultBondCurveChanged(added.id);

        uint256 idBefore = bondCurve.defaultBondCurveId();
        bondCurve.setDefaultBondCurve(added.id);
        uint256 idAfter = bondCurve.defaultBondCurveId();

        assertNotEq(idBefore, idAfter);
        assertEq(idAfter, added.id);
    }

    function test_setDefaultBondCurve_RevertWhen_CurveIdIsZero() public {
        vm.expectRevert(InvalidBondCurveId.selector);
        bondCurve.setDefaultBondCurve(0);
    }

    function test_setDefaultBondCurve_RevertWhen_NoExistingCurveId() public {
        vm.expectRevert(InvalidBondCurveId.selector);
        bondCurve.setDefaultBondCurve(100500);
    }

    function test_setDefaultBondCurve_RevertWhen_CurveIdIsTheSame() public {
        uint256 id = bondCurve.defaultBondCurveId();
        vm.expectRevert(InvalidBondCurveId.selector);
        bondCurve.setDefaultBondCurve(id);
    }

    function test_setBondCurve() public {
        uint256 noId = 0;
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 16 ether;
        uint256 addedId = bondCurve.addBondCurve(curvePoints);

        CSBondCurve.BondCurve memory added = bondCurve.getCurveInfo(addedId);
        bondCurve.setBondCurve(noId, added.id);
        CSBondCurve.BondCurve memory set = bondCurve.getBondCurve(noId);

        assertEq(set.id, added.id);
    }

    function test_getBondCurve_default() public {
        CSBondCurve.BondCurve memory curve = bondCurve.getBondCurve(100500);
        assertEq(curve.id, bondCurve.defaultBondCurveId());
    }

    function test_resetBondCurve() public {
        uint256 noId = 0;
        uint256[] memory curvePoints = new uint256[](1);
        curvePoints[0] = 16 ether;
        uint256 addedId = bondCurve.addBondCurve(curvePoints);
        CSBondCurve.BondCurve memory added = bondCurve.getCurveInfo(addedId);
        bondCurve.setBondCurve(noId, added.id);

        vm.expectEmit(true, true, true, true, address(bondCurve));
        emit BondCurveChanged(noId, bondCurve.defaultBondCurveId());

        bondCurve.resetBondCurve(noId);
        CSBondCurve.BondCurve memory reset = bondCurve.getBondCurve(noId);
        assertEq(reset.id, bondCurve.defaultBondCurveId());
    }

    function test_getKeysCountByBondAmount_default() public {
        assertEq(bondCurve.getKeysCountByBondAmount(0), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.9 ether), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2.1 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(5.1 ether), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(6 ether), 4);
    }

    function test_getBondAmountByKeysCount_default() public {
        assertEq(bondCurve.getBondAmountByKeysCount(0), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2), 4 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3), 5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4), 6 ether);
    }

    function test_getKeysCountByCurveValue_individual() public {
        CSBondCurve.BondCurve memory curve;
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

    function test_getBondAmountByKeysCount_individual() public {
        CSBondCurve.BondCurve memory curve;
        uint256[] memory points = new uint256[](2);
        points[0] = 1 ether;
        points[1] = 2 ether;
        curve.points = points;
        curve.trend = 1 ether;

        assertEq(bondCurve.getBondAmountByKeysCount(0, curve), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curve), 1 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curve), 2 ether);

        points[0] = 1.8 ether;
        points[1] = 3.6 ether;
        curve.points = points;
        curve.trend = 1.8 ether;

        assertEq(bondCurve.getBondAmountByKeysCount(0, curve), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curve), 1.8 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curve), 3.6 ether);
    }
}
