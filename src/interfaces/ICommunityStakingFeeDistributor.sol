// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

struct FeeReward {
    uint256 nodeOperatorId;
    uint256 accumulatedShares;
}

interface ICommunityStakingFeeDistributor {
    function distributeFees(
        bytes32[] calldata rewardProof,
        FeeReward calldata feeReward
    ) external returns (uint256);
}
