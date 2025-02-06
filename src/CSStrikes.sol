// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { ICSStrikes } from "./interfaces/ICSStrikes.sol";

/// @author vgorkavenko
contract CSStrikes is ICSStrikes {
    address public immutable ORACLE;

    /// @notice The latest Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the last published Merkle tree
    string public treeCid;

    constructor(address oracle) {
        if (oracle == address(0)) revert ZeroOracleAddress();
        ORACLE = oracle;
    }

    /// @inheritdoc ICSStrikes
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid
    ) external {
        if (msg.sender != ORACLE) revert NotOracle();
        /// @dev should be both empty or not empty
        bool isNewRootEmpty = _treeRoot == bytes32(0);
        bool isNewCidEmpty = bytes(_treeCid).length == 0;
        if (isNewRootEmpty != isNewCidEmpty) revert InvalidReportData();
        if (isNewRootEmpty) {
            if (treeRoot != bytes32(0)) {
                delete treeRoot;
                delete treeCid;
                emit StrikesDataWiped();
            }
            return;
        }
        if (keccak256(bytes(treeCid)) == keccak256(bytes(_treeCid))) {
            revert InvalidReportData();
        }
        if (treeRoot == _treeRoot) revert InvalidReportData();
        treeRoot = _treeRoot;
        treeCid = _treeCid;
        emit StrikesDataUpdated(_treeRoot, _treeCid);
    }

    /// @inheritdoc ICSStrikes
    function verifyProof(
        uint256 nodeOperatorId,
        bytes calldata pubkey,
        uint256[] calldata strikesData,
        bytes32[] calldata proof
    ) external view {
        if (proof.length == 0) revert InvalidProof();
        bool isValid = MerkleProof.verifyCalldata(
            proof,
            treeRoot,
            hashLeaf(nodeOperatorId, pubkey, strikesData)
        );
        if (!isValid) revert InvalidProof();
    }

    /// @inheritdoc ICSStrikes
    function hashLeaf(
        uint256 nodeOperatorId,
        bytes memory pubkey,
        uint256[] calldata strikesData
    ) public pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    keccak256(abi.encode(nodeOperatorId, pubkey, strikesData))
                )
            );
    }
}
