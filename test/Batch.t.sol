// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { Batch } from "../src/lib/Batch.sol";

contract BatchTest is Test {
    function test_serialize() public {
        bytes32 b = Batch.serialize({ nodeOperatorId: 999, start: 3, end: 42 });

        assertEq(
            b,
            //            noIndex            |    start      |       end     |
            0x000000000000000000000000000003e70000000000000003000000000000002a
        );
    }

    function test_deserialize() public {
        (uint128 nodeOperatorId, uint64 start, uint64 end) = Batch.deserialize(
            0x0000000000000000000000000000000000000000000000000000000000000000
        );

        assertEq(nodeOperatorId, 0, "nodeOperatorId != 0");
        assertEq(start, 0, "start != 0");
        assertEq(end, 0, "end != 0");

        (nodeOperatorId, start, end) = Batch.deserialize(
            0x000000000000000000000000000003e70000000000000003000000000000002a
        );

        assertEq(nodeOperatorId, 999, "nodeOperatorId != 999");
        assertEq(start, 3, "start != 3");
        assertEq(end, 42, "end != 42");

        (nodeOperatorId, start, end) = Batch.deserialize(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        assertEq(
            nodeOperatorId,
            type(uint128).max,
            "nodeOperatorId != uint128.max"
        );
        assertEq(start, type(uint64).max, "start != uint64.max");
        assertEq(end, type(uint64).max, "end != uint64.max");
    }
}
