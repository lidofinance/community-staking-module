// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

/// @dev There's no leaves sorting for simplicity.
contract MerkleTree {
    bytes32[] internal tree;
    bytes32[] internal leaves;

    function root() external view returns (bytes32) {
        return tree.length == 0 ? bytes32(0) : tree[0];
    }

    function getProof(
        uint256 index
    ) public view returns (bytes32[] memory proof) {
        if (tree.length == 1) {
            return proof;
        }

        uint256 i = tree.length - 1 - index;
        uint256 proofLength = _log2(i + 1);
        proof = new bytes32[](proofLength);
        uint256 p = 0;

        while (i > 0) {
            if (i % 2 == 0) {
                proof[p] = tree[i - 1];
            } else {
                proof[p] = tree[i + 1];
            }
            i = (i - 1) / 2;
            p++;
        }

        return proof;
    }

    function pushLeaf(bytes memory leafBytes) external {
        bytes32 leaf = this.hashLeaf(leafBytes);
        leaves.push(leaf);
        _buildTree();
    }

    function _buildTree() internal {
        delete tree;

        if (leaves.length == 1) {
            tree.push(leaves[0]);
            return;
        }

        for (uint256 i = 0; i < 2 * leaves.length - 1; ++i) {
            tree.push(bytes32(0));
        }

        for (uint256 i = 0; i < leaves.length; ++i) {
            tree[tree.length - 1 - i] = leaves[i];
        }

        for (uint256 i = tree.length - 1 - leaves.length; ; --i) {
            tree[i] = _hashPair(tree[2 * i + 1], tree[2 * i + 2]);

            if (i == 0) {
                break;
            }
        }
    }

    function _log2(uint256 x) private pure returns (uint256 y) {
        require(x != 0);
        while (x > 1) {
            x >>= 1;
            y += 1;
        }
        return y;
    }

    function hashLeaf(bytes memory d) external pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(d)));
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return
            a < b
                ? keccak256(bytes.concat(a, b))
                : keccak256(bytes.concat(b, a));
    }
}
