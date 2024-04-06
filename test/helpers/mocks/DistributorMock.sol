// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

contract DistributorMock {
    function processOracleReport(
        bytes32 /* treeRoot */,
        string calldata /* treeCid */,
        uint256 /* distributedShares */
    ) external {
        // do nothing
    }
}
