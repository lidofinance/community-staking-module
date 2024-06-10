// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ICSBondLock } from "../interfaces/ICSBondLock.sol";

/// @dev Bond lock mechanics abstract contract.
///
/// It gives the ability to lock the bond amount of the Node Operator.
/// There is a period of time during which the module can settle the lock in any way (for example, by penalizing the bond).
/// After that period, the lock is removed, and the bond amount is considered unlocked.
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
/// It should be inherited by a module contract or a module-related contract.
/// Internal non-view methods should be used in the Module contract with additional requirements (if any).
///
/// @author vgorkavenko
abstract contract CSBondLock is ICSBondLock, Initializable {
    /// @custom:storage-location erc7201:CSAccounting.CSBondLock
    struct CSBondLockStorage {
        /// @dev Default bond lock retention period for all locks
        ///      After this period the bond lock is removed and no longer valid
        uint256 bondLockRetentionPeriod;
        /// @dev Mapping of the Node Operator id to the bond lock
        mapping(uint256 nodeOperatorId => BondLock) bondLock;
    }

    // keccak256(abi.encode(uint256(keccak256("CSBondLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_LOCK_STORAGE_LOCATION =
        0x78c5a36767279da056404c09083fca30cf3ea61c442cfaba6669f76a37393f00;

    uint256 public immutable MIN_BOND_LOCK_RETENTION_PERIOD;
    uint256 public immutable MAX_BOND_LOCK_RETENTION_PERIOD;

    event BondLockChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 retentionUntil
    );
    event BondLockRetentionPeriodChanged(uint256 retentionPeriod);

    error InvalidBondLockRetentionPeriod();
    error InvalidBondLockAmount();

    constructor(
        uint256 minBondLockRetentionPeriod,
        uint256 maxBondLockRetentionPeriod
    ) {
        if (minBondLockRetentionPeriod > maxBondLockRetentionPeriod) {
            revert InvalidBondLockRetentionPeriod();
        }
        MIN_BOND_LOCK_RETENTION_PERIOD = minBondLockRetentionPeriod;
        MAX_BOND_LOCK_RETENTION_PERIOD = maxBondLockRetentionPeriod;
    }

    /// @notice Get default bond lock retention period
    /// @return Default bond lock retention period
    function getBondLockRetentionPeriod() external view returns (uint256) {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        return $.bondLockRetentionPeriod;
    }

    /// @notice Get information about the locked bond for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Locked bond info
    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) public view returns (BondLock memory) {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        return $.bondLock[nodeOperatorId];
    }

    /// @notice Get amount of the locked bond in ETH (stETH) by the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Amount of the actual locked bond
    function getActualLockedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        BondLock storage bondLock = $.bondLock[nodeOperatorId];
        if (bondLock.retentionUntil < block.timestamp) {
            return 0;
        }
        return bondLock.amount;
    }

    /// @dev Lock bond amount for the given Node Operator until the retention period.
    function _lock(uint256 nodeOperatorId, uint256 amount) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        unchecked {
            if (block.timestamp < $.bondLock[nodeOperatorId].retentionUntil) {
                amount += $.bondLock[nodeOperatorId].amount;
            }
            _changeBondLock({
                nodeOperatorId: nodeOperatorId,
                amount: amount,
                retentionUntil: block.timestamp + $.bondLockRetentionPeriod
            });
        }
    }

    /// @dev Reduce locked bond amount for the given Node Operator without changing retention period
    function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        uint256 blocked = getActualLockedBond(nodeOperatorId);
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        if (blocked < amount) {
            revert InvalidBondLockAmount();
        }
        unchecked {
            _changeBondLock(
                nodeOperatorId,
                $.bondLock[nodeOperatorId].amount - amount,
                $.bondLock[nodeOperatorId].retentionUntil
            );
        }
    }

    /// @dev Remove bond lock for the given Node Operator
    function _remove(uint256 nodeOperatorId) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        delete $.bondLock[nodeOperatorId];
        emit BondLockChanged(nodeOperatorId, 0, 0);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondLock_init(
        uint256 retentionPeriod
    ) internal onlyInitializing {
        _setBondLockRetentionPeriod(retentionPeriod);
    }

    /// @dev Set default bond lock retention period. That period will be sum with the current block timestamp of lock tx
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
            $.slot := CS_BOND_LOCK_STORAGE_LOCATION
        }
    }
}
