// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract CSBondLock is Initializable {
    /// @dev Bond lock structure.
    /// It contains:
    ///  - amount         |> amount of locked bond
    ///  - retentionUntil |> timestamp until locked bond is retained
    struct BondLock {
        uint256 amount;
        uint256 retentionUntil;
    }

    /// @custom:storage-location erc7201:CSAccounting.CSBondLock
    struct CSBondLockStorage {
        /// @dev Default bond lock retention period for all locks
        ///      After this period the bond lock is removed and no longer valid
        uint256 bondLockRetentionPeriod;
        /// @dev Mapping of the node operator id to the bond lock
        mapping(uint256 => BondLock) bondLock;
    }

    // keccak256(abi.encode(uint256(keccak256("CSAccounting.CSBondLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CSBondLockStorageLocation =
        0xde370123b9d98e59208021489ba3cc409fe2a07de86192b6a571d85c904ce000;

    // TODO: should be reconsidered
    uint256 public constant MIN_BOND_LOCK_RETENTION_PERIOD = 4 weeks;
    uint256 public constant MAX_BOND_LOCK_RETENTION_PERIOD = 365 days;

    event BondLockChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 retentionUntil
    );
    event BondLockRetentionPeriodChanged(uint256 retentionPeriod);

    error InvalidBondLockRetentionPeriod();
    error InvalidBondLockAmount();

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondLock_init(
        uint256 retentionPeriod
    ) internal onlyInitializing {
        _setBondLockRetentionPeriod(retentionPeriod);
    }

    /// @dev Sets default bond lock retention period. That period will be sum with the current block timestamp of lock tx.
    function _setBondLockRetentionPeriod(uint256 retentionPeriod) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if (
            retentionPeriod < MIN_BOND_LOCK_RETENTION_PERIOD ||
            retentionPeriod > MAX_BOND_LOCK_RETENTION_PERIOD
        ) {
            revert InvalidBondLockRetentionPeriod();
        }
        $.bondLockRetentionPeriod = retentionPeriod;
        emit BondLockRetentionPeriodChanged(retentionPeriod);
    }

    /// @notice Returns default bond lock retention period.
    /// @return retention default bond lock retention period.
    function getBondLockRetentionPeriod()
        external
        view
        returns (uint256 retention)
    {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        return $.bondLockRetentionPeriod;
    }

    /// @notice Returns information about the locked bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to get locked bond info for.
    /// @return locked bond info.
    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) public view returns (BondLock memory) {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        return $.bondLock[nodeOperatorId];
    }

    /// @notice Returns the amount of locked bond in ETH by the given node operator.
    /// @param nodeOperatorId id of the node operator to get locked bond amount.
    /// @return amount of actual locked bond.
    function getActualLockedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if ($.bondLock[nodeOperatorId].retentionUntil >= block.timestamp) {
            return $.bondLock[nodeOperatorId].amount;
        }
        return 0;
    }

    /// @dev Locks bond amount for the given node operator until the retention period.
    function _lock(uint256 nodeOperatorId, uint256 amount) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        if (block.timestamp < $.bondLock[nodeOperatorId].retentionUntil) {
            amount += $.bondLock[nodeOperatorId].amount;
        }
        _changeBondLock({
            nodeOperatorId: nodeOperatorId,
            amount: amount,
            retentionUntil: block.timestamp + $.bondLockRetentionPeriod
        });
    }

    /// @dev Reduces locked bond amount for the given node operator without changing retention period.
    function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        uint256 blocked = getActualLockedBond(nodeOperatorId);
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        if (blocked < amount) {
            revert InvalidBondLockAmount();
        }
        _changeBondLock(
            nodeOperatorId,
            $.bondLock[nodeOperatorId].amount - amount,
            $.bondLock[nodeOperatorId].retentionUntil
        );
    }

    /// @dev Removes bond lock for the given node operator.
    function _remove(uint256 nodeOperatorId) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        // TODO: check existing lock
        delete $.bondLock[nodeOperatorId];
        emit BondLockChanged(nodeOperatorId, 0, 0);
    }

    function _changeBondLock(
        uint256 nodeOperatorId,
        uint256 amount,
        uint256 retentionUntil
    ) private {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if (amount == 0) {
            _remove(nodeOperatorId);
            return;
        }
        $.bondLock[nodeOperatorId] = BondLock({
            amount: amount,
            retentionUntil: retentionUntil
        });
        emit BondLockChanged(nodeOperatorId, amount, retentionUntil);
    }

    function _getCSBondLockStorage()
        private
        pure
        returns (CSBondLockStorage storage $)
    {
        assembly {
            $.slot := CSBondLockStorageLocation
        }
    }
}
