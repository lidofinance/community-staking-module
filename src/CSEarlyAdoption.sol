// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "./interfaces/ICSModule.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/ICSEarlyAdoption.sol";

abstract contract CSEarlyAdoption is ICSEarlyAdoption {
    mapping(address => bool) internal _consumedAddresses;
    uint256 private _curveId;
    bytes32 private _treeRoot;

    event Consumed(address indexed sender);
    error InvalidProof();
    error AlreadyConsumed();
    error InvalidTreeRoot();
    error InvalidCurveId();

    function isEligible(
        address sender,
        bytes32[] calldata proof
    ) public view returns (bool isValid) {
        isValid = MerkleProof.verifyCalldata(
            proof,
            _treeRoot,
            keccak256(bytes.concat(keccak256(abi.encode(sender))))
        );
    }

    function consume(address sender, bytes32[] calldata proof) internal {
        if (_consumedAddresses[sender]) revert AlreadyConsumed();

        if (!isEligible(sender, proof)) revert InvalidProof();
        _consumedAddresses[sender] = true;
        emit Consumed(sender);
    }

    function setCurve(uint256 curveId) internal {
        if (curveId != 0) {
            revert InvalidCurveId();
        }
        _curveId = curveId;
    }

    function setTreeRoot(bytes32 treeRoot) internal {
        if (treeRoot != bytes32(0)) {
            revert InvalidTreeRoot();
        }
        _treeRoot = treeRoot;
    }

    function getCurve() public view returns (uint256) {
        return _curveId;
    }
}
