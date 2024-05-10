// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { IStakingModule } from "./IStakingModule.sol";
import { ICSAccounting } from "./ICSAccounting.sol";

struct NodeOperator {
    address managerAddress;
    address proposedManagerAddress;
    address rewardAddress;
    address proposedRewardAddress;
    uint256 targetLimit;
    uint8 targetLimitMode;
    // TODO: keys could be packed into uint32
    uint256 stuckPenaltyEndTimestamp;
    uint256 totalExitedKeys; // @dev only increased
    uint256 totalAddedKeys; // @dev increased and decreased when removed
    uint256 totalWithdrawnKeys; // @dev only increased
    uint256 totalDepositedKeys; // @dev only increased
    uint256 totalVettedKeys; // @dev both increased and decreased
    uint256 stuckValidatorsCount; // @dev both increased and decreased
    uint256 refundedValidatorsCount; // @dev only increased
    uint256 depositableValidatorsCount; // @dev any value
    uint256 enqueuedCount; // Tracks how many places are occupied by the node operator's keys in the queue.
}

/// @title Lido's Community Staking Module interface
interface ICSModule is IStakingModule {
    /// @notice Gets node operator non-withdrawn keys
    /// @param nodeOperatorId ID of the node operator
    /// @return Non-withdrawn keys count
    function getNodeOperatorNonWithdrawnKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    /// @notice Returns the node operator by id
    /// @param nodeOperatorId Node Operator id
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory);

    /// @notice Gets node operator signing keys
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return Signing keys
    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory);

    /// @notice Gets node operator signing keys with signatures
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return keys Signing keys
    /// @return signatures Signatures of (deposit_message, domain) tuples
    function getSigningKeysWithSignatures(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory keys, bytes memory signatures);

    /// @notice Report node operator's key as slashed and apply initial slashing penalty.
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the slashed key in the node operator's keys.
    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    /// @notice Report node operator's key as withdrawn and settle withdrawn amount.
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the withdrawn key in the node operator's keys.
    /// @param amount Amount of withdrawn ETH in wei.
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    ) external;

    function depositWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external;

    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external;

    function depositETH(uint256 nodeOperatorId) external payable;
}
