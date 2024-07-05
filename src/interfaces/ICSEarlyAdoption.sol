// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSEarlyAdoption {
    error AlreadyConsumed();
    error InvalidCurveId();
    error InvalidProof();
    error InvalidTreeRoot();
    error SenderIsNotModule();
    error ZeroModuleAddress();

    event Consumed(address indexed member);

    function CURVE_ID() external view returns (uint256);

    function MODULE() external view returns (address);

    function TREE_ROOT() external view returns (bytes32);

    function consume(address member, bytes32[] memory proof) external;

    function hashLeaf(address member) external pure returns (bytes32);

    function isConsumed(address member) external view returns (bool);

    function verifyProof(
        address member,
        bytes32[] memory proof
    ) external view returns (bool);
}
