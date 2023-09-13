// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/// @author madlabman
contract FeeDistributorBase {
    error ZeroAddress(string field);

    error NotBondManager();
    error NotOracle();

    error InvalidShares();
    error InvalidProof();

    /// @dev Emitted when fees are distributed
    event FeeDistributed(uint64 indexed noIndex, uint64 shares);
}
