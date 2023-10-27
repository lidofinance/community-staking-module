// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { CSFeeDistributorBase } from "./CSFeeDistributorBase.sol";

import { ICSFeeOracle } from "./interfaces/ICSFeeOracle.sol";
import { IStETH } from "./interfaces/IStETH.sol";

/// @author madlabman
contract CSFeeDistributor is CSFeeDistributorBase {
    address public immutable CSM;
    address public immutable STETH;
    address public immutable ORACLE;
    address public immutable ACCOUNTING;

    /// @notice Amount of shares sent to the BondManager in favor of the NO
    mapping(uint64 => uint64) public distributedShares;

    constructor(
        address _CSM,
        address stETH,
        address oracle,
        address accounting
    ) {
        if (accounting == address(0)) revert ZeroAddress("accounting");
        if (oracle == address(0)) revert ZeroAddress("oracle");
        if (stETH == address(0)) revert ZeroAddress("stETH");
        if (_CSM == address(0)) revert ZeroAddress("_CSM");

        ACCOUNTING = accounting;
        ORACLE = oracle;
        STETH = stETH;
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
            ICSFeeOracle(ORACLE).reportRoot(),
            ICSFeeOracle(ORACLE).hashLeaf(noIndex, shares)
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
