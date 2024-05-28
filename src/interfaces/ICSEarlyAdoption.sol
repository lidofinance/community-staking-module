// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSEarlyAdoption {
    function CURVE_ID() external view returns (uint256);

    function TREE_ROOT() external view returns (bytes32);

    function verifyProof(
        address addr,
        bytes32[] calldata proof
    ) external view returns (bool);

    function consume(address sender, bytes32[] calldata proof) external;

    function isConsumed(address sender) external view returns (bool);
}
