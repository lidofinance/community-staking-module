// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
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
    using Arrays for uint256[];

    /// @custom:storage-location erc7201:CSAccounting.CSBondCurve
    struct CSBondCurveStorage {
        BondCurve[] bondCurves;
        /// @dev Mapping of Node Operator id to bond curve id
        mapping(uint256 nodeOperatorId => uint256 bondCurveId) operatorBondCurveId;
    }

    // keccak256(abi.encode(uint256(keccak256("CSBondCurve")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_CURVE_STORAGE_LOCATION =
        0x8f22e270e477f5becb8793b61d439ab7ae990ed8eba045eb72061c0e6cfe1500;

    uint256 public constant MIN_CURVE_LENGTH = 1;
    uint256 public constant DEFAULT_BOND_CURVE_ID = 0;
    uint256 public immutable MAX_CURVE_LENGTH;

    event BondCurveAdded(uint256[] bondCurve);
    event BondCurveUpdated(uint256 indexed curveId, uint256[] bondCurve);
    event BondCurveSet(uint256 indexed nodeOperatorId, uint256 indexed curveId);

    error InvalidBondCurveLength();
    error InvalidBondCurveValues();
    error InvalidBondCurveId();
    error InvalidInitialisationCurveId();

    constructor(uint256 maxCurveLength) {
        if (maxCurveLength < MIN_CURVE_LENGTH) revert InvalidBondCurveLength();
        MAX_CURVE_LENGTH = maxCurveLength;
    }

    /// @dev Get default bond curve info if `curveId` is `0` or invalid
    /// @notice Return bond curve for the given curve id
    /// @param curveId Curve id to get bond curve for
    /// @return info Bond curve
    function getCurveInfo(
        uint256 curveId
    ) public view returns (BondCurve memory info) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        info = $.bondCurves[curveId];
    }

    /// @notice Get bond curve for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return curve Bond curve
    function getBondCurve(
        uint256 nodeOperatorId
    ) public view returns (BondCurve memory curve) {
        curve = getCurveInfo(getBondCurveId(nodeOperatorId));
    }

    /// @notice Get bond curve ID for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return id Bond curve ID
    function getBondCurveId(
        uint256 nodeOperatorId
    ) public view returns (uint256 id) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        id = $.operatorBondCurveId[nodeOperatorId];
    }

    /// @notice Get required bond in ETH for the given number of keys for default bond curve
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getBondAmountByKeysCount(newTotal) - getBondAmountByKeysCount(currentTotal)
    /// @param keys Number of keys to get required bond for
    /// @param curveId Id of the curve to perform calculations against
    /// @return amount Amount for particular keys count
    function getBondAmountByKeysCount(
        uint256 keys,
        uint256 curveId
    ) public view returns (uint256 amount) {
        amount = getBondAmountByKeysCount(keys, getCurveInfo(curveId));
    }

    /// @notice Get keys count for the given bond amount with default bond curve
    /// @param amount Bond amount in ETH (stETH)to get keys count for
    /// @param curveId Id of the curve to perform calculations against
    /// @return count Keys count
    function getKeysCountByBondAmount(
        uint256 amount,
        uint256 curveId
    ) public view returns (uint256 count) {
        count = getKeysCountByBondAmount(amount, getCurveInfo(curveId));
    }

    /// @notice Get required bond in ETH for the given number of keys for particular bond curve.
    /// @dev To calculate the amount for the new keys 2 calls are required:
    ///      getBondAmountByKeysCount(newTotal, curve) - getBondAmountByKeysCount(currentTotal, curve)
    /// @param keys Number of keys to get required bond for
    /// @param curve Bond curve to perform calculations against
    /// @return Required bond amount in ETH (stETH) for particular keys count
    function getBondAmountByKeysCount(
        uint256 keys,
        BondCurve memory curve
    ) public pure returns (uint256) {
        if (keys == 0) return 0;
        if (keys <= curve.points.length) {
            return curve.points[keys - 1];
        }
        unchecked {
            return
                curve.points[curve.points.length - 1] +
                (keys - curve.points.length) *
                curve.trend;
        }
    }

    /// @notice Get keys count for the given bond amount for particular bond curve.
    /// @param amount Bond amount to get keys count for
    /// @param curve Bond curve to perform calculations against
    /// @return Keys count
    function getKeysCountByBondAmount(
        uint256 amount,
        BondCurve memory curve
    ) public pure returns (uint256) {
        if (amount < curve.points[0]) return 0;
        uint256 maxCurveAmount = curve.points[curve.points.length - 1];
        if (amount >= maxCurveAmount) {
            unchecked {
                return
                    curve.points.length +
                    (amount - maxCurveAmount) /
                    curve.trend;
            }
        }
        return _searchKeysCount(amount, curve.points);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __CSBondCurve_init(
        uint256[] memory defaultBondCurvePoints
    ) internal onlyInitializing {
        uint256 addedId = _addBondCurve(defaultBondCurvePoints);
        // TODO: Figure out how to test it
        if (addedId != DEFAULT_BOND_CURVE_ID)
            revert InvalidInitialisationCurveId();
    }

    /// @dev Add a new bond curve to the array
    function _addBondCurve(
        uint256[] memory curvePoints
    ) internal returns (uint256 id) {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();

        _checkBondCurve(curvePoints);

        uint256 curveTrend = curvePoints[curvePoints.length - 1] -
            // if the curve length is 1, then 0 is used as the previous value to calculate the trend
            (curvePoints.length > 1 ? curvePoints[curvePoints.length - 2] : 0);
        $.bondCurves.push(
            BondCurve({ points: curvePoints, trend: curveTrend })
        );
        emit BondCurveAdded(curvePoints);
        unchecked {
            id = $.bondCurves.length - 1;
        }
    }

    /// @dev Update existing bond curve
    function _updateBondCurve(
        uint256 curveId,
        uint256[] memory curvePoints
    ) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        if (curveId > $.bondCurves.length - 1) revert InvalidBondCurveId();

        _checkBondCurve(curvePoints);

        uint256 curveTrend = curvePoints[curvePoints.length - 1] -
            // if the curve length is 1, then 0 is used as the previous value to calculate the trend
            (curvePoints.length > 1 ? curvePoints[curvePoints.length - 2] : 0);
        $.bondCurves[curveId] = BondCurve({
            points: curvePoints,
            trend: curveTrend
        });
        emit BondCurveUpdated(curveId, curvePoints);
    }

    /// @dev Sets bond curve for the given Node Operator
    ///      It will be used for the Node Operator instead of the previously set curve
    function _setBondCurve(uint256 nodeOperatorId, uint256 curveId) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        if (curveId > $.bondCurves.length - 1) revert InvalidBondCurveId();
        $.operatorBondCurveId[nodeOperatorId] = curveId;
        emit BondCurveSet(nodeOperatorId, curveId);
    }

    /// @dev Reset bond curve for the given Node Operator to default.
    ///      (for example, because of breaking the rules by Node Operator)
    function _resetBondCurve(uint256 nodeOperatorId) internal {
        CSBondCurveStorage storage $ = _getCSBondCurveStorage();
        $.operatorBondCurveId[nodeOperatorId] = DEFAULT_BOND_CURVE_ID;
        emit BondCurveSet(nodeOperatorId, DEFAULT_BOND_CURVE_ID);
    }

    function _checkBondCurve(uint256[] memory curvePoints) private view {
        if (
            curvePoints.length < MIN_CURVE_LENGTH ||
            curvePoints.length > MAX_CURVE_LENGTH
        ) revert InvalidBondCurveLength();
        if (curvePoints[0] == 0) revert InvalidBondCurveValues();
        uint256 len = curvePoints.length;
        for (uint256 i = 1; i < len; ++i) {
            if (curvePoints[i] <= curvePoints[i - 1])
                revert InvalidBondCurveValues();
        }
    }

    function _searchKeysCount(
        uint256 amount,
        uint256[] memory curvePoints
    ) private pure returns (uint256) {
        unchecked {
            uint256 low;
            // @dev Curves of a length = 1 are handled in the parent method
            uint256 high = curvePoints.length - 2;
            uint256 mid;
            uint256 midAmount;
            while (low <= high) {
                mid = (low + high) / 2;
                midAmount = curvePoints[mid];
                if (amount == midAmount) {
                    return mid + 1;
                }
                // underflow is excluded by the conditions in the parent method
                if (amount < midAmount) {
                    high = mid - 1;
                } else if (amount > midAmount) {
                    low = mid + 1;
                }
            }
            return low;
        }
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
