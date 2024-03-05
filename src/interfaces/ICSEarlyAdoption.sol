// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSEarlyAdoption {
    function isEligible(
        address addr,
        bytes32[] calldata proof
    ) external view returns (bool);

    function getCurve() external view returns (uint256);
}
