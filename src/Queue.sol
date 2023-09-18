// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/// @author madlabman
contract Queue {
    mapping(bytes32 => bytes32) internal queue;

    bytes32 public constant ZERO = bytes32(0);

    bytes32 internal _head;
    bytes32 internal _next;
    bytes32 internal _prev;

    function enqueue(bytes32 item) external {
        require(item != ZERO, "Queue: item is zero");
        require(queue[item] == ZERO, "Queue: item already enqueued");

        if (_prev == _next) {
            _next = item;
        }

        queue[_head] = item;
        _head = item;
    }

    function dequeue() external notEmpty returns (bytes32 item) {
        item = _next;
        _next = queue[item];
        _prev = item;
    }

    function prev() external view returns (bytes32) {
        return _prev;
    }

    function peek() external view returns (bytes32) {
        return queue[_prev];
    }

    function peek(bytes32 item) external view returns (bytes32) {
        return queue[item];
    }

    /// @notice Squash two adjacent items in the queue
    function squash(bytes32 l, bytes32 r) external {
        require(queue[l] == r, "Queue: items are not adjacent");

        queue[l] = queue[r];
        queue[r] = ZERO;

        if (_head == r) {
            _head = l;
        }
    }

    modifier notEmpty() {
        require(_prev != _head, "Queue: empty");
        _;
    }
}
