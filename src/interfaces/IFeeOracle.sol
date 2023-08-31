// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

interface IFeeOracle {
    /// @notice Merkle Tree root
    function reportRoot() external view returns (bytes32);

    /// @notice Merkle Tree leaf hash
    function hashLeaf(uint64, uint64) external view returns (bytes32);
}
