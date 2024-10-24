// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSBondCore {
    function totalBondShares() external view returns (uint256);

    function getBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBond(uint256 nodeOperatorId) external view returns (uint256);
}
