// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IBondReserve {
    /// @dev Public struct to expose reserve info
    struct BondReserveInfo {
        uint128 amount;
        uint128 removableAt;
    }

    // Events
    event BondReserveMinPeriodChanged(uint256 period);
    event BondReserveChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 removableAt
    );
    event BondReserveRemoved(uint256 indexed nodeOperatorId);

    // Errors
    error InvalidBondReserveMinPeriod();
    error InvalidBondReserveAmount();

    /// @notice Get min reserve cooldown
    function getBondReserveMinPeriod() external view returns (uint256);

    /// @notice Get additional bond reserve info
    function getBondReserveInfo(
        uint256 nodeOperatorId
    ) external view returns (BondReserveInfo memory);

    /// @notice Get current reserved amount in ETH (stETH) for a Node Operator
    function getReservedBond(
        uint256 nodeOperatorId
    ) external view returns (uint256);
}
