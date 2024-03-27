// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { TransientUintUintMap } from "../src/lib/TransientUintUintMapLib.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract TransientUintUintMapLibTest is Test {
    using Strings for uint256;

    TransientUintUintMap private dict;

    function testFuzz_dictAddAndGetValue(
        uint256 k,
        uint256 v,
        uint256 s
    ) public {
        // There's no overflow check in the `add` function.
        vm.assume(v < type(uint128).max);
        vm.assume(s < type(uint128).max);

        uint256 sum = v + s;
        uint256 r;

        // Adding to the same key should increment the value.
        dict.add(k, v);
        dict.add(k, s);
        r = dict.get(k);
        assertEq(
            r,
            sum,
            string.concat("expected=", sum.toString(), " actual=", r.toString())
        );

        // Consequent read of the same key should return the same value.
        r = dict.get(k);
        assertEq(
            r,
            sum,
            string.concat("expected=", sum.toString(), " actual=", r.toString())
        );
    }

    function testFuzz_dictClear(uint256 a, uint256 b) public {
        // Doesn't make sense to check 0 values to become 0.
        vm.assume(a > 0);
        vm.assume(b > 0);

        uint256 r;

        dict.add(1, a);
        dict.add(2, b);

        dict.clear();

        r = dict.get(1);
        assertEq(r, 0, string.concat("expected=0 actual=", r.toString()));
        r = dict.get(2);
        assertEq(r, 0, string.concat("expected=0 actual=", r.toString()));
    }
}
