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

    struct BondLock {
        uint256 amount;
        uint256 retentionUntil;
    }

    function getBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBondEth(uint256 nodeOperatorId) external view returns (uint256);

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

    function getRequiredBondETHForKeys(
        uint256 keysCount
    ) external view returns (uint256);

    function getRequiredBondStETHForKeys(
        uint256 keysCount
    ) external view returns (uint256);

    function getRequiredBondWstETHForKeys(
        uint256 keysCount
    ) external view returns (uint256);

    function getRequiredBondETH(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) external view returns (uint256);

    function getRequiredBondStETH(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) external view returns (uint256);

    function getRequiredBondWstETH(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) external view returns (uint256);

    function getUnbondedKeysCount(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) external view returns (BondLock memory);

    function getActualLockedBondETH(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBondLockRetentionPeriod()
        external
        view
        returns (uint256 retention);

    function releaseLockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    ) external;

    function lockBondETH(uint256 nodeOperatorId, uint256 amount) external;

    function settleLockedBondETH(uint256 nodeOperatorId) external;

    function resetBondMultiplier(uint256 nodeOperatorId) external;

    function penalize(uint256 nodeOperatorId, uint256 amount) external;
}
