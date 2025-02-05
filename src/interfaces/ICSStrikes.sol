// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSStrikes {
    /// @dev Emitted when strikes data is updated
    event StrikesDataUpdated(bytes32 treeRoot, string treeCid);
    /// @dev Emitted when strikes is updated from non-empty to empty
    event StrikesDataWiped();

    error ZeroAdminAddress();
    error ZeroOracleAddress();
    error ZeroEjectionFeeAmount();
    error ZeroBadPerformancePenaltyAmount();
    error NotOracle();

    error InvalidReportData();

    error InvalidProof();

    function ORACLE() external view returns (address);

    function treeRoot() external view returns (bytes32);

    function treeCid() external view returns (string calldata);

    /// @notice Receive the data of the Merkle tree from the Oracle contract and process it
    /// @param _treeRoot Root of the Merkle tree
    /// @param _treeCid an IPFS CID of the tree
    /// @dev New tree might be empty and it is valid value because of `strikesLifetime`
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid
    ) external;

    /// @notice Check if Key is eligible to be ejected
    /// @param nodeOperatorId ID of the Node Operator
    /// @param pubkey Pubkey of the Node Operator
    /// @param strikesData Strikes of the Node Operator
    /// @param proof Merkle proof of the leaf
    function verifyProof(
        uint256 nodeOperatorId,
        bytes calldata pubkey,
        uint256[] calldata strikesData,
        bytes32[] calldata proof
    ) external view;

    /// @notice Get a hash of a leaf
    /// @param nodeOperatorId ID of the Node Operator
    /// @param pubkey pubkey of the Node Operator
    /// @param strikes Strikes of the Node Operator
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second pre-image attacks
    function hashLeaf(
        uint256 nodeOperatorId,
        bytes calldata pubkey,
        uint256[] calldata strikes
    ) external pure returns (bytes32);
}
