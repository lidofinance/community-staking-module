// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.24;

abstract contract CSBondLockBase {
    event BondLockChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 retentionUntil
    );
    event BondLockRetentionPeriodChanged(uint256 retentionPeriod);

    error InvalidBondLockRetentionPeriod();
    error InvalidBondLockAmount();
}

/// @dev Bond lock mechanics abstract contract.
///
/// It gives ability to lock bond amount of the node operator.
/// There is a period of time during which the lock can be settled in any way by the module (for example, by penalizing the bond).
/// After that period, the lock is removed and the bond amount is considered as unlocked.
///
/// The contract contains:
///  - set default bond lock retention period
///  - get default bond lock retention period
///  - lock bond
///  - get locked bond info
///  - get actual locked bond amount
///  - reduce locked bond amount
///  - remove bond lock
///
/// Should be inherited by Module contract, or Module-related contract.
/// Internal non-view methods should be used in Module contract with additional requirements (if required).
///
/// @author vgorkavenko
abstract contract CSBondLock is CSBondLockBase {
    /// @dev Bond lock structure.
    /// It contains:
    ///  - amount         |> amount of locked bond
    ///  - retentionUntil |> timestamp until locked bond is retained
    struct BondLock {
        uint256 amount;
        uint256 retentionUntil;
    }

    // TODO: should be reconsidered
    uint256 public constant MIN_BOND_LOCK_RETENTION_PERIOD = 4 weeks;
    uint256 public constant MAX_BOND_LOCK_RETENTION_PERIOD = 365 days;

    /// @dev Default bond lock retention period for all locks
    ///      After this period the bond lock is removed and no longer valid
    uint256 internal _bondLockRetentionPeriod;

    /// @dev Mapping of the node operator id to the bond lock
    mapping(uint256 => BondLock) internal _bondLock;

    constructor(uint256 retentionPeriod) {
        _setBondLockRetentionPeriod(retentionPeriod);
    }

    /// @dev Sets default bond lock retention period. That period will be sum with the current block timestamp of lock tx.
    function _setBondLockRetentionPeriod(uint256 retentionPeriod) internal {
        if (
            retentionPeriod < MIN_BOND_LOCK_RETENTION_PERIOD ||
            retentionPeriod > MAX_BOND_LOCK_RETENTION_PERIOD
        ) {
            revert InvalidBondLockRetentionPeriod();
        }
        _bondLockRetentionPeriod = retentionPeriod;
        emit BondLockRetentionPeriodChanged(retentionPeriod);
    }

    /// @notice Returns default bond lock retention period.
    /// @return retention default bond lock retention period.
    function getBondLockRetentionPeriod()
        external
        view
        returns (uint256 retention)
    {
        return _bondLockRetentionPeriod;
    }

    /// @notice Returns information about the locked bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to get locked bond info for.
    /// @return locked bond info.
    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) public view returns (BondLock memory) {
        return _bondLock[nodeOperatorId];
    }

    /// @notice Returns the amount of locked bond in ETH by the given node operator.
    /// @param nodeOperatorId id of the node operator to get locked bond amount.
    /// @return amount of actual locked bond.
    function getActualLockedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        if (_bondLock[nodeOperatorId].retentionUntil >= block.timestamp) {
            return _bondLock[nodeOperatorId].amount;
        }
        return 0;
    }

    /// @dev Locks bond amount for the given node operator until the retention period.
    function _lock(uint256 nodeOperatorId, uint256 amount) internal {
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        if (block.timestamp < _bondLock[nodeOperatorId].retentionUntil) {
            amount += _bondLock[nodeOperatorId].amount;
        }
        _changeBondLock({
            nodeOperatorId: nodeOperatorId,
            amount: amount,
            retentionUntil: block.timestamp + _bondLockRetentionPeriod
        });
    }

    /// @dev Reduces locked bond amount for the given node operator without changing retention period.
    function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal {
        uint256 blocked = getActualLockedBond(nodeOperatorId);
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        if (blocked < amount) {
            revert InvalidBondLockAmount();
        }
        _changeBondLock(
            nodeOperatorId,
            _bondLock[nodeOperatorId].amount - amount,
            _bondLock[nodeOperatorId].retentionUntil
        );
    }

    /// @dev Removes bond lock for the given node operator.
    function _remove(uint256 nodeOperatorId) internal {
        // TODO: check existing lock
        delete _bondLock[nodeOperatorId];
        emit BondLockChanged(nodeOperatorId, 0, 0);
    }

    function _changeBondLock(
        uint256 nodeOperatorId,
        uint256 amount,
        uint256 retentionUntil
    ) private {
        if (amount == 0) {
            _remove(nodeOperatorId);
            return;
        }
        _bondLock[nodeOperatorId] = BondLock({
            amount: amount,
            retentionUntil: retentionUntil
        });
        emit BondLockChanged(nodeOperatorId, amount, retentionUntil);
    }
}
