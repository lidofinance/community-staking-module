// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSEarlyAdoption {
    event Consumed(address indexed member);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidTreeRoot();
    error InvalidCurveId();
    error ZeroModuleAddress();
    error SenderIsNotModule();

    function CURVE_ID() external view returns (uint256);

    function TREE_ROOT() external view returns (bytes32);

    function MODULE() external view returns (address);

    /// @notice Check is the address is eligible to consume EA access
    /// @param member Address to check
    /// @param proof Merkle proof of EA eligibility
    /// @return Boolean flag if the proof is valid or not
    function verifyProof(
        address member,
        bytes32[] calldata proof
    ) external view returns (bool);

    /// @notice Validate EA eligibility proof and mark it as consumed
    /// @dev Called only by the module
    /// @param member Address to be verified alongside the proof
    /// @param proof Merkle proof of EA eligibility
    function consume(address member, bytes32[] calldata proof) external;

    /// @notice Check if the address has already consumed EA access
    /// @param member Address to check
    /// @return Consumed flag
    function isConsumed(address member) external view returns (bool);

    /// @notice Get a hash of a leaf in EA Merkle tree
    /// @param member EA member address
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second preimage attacks
    function hashLeaf(address member) external pure returns (bytes32);
}
