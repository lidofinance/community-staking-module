// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

import { IAssetRecovererLib } from "../lib/AssetRecovererLib.sol";
import { IStETH } from "./IStETH.sol";

pragma solidity 0.8.24;

interface ICSFeeDistributor is IAssetRecovererLib {
    /// @dev Emitted when fees are distributed
    event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);

    /// @dev Emitted when distribution data is updated
    event DistributionDataUpdated(
        uint256 totalClaimableShares,
        bytes32 treeRoot,
        string treeCid
    );

    /// @dev Emitted when distribution log is updated
    event DistributionLogUpdated(string logCid);

    error ZeroAccountingAddress();
    error ZeroStEthAddress();
    error ZeroAdminAddress();
    error ZeroOracleAddress();
    error NotAccounting();
    error NotOracle();

    error InvalidTreeRoot();
    error InvalidTreeCID();
    error InvalidLogCID();
    error InvalidShares();
    error InvalidProof();
    error FeeSharesDecrease();
    error NotEnoughShares();

    function RECOVERER_ROLE() external view returns (bytes32);

    function STETH() external view returns (IStETH);

    function ACCOUNTING() external view returns (address);

    function ORACLE() external view returns (address);

    function treeRoot() external view returns (bytes32);

    function treeCid() external view returns (string calldata);

    function logCid() external view returns (string calldata);

    function distributedShares(uint256) external view returns (uint256);

    function totalClaimableShares() external view returns (uint256);

    /// @notice Get the Amount of stETH shares that can be distributed in favor of the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Total Amount of stETH shares earned as fees
    /// @param proof Merkle proof of the leaf
    /// @return sharesToDistribute Amount of stETH shares that can be distributed
    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external view returns (uint256);

    /// @notice Distribute fees to the Accounting in favor of the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Total Amount of stETH shares earned as fees
    /// @param proof Merkle proof of the leaf
    /// @return sharesToDistribute Amount of stETH shares distributed
    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external returns (uint256);

    /// @notice Receive the data of the Merkle tree from the Oracle contract and process it
    /// @param _treeRoot Root of the Merkle tree
    /// @param _treeCid an IPFS CID of the tree
    /// @param _logCid an IPFS CID of the log
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid,
        string calldata _logCid,
        uint256 _distributedShares
    ) external;

    /// @notice Get the Amount of stETH shares that are pending to be distributed
    /// @return pendingShares Amount shares that are pending to distribute
    function pendingSharesToDistribute() external view returns (uint256);

    /// @notice Get a hash of a leaf
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Amount of stETH shares
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second preimage attacks
    function hashLeaf(
        uint256 nodeOperatorId,
        uint256 shares
    ) external pure returns (bytes32);
}
