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
}
