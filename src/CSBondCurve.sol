// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.21;

abstract contract CSBondCurveBase {
    event BondCurveAdded(uint256[] bondCurve);
    event DefaultBondCurveChanged(uint256 curveId);
    event BondCurveChanged(uint256 indexed nodeOperatorId, uint256 curveId);

    error InvalidBondCurveLength();
    error InvalidBondCurveValues();
    error InvalidBondCurveId();
}

/// @dev Bond curve mechanics abstract contract
///
/// It gives ability to build bond curve for bond math.
/// There is default bond curve for all node operators, witch can be 'overridden' by particular node operator.
///
/// It contains:
///  - add bond curve
///  - get bond curve info
///  - set default bond curve
///  - set bond curve for the given node operator
///  - get bond curve for the given node operator
///  - get required bond amount for the given keys count
///  - get keys count for the given bond amount
///
/// Should be inherited by Module contract, or Module-related contract.
/// Internal non-view methods should be used in Module contract with additional requirements (if required).
///
/// @author vgorkavenko
abstract contract CSBondCurve is CSBondCurveBase {
    /// @dev Bond curve structure.
    /// It contains:
    ///  - id     |> identifier to set default curve for the module or particular node operator
    ///  - points |> bond amount for particular keys count
    ///  - trend  |> value for the next keys after described points
    ///
    /// For example how the curve points looks like:
    ///   Points Array Index  |>       0          1          2          i
    ///   Bond Amount         |>   [ 2 ETH ] [ 3.9 ETH ] [ 5.7 ETH ] [ ... ]
    ///   Keys Count          |>       1          2          3        i + 1
    ///
    ///   Bond Amount (ETH)
    ///       ^
    ///       |
    ///     6 -
    ///       | ------------------- 5.9 ETH -->..
    ///   5.5 -                              . ^
    ///       |                             .  |
    ///     5 -                            .   |
    ///       |                           .    |
    ///   4.5 -                          .     |
    ///       |                         .      |
    ///     4 -                       ..       |
    ///       | -------- 3.9 ETH -->..         |
    ///   3.5 -                    .^          |
    ///       |                  .. |          |
    ///     3 -                ..   |          |
    ///       |               .     |          |
    ///   2.5 -              .      |          |
    ///       |            ..       |          |
    ///     2 - -------->..         |          |
    ///       |          ^          |          |
    ///       |----------|----------|----------|----------|----> Keys Count
    ///       |          1          2          3          i
    ///
    struct BondCurve {
        uint256 id;
        uint256[] points;
        uint256 trend;
    }

    // TODO: should we strictly define max curves array length?
    BondCurve[] internal _bondCurves;
    /// @dev Default bond curve id for node operator if no special curve is set
    uint256 public defaultBondCurveId;
    /// @dev Mapping of node operator id to bond curve id
    mapping(uint256 => uint256) public operatorBondCurveId;

    // TODO: might be redefined in the future
    uint256 internal constant MAX_CURVE_LENGTH = 20;
    uint256 internal constant MIN_CURVE_LENGTH = 1;

    constructor(uint256[] memory defaultBondCurvePoints) {
        _setDefaultBondCurve(_addBondCurve(defaultBondCurvePoints));
    }

    /// @dev Adds new bond curve to the array.
    ///      After that returned ID can be used to set default curve or curve for the particular node operator.
    function _addBondCurve(
        uint256[] memory curvePoints
    ) internal returns (uint256) {
        if (
            curvePoints.length < MIN_CURVE_LENGTH ||
            curvePoints.length > MAX_CURVE_LENGTH
        ) revert InvalidBondCurveLength();
        // TODO: check curve values (that makes sense)
        if (curvePoints[0] == 0) revert InvalidBondCurveValues();
        for (uint256 i = 1; i < curvePoints.length; i++) {
            if (curvePoints[i] <= curvePoints[i - 1])
                revert InvalidBondCurveValues();
        }
        uint256 curveTrend = curvePoints[curvePoints.length - 1] -
            // if the curve length is 1, then 0 is used as the previous value to calculate the trend
            (curvePoints.length > 1 ? curvePoints[curvePoints.length - 2] : 0);
        _bondCurves.push(
            BondCurve({
                id: _bondCurves.length + 1, // to avoid zero id in arrays
                points: curvePoints,
                trend: curveTrend
            })
        );
        emit BondCurveAdded(curvePoints);
        return _bondCurves.length;
    }

    /// @dev Sets default bond curve for the module.
    ///      It will be used for the node operators without special curve.
    function _setDefaultBondCurve(uint256 curveId) internal {
        // TODO: should we check that new curve is not worse than the old one?
        if (
            curveId == 0 ||
            curveId > _bondCurves.length ||
            curveId == defaultBondCurveId
        ) revert InvalidBondCurveId();
        defaultBondCurveId = curveId;
        emit DefaultBondCurveChanged(curveId);
    }

    /// @dev Sets bond curve for the given node operator.
    ///      It will be used for the node operator instead of default curve.
    function _setBondCurve(uint256 nodeOperatorId, uint256 curveId) internal {
        if (curveId == 0 || curveId > _bondCurves.length)
            revert InvalidBondCurveId();
        operatorBondCurveId[nodeOperatorId] = curveId;
        emit BondCurveChanged(nodeOperatorId, curveId);
    }

    /// @dev Resets bond curve for the given node operator to default (for example, because of breaking the rules by node operator)
    function _resetBondCurve(uint256 nodeOperatorId) internal {
        delete operatorBondCurveId[nodeOperatorId];
        emit BondCurveChanged(nodeOperatorId, defaultBondCurveId);
    }

    /// @dev returns default bond curve info if `curveId` is `0` or invalid
    /// @notice Returns bond curve for the given curve id.
    /// @param curveId curve id to get bond curve for.
    /// @return bond curve.
    function getCurveInfo(
        uint256 curveId
    ) public view returns (BondCurve memory) {
        return
            (curveId == 0 || curveId > _bondCurves.length)
                ? _bondCurves[defaultBondCurveId - 1]
                : _bondCurves[curveId - 1];
    }

    /// @notice Returns bond curve for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond curve for.
    /// @return bond curve.
    function getBondCurve(
        uint256 nodeOperatorId
    ) public view returns (BondCurve memory) {
        return getCurveInfo(operatorBondCurveId[nodeOperatorId]);
    }

    /// @notice Returns the required bond in ETH for the given number of keys for default bond curve.
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getBondAmountByKeysCount(newTotal) - getBondAmountByKeysCount(currentTotal)
    /// @param keys number of keys to get required bond for.
    /// @return required amount for particular keys count.
    function getBondAmountByKeysCount(
        uint256 keys
    ) public view returns (uint256) {
        return getBondAmountByKeysCount(keys, getCurveInfo(defaultBondCurveId));
    }

    /// @notice Returns the required bond in ETH for the given number of keys for particular bond curve.
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getBondAmountByKeysCount(newTotal, curve) - getBondAmountByKeysCount(currentTotal, curve)
    /// @param keys number of keys to get required bond for.
    /// @param curve bond curve to get required bond for.
    /// @return required in amount for particular keys count.
    function getBondAmountByKeysCount(
        uint256 keys,
        BondCurve memory curve
    ) public pure returns (uint256) {
        if (keys == 0) return 0;
        if (keys <= curve.points.length) {
            return curve.points[keys - 1];
        }
        return
            curve.points[curve.points.length - 1] +
            (keys - curve.points.length) *
            curve.trend;
    }

    /// @notice Returns keys count for the given bond amount with default bond curve.
    /// @param amount bond amount to get keys count for.
    /// @return keys count.
    function getKeysCountByBondAmount(
        uint256 amount
    ) public view returns (uint256) {
        return
            getKeysCountByBondAmount(amount, getCurveInfo(defaultBondCurveId));
    }

    /// @notice Returns keys count for the given bond amount for particular bond curve.
    /// @param amount bond amount to get keys count for.
    /// @param curve bond curve to get keys count for.
    /// @return keys count.
    function getKeysCountByBondAmount(
        uint256 amount,
        BondCurve memory curve
    ) public pure returns (uint256) {
        if (amount < curve.points[0]) return 0;
        uint256 maxCurveAmount = curve.points[curve.points.length - 1];
        if (amount >= maxCurveAmount) {
            return
                curve.points.length + (amount - maxCurveAmount) / curve.trend;
        }
        return _searchKeysCount(amount, curve.points);
    }

    function _searchKeysCount(
        uint256 amount,
        uint256[] memory curvePoints
    ) private pure returns (uint256) {
        uint256 low;
        uint256 high = curvePoints.length - 1;
        while (low <= high) {
            uint256 mid = (low + high) / 2;
            uint256 midAmount = curvePoints[mid];
            if (amount == midAmount) {
                return mid + 1;
            }
            if (amount < midAmount) {
                // zero mid is avoided above
                high = mid - 1;
            } else if (amount > midAmount) {
                low = mid + 1;
            }
        }
        return low;
    }
}
