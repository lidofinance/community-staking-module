// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

/**
 * @title Interface defining ERC20-compatible StETH token
 */
interface IStETH {
    /**
     * @notice Get stETH amount by the provided shares amount
     * @param _sharesAmount shares amount
     * @dev dual to `getSharesByPooledEth`.
     */
    function getPooledEthByShares(
        uint256 _sharesAmount
    ) external view returns (uint256);

    /**
     * @notice Get shares amount by the provided stETH amount
     * @param _pooledEthAmount stETH amount
     * @dev dual to `getPooledEthByShares`.
     */
    function getSharesByPooledEth(
        uint256 _pooledEthAmount
    ) external view returns (uint256);

    /**
     * @notice Get shares amount of the provided account
     * @param _account provided account address.
     */
    function sharesOf(address _account) external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    /**
     * @notice Transfer `_sharesAmount` stETH shares from `_sender` to `_recipient` using allowance.
     */
    function transferSharesFrom(
        address _sender,
        address _recipient,
        uint256 _sharesAmount
    ) external returns (uint256);

    /**
     * @notice Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.
     */
    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) external returns (uint256);

    /**
     * @notice Moves `_amount` stETH from the caller's account to the `_recipient` account.
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice Moves `_amount` stETH from the `_sender` account to the `_recipient` account.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256);
}
