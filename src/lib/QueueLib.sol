// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;


/// @author madlabman
library QueueLib {
    bytes32 public constant NULL_POINTER = bytes32(0);

    struct Queue {
        mapping(bytes32 => bytes32) queue;
        bytes32 front;
        bytes32 back;
    }

    function enqueue(Queue storage self, bytes32 item) internal {
        require(item != NULL_POINTER, "Queue: item is zero");
        require(self.queue[item] == NULL_POINTER, "Queue: item already enqueued");

        if (self.front == self.queue[self.front]) {
            self.queue[self.front] = item;
        }

        self.queue[self.back] = item;
        self.back = item;
    }

    function dequeue(Queue storage self) internal notEmpty(self) returns (bytes32 item) {
        item = self.queue[self.front];
        self.front = item;
    }

    function peek(Queue storage self) internal view returns (bytes32) {
        return self.queue[self.front];
    }

    function at(Queue storage self, bytes32 pointer) internal view returns (bytes32) {
        return self.queue[pointer];
    }

    function list(Queue storage self, bytes32 pointer, uint256 limit) internal notEmpty(self) view returns (
        bytes32[] memory items,
        bytes32 /* pointer */,
        uint256 /* count */
    ) {
        items = new bytes32[](limit);

        uint256 i;
        for (; i < limit; i++) {
            bytes32 item = self.queue[pointer];
            if (item == NULL_POINTER) {
                break;
            }
            
            items[i] = item;
            pointer = item;
        }

        return (items, pointer, i);
    }

    function isEmpty(Queue storage self) internal view returns (bool) {
        return self.front == self.back;
    }

    function remove(Queue storage self, bytes32 pointerToItem, bytes32 item) internal {
        require(self.queue[pointerToItem] == item, "Queue: wrong pointer given");

        self.queue[pointerToItem] = self.queue[item];
        self.queue[item] = NULL_POINTER;

        if (self.back == item) {
            self.back = pointerToItem;
        }
    }

    modifier notEmpty(Queue storage self) {
        require(!isEmpty(self), "Queue: empty");
        _;
    }
}
