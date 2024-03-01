// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IWithdrawalQueue {
    /// @notice minimal amount of stETH that is possible to withdraw
    function MIN_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /// @notice maximum amount of stETH that is possible to withdraw by a single request
    /// Prevents accumulating too much funds per single request fulfillment in the future.
    /// @dev To withdraw larger amounts, it's recommended to split it to several requests
    function MAX_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);
}
