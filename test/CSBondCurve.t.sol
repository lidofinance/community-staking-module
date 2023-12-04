// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSBondCurve } from "../src/CSBondCurve.sol";

contract CSBondCurveTestable is CSBondCurve {
    constructor(uint256[] memory bondCurve) CSBondCurve(bondCurve) {}

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

    function test_setBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 16 ether;
        _bondCurve[1] = 32 ether;

        bondCurve.setBondCurve(_bondCurve);

        assertEq(bondCurve.bondCurve(0), 16 ether);
        assertEq(bondCurve.bondCurve(1), 32 ether);
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
        vm.expectRevert(CSBondCurve.InvalidBondCurveValues.selector);

        uint256[] memory _bondCurve = new uint256[](1);
        _bondCurve[0] = 0 ether;

        bondCurve.setBondCurve(_bondCurve);
    }

    function test_getKeysCountByBondAmount() public {
        assertEq(bondCurve.getKeysCountByBondAmount(0), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3.90 ether), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(17 ether), 11);
        assertEq(bondCurve.getKeysCountByBondAmount(17.40 ether), 12);
    }

    function test_getBondAmountByKeysCount() public {
        assertEq(bondCurve.getBondAmountByKeysCount(0), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2), 3.90 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(11), 16.40 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(12), 17.40 ether);
    }
}

contract CSBondCurveWithMultiplierTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        uint256[] memory simple = new uint256[](1);
        simple[0] = 2 ether;
        bondCurve = new CSBondCurveTestable(simple);
    }

    function test_setBondMultiplier() public {
        assertEq(bondCurve.getBondMultiplier(0), 10000);

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
        assertEq(
            bondCurve.getKeysCountByBondAmount({ amount: 0, multiplier: 5000 }),
            0
        );
        assertEq(
            bondCurve.getKeysCountByBondAmount({
                amount: 1 ether,
                multiplier: 5000
            }),
            1
        );
        assertEq(
            bondCurve.getKeysCountByBondAmount({
                amount: 2.99 ether,
                multiplier: 5000
            }),
            2
        );

        assertEq(
            bondCurve.getKeysCountByBondAmount({ amount: 0, multiplier: 9000 }),
            0
        );
        assertEq(
            bondCurve.getKeysCountByBondAmount({
                amount: 1.8 ether,
                multiplier: 9000
            }),
            1
        );
        assertEq(
            bondCurve.getKeysCountByBondAmount({
                amount: 5.39 ether,
                multiplier: 9000
            }),
            2
        );
    }

    function test_getBondAmountByKeysCount() public {
        assertEq(
            bondCurve.getBondAmountByKeysCount({ keys: 0, multiplier: 5000 }),
            0
        );
        assertEq(
            bondCurve.getBondAmountByKeysCount({ keys: 1, multiplier: 5000 }),
            1 ether
        );
        assertEq(
            bondCurve.getBondAmountByKeysCount({ keys: 2, multiplier: 5000 }),
            2 ether
        );

        assertEq(
            bondCurve.getBondAmountByKeysCount({ keys: 0, multiplier: 9000 }),
            0
        );
        assertEq(
            bondCurve.getBondAmountByKeysCount({ keys: 1, multiplier: 9000 }),
            1.8 ether
        );
        assertEq(
            bondCurve.getBondAmountByKeysCount({ keys: 2, multiplier: 9000 }),
            3.6 ether
        );
    }
}
