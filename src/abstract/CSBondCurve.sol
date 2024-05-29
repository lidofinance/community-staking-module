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
    /// @custom:storage-location erc7201:CSAccounting.CSBondCurve
    struct CSBondCurveStorage {
        // TODO: should we strictly define max curves array length?
        BondCurve[] bondCurves;
        /// @dev Default bond curve id for Node Operator if no special curve is set
        uint256 defaultBondCurveId;
        /// @dev Mapping of Node Operator id to bond curve id
        mapping(uint256 nodeOperatorId => uint256 bondCurveId) operatorBondCurveId;
    }

    // keccak256(abi.encode(uint256(keccak256("CSBondCurve")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_CURVE_STORAGE_LOCATION =
        0x8f22e270e477f5becb8793b61d439ab7ae990ed8eba045eb72061c0e6cfe1500;

    uint256 internal constant MIN_CURVE_LENGTH = 1;
    uint256 internal immutable MAX_CURVE_LENGTH;

    event BondCurveAdded(uint256[] bondCurve);
    event DefaultBondCurveChanged(uint256 curveId);
    event BondCurveChanged(uint256 indexed nodeOperatorId, uint256 curveId);

    error InvalidBondCurveLength();
    error InvalidBondCurveValues();
    error InvalidBondCurveId();

    constructor(uint256 maxCurveLength) {
        if (maxCurveLength < MIN_CURVE_LENGTH) revert InvalidBondCurveLength();
        MAX_CURVE_LENGTH = maxCurveLength;
    }

    function defaultBondCurveId() public view returns (uint256) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        return $.defaultBondCurveId;
    }

    /// @dev Get default bond curve info if `curveId` is `0` or invalid
    /// @notice Return bond curve for the given curve id
    /// @param curveId Curve id to get bond curve for
    /// @return Bond curve
    function getCurveInfo(
        uint256 curveId
    ) public view returns (BondCurve memory) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        return
            (curveId == 0)
                ? $.bondCurves[$.defaultBondCurveId - 1]
                : $.bondCurves[curveId - 1];
    }

    /// @notice Get bond curve for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Bond curve
    function getBondCurve(
        uint256 nodeOperatorId
    ) public view returns (BondCurve memory) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        return getCurveInfo($.operatorBondCurveId[nodeOperatorId]);
    }

    /// @notice Get required bond in ETH for the given number of keys for default bond curve
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getBondAmountByKeysCount(newTotal) - getBondAmountByKeysCount(currentTotal)
    /// @param keys Number of keys to get required bond for
    /// @return Amount for particular keys count
    function getBondAmountByKeysCount(
        uint256 keys
    ) public view returns (uint256) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        return
            getBondAmountByKeysCount(keys, getCurveInfo($.defaultBondCurveId));
    }

    /// @notice Get keys count for the given bond amount with default bond curve
    /// @param amount Bond amount in ETH (stETH)to get keys count for
    /// @return Keys count
    function getKeysCountByBondAmount(
        uint256 amount
    ) public view returns (uint256) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        return
            getKeysCountByBondAmount(
                amount,
                getCurveInfo($.defaultBondCurveId)
            );
    }

    /// @notice Get required bond in ETH for the given number of keys for particular bond curve.
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getBondAmountByKeysCount(newTotal, curve) - getBondAmountByKeysCount(currentTotal, curve)
    /// @param keys Number of keys to get required bond for
    /// @param curve Bond curve to get required bond for
    /// @return Required bond amount in ETH (stETH) for particular keys count
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

    /// @notice Get keys count for the given bond amount for particular bond curve.
    /// @param amount Bond amount to get keys count for
    /// @param curve Bond curve to get keys count for
    /// @return Keys count
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

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondCurve_init(
        uint256[] memory defaultBondCurvePoints
    ) internal onlyInitializing {
        _setDefaultBondCurve(_addBondCurve(defaultBondCurvePoints));
    }

    /// @dev Add a new bond curve to the array
    ///      After that, the returned ID can be used to set the default curve or curve for the particular Node Operator
    function _addBondCurve(
        uint256[] memory curvePoints
    ) internal returns (uint256) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
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
        $.bondCurves.push(
            BondCurve({
                id: $.bondCurves.length + 1, // to avoid zero id in arrays
                points: curvePoints,
                trend: curveTrend
            })
        );
        emit BondCurveAdded(curvePoints);
        return $.bondCurves.length;
    }

    /// @dev Set default bond curve for the module
    ///      It will be used for the Node Operators without a custom curve set
    function _setDefaultBondCurve(uint256 curveId) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        if (
            curveId == 0 ||
            curveId > $.bondCurves.length ||
            curveId == $.defaultBondCurveId
        ) revert InvalidBondCurveId();
        $.defaultBondCurveId = curveId;
        emit DefaultBondCurveChanged(curveId);
    }

    /// @dev Sets bond curve for the given Node Operator
    ///      It will be used for the Node Operator instead of the default curve
    function _setBondCurve(uint256 nodeOperatorId, uint256 curveId) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        if (curveId == 0 || curveId > $.bondCurves.length)
            revert InvalidBondCurveId();
        $.operatorBondCurveId[nodeOperatorId] = curveId;
        emit BondCurveChanged(nodeOperatorId, curveId);
    }

    /// @dev Reset bond curve for the given Node Operator to default (for example, because of breaking the rules by Node Operator)
    function _resetBondCurve(uint256 nodeOperatorId) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        delete $.operatorBondCurveId[nodeOperatorId];
        emit BondCurveChanged(nodeOperatorId, $.defaultBondCurveId);
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
