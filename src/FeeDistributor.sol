// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { FeeDistributorBase } from "./FeeDistributorBase.sol";

import { IFeeOracle } from "./interfaces/IFeeOracle.sol";
import { IStETH } from "./interfaces/IStETH.sol";

/// @author madlabman
contract FeeDistributor is FeeDistributorBase {
    address public immutable CSM;
    address public immutable STETH;
    address public immutable ORACLE;
    address public immutable ACCOUNTING;

    /// @notice Amount of shares sent to the BondManager in favor of the NO
    mapping(uint64 => uint64) public distributedShares;

    constructor(
        address _CSM,
        address _stETH,
        address _oracle,
        address _accounting
    ) {
        if (_accounting == address(0)) revert ZeroAddress("_accounting");
        if (_oracle == address(0)) revert ZeroAddress("_oracle");
        if (_stETH == address(0)) revert ZeroAddress("_stETH");
        if (_CSM == address(0)) revert ZeroAddress("_CSM");

        ACCOUNTING = _accounting;
        ORACLE = _oracle;
        STETH = _stETH;
        CSM = _CSM;
    }

    /// @notice Returns the amount of shares that can be distributed in favor of the NO
    /// @param proof Merkle proof of the leaf
    /// @param noIndex Index of the NO
    /// @param shares Total amount of shares earned as fees
    function getFeesToDistribute(
        bytes32[] calldata proof,
        uint64 noIndex,
        uint64 shares
    ) public view returns (uint64) {
        bool isValid = MerkleProof.verifyCalldata(
            proof,
            IFeeOracle(ORACLE).reportRoot(),
            IFeeOracle(ORACLE).hashLeaf(noIndex, shares)
        );
        if (!isValid) revert InvalidProof();

        if (distributedShares[noIndex] > shares) {
            revert InvalidShares();
        }

        return shares - distributedShares[noIndex];
    }

    /// @notice Distribute fees to the BondManager in favor of the NO
    /// @param proof Merkle proof of the leaf
    /// @param noIndex Index of the NO
    /// @param shares Total amount of shares earned as fees
    function distributeFees(
        bytes32[] calldata proof,
        uint64 noIndex,
        uint64 shares
    ) external returns (uint64) {
        if (msg.sender != ACCOUNTING) revert NotBondManager();

        uint64 sharesToDistribute = getFeesToDistribute(proof, noIndex, shares);
        if (sharesToDistribute == 0) {
            // To avoid breaking claim rewards logic
            return 0;
        }
        distributedShares[noIndex] += sharesToDistribute;
        IStETH(STETH).transferShares(ACCOUNTING, sharesToDistribute);
        emit FeeDistributed(noIndex, sharesToDistribute);

        return sharesToDistribute;
    }

    /// Transfers shares from the CSM to the distributor
    /// @param amount Amount of shares to transfer
    function receiveFees(uint256 amount) external {
        if (msg.sender != ORACLE) revert NotOracle();
        IStETH(STETH).transferSharesFrom(CSM, address(this), amount);
    }
}
