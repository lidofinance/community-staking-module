// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IBondReserve } from "../interfaces/IBondReserve.sol";

/// @dev Additional Bond Reserve mechanics abstract contract.
/// This contract provides storage and internal helpers to manage the reserve value per Node Operator.
abstract contract BondReserve is Initializable, IBondReserve {
    using SafeCast for uint256;

    /// @custom:storage-location erc7201:BondReserve
    struct BondReserveStorage {
        /// @dev Minimum cooldown for any reserve increase before it can be removed.
        uint256 minBondReservePeriod;
        /// @dev Mapping of the Node Operator id to the additional reserve info
        mapping(uint256 nodeOperatorId => IBondReserve.BondReserveInfo) reserve;
    }

    // keccak256(abi.encode(uint256(keccak256("BondReserve")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BOND_RESERVE_STORAGE_LOCATION =
        0xff8c44575080f51f299862a93b6dcf35fa9c3cefb78d7f632f77807658d3cd00;

    /// @notice Get current min reserve cooldown in seconds
    function getBondReserveMinPeriod() external view returns (uint256) {
        return _getBondReserveStorage().minBondReservePeriod;
    }

    /// @notice Get additional reserve info for a Node Operator
    function getBondReserveInfo(
        uint256 nodeOperatorId
    ) public view returns (IBondReserve.BondReserveInfo memory) {
        return _getBondReserveStorage().reserve[nodeOperatorId];
    }

    /// @notice Get current reserved amount in ETH (stETH) for a Node Operator
    function getReservedBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return _getBondReserveStorage().reserve[nodeOperatorId].amount;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __BondReserve_init(uint256 minPeriod) internal onlyInitializing {
        _setBondReserveMinPeriod(minPeriod);
    }

    /// @dev Set minimum cooldown for reserve removal
    function _setBondReserveMinPeriod(uint256 period) internal {
        if (period == 0) {
            revert InvalidBondReserveMinPeriod();
        }
        _getBondReserveStorage().minBondReservePeriod = period;
        emit BondReserveMinPeriodChanged(period);
    }

    // @dev Set value for reserve. Can be used to set, update, remove the value
    function _setBondReserve(
        uint256 nodeOperatorId,
        uint256 newAmount
    ) internal {
        BondReserveStorage storage $ = _getBondReserveStorage();
        IBondReserve.BondReserveInfo storage r = $.reserve[nodeOperatorId];
        uint128 currentAmount = r.amount;
        if (newAmount == 0) {
            if (currentAmount == 0) {
                return;
            }
            delete $.reserve[nodeOperatorId];
            emit BondReserveRemoved(nodeOperatorId);
        }
        uint128 removableAt = r.removableAt;
        if (currentAmount < newAmount) {
            // Extend reserve period if the new reserve is bigger than the current one
            removableAt = (block.timestamp + $.minBondReservePeriod)
                .toUint128();
            r.removableAt = removableAt;
        }
        r.amount = newAmount.toUint128();
        emit BondReserveChanged(nodeOperatorId, newAmount, removableAt);
    }

    function _getBondReserveStorage()
        private
        pure
        returns (BondReserveStorage storage $)
    {
        assembly {
            $.slot := BOND_RESERVE_STORAGE_LOCATION
        }
    }
}
