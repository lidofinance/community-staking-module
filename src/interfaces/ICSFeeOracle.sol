// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

interface ICSFeeOracle {
    /// @notice Merkle Tree root
    function treeRoot() external view returns (bytes32);

    /// @notice Merkle Tree leaf hash
    function hashLeaf(uint256, uint256) external view returns (bytes32);
}
