// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface ICommunityStakingBondManager {
    function deposit(
        address from,
        uint256 nodeOperatorId,
        uint256 shares
    ) external;

    function getRequiredBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);
}
