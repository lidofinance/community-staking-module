// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSEarlyAdoption {
    event TreeRootSet(bytes32 indexed treeRoot);
    event CurveIdSet(uint256 indexed curveId);
    event Consumed(address indexed member);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidTreeRoot();
    error InvalidCurveId();
    error ZeroModuleAddress();
    error ZeroAdminAddress();
    error SenderIsNotModule();

    function PAUSE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function SET_TREE_ROOT_ROLE() external view returns (bytes32);

    function SET_CURVE_ID_ROLE() external view returns (bytes32);

    function MODULE() external view returns (address);

    function curveId() external view returns (uint256);

    function treeRoot() external view returns (bytes32);

    /// @notice Pause the contract for a given duration
    ///         Pausing the contract prevent creating new node operators using EA
    ///         and consuming EA benefits for the existing ones
    /// @param duration Duration of the pause
    function pauseFor(uint256 duration) external;

    /// @notice Resume the contract
    function resume() external;

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

    /// @notice Set the root of the EA members Merkle Tree
    /// @param _treeRoot New root of the Merkle Tree
    function setTreeRoot(bytes32 _treeRoot) external;

    /// @notice Set the id of the bond curve to be assigned for the EA members
    /// @param _curveId New curve id
    /// @dev does not affect the existing EA members
    function setCurveId(uint256 _curveId) external;
}
