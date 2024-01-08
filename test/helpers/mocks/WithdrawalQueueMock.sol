// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract WithdrawalQueueMock {
    /// @notice minimal amount of stETH that is possible to withdraw
    uint256 public constant MIN_STETH_WITHDRAWAL_AMOUNT = 100;

    /// @notice maximum amount of stETH that is possible to withdraw by a single request
    /// Prevents accumulating too much funds per single request fulfillment in the future.
    /// @dev To withdraw larger amounts, it's recommended to split it to several requests
    uint256 public constant MAX_STETH_WITHDRAWAL_AMOUNT = 1000 * 1e18;
}
