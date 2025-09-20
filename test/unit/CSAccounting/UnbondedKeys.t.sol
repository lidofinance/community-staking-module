// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "./_Base.t.sol";

// Combined keys count tests: unbonded and ejection

contract GetUnbondedKeysCountTest is BondStateBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 11);
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        assertEq(accounting.getUnbondedKeysCount(0), 6);
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 11);
    }

    function test_WithLocked_MoreThanBond() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _lock({ amount: 100500 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 16);
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 7);
    }

    function test_WithReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        assertGt(reservable, 0);
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithCurveAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _deposit({ bond: 18 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithLockedAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        _deposit({ bond: 34 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithCurveAndLockedAndReserve()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        _deposit({ bond: 19 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 12.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 10);
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 0);
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 14);
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 13);
    }

    function test_WithCustomSmolCurve() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](2);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 2 ether
        });
        curve[1] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 2,
            trend: 1 ether
        });
        _curve(curve);
        _deposit({ bond: 2.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 15);
    }

    function test_WithCustomHugeCurve_1() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 1 ether
        });
        _curve(curve);
        _deposit({ bond: 3.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 13);
    }

    function test_WithCustomHugeCurve_2() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 1 ether
        });
        _curve(curve);
        _deposit({ bond: 8.5 ether });
        assertEq(accounting.getUnbondedKeysCount(0), 8);
    }
}

contract GetUnbondedKeysCountToEjectTest is BondStateBaseTest {
    function test_default() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithCurve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        assertEq(accounting.getUnbondedKeysCountToEject(0), 6);
    }

    function test_WithLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        _lock({ amount: 2 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithLocked_MoreThanBond() public assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 30 ether });
        _lock({ amount: 100500 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 1);
    }

    function test_WithCurveAndLocked() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 6);
    }

    function test_WithReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        assertGt(reservable, 0);
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithCurveAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _deposit({ bond: 18 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithLockedAndReserve() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _lock({ amount: 1 ether });
        _deposit({ bond: 34 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithCurveAndLockedAndReserve()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 0 });
        _curve(curveWithDiscount);
        _lock({ amount: 1 ether });
        _deposit({ bond: 19 ether });

        (uint256 curr, uint256 req) = accounting.getBondSummary(0);
        uint256 reservable = curr - req;
        assertGt(reservable, 0);
        _reserve({ amount: reservable });

        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithOneWithdrawnValidator() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 10);
    }

    function test_WithBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 11);
    }

    function test_WithBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 11.5 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 10);
    }

    function test_WithExcessBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithExcessBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 33 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 0);
    }

    function test_WithMissingBond() public override assertInvariants {
        _operator({ ongoing: 16, withdrawn: 0 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 14);
    }

    function test_WithMissingBondAndOneWithdrawnValidator()
        public
        override
        assertInvariants
    {
        _operator({ ongoing: 16, withdrawn: 1 });
        _deposit({ bond: 5.75 ether });
        assertEq(accounting.getUnbondedKeysCountToEject(0), 13);
    }
}
