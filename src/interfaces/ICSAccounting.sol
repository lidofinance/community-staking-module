// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface ICSAccounting {
    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function getBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBond(uint256 nodeOperatorId) external view returns (uint256);

    function depositWstETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput calldata permit
    ) external returns (uint256);

    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) external returns (uint256);

    function depositStETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput calldata permit
    ) external returns (uint256);

    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256);

    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable returns (uint256);

    function getBondAmountByKeysCount(
        uint256 keys
    ) external view returns (uint256);

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount
    ) external view returns (uint256);

    function getRequiredBondForNextKeys(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) external view returns (uint256);

    function getRequiredBondForNextKeysWstETH(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) external view returns (uint256);

    function penalize(uint256 nodeOperatorId, uint256 shares) external;
}
