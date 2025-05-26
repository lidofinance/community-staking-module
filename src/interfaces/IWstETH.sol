// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IWstETH {
    function balanceOf(address account) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transfer(address recipient, uint256 amount) external;

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

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
