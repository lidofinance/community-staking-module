// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { Batch } from "../src/lib/Batch.sol";

contract BatchTest is Test {
    function test_serialize() public {
        bytes32 b = Batch.serialize({
            nodeOperatorId: 999,
            start: 3,
            count: 42,
            nonce: 7
        });

        assertEq(
            b,
            //   noIndex     |    start      |     count     |     nonce
            0x00000000000003e70000000000000003000000000000002a0000000000000007
        );
    }

    function test_deserialize() public {
        (
            uint256 nodeOperatorId,
            uint256 start,
            uint256 count,
            uint256 nonce
        ) = Batch.deserialize(
                0x0000000000000000000000000000000000000000000000000000000000000000
            );

        assertEq(nodeOperatorId, 0, "nodeOperatorId != 0");
        assertEq(start, 0, "start != 0");
        assertEq(count, 0, "count != 0");
        assertEq(nonce, 0, "nonce != 0");

        (nodeOperatorId, start, count, nonce) = Batch.deserialize(
            0x00000000000003e70000000000000003000000000000002a0000000000000007
        );

        assertEq(nodeOperatorId, 999, "nodeOperatorId != 999");
        assertEq(start, 3, "start != 3");
        assertEq(count, 42, "count != 42");
        assertEq(nonce, 7, "nonce != 7");

        (nodeOperatorId, start, count, nonce) = Batch.deserialize(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        assertEq(
            nodeOperatorId,
            type(uint64).max,
            "nodeOperatorId != uint64.max"
        );
        assertEq(start, type(uint64).max, "start != uint64.max");
        assertEq(count, type(uint64).max, "count != uint64.max");
        assertEq(nonce, type(uint64).max, "nonce != uint64.max");
    }
}
