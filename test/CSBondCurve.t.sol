// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSBondCurve, CSBondCurveBase } from "../src/CSBondCurve.sol";

contract CSBondCurveTestable is CSBondCurve {
    constructor(uint256[] memory bondCurve) CSBondCurve(bondCurve) {}

    function getBondCurveTrend() external view returns (uint256) {
        return _bondCurveTrend;
    }

    function setBondCurve(uint256[] memory bondCurve) external {
        _setBondCurve(bondCurve);
    }

    function setBondMultiplier(
        uint256 nodeOperatorId,
        uint256 basisPoints
    ) external {
        _setBondMultiplier(nodeOperatorId, basisPoints);
    }

    function getKeysCountByBondAmount(
        uint256 amount
    ) external view returns (uint256) {
        return _getKeysCountByBondAmount(amount);
    }

    function getBondAmountByKeysCount(
        uint256 keys
    ) external view returns (uint256) {
        return _getBondAmountByKeysCount(keys);
    }

    function getKeysCountByBondAmount(
        uint256 amount,
        uint256 multiplier
    ) external view returns (uint256) {
        return _getKeysCountByBondAmount(amount, multiplier);
    }

    function getBondAmountByKeysCount(
        uint256 keys,
        uint256 multiplier
    ) external view returns (uint256) {
        return _getBondAmountByKeysCount(keys, multiplier);
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

    function test_setBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        vm.expectEmit(true, true, true, true, address(bondCurve));
        emit BondCurveChanged(_bondCurve);

        bondCurve.setBondCurve(_bondCurve);

        assertEq(bondCurve.bondCurve(0), 16 ether);
        assertEq(bondCurve.bondCurve(1), 32 ether);
        assertEq(bondCurve.getBondCurveTrend(), 16 ether);
    }

    function test_setBondCurve_RevertWhen_LessThanMinBondCurveLength() public {
        vm.expectRevert(CSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.setBondCurve(new uint256[](0));
    }

    function test_setBondCurve_RevertWhen_MoreThanMaxBondCurveLength() public {
        vm.expectRevert(CSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.setBondCurve(new uint256[](21));
    }

    function test_setBondCurve_RevertWhen_ZeroValue() public {
        uint256[] memory _bondCurve = new uint256[](1);
        _bondCurve[0] = 0 ether;

        vm.expectRevert(CSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.setBondCurve(_bondCurve);
    }

    function test_getKeysCountByBondAmount() public {
        assertEq(bondCurve.getKeysCountByBondAmount(0), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.9 ether), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2.1 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(5.1 ether), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(6 ether), 4);
    }

    function test_getBondAmountByKeysCount() public {
        assertEq(bondCurve.getBondAmountByKeysCount(0), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2), 4 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3), 5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4), 6 ether);
    }
}

contract CSBondCurveWithMultiplierTest is Test, CSBondCurveBase {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        uint256[] memory simple = new uint256[](1);
        simple[0] = 2 ether;
        bondCurve = new CSBondCurveTestable(simple);
    }

    function test_setBondMultiplier() public {
        assertEq(bondCurve.getBondMultiplier(0), 10000);

        vm.expectEmit(true, true, true, true, address(bondCurve));
        emit BondMultiplierChanged(0, 5000);

        bondCurve.setBondMultiplier(0, 5000);
        assertEq(bondCurve.getBondMultiplier(0), 5000);

        bondCurve.setBondMultiplier(0, 10000);
        assertEq(bondCurve.getBondMultiplier(0), 10000);
    }

    function test_setBondMultiplier_RevertWhen_LessThanMin() public {
        vm.expectRevert(CSBondCurve.InvalidMultiplier.selector);
        bondCurve.setBondMultiplier(0, 4999);
    }

    function test_setBondMultiplier_RevertWhen_MoreThanMax() public {
        vm.expectRevert(CSBondCurve.InvalidMultiplier.selector);
        bondCurve.setBondMultiplier(0, 10001);
    }

    function test_getKeysCountByCurveValue() public {
        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, 5000), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, 5000), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, 5000), 2);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, 9000), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.8 ether, 9000), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(5.39 ether, 9000), 2);
    }

    function test_getBondAmountByKeysCount() public {
        assertEq(bondCurve.getBondAmountByKeysCount(0, 5000), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, 5000), 1 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, 5000), 2 ether);

        assertEq(bondCurve.getBondAmountByKeysCount(0, 9000), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, 9000), 1.8 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, 9000), 3.6 ether);
    }
}
