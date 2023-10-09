// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/// @author madlabman
contract Queue {
    bytes32 public constant NULL_POINTER = bytes32(0);

    mapping(bytes32 => bytes32) internal queue;

    bytes32 internal _front;
    bytes32 internal _back;

    function enqueue(bytes32 item) external {
        require(item != NULL_POINTER, "Queue: item is zero");
        require(queue[item] == NULL_POINTER, "Queue: item already enqueued");

        if (_front == queue[_front]) {
            queue[_front] = item;
        }

        queue[_back] = item;
        _back = item;
    }

    function dequeue() external notEmpty returns (bytes32 item) {
        item = queue[_front];
        _front = item;
    }

    function frontPointer() external view returns (bytes32) {
        return _front;
    }

    function front() external view returns (bytes32) {
        return queue[_front];
    }

    function at(bytes32 pointer) external view returns (bytes32) {
        return queue[pointer];
    }

    function remove(bytes32 pointerToItem, bytes32 item) external {
        require(queue[pointerToItem] == item, "Queue: wrong pointer given");

        queue[pointerToItem] = queue[item];
        queue[item] = NULL_POINTER;

        if (_back == item) {
            _back = pointerToItem;
        }
    }

    modifier notEmpty() {
        require(_front != _back, "Queue: empty");
        _;
    }
}
