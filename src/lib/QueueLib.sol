// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

// Batch is an uint256 as it's the internal data type used by solidity.
// Batch is a packed value, consisting of the following fields:
//    - uint64  nodeOperatorId
//    - uint64  keysCount -- count of keys enqueued by the batch
//    - uint128 next -- index of the next batch in the queue
type Batch is uint256;

/// @notice Batch of the operator with index 0, with no keys in it and the next Batch' index 0 is meaningless.
function isNil(Batch self) pure returns (bool) {
    return Batch.unwrap(self) == 0;
}

/// @dev Syntactic sugar for the type.
function unwrap(Batch self) pure returns (uint256) {
    return Batch.unwrap(self);
}

function noId(Batch self) pure returns (uint64 n) {
    assembly {
        n := shr(192, self)
    }
}

function keys(Batch self) pure returns (uint64 n) {
    assembly {
        n := shl(64, self)
        n := shr(192, n)
    }
}

function next(Batch self) pure returns (uint128 n) {
    assembly {
        n := self // uint128(self)
    }
}

function setKeys(Batch self, uint256 keysCount) pure returns (Batch) {
    assembly {
        self := or(
            and(
                self,
                0xffffffffffffffff0000000000000000ffffffffffffffffffffffffffffffff
            ),
            shl(128, and(keysCount, 0xffffffffffffffff))
        ) // self.keys = keysCount
    }

    return self;
}

/// @dev Instantiate a new Batch to be added to the queue. The `next` field will be determined upon the enqueue.
/// @dev Parameters are uint256 to make usage easier.
function createBatch(
    uint256 nodeOperatorId,
    uint256 keysCount
) pure returns (Batch item) {
    nodeOperatorId = uint64(nodeOperatorId);
    keysCount = uint64(keysCount);

    assembly {
        item := shl(128, keysCount) // `keysCount` in [64:127]
        item := or(item, shl(192, nodeOperatorId)) // `nodeOperatorId` in [0:63]
    }
}

using { noId, keys, setKeys, next, isNil, unwrap } for Batch global;

/// @author madlabman
library QueueLib {
    // TODO: Is it possible to get the advantage of zeroing storage variables and do not waste the storage?
    struct Queue {
        // Pointer to the item to be dequeued.
        uint128 head;
        // Tracks the total number of batches enqueued.
        uint128 length;
        // Mapping saves a little in costs and allows easily fallback to a zeroed batch on out-of-bounds access.
        mapping(uint128 => Batch) queue;
    }

    error InvalidIndex();
    error QueueIsEmpty();

    // TODO: Consider changing to accept the batch fields as arguments.
    function enqueue(Queue storage self, Batch item) internal returns (Batch) {
        uint128 length = self.length;

        assembly {
            item := or(
                and(
                    item,
                    0xffffffffffffffffffffffffffffffff00000000000000000000000000000000
                ),
                add(length, 1)
            ) // item.next = self.length+1;
        }

        self.queue[length] = item;
        unchecked {
            ++self.length;
        }

        return item;
    }

    function dequeue(Queue storage self) internal returns (Batch item) {
        item = peek(self);

        if (item.isNil()) {
            revert QueueIsEmpty();
        }

        self.head = item.next();
    }

    function peek(Queue storage self) internal view returns (Batch item) {
        return self.queue[self.head];
    }

    function at(
        Queue storage self,
        uint128 index
    ) internal view returns (Batch item) {
        return self.queue[index];
    }

    /// @dev Returns the updated item.
    /// @dev It's supposed the `indexOfPrev` is >= `queue.head`, otherwise, dequeue the item.
    /// @param indexOfPrev Index of the batch that points to the item to remove.
    /// @param prev Batch is pointing to the item to remove.
    /// @param item Batch to remove from the queue.
    function remove(
        Queue storage self,
        uint128 indexOfPrev,
        Batch prev,
        Batch item
    ) internal returns (Batch) {
        assembly {
            prev := or(
                and(
                    prev,
                    0xffffffffffffffffffffffffffffffff00000000000000000000000000000000
                ),
                and(
                    item,
                    0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff
                )
            ) // prev.next = item.next
        }

        self.queue[indexOfPrev] = prev;
        return prev;
    }
}
