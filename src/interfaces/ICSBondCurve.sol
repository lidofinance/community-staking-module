// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface ICSBondCurve {
    struct BondCurve {
        uint256 id;
        uint256[] points;
        uint256 trend;
    }

    function getCurveInfo(
        uint256 curveId
    ) external view returns (BondCurve memory);

    function getBondCurve(
        uint256 nodeOperatorId
    ) external view returns (BondCurve memory);

    function getBondAmountByKeysCount(
        uint256 keys
    ) external view returns (uint256);

    function getBondAmountByKeysCount(
        uint256 keys,
        BondCurve memory curve
    ) external view returns (uint256);

    function getKeysCountByBondAmount(
        uint256 amount
    ) external view returns (uint256);

    function getKeysCountByBondAmount(
        uint256 amount,
        uint256 curveId
    ) external view returns (uint256);
}
