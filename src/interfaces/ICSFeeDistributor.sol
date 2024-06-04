// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSFeeDistributor {
    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external view returns (uint256);

    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external returns (uint256);

    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid,
        uint256 _distributedShares
    ) external;

    /// @notice Returns the amount of shares that are pending to be distributed
    function pendingSharesToDistribute() external view returns (uint256);
}
