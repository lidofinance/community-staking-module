// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSBondCurve } from "../src/abstract/CSBondCurve.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

contract CSBondCurveTestable is CSBondCurve(10) {
    function initialize(
        ICSBondCurve.BondCurveIntervalCalldata[] calldata bondCurve
    ) public initializer {
        __CSBondCurve_init(bondCurve);
    }

    function addBondCurve(
        ICSBondCurve.BondCurveIntervalCalldata[] calldata _bondCurve
    ) external returns (uint256) {
        return _addBondCurve(_bondCurve);
    }

    function updateBondCurve(
        uint256 curveId,
        ICSBondCurve.BondCurveIntervalCalldata[] calldata _bondCurve
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
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });

        bondCurve.addBondCurve(_bondCurve);

        vm.expectRevert(ICSBondCurve.InvalidInitialisationCurveId.selector);
        bondCurve.initialize(_bondCurve);
    }
}

contract CSBondCurveTest is Test {
    CSBondCurveTestable public bondCurve;

    function setUp() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](2);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 2 ether
        });
        _bondCurve[1] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 3,
            trend: 1 ether
        });
        bondCurve = new CSBondCurveTestable();
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
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });

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

    function test_addBondCurve_RevertWhen_LessThanMinBondCurveLength() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(new ICSBondCurve.BondCurveIntervalCalldata[](0));
    }

    function test_addBondCurve_RevertWhen_MoreThanMaxBondCurveLength() public {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.addBondCurve(
            new ICSBondCurve.BondCurveIntervalCalldata[](21)
        );
    }

    function test_addBondCurve_RevertWhen_ZeroValue() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 0 ether
        });

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(_bondCurve);
    }

    function test_addBondCurve_RevertWhen_NextValueIsLessThanPrevious() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](2);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 2,
            trend: 10 ether
        });
        _bondCurve[1] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 9 ether
        });

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.addBondCurve(_bondCurve);
    }

    function test_updateBondCurve() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });

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

    function test_updateBondCurve_RevertWhen_LessThanMinBondCurveLength()
        public
    {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.updateBondCurve(
            0,
            new ICSBondCurve.BondCurveIntervalCalldata[](0)
        );
    }

    function test_updateBondCurve_RevertWhen_MoreThanMaxBondCurveLength()
        public
    {
        vm.expectRevert(ICSBondCurve.InvalidBondCurveLength.selector);
        bondCurve.updateBondCurve(
            0,
            new ICSBondCurve.BondCurveIntervalCalldata[](21)
        );
    }

    function test_updateBondCurve_RevertWhen_ZeroValue() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 0 ether
        });

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.updateBondCurve(0, _bondCurve);
    }

    function test_updateBondCurve_RevertWhen_NextValueIsLessThanPrevious()
        public
    {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](2);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 2,
            trend: 10 ether
        });
        _bondCurve[1] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 9 ether
        });

        vm.expectRevert(ICSBondCurve.InvalidBondCurveValues.selector);
        bondCurve.updateBondCurve(0, _bondCurve);
    }

    function test_updateBondCurve_RevertWhen_InvalidBondCurveId() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });
        vm.expectRevert(ICSBondCurve.InvalidBondCurveId.selector);
        bondCurve.updateBondCurve(1, _bondCurve);
    }

    function test_setBondCurve() public {
        uint256 noId = 0;
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });
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

    function test_resetBondCurve() public {
        uint256 noId = 0;
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });
        uint256 addedId = bondCurve.addBondCurve(_bondCurve);
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

    function test_getCurvesCount() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 16 ether
        });
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
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 1 wei
        });
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
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 1 ether
        });
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curveId), 2);

        _bondCurve[0].trend = 1.8 ether;
        curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1.8 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(5.39 ether, curveId), 2);
    }

    function test_getKeysCountByBondAmount_singlePointCurve() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 2 ether
        });
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getKeysCountByBondAmount(0 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(1 ether, curveId), 0);
        assertEq(bondCurve.getKeysCountByBondAmount(2 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(3 ether, curveId), 1);
        assertEq(bondCurve.getKeysCountByBondAmount(4 ether, curveId), 2);
        assertEq(bondCurve.getKeysCountByBondAmount(5 ether, curveId), 2);
    }

    function test_getKeysCountByBondAmount_twoPointsCurve() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](2);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 2 ether
        });
        _bondCurve[1] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 2,
            trend: 1.5 ether
        });

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
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 1 ether
        });
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
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](1);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 1 ether
        });
        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getBondAmountByKeysCount(0, curveId), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curveId), 1 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curveId), 2 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curveId), 3 ether);

        _bondCurve[0].trend = 1.8 ether;
        curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getBondAmountByKeysCount(0, curveId), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curveId), 1.8 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curveId), 3.6 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curveId), 5.4 ether);
    }

    function test_getBondAmountByKeysCount_bigCurve() public {
        ICSBondCurve.BondCurveIntervalCalldata[]
            memory _bondCurve = new ICSBondCurve.BondCurveIntervalCalldata[](3);
        _bondCurve[0] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 1,
            trend: 1.5 ether
        });
        _bondCurve[1] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 2,
            trend: 1 ether
        });
        _bondCurve[2] = ICSBondCurve.BondCurveIntervalCalldata({
            fromKeysCount: 4,
            trend: 0.5 ether
        });

        uint256 curveId = bondCurve.addBondCurve(_bondCurve);

        assertEq(bondCurve.getBondAmountByKeysCount(0, curveId), 0);
        assertEq(bondCurve.getBondAmountByKeysCount(1, curveId), 1.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(2, curveId), 2.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(3, curveId), 3.5 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(4, curveId), 4 ether);
        assertEq(bondCurve.getBondAmountByKeysCount(16, curveId), 10 ether);
    }
}
