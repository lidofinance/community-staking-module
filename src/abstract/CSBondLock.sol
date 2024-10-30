// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
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
///  - set default bond lock freeze period
///  - get default bond lock freeze period
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

    /// @custom:storage-location erc7201:CSAccounting.CSBondLock
    struct CSBondLockStorage {
        /// @dev Default bond lock freeze period for all locks
        ///      After this period the bond lock is removed and no longer valid
        uint256 bondLockFreezePeriod;
        /// @dev Mapping of the Node Operator id to the bond lock
        mapping(uint256 nodeOperatorId => BondLock) bondLock;
    }

    // keccak256(abi.encode(uint256(keccak256("CSBondLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_LOCK_STORAGE_LOCATION =
        0x78c5a36767279da056404c09083fca30cf3ea61c442cfaba6669f76a37393f00;

    uint256 public immutable MIN_BOND_LOCK_FREEZE_PERIOD;
    uint256 public immutable MAX_BOND_LOCK_FREEZE_PERIOD;

    event BondLockChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 freezeUntil
    );
    event BondLockRemoved(uint256 indexed nodeOperatorId);

    event BondLockFreezePeriodChanged(uint256 freezePeriod);

    error InvalidBondLockFreezePeriod();
    error InvalidBondLockAmount();

    constructor(
        uint256 minBondLockFreezePeriod,
        uint256 maxBondLockFreezePeriod
    ) {
        if (minBondLockFreezePeriod > maxBondLockFreezePeriod) {
            revert InvalidBondLockFreezePeriod();
        }
        // freeze period can not be more than type(uint64).max to avoid overflow when setting bond lock
        if (maxBondLockFreezePeriod > type(uint64).max) {
            revert InvalidBondLockFreezePeriod();
        }
        MIN_BOND_LOCK_FREEZE_PERIOD = minBondLockFreezePeriod;
        MAX_BOND_LOCK_FREEZE_PERIOD = maxBondLockFreezePeriod;
    }

    /// @notice Get default bond lock freeze period
    /// @return Default bond lock freeze period
    function getBondLockFreezePeriod() external view returns (uint256) {
        return _getCSBondLockStorage().bondLockFreezePeriod;
    }

    /// @notice Get information about the locked bond for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Locked bond info
    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) public view returns (BondLock memory) {
        return _getCSBondLockStorage().bondLock[nodeOperatorId];
    }

    /// @notice Get amount of the locked bond in ETH (stETH) by the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Amount of the actual locked bond
    function getActualLockedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        BondLock storage bondLock = _getCSBondLockStorage().bondLock[
            nodeOperatorId
        ];
        return bondLock.freezeUntil > block.timestamp ? bondLock.amount : 0;
    }

    /// @dev Lock bond amount for the given Node Operator until the freeze period.
    function _lock(uint256 nodeOperatorId, uint256 amount) internal {
        CSBondLockStorage storage $ = _getCSBondLockStorage();
        if (amount == 0) {
            revert InvalidBondLockAmount();
        }
        if ($.bondLock[nodeOperatorId].freezeUntil > block.timestamp) {
            amount += $.bondLock[nodeOperatorId].amount;
        }
        _changeBondLock({
            nodeOperatorId: nodeOperatorId,
            amount: amount,
            freezeUntil: block.timestamp + $.bondLockFreezePeriod
        });
    }

    /// @dev Reduce locked bond amount for the given Node Operator without changing freeze period
    function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal {
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
                blocked - amount,
                _getCSBondLockStorage().bondLock[nodeOperatorId].freezeUntil
            );
        }
    }

    /// @dev Remove bond lock for the given Node Operator
    function _remove(uint256 nodeOperatorId) internal {
        delete _getCSBondLockStorage().bondLock[nodeOperatorId];
        emit BondLockRemoved(nodeOperatorId);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondLock_init(uint256 freezePeriod) internal onlyInitializing {
        _setBondLockFreezePeriod(freezePeriod);
    }

    /// @dev Set default bond lock freeze period. That period will be sum with the current block timestamp of lock tx
    function _setBondLockFreezePeriod(uint256 freezePeriod) internal {
        if (
            freezePeriod < MIN_BOND_LOCK_FREEZE_PERIOD ||
            freezePeriod > MAX_BOND_LOCK_FREEZE_PERIOD
        ) {
            revert InvalidBondLockFreezePeriod();
        }
        _getCSBondLockStorage().bondLockFreezePeriod = freezePeriod;
        emit BondLockFreezePeriodChanged(freezePeriod);
    }

    function _changeBondLock(
        uint256 nodeOperatorId,
        uint256 amount,
        uint256 freezeUntil
    ) private {
        if (amount == 0) {
            _remove(nodeOperatorId);
            return;
        }
        _getCSBondLockStorage().bondLock[nodeOperatorId] = BondLock({
            amount: amount.toUint128(),
            freezeUntil: freezeUntil.toUint128()
        });
        emit BondLockChanged(nodeOperatorId, amount, freezeUntil);
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
