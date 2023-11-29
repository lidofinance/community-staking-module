// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

abstract contract CSBondCurve {
    error InvalidBondCurveLength();
    error InvalidMultiplier();

    // @dev Keys count to bond amount mapping
    //      i            | array index
    //      i + 1        | keys count for particular bond amount
    //      bondCurve[i] | bond amount for `i + 1` keys count
    uint256[] public bondCurve;

    uint256 internal constant MIN_CURVE_LENGTH = 1;
    // todo: might be redefined in the future
    uint256 internal constant MAX_CURVE_LENGTH = 20;
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant MIN_BOND_MULTIPLIER = MAX_BOND_MULTIPLIER / 2; // x0.5
    uint256 internal constant MAX_BOND_MULTIPLIER = 10000; // x1

    /// This mapping contains bond multiplier points (in basis points) for Node Operator's bond.
    /// By default, all Node Operators have x1 multiplier (10000 basis points).
    mapping(uint256 => uint256) internal _bondMultiplierBP;

    uint256 internal _bondCurveTrend;

    constructor(uint256[] memory _bondCurve) {
        _setBondCurve(_bondCurve);
    }

    function _setBondCurve(uint256[] memory _bondCurve) internal {
        _checkCurveLength(_bondCurve);
        bondCurve = _bondCurve;
        _bondCurveTrend =
            _bondCurve[_bondCurve.length - 1] -
            (_bondCurve.length > 1 ? _bondCurve[_bondCurve.length - 2] : 0);
    }

    function _setBondMultiplier(
        uint256 nodeOperatorId,
        uint256 basisPoints
    ) internal {
        _checkMultiplier(basisPoints);
        _bondMultiplierBP[nodeOperatorId] = basisPoints;
    }

    /// @notice Returns basis points of the bond multiplier for the given node operator.
    ///         if it isn't set, the multiplier is x1 (MAX_BOND_MULTIPLIER)
    function getBondMultiplier(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        uint256 basisPoints = _bondMultiplierBP[nodeOperatorId];
        return basisPoints > 0 ? basisPoints : MAX_BOND_MULTIPLIER;
    }

    function _checkCurveLength(uint256[] memory xy) internal pure {
        if (xy.length < MIN_CURVE_LENGTH || xy.length > MAX_CURVE_LENGTH)
            revert InvalidBondCurveLength();
    }

    function _checkMultiplier(uint256 multiplier) internal pure {
        if (
            multiplier < MIN_BOND_MULTIPLIER || multiplier > MAX_BOND_MULTIPLIER
        ) revert InvalidMultiplier();
    }

    /// @notice Returns the amount of keys for the given bond amount.
    function _getKeysCountByCurveValue(
        uint256 amount
    ) internal view returns (uint256) {
        return _getKeysCountByCurveValue(type(uint256).max, amount);
    }

    /// @notice Returns the amount of keys for the given bond amount for particular node operator.
    function _getKeysCountByCurveValue(
        uint256 nodeOperatorId,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 mult = getBondMultiplier(nodeOperatorId);
        if (amount < (bondCurve[0] * mult) / BASIS_POINTS) return 0;
        uint256 last = (bondCurve[bondCurve.length - 1] * mult) / BASIS_POINTS;
        if (amount >= last) {
            return
                bondCurve.length +
                ((amount - last) / ((_bondCurveTrend * mult) / BASIS_POINTS));
        }
        return _searchKeysByBond(amount, mult);
    }

    function _searchKeysByBond(
        uint256 value,
        uint256 multiplier
    ) internal view returns (uint256) {
        uint256 low;
        uint256 high = bondCurve.length - 1;
        while (low <= high) {
            uint256 mid = (low + high) / 2;
            uint256 midValue = (bondCurve[mid] * multiplier) / BASIS_POINTS;
            if (value == midValue) {
                return mid + 1;
            }
            if (value < midValue) {
                // zero mid is avoided above
                high = mid - 1;
            } else if (value > midValue) {
                low = mid + 1;
            }
        }
        return low;
    }

    function _getCurveValueByKeysCount(
        uint256 keys
    ) internal view returns (uint256) {
        return _getCurveValueByKeysCount(type(uint256).max, keys);
    }

    function _getCurveValueByKeysCount(
        uint256 nodeOperatorId,
        uint256 keys
    ) internal view returns (uint256) {
        if (keys == 0) return 0;
        uint256 mult = getBondMultiplier(nodeOperatorId);
        if (keys <= bondCurve.length) {
            return (bondCurve[keys - 1] * mult) / BASIS_POINTS;
        }
        return
            ((bondCurve[bondCurve.length - 1] * mult) / BASIS_POINTS) +
            (keys - bondCurve.length) *
            ((_bondCurveTrend * mult) / BASIS_POINTS);
    }
}
