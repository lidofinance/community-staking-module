// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

interface IQueue {
    function enqueue(bytes32) external;

    function dequeue() external returns (bytes32);

    function frontPointer() external view returns (bytes32);

    function front() external view returns (bytes32);

    function at(bytes32) external view returns (bytes32);

    function remove(bytes32, bytes32) external;
}
