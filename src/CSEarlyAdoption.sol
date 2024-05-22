// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";

contract CSEarlyAdoption is ICSEarlyAdoption {
    // TODO: add natspec comments
    bytes32 public immutable TREE_ROOT;
    uint256 public immutable CURVE_ID;
    address public immutable MODULE;

    mapping(address => bool) internal _consumedAddresses;

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
        // TODO: change `sender` to smth
        if (msg.sender != MODULE) revert OnlyModule(); // TODO: change the name of the error
        if (_consumedAddresses[sender]) revert AlreadyConsumed();

        if (!isEligible(sender, proof)) revert InvalidProof();
        _consumedAddresses[sender] = true;
        emit Consumed(sender);
    }

    // TODO: rename to `isConsumed`
    /// @notice Check if the address has already consumed EA access
    /// @param sender Address to check
    function consumed(address sender) external view returns (bool) {
        // TODO: change `sender` to smth
        return _consumedAddresses[sender];
    }

    // TODO: rename to `verifyProof` ?
    /// @notice Check is the address is eligible to consume EA access
    /// @param sender Address to check
    /// @param proof Merkle proof of EA eligibility
    function isEligible(
        address sender, // TODO: change `sender` to smth
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
