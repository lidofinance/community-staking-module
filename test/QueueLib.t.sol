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

    function peek() public view returns (Batch) {
        return q.peek();
    }

    function at(uint128 index) public view returns (Batch) {
        return q.at(index);
    }
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

    function testFuzz_setKeys(uint64 a, uint64 b, uint64 c) public {
        Batch p = createBatch(a, b);
        p = p.setKeys(c);
        assertEq(p.keys(), c);
    }

    function testFuzz_setNext(uint64 a, uint64 b, uint64 c, uint64 d) public {
        Batch p0 = createBatch(a, b);
        Batch p1 = createBatch(c, d);
        p0 = p0.setNext(p1);
        assertEq(p0.next(), p1.next());
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

    function test_dequeue_revertWhen_QueueIsEmpty() public {
        assertTrue(q.peek().isNil());
        vm.expectRevert(QueueLib.QueueIsEmpty.selector);
        q.dequeue();
    }
}

function eq(Batch lhs, Batch rhs) pure returns (bool) {
    return lhs.unwrap() == rhs.unwrap();
}
