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
        (uint64 nodeOperatorId, uint64 start, uint64 end) = Batch.deserialize(
            0x000000000000000000000000000003e70000000000000003000000000000002a
        );

        assertEq(nodeOperatorId, 999);
        assertEq(start, 3);
        assertEq(end, 42);
    }
}
