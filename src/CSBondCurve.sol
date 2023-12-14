// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

abstract contract CSBondCurveBase {
    event BondCurveAdded(uint256[] bondCurve);
    event DefaultBondCurveChanged(uint256 curveId);
    event BondCurveChanged(uint256 indexed nodeOperatorId, uint256 curveId);
}

abstract contract CSBondCurve is CSBondCurveBase {
    struct BondCurve {
        uint256 id;
        uint256[] points;
        uint256 trend;
    }

    /// @dev Array with bond curves, where curve is array of points (bond amounts for particular keys count).
    ///
    /// For example:
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
    // todo: should we strictly define max curves array length?
    BondCurve[] public bondCurves;
    /// @dev Default bond curve id for node operator if no special curve is set
    uint256 public defaultBondCurveId;
    /// @dev Mapping of node operator id to bond curve id
    mapping(uint256 => uint256) public bondCurveId;

    // todo: might be redefined in the future
    uint256 internal constant MAX_CURVE_LENGTH = 20;
    uint256 internal constant MIN_CURVE_LENGTH = 1;

    constructor(uint256[] memory defaultBondCurvePoints) {
        _addBondCurve(defaultBondCurvePoints);
        _setDefaultBondCurve(bondCurves.length);
    }

    function _addBondCurve(
        uint256[] memory curvePoints
    ) internal returns (uint256) {
        if (
            curvePoints.length < MIN_CURVE_LENGTH ||
            curvePoints.length > MAX_CURVE_LENGTH
        ) revert InvalidBondCurveLength();
        // todo: check curve values (that makes sense)
        if (curvePoints[0] == 0) revert InvalidBondCurveValues();
        for (uint256 i = 1; i < curvePoints.length; i++) {
            if (curvePoints[i] <= curvePoints[i - 1])
                revert InvalidBondCurveValues();
        }
        uint256 curveTrend = curvePoints[curvePoints.length - 1] -
            // if the curve length is 1, then 0 is used as the previous value to calculate the trend
            (curvePoints.length > 1 ? curvePoints[curvePoints.length - 2] : 0);
        bondCurves.push(
            BondCurve({
                id: bondCurves.length + 1, // to avoid zero id in arrays
                points: curvePoints,
                trend: curveTrend
            })
        );
        emit BondCurveAdded(curvePoints);
        return bondCurves.length;
    }

    function _setDefaultBondCurve(uint256 curveId) internal {
        // todo: should we check that new curve is not worse than the old one?
        if (
            curveId == 0 ||
            curveId > bondCurves.length ||
            curveId == defaultBondCurveId
        ) revert InvalidBondCurveId();
        defaultBondCurveId = curveId;
        emit DefaultBondCurveChanged(curveId);
    }

    function _setBondCurve(uint256 nodeOperatorId, uint256 curveId) internal {
        if (curveId == 0 || curveId > bondCurves.length)
            revert InvalidBondCurveId();
        bondCurveId[nodeOperatorId] = curveId;
        emit BondCurveChanged(nodeOperatorId, curveId);
    }

    function _resetBondCurve(uint256 nodeOperatorId) internal {
        delete bondCurveId[nodeOperatorId];
        emit BondCurveChanged(nodeOperatorId, defaultBondCurveId);
    }

    /// @notice Returns bond curve for the given curve id.
    /// @param curveId curve id to get bond curve for.
    function getCurveInfo(
        uint256 curveId
    ) public view returns (BondCurve memory) {
        return bondCurves[curveId - 1];
    }

    /// @notice Returns bond curve for the given node operator.
    function getBondCurve(
        uint256 nodeOperatorId
    ) public view returns (BondCurve memory) {
        uint256 curveId = bondCurveId[nodeOperatorId];
        return
            curveId == 0
                ? bondCurves[defaultBondCurveId - 1]
                : bondCurves[curveId - 1];
    }

    /// @notice Returns the required bond in ETH for the given number of keys for default bond curve.
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getRequiredBondETHForKeys(newTotal) - getRequiredBondETHForKeys(currentTotal)
    /// @param keys number of keys to get required bond for.
    /// @return required in ETH.
    function getBondAmountByKeysCount(
        uint256 keys
    ) public view returns (uint256) {
        return
            getBondAmountByKeysCount(keys, bondCurves[defaultBondCurveId - 1]);
    }

    /// @notice Returns the required bond in ETH for the given number of keys.
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getRequiredBondETHForKeys(newTotal) - getRequiredBondETHForKeys(currentTotal)
    /// @param keys number of keys to get required bond for.
    /// @return required in ETH.
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
    function getKeysCountByBondAmount(
        uint256 amount
    ) public view returns (uint256) {
        return
            getKeysCountByBondAmount(
                amount,
                bondCurves[defaultBondCurveId - 1]
            );
    }

    /// @notice Returns keys count for the given bond amount for particular node operator.
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
    ) internal pure returns (uint256) {
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

    error InvalidBondCurveLength();
    error InvalidBondCurveValues();
    error InvalidBondCurveId();
}
