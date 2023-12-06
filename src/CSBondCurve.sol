// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

abstract contract CSBondCurveBase {
    event BondCurveChanged(uint256[] bondCurve);
    event BondMultiplierChanged(
        uint256 indexed nodeOperatorId,
        uint256 basisPoints
    );
}

abstract contract CSBondCurve is CSBondCurveBase {
    /// @dev Array of bond amounts for particular keys count.
    ///
    /// For example:
    ///   Array Index  |>       0          1          2          i
    ///   Bond Amount  |>   [ 2 ETH ] [ 3.9 ETH ] [ 5.7 ETH ] [ ... ]
    ///    Keys Count  |>       1          2          3        i + 1
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
    uint256[] public bondCurve;

    /// @dev This mapping contains bond multiplier points (in basis points) for Node Operator's bond.
    /// By default, all Node Operators have x1 multiplier (10000 basis points).
    ///
    /// For example:
    ///   There is a bond curve as above ^
    ///   Some Node Operator has x0.90 bond multiplier (9000 basis points)
    ///   Bond Curve with multiplier for this Node Operator will be:
    ///
    ///   Bond Amount (ETH)
    ///       ^
    ///       |
    ///     4 -
    ///       | ------------------- 3.6 ETH -->.
    ///   3.5 -                            ..  ^
    ///       |                          ..    |
    ///     3 -                        ..      |
    ///       | -------- 2.7 ETH -->...        |
    ///   2.5 -                  .. |          |
    ///       |               ..    |          |
    ///     2 -             ..      |          |
    ///       | 1.8 ETH->...        |          |
    ///   1.5 -          ^          |          |
    ///       |          |          |          |
    ///     1 -          |          |          |
    ///       |----------|----------|----------|----------|----> Keys Count
    ///       |          1          2          3          i
    ///
    mapping(uint256 => uint256) public bondMultiplierBP;

    // todo: might be redefined in the future
    uint256 internal constant MAX_CURVE_LENGTH = 20;
    uint256 internal constant MIN_CURVE_LENGTH = 1;

    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant MAX_BOND_MULTIPLIER = BASIS_POINTS; // x1
    uint256 internal constant MIN_BOND_MULTIPLIER = MAX_BOND_MULTIPLIER / 2; // x0.5

    uint256 internal _bondCurveTrend;

    constructor(uint256[] memory _bondCurve) {
        _setBondCurve(_bondCurve);
    }

    function _setBondCurve(uint256[] memory _bondCurve) internal {
        if (
            _bondCurve.length < MIN_CURVE_LENGTH ||
            _bondCurve.length > MAX_CURVE_LENGTH
        ) revert InvalidBondCurveLength();
        // todo: check curve values (not worse than previous and makes sense)
        if (_bondCurve[0] == 0) revert InvalidBondCurveValues();
        for (uint256 i = 1; i < _bondCurve.length; i++) {
            if (_bondCurve[i] <= _bondCurve[i - 1])
                revert InvalidBondCurveValues();
        }
        bondCurve = _bondCurve;
        _bondCurveTrend =
            _bondCurve[_bondCurve.length - 1] -
            // if the curve length is 1, then 0 is used as the previous value to calculate the trend
            (_bondCurve.length > 1 ? _bondCurve[_bondCurve.length - 2] : 0);
        emit BondCurveChanged(_bondCurve);
    }

    function _setBondMultiplier(
        uint256 nodeOperatorId,
        uint256 basisPoints
    ) internal {
        if (
            basisPoints < MIN_BOND_MULTIPLIER ||
            basisPoints > MAX_BOND_MULTIPLIER
        ) revert InvalidMultiplier();
        // todo: check curve values (not worse than previous)
        bondMultiplierBP[nodeOperatorId] = basisPoints;
        emit BondMultiplierChanged(nodeOperatorId, basisPoints);
    }

    /// @notice Returns basis points of the bond multiplier for the given node operator.
    ///         if it isn't set, the multiplier is x1 (MAX_BOND_MULTIPLIER)
    function getBondMultiplier(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        uint256 basisPoints = bondMultiplierBP[nodeOperatorId];
        return basisPoints > 0 ? basisPoints : MAX_BOND_MULTIPLIER;
    }

    /// @notice Returns keys count for the given bond amount.
    function _getKeysCountByBondAmount(
        uint256 amount
    ) internal view returns (uint256) {
        return _getKeysCountByBondAmount(amount, MAX_BOND_MULTIPLIER);
    }

    /// @notice Returns keys count for the given bond amount for particular node operator.
    function _getKeysCountByBondAmount(
        uint256 amount,
        uint256 multiplier
    ) internal view returns (uint256) {
        if (amount < (bondCurve[0] * multiplier) / BASIS_POINTS) return 0;
        uint256 maxCurveAmount = (bondCurve[bondCurve.length - 1] *
            multiplier) / BASIS_POINTS;
        if (amount >= maxCurveAmount) {
            return
                bondCurve.length +
                ((amount - maxCurveAmount) /
                    ((_bondCurveTrend * multiplier) / BASIS_POINTS));
        }
        return _searchKeysCount(amount, multiplier);
    }

    function _searchKeysCount(
        uint256 amount,
        uint256 multiplier
    ) internal view returns (uint256) {
        uint256 low;
        uint256 high = bondCurve.length - 1;
        while (low <= high) {
            uint256 mid = (low + high) / 2;
            uint256 midAmount = (bondCurve[mid] * multiplier) / BASIS_POINTS;
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

    function _getBondAmountByKeysCount(
        uint256 keys
    ) internal view returns (uint256) {
        return _getBondAmountByKeysCount(keys, MAX_BOND_MULTIPLIER);
    }

    function _getBondAmountByKeysCount(
        uint256 keys,
        uint256 multiplier
    ) internal view returns (uint256) {
        if (keys == 0) return 0;
        if (keys <= bondCurve.length) {
            return (bondCurve[keys - 1] * multiplier) / BASIS_POINTS;
        }
        return
            ((bondCurve[bondCurve.length - 1] * multiplier) / BASIS_POINTS) +
            (keys - bondCurve.length) *
            ((_bondCurveTrend * multiplier) / BASIS_POINTS);
    }

    error InvalidBondCurveLength();
    error InvalidBondCurveValues();
    error InvalidMultiplier();
}
