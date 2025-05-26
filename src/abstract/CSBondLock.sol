// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ICSBondLock } from "../interfaces/ICSBondLock.sol";

/// @dev Bond lock mechanics abstract contract.
///
/// It gives the ability to lock the bond amount of the Node Operator.
/// There is a period of time during which the module can settle the lock in any way (for example, by penalizing the bond).
/// After that period, the lock is removed, and the bond amount is considered unlocked.
///
/// The contract contains:
///  - set default bond lock period
///  - get default bond lock period
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
    using SafeCast for uint256;

    /// @custom:storage-location erc7201:CSBondLock
    struct CSBondLockStorage {
        /// @dev Default bond lock period for all locks
        ///      After this period the bond lock is removed and no longer valid
        uint256 bondLockPeriod;
        /// @dev Mapping of the Node Operator id to the bond lock
        mapping(uint256 nodeOperatorId => BondLock) bondLock;
    }

    // keccak256(abi.encode(uint256(keccak256("CSBondLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_LOCK_STORAGE_LOCATION =
        0x78c5a36767279da056404c09083fca30cf3ea61c442cfaba6669f76a37393f00;

    uint256 public immutable MIN_BOND_LOCK_PERIOD;
    uint256 public immutable MAX_BOND_LOCK_PERIOD;

    constructor(uint256 minBondLockPeriod, uint256 maxBondLockPeriod) {
        if (minBondLockPeriod > maxBondLockPeriod) {
            revert InvalidBondLockPeriod();
        }
        // period can not be more than type(uint64).max to avoid overflow when setting bond lock
        if (maxBondLockPeriod > type(uint64).max) {
            revert InvalidBondLockPeriod();
        }
        MIN_BOND_LOCK_PERIOD = minBondLockPeriod;
        MAX_BOND_LOCK_PERIOD = maxBondLockPeriod;
    }

    /// @inheritdoc ICSBondLock
    function getBondLockPeriod() external view returns (uint256) {
        return _getCSBondLockStorage().bondLockPeriod;
    }

    /// @inheritdoc ICSBondLock
    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) external view returns (BondLock memory) {
        return _getCSBondLockStorage().bondLock[nodeOperatorId];
    }

    /// @inheritdoc ICSBondLock
    function getActualLockedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        BondLock storage bondLock = _getCSBondLockStorage().bondLock[
            nodeOperatorId
        ];
        return bondLock.until > block.timestamp ? bondLock.amount : 0;
    }

    /// @dev Lock bond amount for the given Node Operator until the period.
    function _lock(uint256 nodeOperatorId, uint256 amount) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        BondLock memory lock = $.bondLock[nodeOperatorId];
        if (lock.until > block.timestamp) {
            amount += lock.amount;
        }
        unchecked {
            _changeBondLock({
                nodeOperatorId: nodeOperatorId,
                amount: amount,
                until: block.timestamp + $.bondLockPeriod
            });
        }
    }

    /// @dev Reduce the locked bond amount for the given Node Operator without changing the lock period
    function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal {
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        uint256 locked = getActualLockedBond(nodeOperatorId);
        if (locked < amount) {
            revert InvalidBondLockAmount();
        }
        unchecked {
            _changeBondLock(
                nodeOperatorId,
                locked - amount,
                _getCSBondLockStorage().bondLock[nodeOperatorId].until
            );
        }
    }

    /// @dev Remove bond lock for the given Node Operator
    function _remove(uint256 nodeOperatorId) internal {
        delete _getCSBondLockStorage().bondLock[nodeOperatorId];
        emit BondLockRemoved(nodeOperatorId);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondLock_init(uint256 period) internal onlyInitializing {
        _setBondLockPeriod(period);
    }

    /// @dev Set default bond lock period. That period will be added to the block timestamp of the lock translation to determine the bond lock duration
    function _setBondLockPeriod(uint256 period) internal {
        if (period < MIN_BOND_LOCK_PERIOD || period > MAX_BOND_LOCK_PERIOD) {
            revert InvalidBondLockPeriod();
        }
        _getCSBondLockStorage().bondLockPeriod = period;
        emit BondLockPeriodChanged(period);
    }

    function _changeBondLock(
        uint256 nodeOperatorId,
        uint256 amount,
        uint256 until
    ) private {
        if (amount == 0) {
            _remove(nodeOperatorId);
            return;
        }
        _getCSBondLockStorage().bondLock[nodeOperatorId] = BondLock({
            amount: amount.toUint128(),
            until: until.toUint128()
        });
        emit BondLockChanged(nodeOperatorId, amount, until);
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
