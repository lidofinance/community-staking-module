// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface ICommunityStakingFeeDistributor {
    function distributeFees(
        bytes32[] calldata rewardProof,
        uint256 noIndex,
        uint256 shares
    ) external returns (uint256);
}
