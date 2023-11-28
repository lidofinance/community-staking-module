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

    function getKeysCountByCurveValue(
        uint256 amount
    ) external view returns (uint256) {
        return _getKeysCountByCurveValue(amount);
    }

    function getCurveValueByKeysCount(
        uint256 keysCount
    ) external view returns (uint256) {
        return _getCurveValueByKeysCount(keysCount);
    }

    function getKeysCountByCurveValue(
        uint256 nodeOperatorId,
        uint256 amount
    ) external view returns (uint256) {
        return _getKeysCountByCurveValue(nodeOperatorId, amount);
    }

    function getCurveValueByKeysCount(
        uint256 nodeOperatorId,
        uint256 keysCount
    ) external view returns (uint256) {
        return _getCurveValueByKeysCount(nodeOperatorId, keysCount);
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

    function test_getKeysCountByCurveValue() public {
        assertEq(bondCurve.getKeysCountByCurveValue(0), 0);
        assertEq(bondCurve.getKeysCountByCurveValue(2 ether), 1);
        assertEq(bondCurve.getKeysCountByCurveValue(3 ether), 1);
        assertEq(bondCurve.getKeysCountByCurveValue(3.90 ether), 2);
        assertEq(bondCurve.getKeysCountByCurveValue(5.70 ether), 3);
        assertEq(bondCurve.getKeysCountByCurveValue(7.40 ether), 4);
        assertEq(bondCurve.getKeysCountByCurveValue(9.00 ether), 5);
        assertEq(bondCurve.getKeysCountByCurveValue(10.50 ether), 6);
        assertEq(bondCurve.getKeysCountByCurveValue(11.90 ether), 7);
        assertEq(bondCurve.getKeysCountByCurveValue(13.10 ether), 8);
        assertEq(bondCurve.getKeysCountByCurveValue(14.30 ether), 9);
        assertEq(bondCurve.getKeysCountByCurveValue(15.40 ether), 10);
        assertEq(bondCurve.getKeysCountByCurveValue(16.40 ether), 11);
        assertEq(bondCurve.getKeysCountByCurveValue(17.40 ether), 12);

        bondCurve.setBondMultiplier(0, 5000);

        assertEq(bondCurve.getKeysCountByCurveValue(0, 0), 0);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 2 ether), 2);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 3 ether), 3);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 3.90 ether), 4);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 5.70 ether), 6);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 7.40 ether), 9);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 9.00 ether), 12);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 10.50 ether), 15);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 11.90 ether), 18);
        assertEq(bondCurve.getKeysCountByCurveValue(0, 13.10 ether), 20);
    }

    function test_getCurveValueByKeysCount() public {
        assertEq(bondCurve.getCurveValueByKeysCount(0), 0);
        assertEq(bondCurve.getCurveValueByKeysCount(1), 2 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(2), 3.90 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(3), 5.70 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(4), 7.40 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(5), 9.00 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(6), 10.50 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(7), 11.90 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(8), 13.10 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(9), 14.30 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(10), 15.40 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(11), 16.40 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(12), 17.40 ether);

        bondCurve.setBondMultiplier(0, 5000);

        assertEq(bondCurve.getCurveValueByKeysCount(0, 0), 0);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 1), 1 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 2), 1.95 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 3), 2.85 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 4), 3.70 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 5), 4.50 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 6), 5.25 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 7), 5.95 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 8), 6.55 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 9), 7.15 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 10), 7.7 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 11), 8.20 ether);
        assertEq(bondCurve.getCurveValueByKeysCount(0, 12), 8.70 ether);
    }
}
