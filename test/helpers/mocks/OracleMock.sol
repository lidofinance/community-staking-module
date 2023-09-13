// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { MerkleTree } from "../../helpers/MerkleTree.sol";

contract OracleMock {
    MerkleTree public merkleTree = new MerkleTree();

    function hashLeaf(
        uint64 noIndex,
        uint64 shares
    ) external view returns (bytes32) {
        return merkleTree.hashLeaf(abi.encodePacked(noIndex, shares));
    }

    function reportRoot() external view returns (bytes32) {
        return merkleTree.root();
    }
}
