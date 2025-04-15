// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CSBondCurve } from "../src/abstract/CSBondCurve.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

import { console } from "forge-std/console.sol";

contract CSBondCurveTestable is CSBondCurve {
    constructor(uint256 maxCurveLength) CSBondCurve(maxCurveLength) {}

    function initialize(uint256[2][] calldata bondCurve) public initializer {
        __CSBondCurve_init(bondCurve);
    }

    function addBondCurve(
        uint256[2][] calldata _bondCurve
    ) external returns (uint256) {
        return _addBondCurve(_bondCurve);
    }

    function updateBondCurve(
        uint256 curveId,
        uint256[2][] calldata _bondCurve
    ) external {
        _updateBondCurve(curveId, _bondCurve);
    }

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external {
        _setBondCurve(nodeOperatorId, curveId);
    }
}

contract CSBondCurveInitTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        bondCurve = new CSBondCurveTestable(10);
    }

    function test_initialize_revertWhen_InvalidInitialisationCurveId() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 2 ether];

        bondCurve.addBondCurve(_bondCurve);

        vm.expectRevert(ICSBondCurve.InvalidInitialisationCurveId.selector);
        bondCurve.initialize(_bondCurve);
    }
}

contract CSBondCurveTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        uint256[2][] memory _bondCurve = new uint256[2][](2);
        _bondCurve[0] = [uint256(1), 2 ether];
        _bondCurve[1] = [uint256(3), 1 ether];
        bondCurve = new CSBondCurveTestable(10);
        vm.startSnapshotGas("bondCurve.initialize");
        bondCurve.initialize(_bondCurve);
        vm.stopSnapshotGas();
    }

    function test_getCurveInfo() public view {
        ICSBondCurve.BondCurveInterval[] memory curve = bondCurve.getCurveInfo(
            0
        );

        assertEq(curve.length, 2);
        assertEq(curve[0].fromKeysCount, 1);
        assertEq(curve[0].fromBond, 2 ether);
        assertEq(curve[0].trend, 2 ether);
        assertEq(curve[1].fromKeysCount, 3);
        assertEq(curve[1].fromBond, 5 ether);
        assertEq(curve[1].trend, 1 ether);
    }

    function test_getCurveInfo_RevertWhen_InvalidBondCurveId() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.getCurveInfo(1337);
    }

    function test_addBondCurve() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 16 ether];

        uint256 curvesCount = bondCurve.getCurvesCount();

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveAdded(curvesCount, _bondCurve);

        uint256 addedId = bondCurve.addBondCurve(_bondCurve);

        ICSBondCurve.BondCurveInterval[] memory added = bondCurve.getCurveInfo(
            addedId
        );

        assertEq(addedId, 1);
        assertEq(added.length, 1);
        assertEq(added[0].fromKeysCount, 1);
        assertEq(added[0].fromBond, 16 ether);
        assertEq(added[0].trend, 16 ether);
    }

    function test_addBondCurve_SeveralIntervals() public {
        uint256[2][] memory _bondCurve = new uint256[2][](4);
        _bondCurve[0] = [uint256(1), 16 ether];
        _bondCurve[1] = [uint256(10), 1 ether];
        _bondCurve[2] = [uint256(33), 0.5 ether];
        _bondCurve[3] = [uint256(100), 10 ether];

        uint256 addedId = bondCurve.addBondCurve(_bondCurve);

        ICSBondCurve.BondCurveInterval[] memory added = bondCurve.getCurveInfo(
            addedId
        );

        assertEq(addedId, 1);
        assertEq(added.length, 4);
        assertEq(added[0].fromKeysCount, 1);
        assertEq(added[0].fromBond, 16 ether);
        assertEq(added[0].trend, 16 ether);

        assertEq(added[1].fromKeysCount, 10);
        assertEq(added[1].fromBond, 145 ether);
        assertEq(added[1].trend, 1 ether);

        assertEq(added[2].fromKeysCount, 33);
        assertEq(added[2].fromBond, 167.5 ether);
        assertEq(added[2].trend, 0.5 ether);

        assertEq(added[3].fromKeysCount, 100);
        assertEq(added[3].fromBond, 210.5 ether);
        assertEq(added[3].trend, 10 ether);
    }

    function test_addBondCurve_RevertWhen_LessThanMinBondCurveLength() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new uint256[2][](0));
    }

    function test_addBondCurve_RevertWhen_MoreThanMaxBondCurveLength() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new uint256[2][](21));
    }

    function test_addBondCurve_RevertWhen_ZeroValue() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 0 ether];

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(_bondCurve);
    }

    function test_addBondCurve_RevertWhen_NextValueIsLessThanPrevious() public {
        uint256[2][] memory _bondCurve = new uint256[2][](2);
        _bondCurve[0] = [uint256(2), 10 ether];
        _bondCurve[1] = [uint256(1), 9 ether];

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(_bondCurve);
    }

    function test_updateBondCurve() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 16 ether];

        uint256 toUpdateId = 0;

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveUpdated(toUpdateId, _bondCurve);

        bondCurve.updateBondCurve(toUpdateId, _bondCurve);

        ICSBondCurve.BondCurveInterval[] memory updated = bondCurve
            .getCurveInfo(toUpdateId);

        assertEq(updated.length, 1);
        assertEq(updated[0].fromKeysCount, 1);
        assertEq(updated[0].fromBond, 16 ether);
        assertEq(updated[0].trend, 16 ether);
    }

    function test_updateBondCurve_SeveralIntervals() public {
        uint256[2][] memory _bondCurve = new uint256[2][](4);
        _bondCurve[0] = [uint256(1), 16 ether];
        _bondCurve[1] = [uint256(10), 1 ether];
        _bondCurve[2] = [uint256(33), 0.5 ether];
        _bondCurve[3] = [uint256(100), 10 ether];

        uint256 toUpdateId = 0;

        bondCurve.updateBondCurve(toUpdateId, _bondCurve);

        ICSBondCurve.BondCurveInterval[] memory updated = bondCurve
            .getCurveInfo(toUpdateId);

        assertEq(updated.length, 4);
        assertEq(updated[0].fromKeysCount, 1);
        assertEq(updated[0].fromBond, 16 ether);
        assertEq(updated[0].trend, 16 ether);

        assertEq(updated[1].fromKeysCount, 10);
        assertEq(updated[1].fromBond, 145 ether);
        assertEq(updated[1].trend, 1 ether);

        assertEq(updated[2].fromKeysCount, 33);
        assertEq(updated[2].fromBond, 167.5 ether);
        assertEq(updated[2].trend, 0.5 ether);

        assertEq(updated[3].fromKeysCount, 100);
        assertEq(updated[3].fromBond, 210.5 ether);
        assertEq(updated[3].trend, 10 ether);
    }

    function test_updateBondCurve_RevertWhen_LessThanMinBondCurveLength()
        public
    {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.updateBondCurve(0, new uint256[2][](0));
    }

    function test_updateBondCurve_RevertWhen_MoreThanMaxBondCurveLength()
        public
    {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.updateBondCurve(0, new uint256[2][](21));
    }

    function test_updateBondCurve_RevertWhen_ZeroValue() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 0 ether];
        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.updateBondCurve(0, _bondCurve);
    }

    function test_updateBondCurve_RevertWhen_NextValueIsLessThanPrevious()
        public
    {
        uint256[2][] memory _bondCurve = new uint256[2][](2);
        _bondCurve[0] = [uint256(2), 10 ether];
        _bondCurve[1] = [uint256(1), 9 ether];

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.updateBondCurve(0, _bondCurve);
    }

    function test_updateBondCurve_RevertWhen_InvalidBondCurveId() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 16 ether];
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.updateBondCurve(1, _bondCurve);
    }

    function test_setBondCurve() public {
        uint256 noId = 0;
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 16 ether];
        uint256 addedId = bondCurve.addBondCurve(_bondCurve);

        vm.expectEmit(address(bondCurve));
        emit ICSBondCurve.BondCurveSet(noId, addedId);
        bondCurve.setBondCurve(noId, addedId);

        assertEq(bondCurve.getBondCurveId(noId), addedId);
    }

    function test_setBondCurve_RevertWhen_NoExistingCurveId() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.setBondCurve(0, 100500);
    }

    function test_getCurvesCount() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 16 ether];
        bondCurve.addBondCurve(_bondCurve);

        // default one + 1 extra curve
        assertEq(bondCurve.getCurvesCount(), 2);
    }

    function test_getCurvesCount_noExtraCurves() public view {
        // only default one
        assertEq(bondCurve.getCurvesCount(), 1);
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
        ICSBondCurve.BondCurveInterval[] memory curve = bondCurve.getBondCurve(
            0
        );
        uint256 len = curve.length;
        ICSBondCurve.BondCurveInterval memory lastInterval = curve[len - 1];
        uint256 amount = type(uint256).max;

        assertEq(
            bondCurve.getKeysCountByBondAmount(amount, 0),
            lastInterval.fromKeysCount +
                (amount - lastInterval.fromBond) /
                lastInterval.trend
        );
    }

    function test_getKeysCountByBondAmount_noOverflowWithMinUint() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 1 wei];
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

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

    function test_getKeysCountByCurveValue_individual() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 1 ether];
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curveId), 2);

        _bondCurve[0][1] = 1.8 ether;
        curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.8 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(5.39 ether, curveId), 2);
    }

    function test_getKeysCountByBondAmount_singlePointCurve() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 2 ether];
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether, curveId), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether, curveId), 2);
    }

    function test_getKeysCountByBondAmount_twoPointsCurve() public {
        uint256[2][] memory _bondCurve = new uint256[2][](2);
        _bondCurve[0] = [uint256(1), 2 ether];
        _bondCurve[1] = [uint256(2), 1.5 ether];

        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3.5 ether, curveId), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether, curveId), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether, curveId), 3);
        assertEq(bondCurve.getKeysCountByBondAmount(6 ether, curveId), 3);
    }

    function test_getKeysCountByBondAmount_tenPointsCurve() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 1 ether];
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        for (uint256 i = 0; i < 10; i++) {
            assertEq(
                bondCurve.getKeysCountByBondAmount(i * 1 ether, curveId),
                i
            );
            assertEq(
                bondCurve.getKeysCountByBondAmount(
                    i * 1 ether + 0.5 ether,
                    curveId
                ),
                i
            );
        }
    }

    function test_getBondAmountByKeysCount_individual() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 1 ether];
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getBondAmountByKeysCount(0, curveId), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curveId), 1 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curveId), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curveId), 3 ether);

        _bondCurve[0][1] = 1.8 ether;
        curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getBondAmountByKeysCount(0, curveId), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curveId), 1.8 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curveId), 3.6 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curveId), 5.4 ether);
    }

    function test_getBondAmountByKeysCount_bigCurve() public {
        uint256[2][] memory _bondCurve = new uint256[2][](3);
        _bondCurve[0] = [uint256(1), 1.5 ether];
        _bondCurve[1] = [uint256(2), 1 ether];
        _bondCurve[2] = [uint256(4), 0.5 ether];

        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getBondAmountByKeysCount(0, curveId), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curveId), 1.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curveId), 2.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curveId), 3.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4, curveId), 4 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(16, curveId), 10 ether);
    }

    function test_viceVersa_OneInterval() public {
        uint256[2][] memory _bondCurve = new uint256[2][](1);
        _bondCurve[0] = [uint256(1), 0.33 ether];

        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        for (uint256 keysIn = 0; keysIn < 100; ++keysIn) {
            uint256 bondOut = bondCurve.getBondAmountByKeysCount(
                keysIn,
                curveId
            );
            assertEq(
                bondCurve.getKeysCountByBondAmount(bondOut, curveId),
                keysIn
            );
        }

        for (
            uint256 bondIn = 0 ether;
            bondIn < 33 ether;
            bondIn += 0.33 ether
        ) {
            uint256 keysOut = bondCurve.getKeysCountByBondAmount(
                bondIn,
                curveId
            );
            assertGe(
                bondIn,
                bondCurve.getBondAmountByKeysCount(keysOut, curveId)
            );
        }
    }

    function test_viceVersa_ThreeIntervals() public {
        uint256[2][] memory _bondCurve = new uint256[2][](3);
        _bondCurve[0] = [uint256(1), 1.5 ether];
        _bondCurve[1] = [uint256(2), 1 ether];
        _bondCurve[2] = [uint256(4), 0.5 ether];

        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        for (uint256 keysIn = 0; keysIn < 100; ++keysIn) {
            uint256 bondOut = bondCurve.getBondAmountByKeysCount(
                keysIn,
                curveId
            );
            assertEq(
                bondCurve.getKeysCountByBondAmount(bondOut, curveId),
                keysIn
            );
        }

        for (
            uint256 bondIn = 0 ether;
            bondIn < 33 ether;
            bondIn += 0.33 ether
        ) {
            uint256 keysOut = bondCurve.getKeysCountByBondAmount(
                bondIn,
                curveId
            );
            assertGe(
                bondIn,
                bondCurve.getBondAmountByKeysCount(keysOut, curveId)
            );
        }
    }

    function test_viceVersa_SixIntervals() public {
        uint256[2][] memory _bondCurve = new uint256[2][](6);
        _bondCurve[0] = [uint256(1), 1.5 ether];
        _bondCurve[1] = [uint256(2), 1 ether];
        _bondCurve[2] = [uint256(4), 0.5 ether];
        _bondCurve[3] = [uint256(5), 0.5 ether + 1 wei];
        _bondCurve[4] = [uint256(13), 1.11 ether - 1 wei];
        _bondCurve[5] = [uint256(16), 0.01 ether];

        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        for (uint256 keysIn = 0; keysIn < 100; ++keysIn) {
            uint256 bondOut = bondCurve.getBondAmountByKeysCount(
                keysIn,
                curveId
            );
            assertEq(
                bondCurve.getKeysCountByBondAmount(bondOut, curveId),
                keysIn
            );
        }

        for (
            uint256 bondIn = 0 ether;
            bondIn < 33 ether;
            bondIn += 0.33 ether
        ) {
            uint256 keysOut = bondCurve.getKeysCountByBondAmount(
                bondIn,
                curveId
            );
            assertGe(
                bondIn,
                bondCurve.getBondAmountByKeysCount(keysOut, curveId)
            );
        }
    }
}

contract CSBondCurveFuzz is Test {
    CSBondCurveTestable public bondCurve;

    uint256 public constant MAX_BOND_CURVE_INTERVALS_COUNT = 150;
    uint256 public constant MAX_FROM_KEYS_COUNT_VALUE = 10000;
    uint256 public constant MAX_TREND_VALUE = 1000 ether;

    function testFuzz_keysAndBondValues(
        uint256[] memory fromKeysCount,
        uint256[] memory trend,
        uint256 keysToCheck,
        uint256 bondToCheck
    ) public {
        uint256[2][] memory _bondCurve;
        (_bondCurve, keysToCheck, bondToCheck) = prepareInputs(
            fromKeysCount,
            trend,
            keysToCheck,
            bondToCheck
        );
        bondCurve = new CSBondCurveTestable(MAX_BOND_CURVE_INTERVALS_COUNT);
        bondCurve.initialize(_bondCurve);
        ICSBondCurve.BondCurveInterval[] memory intervals = bondCurve
            .getCurveInfo(0);

        // Compare contract output with different algorithm
        uint256 keysCountSecondOpinion = getKeysCountByBondAmountSecondOpinion(
            intervals,
            bondToCheck
        );
        uint256 keysCount = bondCurve.getKeysCountByBondAmount(bondToCheck, 0);
        assertEq(
            keysCount,
            keysCountSecondOpinion,
            "keysCount != keysCountSecondOpinion"
        );
        // Can't check this fully, because of the rounding (`bondToCheck` can be "between" two keys amounts).
        // So it is enough to check that one less or equal than another
        uint256 bondFromKeysCount = bondCurve.getBondAmountByKeysCount(
            keysCount,
            0
        );
        assertGe(
            bondToCheck,
            bondFromKeysCount,
            "bondFromKeysCount > bondToCheck"
        );

        uint256 bondAmountSecondOpinion = getBondAmountByKeysCountSecondOpinion(
            intervals,
            keysToCheck
        );
        uint256 bondAmount = bondCurve.getBondAmountByKeysCount(keysToCheck, 0);
        assertEq(
            bondAmount,
            bondAmountSecondOpinion,
            "bondAmount != bondOutSecondOpinion"
        );
        // Check that values are the same in both directions
        uint256 keysFromBondAmount = bondCurve.getKeysCountByBondAmount(
            bondAmount,
            0
        );
        assertEq(
            keysFromBondAmount,
            keysToCheck,
            "keysFromBondAmount != keysToCheck"
        );
    }

    /// NOTE: Ugly, ineffective version of binary search algorithm from the contract.
    //        Needed only as a second opinion to compare outputs.
    function getBondAmountByKeysCountSecondOpinion(
        ICSBondCurve.BondCurveInterval[] memory intervals,
        uint256 keysToCheck
    ) public pure returns (uint256) {
        uint256 bondAmount = 0;
        uint256 fromBondAcc = intervals[0].trend;
        for (uint256 i = 0; i < intervals.length; ++i) {
            if (i > 0) {
                // Current trend + difference between current and previous fromKeysCount multiplied by previous trend
                fromBondAcc +=
                    intervals[i].trend +
                    (intervals[i].fromKeysCount -
                        intervals[i - 1].fromKeysCount -
                        1) *
                    intervals[i - 1].trend;
            }
            if (keysToCheck >= intervals[i].fromKeysCount) {
                bondAmount =
                    fromBondAcc +
                    (keysToCheck - intervals[i].fromKeysCount) *
                    intervals[i].trend;
            } else {
                break;
            }
        }
        return bondAmount;
    }

    /// NOTE: Ugly, ineffective version of binary search algorithm from the contract.
    //        Needed only as a second opinion to compare outputs.
    function getKeysCountByBondAmountSecondOpinion(
        ICSBondCurve.BondCurveInterval[] memory intervals,
        uint256 bondToCheck
    ) public pure returns (uint256) {
        if (bondToCheck < intervals[0].fromBond) {
            return 0;
        }

        uint256 neededIndex = 0;
        uint256 fromBondAcc = intervals[0].trend;
        for (uint256 i = 0; i < intervals.length; i++) {
            if (i > 0) {
                // Current trend + difference between current and previous fromKeysCount multiplied by previous trend
                fromBondAcc +=
                    intervals[i].trend +
                    (intervals[i].fromKeysCount -
                        intervals[i - 1].fromKeysCount -
                        1) *
                    intervals[i - 1].trend;
            }
            if (bondToCheck == fromBondAcc) {
                return intervals[i].fromKeysCount;
            }
            if (i < intervals.length - 1) {
                uint256 nextFromBond = fromBondAcc +
                    intervals[i + 1].trend +
                    (intervals[i + 1].fromKeysCount -
                        intervals[i].fromKeysCount -
                        1) *
                    intervals[i].trend;
                if (bondToCheck < nextFromBond) {
                    uint256 maxBondInInterval = nextFromBond -
                        intervals[i + 1].trend;
                    if (bondToCheck > maxBondInInterval) {
                        bondToCheck = maxBondInInterval;
                    }
                    neededIndex = i;
                    break;
                }
            }
            neededIndex = i;
        }

        return
            intervals[neededIndex].fromKeysCount +
            (bondToCheck - fromBondAcc) /
            intervals[neededIndex].trend;
    }

    function prepareInputs(
        uint256[] memory fromKeysCount,
        uint256[] memory trend,
        uint256 keysToCheck,
        uint256 bondToCheck
    ) public pure returns (uint256[2][] memory, uint256, uint256) {
        vm.assume(fromKeysCount.length > 0);
        vm.assume(trend.length > 0);

        // Assume: intervals.length > 0
        uint256 intervalsCount = Math.max(
            1,
            Math.min(fromKeysCount.length, trend.length) %
                MAX_BOND_CURVE_INTERVALS_COUNT
        );
        for (uint256 i = 0; i < intervalsCount; ++i) {
            // Assume: fromKeysCount[i] > 0
            fromKeysCount[i] = Math.max(
                1,
                fromKeysCount[i] % MAX_FROM_KEYS_COUNT_VALUE
            );
            // Assume: trend[i] > 0
            trend[i] = Math.max(1 wei, trend[i] % MAX_TREND_VALUE);
        }
        assembly ("memory-safe") {
            // Shrink `fromKeysCount` and `trend` arrays to `intervalsCount`
            mstore(fromKeysCount, intervalsCount)
            mstore(trend, intervalsCount)
        }

        // Assume: fromKeysCount[i] < fromKeysCount[i + 1]
        uint256 n = fromKeysCount.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n - 1; j++) {
                if (fromKeysCount[j] > fromKeysCount[j + 1]) {
                    (fromKeysCount[j], fromKeysCount[j + 1]) = (
                        fromKeysCount[j + 1],
                        fromKeysCount[j]
                    );
                }
                if (fromKeysCount[j] == fromKeysCount[j + 1]) {
                    // Make it different because we need to have unique values
                    fromKeysCount[j + 1] = fromKeysCount[j] + 1;
                }
            }
        }
        // Assume: first interval starts from "1" keys count
        fromKeysCount[0] = 1;

        assertEq(fromKeysCount.length, trend.length);

        // Dev: zip `fromKeysCount` and `trend` arrays to `uint256[2][] intervals`
        uint256[2][] memory _bondCurve = new uint256[2][](fromKeysCount.length);
        for (uint256 i = 0; i < intervalsCount; ++i) {
            _bondCurve[i] = [fromKeysCount[i], trend[i]];
        }
        keysToCheck = bound(keysToCheck, 1, MAX_FROM_KEYS_COUNT_VALUE);
        bondToCheck = bound(
            bondToCheck,
            trend[0],
            MAX_TREND_VALUE * MAX_FROM_KEYS_COUNT_VALUE
        );
        return (_bondCurve, keysToCheck, bondToCheck);
    }
}
