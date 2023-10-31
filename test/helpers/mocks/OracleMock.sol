// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { ICSFeeOracle } from "../../../src/interfaces/ICSFeeOracle.sol";
import { MerkleTree } from "../../helpers/MerkleTree.sol";

contract OracleMock is ICSFeeOracle {
    MerkleTree public merkleTree = new MerkleTree();

    function hashLeaf(
        uint256 noIndex,
        uint256 shares
    ) external view returns (bytes32) {
        return merkleTree.hashLeaf(abi.encode(noIndex, shares));
    }

    function treeRoot() external view returns (bytes32) {
        return merkleTree.root();
    }
}
