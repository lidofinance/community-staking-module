// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";

contract CSEarlyAdoption is ICSEarlyAdoption {
    /// @dev Root of the EA members Merkle Tree
    bytes32 public immutable TREE_ROOT;
    /// @dev Id of the bond curve to be assigned for the EA members
    uint256 public immutable CURVE_ID;
    /// @dev Address of the Staking Module using Early Adoption contract
    address public immutable MODULE;

    mapping(address => bool) internal _consumedAddresses;

    event Consumed(address indexed member);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidTreeRoot();
    error InvalidCurveId();
    error ZeroModuleAddress();
    error SenderIsNotModule();

    constructor(bytes32 treeRoot, uint256 curveId, address module) {
        if (treeRoot == bytes32(0)) revert InvalidTreeRoot();
        if (curveId == 0) revert InvalidCurveId();
        if (module == address(0)) revert ZeroModuleAddress();

        TREE_ROOT = treeRoot;
        CURVE_ID = curveId;
        MODULE = module;
    }

    /// @notice Validate EA eligibility proof and mark it as consumed
    /// @dev Called only by the module
    /// @param member Address to be verified alongside the proof
    /// @param proof Merkle proof of EA eligibility
    function consume(address member, bytes32[] calldata proof) external {
        if (msg.sender != MODULE) revert SenderIsNotModule();
        if (_consumedAddresses[member]) revert AlreadyConsumed();
        if (!verifyProof(member, proof)) revert InvalidProof();
        _consumedAddresses[member] = true;
        emit Consumed(member);
    }

    /// @notice Check if the address has already consumed EA access
    /// @param member Address to check
    function isConsumed(address member) external view returns (bool) {
        return _consumedAddresses[member];
    }

    /// @notice Check is the address is eligible to consume EA access
    /// @param member Address to check
    /// @param proof Merkle proof of EA eligibility
    /// @return Boolean flag if the proof is valid or not
    function verifyProof(
        address member,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return MerkleProof.verifyCalldata(proof, TREE_ROOT, hashLeaf(member));
    }

    /// @notice Get a hash of a leaf in EA Merkle tree
    /// @param member EA member address
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second preimage attacks
    function hashLeaf(address member) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(member))));
    }
}
