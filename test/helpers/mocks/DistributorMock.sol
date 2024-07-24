// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "../../../src/interfaces/IStETH.sol";

contract DistributorMock {
    uint256 internal mockShares;
    IStETH public immutable STETH;
    address public immutable ACCOUNTING;

    constructor(address stETH, address accounting) {
        STETH = IStETH(stETH);
        ACCOUNTING = accounting;
    }

    function processOracleReport(
        bytes32 /* treeRoot */,
        string calldata /* treeCid */,
        uint256 /* distributedShares */
    ) external {
        // do nothing
    }

    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) public view returns (uint256 sharesToDistribute) {
        return STETH.sharesOf(address(this));
    }

    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external returns (uint256) {
        STETH.transferShares(ACCOUNTING, shares);
        return shares;
    }
}
