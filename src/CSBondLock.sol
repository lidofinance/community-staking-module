// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract CSBondLockBase {
    event BondLockChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 retentionUntil
    );
    event BondLockRetentionPeriodChanged(uint256 retentionPeriod);

    error InvalidBondLockRetentionPeriod();
    error InvalidBondLockAmount();
}

abstract contract CSBondLock is CSBondLockBase {
    struct BondLock {
        uint256 amount;
        uint256 retentionUntil;
    }

    // todo: should be reconsidered
    uint256 public constant MIN_BOND_LOCK_RETENTION_PERIOD = 4 weeks;
    uint256 public constant MAX_BOND_LOCK_RETENTION_PERIOD = 365 days;

    uint256 internal _bondLockRetentionPeriod;

    mapping(uint256 => BondLock) internal _bondLock;

    constructor(uint256 retentionPeriod) {
        _setBondLockRetentionPeriod(retentionPeriod);
    }

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
    /// @return amount of locked bond in ETH.
    function getActualLockedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        if (_bondLock[nodeOperatorId].retentionUntil >= block.timestamp) {
            return _bondLock[nodeOperatorId].amount;
        }
        return 0;
    }

    /// @notice Reports EL rewards stealing for the given node operator.
    /// @param nodeOperatorId id of the node operator to lock bond for.
    /// @param amount amount to lock.
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

    function _changeBondLock(
        uint256 nodeOperatorId,
        uint256 amount,
        uint256 retentionUntil
    ) private {
        if (amount == 0) {
            delete _bondLock[nodeOperatorId];
            emit BondLockChanged(nodeOperatorId, 0, 0);
            return;
        }
        _bondLock[nodeOperatorId] = BondLock({
            amount: amount,
            retentionUntil: retentionUntil
        });
        emit BondLockChanged(nodeOperatorId, amount, retentionUntil);
    }
}
