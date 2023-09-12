// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface ICommunityStakingBondManager {
    function getBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBondEth(uint256 nodeOperatorId) external view returns (uint256);

    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256);

    function depositETH(
        uint256 nodeOperatorId
    ) external payable returns (uint256);

    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256);

    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable returns (uint256);

    function getRequiredBondSharesForKeys(
        uint256 keysCount
    ) external view returns (uint256);

    function getRequiredBondEthForKeys(
        uint256 keysCount
    ) external view returns (uint256);

    function getRequiredBondEth(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getRequiredBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);
}
