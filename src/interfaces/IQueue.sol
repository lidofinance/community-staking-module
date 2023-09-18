// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

interface IQueue {
    function enqueue(bytes32) external;

    function dequeue() external returns (bytes32);

    function prev() external view returns (bytes32);

    function peek() external view returns (bytes32);

    function peek(bytes32) external view returns (bytes32);

    function squash(bytes32, bytes32) external;
}
