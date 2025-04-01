// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSEjector } from "./interfaces/ICSEjector.sol";
import { ICSStrikes } from "./interfaces/ICSStrikes.sol";

/// @author vgorkavenko
contract CSStrikes is ICSStrikes {
    address public immutable ORACLE;
    ICSModule public immutable MODULE;
    ICSEjector public immutable EJECTOR;

    /// @notice The latest Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the last published Merkle tree
    string public treeCid;

    constructor(address ejector, address oracle) {
        if (ejector == address(0)) revert ZeroEjectorAddress();
        if (oracle == address(0)) revert ZeroOracleAddress();
        EJECTOR = ICSEjector(ejector);
        MODULE = EJECTOR.MODULE();
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

        bool isSameRoot = _treeRoot == treeRoot;
        bool isSameCid = keccak256(bytes(_treeCid)) ==
            keccak256(bytes(treeCid));
        if (isSameRoot != isSameCid) revert InvalidReportData();
        if (!isSameRoot) {
            treeRoot = _treeRoot;
            treeCid = _treeCid;
            emit StrikesDataUpdated(_treeRoot, _treeCid);
        }
    }

    /// @inheritdoc ICSStrikes
    function processBadPerformanceProof(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256[] calldata strikesData,
        bytes32[] calldata proof
    ) external {
        // NOTE: We allow empty proofs to be delivered because there’s no way to use the tree’s
        // internal nodes without brute-forcing the input data.

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );
        if (!verifyProof(nodeOperatorId, pubkey, strikesData, proof))
            revert InvalidProof();

        uint256 strikes = 0;
        for (uint256 i; i < strikesData.length; ++i) {
            strikes += strikesData[i];
        }

        EJECTOR.ejectBadPerformer(nodeOperatorId, keyIndex, strikes);
    }

    /// @inheritdoc ICSStrikes
    function verifyProof(
        uint256 nodeOperatorId,
        bytes memory pubkey,
        uint256[] calldata strikesData,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verifyCalldata(
                proof,
                treeRoot,
                hashLeaf(nodeOperatorId, pubkey, strikesData)
            );
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
