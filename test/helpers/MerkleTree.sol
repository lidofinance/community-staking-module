// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/// @dev See https://github.com/succinctlabs/telepathy-contracts/blob/main/src/libraries/MerkleProof.sol
contract MerkleTree {
    uint256 internal treeHeight;
    bytes32[][] internal tree;
    bytes32[] internal leaves;

    function root() external view returns (bytes32) {
        return tree.length == 0 ? bytes32(0) : tree[treeHeight][0];
    }

    function getProof(uint256 index) public view returns (bytes32[] memory) {
        // Generate the proof
        bytes32[] memory proof = new bytes32[](treeHeight);
        for (uint256 i = 0; i < treeHeight; i++) {
            if (index % 2 == 0) {
                // sibling is on the right
                proof[i] = tree[i][index + 1];
            } else {
                // sibling is on the left
                proof[i] = tree[i][index - 1];
            }

            index = index / 2;
        }

        return proof;
    }

    function pushLeaf(uint256 noIndex, uint256 shares) external {
        bytes32 leaf = this.hashLeaf(abi.encodePacked(noIndex, shares));
        leaves.push(leaf);
        _buildTree();
    }

    function _buildTree() internal {
        treeHeight = _ceilLog2(leaves.length);
        tree = new bytes32[][](treeHeight + 1);
        tree[0] = leaves;

        while (tree[0].length < 2 ** treeHeight) {
            tree[0].push(this.hashLeaf(bytes.concat(bytes32(0))));
        }

        for (uint256 i = 1; i <= treeHeight; i++) {
            uint256 previousLevelLength = tree[i - 1].length;
            bytes32[] memory currentLevel = new bytes32[](
                previousLevelLength / 2
            );

            for (uint256 j = 0; j < previousLevelLength; j += 2) {
                currentLevel[j / 2] = _hashPair(
                    tree[i - 1][j],
                    tree[i - 1][j + 1]
                );
            }

            tree[i] = currentLevel;
        }
    }

    function _ceilLog2(uint256 _x) private pure returns (uint256 y) {
        // To avoid a leaf to become a root
        if (_x == 1) return 1;

        require(_x != 0);
        y = (_x & (_x - 1)) == 0 ? 0 : 1;
        while (_x > 1) {
            _x >>= 1;
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
