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
    ) external view returns (IBondReserve.BondReserveInfo memory) {
        IBondReserve.BondReserveInfo memory r = _getBondReserveStorage()
            .reserve[nodeOperatorId];
        return
            IBondReserve.BondReserveInfo({
                amount: r.amount,
                removableAt: r.removableAt
            });
    }

    /// @dev Get raw reserve info for internal usage
    function _getBondReserveInfo(
        uint256 nodeOperatorId
    ) internal view returns (IBondReserve.BondReserveInfo memory) {
        return _getBondReserveStorage().reserve[nodeOperatorId];
    }

    /// @dev Get current reserved amount in ETH (stETH) for a Node Operator
    function _getReservedBond(
        uint256 nodeOperatorId
    ) internal view returns (uint256) {
        return _getBondReserveStorage().reserve[nodeOperatorId].amount;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __BondReserve_init(uint256 minPeriod) internal onlyInitializing {
        _setBondReserveMinPeriod(minPeriod);
    }

    /// @dev Set minimum cooldown for reserve removal
    function _setBondReserveMinPeriod(uint256 period) internal {
        if (period == 0) {
            revert InvalidBondReservePeriod();
        }
        _getBondReserveStorage().minBondReservePeriod = period;
        emit BondReserveMinPeriodChanged(period);
    }

    /// @dev Increase additional reserve for a Node Operator by `amount` and extend cooldown
    function _increaseReserve(uint256 nodeOperatorId, uint256 amount) internal {
        if (amount == 0) revert InvalidBondReserveAmount();
        BondReserveStorage storage $ = _getBondReserveStorage();
        IBondReserve.BondReserveInfo storage r = $.reserve[nodeOperatorId];

        uint256 newAmount = uint256(r.amount) + amount;
        uint256 newUntil = block.timestamp + $.minBondReservePeriod;
        r.removableAt = newUntil.toUint128();
        r.amount = newAmount.toUint128();
        emit BondReserveChanged(nodeOperatorId, newAmount, newUntil);
    }

    /// @dev Reduce reserve by `amount` (used when penalties/charges)
    function _reduceReserveAmount(
        uint256 nodeOperatorId,
        uint256 amount
    ) internal {
        if (amount == 0) return;
        BondReserveStorage storage $ = _getBondReserveStorage();
        IBondReserve.BondReserveInfo storage r = $.reserve[nodeOperatorId];
        uint256 current = r.amount;
        if (current == 0) return;

        uint256 newAmount = current > amount ? current - amount : 0;
        if (newAmount == 0) {
            delete $.reserve[nodeOperatorId];
            emit BondReserveRemoved(nodeOperatorId);
        } else {
            r.amount = uint128(newAmount);
            emit BondReserveChanged(nodeOperatorId, newAmount, r.removableAt);
        }
    }

    /// @dev Remove the whole reserve for a Node Operator
    function _removeReserve(uint256 nodeOperatorId) internal {
        BondReserveStorage storage $ = _getBondReserveStorage();
        if ($.reserve[nodeOperatorId].amount == 0) return;
        delete $.reserve[nodeOperatorId];
        emit BondReserveRemoved(nodeOperatorId);
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
