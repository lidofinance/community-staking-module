// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSBondCurve } from "../src/CSBondCurve.sol";

contract CSBondCurveTestable is CSBondCurve {
    constructor(uint256[] memory _bondCurve) CSBondCurve(_bondCurve) {}

    function setBondCurve(uint256[] memory _bondCurve) external {
        _setBondCurve(_bondCurve);
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
        uint256 keysCount
    ) external view returns (uint256) {
        return _getBondAmountByKeysCount(keysCount);
    }

    function getKeysCountByBondAmount(
        uint256 nodeOperatorId,
        uint256 amount
    ) external view returns (uint256) {
        return _getKeysCountByBondAmount(nodeOperatorId, amount);
    }

    function getBondAmountByKeysCount(
        uint256 nodeOperatorId,
        uint256 keysCount
    ) external view returns (uint256) {
        return _getBondAmountByKeysCount(nodeOperatorId, keysCount);
    }
}

contract CSBondCurveTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        uint256[] memory _bondCurve = new uint256[](11);
        _bondCurve[0] = 2 ether;
        _bondCurve[1] = 3.90 ether; // 1.9
        _bondCurve[2] = 5.70 ether; // 1.8
        _bondCurve[3] = 7.40 ether; // 1.7
        _bondCurve[4] = 9.00 ether; // 1.6
        _bondCurve[5] = 10.50 ether; // 1.5
        _bondCurve[6] = 11.90 ether; // 1.4
        _bondCurve[7] = 13.10 ether; // 1.3
        _bondCurve[8] = 14.30 ether; // 1.2
        _bondCurve[9] = 15.40 ether; // 1.1
        _bondCurve[10] = 16.40 ether; // 1.0
        bondCurve = new CSBondCurveTestable(_bondCurve);
    }

    function test_setBondCurve_RevertWhen_LessThanMinBondCurveLength() public {
        uint256[] memory _bondCurve = new uint256[](0);

        vm.expectRevert(CSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.setBondCurve(_bondCurve);
    }

    function test_setBondCurve_RevertWhen_MoreThanMaxBondCurveLength() public {
        uint256[] memory _bondCurve = new uint256[](21);
        _bondCurve = new uint256[](21);
        for (uint256 i = 0; i < 21; i++) {
            _bondCurve[i] = i;
        }

        vm.expectRevert(CSBondCurve.InvalidBondCurveLength.selector);

        bondCurve.setBondCurve(_bondCurve);
    }

    function test_setBondMultiplier_RevertWhen_LessThanMin() public {
        vm.expectRevert(CSBondCurve.InvalidMultiplier.selector);

        bondCurve.setBondMultiplier(0, 4999);
    }

    function test_setBondMultiplier_RevertWhen_MoreThanMax() public {
        vm.expectRevert(CSBondCurve.InvalidMultiplier.selector);

        bondCurve.setBondMultiplier(0, 10001);
    }

    function test_getKeysCountByBondAmount() public {
        assertEq(bondCurve.getKeysCountByBondAmount(0), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3.90 ether), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5.70 ether), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(7.40 ether), 4);
        assertEq(bondCurve.getKeysCountByBondAmount(9.00 ether), 5);
        assertEq(bondCurve.getKeysCountByBondAmount(10.50 ether), 6);
        assertEq(bondCurve.getKeysCountByBondAmount(11.90 ether), 7);
        assertEq(bondCurve.getKeysCountByBondAmount(13.10 ether), 8);
        assertEq(bondCurve.getKeysCountByBondAmount(14.30 ether), 9);
        assertEq(bondCurve.getKeysCountByBondAmount(15.40 ether), 10);
        assertEq(bondCurve.getKeysCountByBondAmount(16.40 ether), 11);
        assertEq(bondCurve.getKeysCountByBondAmount(17.40 ether), 12);
    }

    function test_getKeysCountByCurveValue_WithMultiplier() public {
        assertEq(bondCurve.getKeysCountByBondAmount(0, 5000), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, 5000), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether, 5000), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(3.90 ether, 5000), 4);
        assertEq(bondCurve.getKeysCountByBondAmount(5.70 ether, 5000), 6);
        assertEq(bondCurve.getKeysCountByBondAmount(7.40 ether, 5000), 9);
        assertEq(bondCurve.getKeysCountByBondAmount(9.00 ether, 5000), 12);
        assertEq(bondCurve.getKeysCountByBondAmount(10.50 ether, 5000), 15);
        assertEq(bondCurve.getKeysCountByBondAmount(11.90 ether, 5000), 18);
        assertEq(bondCurve.getKeysCountByBondAmount(13.10 ether, 5000), 20);
    }

    function test_getBondAmountByKeysCount() public {
        assertEq(bondCurve.getBondAmountByKeysCount(0), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2), 3.90 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3), 5.70 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4), 7.40 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(5), 9.00 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(6), 10.50 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(7), 11.90 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(8), 13.10 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(9), 14.30 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(10), 15.40 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(11), 16.40 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(12), 17.40 ether);
    }

    function test_getBondAmountByKeysCount_WithMultiplier() public {
        assertEq(bondCurve.getBondAmountByKeysCount(0, 5000), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, 5000), 1 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, 5000), 1.95 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, 5000), 2.85 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4, 5000), 3.70 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(5, 5000), 4.50 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(6, 5000), 5.25 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(7, 5000), 5.95 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(8, 5000), 6.55 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(9, 5000), 7.15 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(10, 5000), 7.7 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(11, 5000), 8.20 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(12, 5000), 8.70 ether);
    }
}
