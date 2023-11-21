// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

abstract contract CSBondCurve {
    error InvalidBondCurveLength();
    error InvalidMultiplier();

    // @dev Keys count to bond amount mapping
    //      x - keys count
    //      y - bond amount for x keys
    uint256[] public bondCurve;

    uint256 internal constant MIN_CURVE_LENGTH = 2;
    // todo: might be redefined in the future
    uint256 internal constant MAX_CURVE_LENGTH = 20;
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant MIN_BOND_MULTIPLIER = MAX_BOND_MULTIPLIER / 2; // x0.5
    uint256 internal constant MAX_BOND_MULTIPLIER = 10000; // x1

    /// This mapping contains bond multiplier points (in basis points) for Node Operator's bond.
    /// By default, all Node Operators have x1 multiplier (10000 basis points).
    mapping(uint256 => uint256) internal _bondMultiplierBP;

    constructor(uint256[] memory _bondCurve) {
        _checkCurveLength(_bondCurve);
        bondCurve = _bondCurve;
    }

    function _setBondCurve(uint256[] memory _bondCurve) internal {
        _checkCurveLength(_bondCurve);
        bondCurve = _bondCurve;
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
        uint256 last = (bondCurve[bondCurve.length - 1] * mult) / BASIS_POINTS;
        if (amount >= last) {
            return
                bondCurve.length +
                ((amount - last) /
                    (last -
                        (bondCurve[bondCurve.length - 2] * mult) /
                        BASIS_POINTS));
        }
        return _searchKeysByBond(amount, mult);
    }

    function _searchKeysByBond(
        uint256 value,
        uint256 multiplier
    ) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = bondCurve.length - 1;
        while (low <= high) {
            uint256 mid = (low + high) / 2;
            if (
                (bondCurve[mid] * multiplier) / BASIS_POINTS > value && mid != 0
            ) {
                high = mid - 1;
            } else if ((bondCurve[mid] * multiplier) / BASIS_POINTS <= value) {
                low = mid + 1;
            } else {
                return mid;
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
        uint256 mult = getBondMultiplier(nodeOperatorId);
        if (keys == 0) return 0;
        if (keys <= bondCurve.length) {
            return (bondCurve[keys - 1] * mult) / BASIS_POINTS;
        } else {
            uint256 last = (bondCurve[bondCurve.length - 1] * mult) /
                BASIS_POINTS;
            return
                last +
                (keys - bondCurve.length) *
                (last -
                    ((bondCurve[bondCurve.length - 2] * mult) / BASIS_POINTS));
        }
    }
}
