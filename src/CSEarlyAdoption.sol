// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";

contract CSEarlyAdoption is ICSEarlyAdoption {
    mapping(address => bool) internal _consumedAddresses;
    uint256 public immutable CURVE_ID;
    bytes32 public immutable TREE_ROOT;
    address public immutable MODULE;

    event Consumed(address indexed sender);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidValue();
    error OnlyModule();

    constructor(bytes32 treeRoot, uint256 curveId, address module) {
        if (treeRoot == bytes32(0)) revert InvalidValue();
        if (curveId == 0) revert InvalidValue();
        if (module == address(0)) revert InvalidValue();

        TREE_ROOT = treeRoot;
        CURVE_ID = curveId;
        MODULE = module;
    }

    /// @notice Validate EA eligibility proof and mark it as consumed
    /// @dev Called only by the module
    /// @param sender Address to be verified alongside the proof
    /// @param proof Merkle proof of EA eligibility
    function consume(address sender, bytes32[] calldata proof) external {
        if (msg.sender != MODULE) revert OnlyModule();
        if (_consumedAddresses[sender]) revert AlreadyConsumed();

        if (!isEligible(sender, proof)) revert InvalidProof();
        _consumedAddresses[sender] = true;
        emit Consumed(sender);
    }

    /// @notice Check if the address has already claimed EA access
    /// @param sender Address to check
    function consumed(address sender) external view returns (bool) {
        return _consumedAddresses[sender];
    }

    /// @notice Check is the address is eligible to claim EA access
    /// @param sender Address to check
    /// @param proof Merkle proof of EA eligibility
    function isEligible(
        address sender,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verifyCalldata(
                proof,
                TREE_ROOT,
                keccak256(bytes.concat(keccak256(abi.encode(sender))))
            );
    }
}
