// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStakingModule } from "./IStakingModule.sol";

/// @title Lido's Community Staking Module interface
interface ICSModule is IStakingModule {
    struct NodeOperatorInfo {
        bool active;
        address managerAddress;
        address rewardAddress;
        uint256 totalVettedValidators;
        uint256 totalExitedValidators;
        uint256 totalWithdrawnValidators;
        uint256 totalAddedValidators;
        uint256 totalDepositedValidators;
    }

    /// @notice Returns the node operator by id
    /// @param nodeOperatorId Node Operator id
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperatorInfo memory);

    /// @notice Gets node operator signing keys
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return Signing keys
    function getNodeOperatorSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory);

    /// @notice Report node operator's key as withdrawn and settle withdrawn amount.
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the withdrawn key in the node operator's keys.
    /// @param amount Amount of withdrawn ETH in wei.
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    ) external;
}
