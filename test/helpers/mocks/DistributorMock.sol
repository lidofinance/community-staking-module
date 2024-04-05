// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

contract DistributorMock {
    function processTreeData(
        bytes32 _treeRoot,
        string calldata _treeCid,
        uint256 distributedShares
    ) external {
        // do nothing
    }
}
