// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { Math, Log2Undefined } from "../src/lib/Math.sol";

// Wrap the library internal methods to make an actual call to them.
// Supposed to be used with `expectRevert` cheatcode.
contract Library {
    function log2(uint256 n) public pure returns (uint256) {
        return Math.log2(n);
    }
}

contract MathTest is Test {
    Library internal lib;

    function setUp() public {
        lib = new Library();
    }

    function test_log2() public {
        assertEq(Math.log2(1), 0);
        assertEq(Math.log2(2), 1);
        assertEq(Math.log2(4), 2);
        assertEq(Math.log2(8), 3);
        assertEq(Math.log2(256), 8);
    }

    function test_log2_RoundsDow() public {
        assertEq(Math.log2(3), 1);
        assertEq(Math.log2(7), 2);
        assertEq(Math.log2(10), 3);
        assertEq(Math.log2(300), 8);
    }

    function testFuzz_log2(uint8 pow) public {
        assertEq(Math.log2(2 ** pow), pow);
    }

    function testFuzz_log2_RoundsDown(uint256 n) public {
        vm.assume(n > 0);
        uint256 pow = Math.log2(n);
        assertLe(2 ** pow, n);
    }

    function test_log2_RevertsIfZero() public {
        vm.expectRevert(Log2Undefined.selector);
        lib.log2(0);
    }
}
