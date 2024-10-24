// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSBondLock {
    /// @dev Bond lock structure.
    /// It contains:
    ///  - amount         |> amount of locked bond
    ///  - retentionUntil |> timestamp until locked bond is retained
    struct BondLock {
        uint128 amount;
        uint128 retentionUntil;
    }

    function getBondLockRetentionPeriod()
        external
        view
        returns (uint256 retention);

    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) external view returns (BondLock memory);

    function getActualLockedBond(
        uint256 nodeOperatorId
    ) external view returns (uint256);
}
