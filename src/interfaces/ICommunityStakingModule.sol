// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStakingModule } from "./IStakingModule.sol";

/// @title Lido's Community Staking Module interface
interface ICommunityStakingModule is IStakingModule {
    /// @notice Returns the node operator by id
    /// @param _nodeOperatorId Node Operator id
    /// @param _fullInfo If true, name will be returned as well
    function getNodeOperator(
        uint256 _nodeOperatorId,
        bool _fullInfo
    )
        external
        view
        returns (
            bool active,
            string memory name,
            address rewardAddress,
            uint64 totalVettedValidators,
            uint64 totalExitedValidators,
            uint64 totalWithdrawnValidators, // new
            uint64 totalAddedValidators,
            uint64 totalDepositedValidators
        );
}
