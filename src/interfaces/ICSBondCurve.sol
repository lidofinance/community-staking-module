// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSBondCurve {
    /// @dev Bond curve structure.
    /// It contains:
    ///  - points |> total bond amount for particular keys count
    ///  - trend  |> value for the next keys after described points
    ///
    /// For example, how the curve points look like:
    ///   Points Array Index  |>       0          1          2          i
    ///   Bond Amount         |>   [ 2 ETH ] [ 3.9 ETH ] [ 5.7 ETH ] [ ... ]
    ///   Keys Count          |>       1          2          3        i + 1
    ///
    ///   Bond Amount (ETH)
    ///       ^
    ///       |
    ///     6 -
    ///       | ------------------ 5.7 ETH --> .
    ///   5.5 -                              ..^
    ///       |                             .  |
    ///     5 -                            .   |
    ///       |                           .    |
    ///   4.5 -                          .     |
    ///       |                         .      |
    ///     4 -                       ..       |
    ///       | ------- 3.9 ETH --> ..         |
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
        uint256[] points;
        uint256 trend;
    }

    function getCurveInfo(
        uint256 curveId
    ) external view returns (BondCurve memory);

    function getBondCurve(
        uint256 nodeOperatorId
    ) external view returns (BondCurve memory);

    function getBondCurveId(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBondAmountByKeysCount(
        uint256 keys,
        uint256 curveId
    ) external view returns (uint256);

    function getBondAmountByKeysCount(
        uint256 keys,
        BondCurve memory curve
    ) external view returns (uint256);

    function getKeysCountByBondAmount(
        uint256 amount,
        uint256 curveId
    ) external view returns (uint256);

    function getKeysCountByBondAmount(
        uint256 amount,
        BondCurve memory curve
    ) external view returns (uint256);
}
