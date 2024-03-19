// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { Batch, createBatch, QueueLib } from "../src/lib/QueueLib.sol";

// Wrap the library internal methods to make an actual call to them.
// Supposed to be used with `expectRevert` cheatcode and to pass
// calldata arguments.
contract Library {
    using QueueLib for QueueLib.Queue;

    QueueLib.Queue internal q;

    function length() public view returns (uint128) {
        return q.length;
    }

    function head() public view returns (uint128) {
        return q.head;
    }

    function enqueue(Batch item) public returns (Batch) {
        return q.enqueue(item);
    }

    function dequeue() public returns (Batch) {
        return q.dequeue();
    }

    function remove(
        uint64 indexOfPrev,
        Batch prev,
        Batch item
    ) public returns (Batch) {
        return q.remove(indexOfPrev, prev, item);
    }

    function peek() public view returns (Batch) {
        return q.peek();
    }

    function at(uint128 index) public view returns (Batch) {
        return q.at(index);
    }
}

function eq(Batch lhs, Batch rhs) pure returns (bool) {
    return lhs.unwrap() == rhs.unwrap();
}

contract QueueLibTest is Test {
    using { eq } for Batch;

    Library q;
    Batch buf;

    function setUp() public {
        q = new Library();
    }

    function test_createBatch() public {
        assertEq(
            createBatch(0x27489e20a0060b72, 0x3a1748bdff5e4457).unwrap(),
            0x27489e20a0060b723a1748bdff5e445700000000000000000000000000000000
        );
    }

    function testFuzz_enqueue(uint64 a, uint64 b, uint64 c, uint64 d) public {
        assertTrue(q.peek().isNil());

        Batch p0 = q.enqueue(createBatch(a, b));
        Batch p1 = q.enqueue(createBatch(c, d));

        assertTrue(q.peek().eq(p0));
        assertTrue(q.at(1).eq(p1));

        assertEq(p0.noId(), a);
        assertEq(p0.keys(), b);
        assertEq(p1.noId(), c);
        assertEq(p1.keys(), d);
    }

    function testFuzz_dequeue(
        uint64 a,
        uint64 b,
        uint64 c,
        uint64 d,
        uint64 e,
        uint64 f
    ) public {
        assertTrue(q.peek().isNil());

        Batch p0 = q.enqueue(createBatch(a, b));
        Batch p1 = q.enqueue(createBatch(c, d));
        Batch p2 = q.enqueue(createBatch(e, f));

        assertFalse(q.peek().isNil());

        buf = q.dequeue();
        assertTrue(buf.eq(p0));
        assertTrue(q.peek().eq(p1));

        buf = q.dequeue();
        assertTrue(buf.eq(p1));
        assertTrue(q.peek().eq(p2));

        q.dequeue();
        assertTrue(q.peek().isNil());
    }

    function testFuzz_remove(
        uint64 a,
        uint64 b,
        uint64 c,
        uint64 d,
        uint64 e,
        uint64 f
    ) public {
        Batch p0 = q.enqueue(createBatch(a, b));
        Batch p1 = q.enqueue(createBatch(c, d));
        Batch p2 = q.enqueue(createBatch(e, f));

        // [p0, p1, p2]
        q.remove(0, p0, p1);
        // [p0', p2]
        buf = q.dequeue();
        // [p2]
        assertEq(p0.noId(), buf.noId());
        assertEq(p0.keys(), buf.keys());
        // [p2]
        buf = q.dequeue();
        // []
        assertEq(p2.noId(), buf.noId());
        assertEq(p2.keys(), buf.keys());
        // []
        q.enqueue(p1);
        // [p1']
        buf = q.peek();
        assertEq(p1.noId(), buf.noId());
        assertEq(p1.keys(), buf.keys());
        // [p1']
        q.dequeue();
        assertTrue(q.peek().isNil());
    }
}
