// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IWithdrawalVault {
    function getWithdrawalRequestFee() external view returns (uint256);
}
