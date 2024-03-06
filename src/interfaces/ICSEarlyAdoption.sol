// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSEarlyAdoption {
    function curveId() external view returns (uint256);

    function treeRoot() external view returns (bytes32);

    function isEligible(
        address addr,
        bytes32[] calldata proof
    ) external view returns (bool);

    function consume(address sender, bytes32[] calldata proof) external;
}
