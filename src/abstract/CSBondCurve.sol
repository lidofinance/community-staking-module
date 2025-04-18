// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ICSBondCurve } from "../interfaces/ICSBondCurve.sol";

/// @dev Bond curve mechanics abstract contract
///
/// It gives the ability to build bond curves for flexible bond math.
/// There is a default bond curve for all Node Operators, which might be 'overridden' for a particular Node Operator.
///
/// It contains:
///  - add bond curve
///  - get bond curve info
///  - set default bond curve
///  - set bond curve for the given Node Operator
///  - get bond curve for the given Node Operator
///  - get required bond amount for the given keys count
///  - get keys count for the given bond amount
///
/// It should be inherited by a module contract or a module-related contract.
/// Internal non-view methods should be used in the Module contract with additional requirements (if any).
///
/// @author vgorkavenko
abstract contract CSBondCurve is ICSBondCurve, Initializable {
    /// @custom:storage-location erc7201:CSBondCurve
    struct CSBondCurveStorage {
        /// @dev DEPRECATED. DO NOT USE. Preserves storage layout.
        bytes32 legacyBondCurves;
        /// @dev Mapping of Node Operator id to bond curve id
        mapping(uint256 nodeOperatorId => uint256 bondCurveId) operatorBondCurveId;
        BondCurveInterval[][] bondCurves;
    }

    // keccak256(abi.encode(uint256(keccak256("CSBondCurve")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_CURVE_STORAGE_LOCATION =
        0x8f22e270e477f5becb8793b61d439ab7ae990ed8eba045eb72061c0e6cfe1500;

    uint256 public constant MIN_CURVE_LENGTH = 1;
    uint256 public constant DEFAULT_BOND_CURVE_ID = 0;
    uint256 public immutable MAX_CURVE_LENGTH;

    constructor(uint256 maxCurveLength) {
        if (maxCurveLength < MIN_CURVE_LENGTH) {
            revert InvalidBondCurveMaxLength();
        }

        MAX_CURVE_LENGTH = maxCurveLength;
    }

    // @inheritdoc ICSBondCurve
    function getCurvesCount() external view returns (uint256) {
        return _getCSBondCurveStorage().bondCurves.length;
    }

    /// @inheritdoc ICSBondCurve
    function getCurveInfo(
        uint256 curveId
    ) public view returns (BondCurveInterval[] memory) {
        return _getCurveInfo(curveId);
    }

    /// @inheritdoc ICSBondCurve
    function getBondCurve(
        uint256 nodeOperatorId
    ) public view returns (BondCurveInterval[] memory) {
        return _getCurveInfo(getBondCurveId(nodeOperatorId));
    }

    /// @inheritdoc ICSBondCurve
    function getBondCurveId(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return _getCSBondCurveStorage().operatorBondCurveId[nodeOperatorId];
    }

    /// @inheritdoc ICSBondCurve
    function getBondAmountByKeysCount(
        uint256 keys,
        uint256 curveId
    ) public view returns (uint256) {
        return _getBondAmountByKeysCount(keys, _getCurveInfo(curveId));
    }

    /// @inheritdoc ICSBondCurve
    function getKeysCountByBondAmount(
        uint256 amount,
        uint256 curveId
    ) public view returns (uint256) {
        return _getKeysCountByBondAmount(amount, _getCurveInfo(curveId));
    }

    function _getBondAmountByKeysCount(
        uint256 keys,
        BondCurveInterval[] storage intervals
    ) internal view returns (uint256) {
        if (keys == 0) {
            return 0;
        }

        unchecked {
            uint256 low = 0;
            uint256 high = intervals.length - 1;
            while (low < high) {
                uint256 mid = (low + high + 1) / 2;
                if (keys < intervals[mid].minKeysCount) {
                    high = mid - 1;
                } else {
                    low = mid;
                }
            }
            BondCurveInterval storage interval = intervals[low];
            return
                interval.minBond +
                (keys - interval.minKeysCount) *
                interval.trend;
        }
    }

    function _getKeysCountByBondAmount(
        uint256 amount,
        BondCurveInterval[] storage intervals
    ) internal view returns (uint256) {
        if (amount < intervals[0].minBond) {
            return 0;
        }

        unchecked {
            uint256 low = 0;
            uint256 high = intervals.length - 1;
            while (low < high) {
                uint256 mid = (low + high + 1) / 2;
                if (amount < intervals[mid].minBond) {
                    high = mid - 1;
                } else {
                    low = mid;
                }
            }
            //
            //                          <-------> trend[B]
            //               minBond[A]         minBond[B]
            // bond      ----|----|----|----^---|--------|--> eth
            // fromKeys      1         3    |   4
            //           <---> trend[A]     |
            //                              - amount
            // Starting from keys count = 3 trend[B] is already in use, it means if the amount is
            // somewhere within the interval (minBond[B] - trend[B]; minBond[B]), the maximum
            // amount of keys it's possible to create is minKeysCount[B] - 1
            //
            BondCurveInterval storage interval;
            if (low < intervals.length - 1) {
                interval = intervals[low + 1];
                if (amount > interval.minBond - interval.trend) {
                    return interval.minKeysCount - 1;
                }
            }
            interval = intervals[low];
            return
                interval.minKeysCount +
                (amount - interval.minBond) /
                interval.trend;
        }
    }

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondCurve_init(
        uint256[2][] calldata defaultBondCurveIntervals
    ) internal onlyInitializing {
        uint256 addedId = _addBondCurve(defaultBondCurveIntervals);
        if (addedId != DEFAULT_BOND_CURVE_ID) {
            revert InvalidInitialisationCurveId();
        }
    }

    /// @dev Add a new bond curve to the array
    function _addBondCurve(
        uint256[2][] calldata intervals
    ) internal returns (uint256 curveId) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();

        _checkBondCurve(intervals);

        $.bondCurves.push();
        curveId = $.bondCurves.length - 1;
        _addIntervalsToBondCurve($.bondCurves[curveId], intervals);

        emit BondCurveAdded(curveId, intervals);
    }

    /// @dev Update existing bond curve
    function _updateBondCurve(
        uint256 curveId,
        uint256[2][] calldata intervals
    ) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        if (curveId > $.bondCurves.length - 1) {
            revert InvalidBondCurveId();
        }

        _checkBondCurve(intervals);

        delete $.bondCurves[curveId];

        _addIntervalsToBondCurve($.bondCurves[curveId], intervals);

        emit BondCurveUpdated(curveId, intervals);
    }

    function _addIntervalsToBondCurve(
        BondCurveInterval[] storage bondCurve,
        uint256[2][] calldata intervals
    ) private {
        for (uint256 i = 0; i < intervals.length; ++i) {
            BondCurveInterval storage interval = bondCurve.push();
            (uint256 minKeysCount, uint256 trend) = (
                intervals[i][0],
                intervals[i][1]
            );
            interval.minKeysCount = minKeysCount;
            interval.trend = trend;
            if (i != 0) {
                BondCurveInterval storage prev = bondCurve[i - 1];
                interval.minBond =
                    trend +
                    prev.minBond +
                    (minKeysCount - prev.minKeysCount - 1) *
                    prev.trend;
            } else {
                interval.minBond = trend;
            }
        }
    }

    /// @dev Sets bond curve for the given Node Operator
    ///      It will be used for the Node Operator instead of the previously set curve
    function _setBondCurve(uint256 nodeOperatorId, uint256 curveId) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        unchecked {
            if (curveId > $.bondCurves.length - 1) {
                revert InvalidBondCurveId();
            }
        }
        $.operatorBondCurveId[nodeOperatorId] = curveId;
        emit BondCurveSet(nodeOperatorId, curveId);
    }

    function _checkBondCurve(uint256[2][] calldata intervals) private view {
        if (
            intervals.length < MIN_CURVE_LENGTH ||
            intervals.length > MAX_CURVE_LENGTH
        ) {
            revert InvalidBondCurveLength();
        }

        (uint256 firstIntervalminKeysCount, uint256 firstIntervalTrend) = (
            intervals[0][0],
            intervals[0][1]
        );

        if (firstIntervalminKeysCount != 1) {
            revert InvalidBondCurveValues();
        }

        if (firstIntervalTrend == 0) {
            revert InvalidBondCurveValues();
        }

        for (uint256 i = 1; i < intervals.length; ++i) {
            unchecked {
                (uint256 minKeysCount, uint256 trend) = (
                    intervals[i][0],
                    intervals[i][1]
                );
                uint256 prevminKeysCount = intervals[i - 1][0];
                if (minKeysCount <= prevminKeysCount) {
                    revert InvalidBondCurveValues();
                }
                if (trend == 0) {
                    revert InvalidBondCurveValues();
                }
            }
        }
    }

    function _getCurveInfo(
        uint256 curveId
    ) private view returns (BondCurveInterval[] storage) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        if (curveId > $.bondCurves.length - 1) {
            revert InvalidBondCurveId();
        }

        return $.bondCurves[curveId];
    }

    function _getCSBondCurveStorage()
        private
        pure
        returns (CSBondCurveStorage storage $)
    {
        assembly {
            $.slot := CS_BOND_CURVE_STORAGE_LOCATION
        }
    }
}
