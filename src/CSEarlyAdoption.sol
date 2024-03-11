// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";

contract CSEarlyAdoption is ICSEarlyAdoption {
    mapping(address => bool) internal _consumedAddresses;
    uint256 public curveId;
    bytes32 public treeRoot;
    address public module;

    event Consumed(address indexed sender);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidValue();
    error OnlyModule();

    constructor(bytes32 _treeRoot, uint256 _curveId, address _module) {
        if (_treeRoot == bytes32(0)) revert InvalidValue();
        if (_curveId == 0) revert InvalidValue();
        if (_module == address(0)) revert InvalidValue();

        treeRoot = _treeRoot;
        curveId = _curveId;
        module = _module;
    }

    function isEligible(
        address sender,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verifyCalldata(
                proof,
                treeRoot,
                keccak256(bytes.concat(keccak256(abi.encode(sender))))
            );
    }

    function consume(address sender, bytes32[] calldata proof) external {
        if (msg.sender != module) revert OnlyModule();
        if (_consumedAddresses[sender]) revert AlreadyConsumed();

        if (!isEligible(sender, proof)) revert InvalidProof();
        _consumedAddresses[sender] = true;
        emit Consumed(sender);
    }

    function consumed(address sender) external view returns (bool) {
        return _consumedAddresses[sender];
    }
}
