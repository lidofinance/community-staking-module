// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { FeeDistributorBase } from "./FeeDistributorBase.sol";

import { IFeeOracle } from "./interfaces/IFeeOracle.sol";
import { IStETH } from "./interfaces/IStETH.sol";

/// @author madlabman
contract FeeDistributor is FeeDistributorBase {
    address public immutable STETH;
    address public immutable ORACLE;
    address public immutable BOND_MANAGER;

    /// @notice Amount of shares sent to the BondManager in favor of the NO
    mapping(uint64 => uint64) public distributedShares;

    constructor(address _stETH, address _oracle, address _bondManager) {
        if (_bondManager == address(0)) revert ZeroAddress("_bondManager");
        if (_oracle == address(0)) revert ZeroAddress("_oracle");
        if (_stETH == address(0)) revert ZeroAddress("_stETH");

        BOND_MANAGER = _bondManager;
        ORACLE = _oracle;
        STETH = _stETH;
    }

    /// @notice Distribute fees to the BondManager
    /// @param proof Merkle proof of the leaf
    /// @param noIndex Index of the NO
    /// @param shares Total amount of shares earned as fees
    function distributeFees(
        bytes32[] calldata proof,
        uint64 noIndex,
        uint64 shares
    ) external returns (uint64) {
        if (msg.sender != BOND_MANAGER) revert NotBondManager();

        bool isValid = MerkleProof.verifyCalldata(
            proof,
            IFeeOracle(ORACLE).reportRoot(),
            IFeeOracle(ORACLE).hashLeaf(noIndex, shares)
        );
        if (!isValid) revert InvalidProof();

        if (distributedShares[noIndex] > shares) {
            revert InvalidShares();
        }

        if (distributedShares[noIndex] == shares) {
            // To avoid breaking claim rewards logic
            return 0;
        }

        uint64 sharesToDistribute = shares - distributedShares[noIndex];
        distributedShares[noIndex] += sharesToDistribute;
        IStETH(STETH).transferShares(BOND_MANAGER, sharesToDistribute);
        emit FeeDistributed(noIndex, sharesToDistribute);

        return sharesToDistribute;
    }
}
