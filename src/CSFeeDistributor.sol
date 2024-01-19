// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.21;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { ICSFeeOracle } from "./interfaces/ICSFeeOracle.sol";
import { IStETH } from "./interfaces/IStETH.sol";

/// @author madlabman
contract CSFeeDistributorBase {
    /// @dev Emitted when fees are distributed
    event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);

    error ZeroAddress(string field);

    error NotBondManager();
    error NotOracle();

    error InvalidShares();
    error InvalidProof();
}

/// @author madlabman
contract CSFeeDistributor is ICSFeeDistributor, CSFeeDistributorBase {
    using SafeCast for uint256;

    address public immutable CSM;
    address public immutable STETH;
    address public immutable ORACLE;
    address public immutable ACCOUNTING;

    /// @notice Amount of shares sent to the BondManager in favor of the NO
    mapping(uint256 => uint256) public distributedShares;

    constructor(
        address csm,
        address stETH,
        address oracle,
        address accounting
    ) {
        if (accounting == address(0)) revert ZeroAddress("accounting");
        if (oracle == address(0)) revert ZeroAddress("oracle");
        if (stETH == address(0)) revert ZeroAddress("stETH");
        if (csm == address(0)) revert ZeroAddress("_CSM");

        ACCOUNTING = accounting;
        ORACLE = oracle;
        STETH = stETH;
        CSM = csm;
    }

    /// @notice Returns the amount of shares that can be distributed in favor of the NO
    /// @param proof Merkle proof of the leaf
    /// @param nodeOperatorId ID of the NO
    /// @param shares Total amount of shares earned as fees
    /// @return Amount of shares that can be distributed
    function getFeesToDistribute(
        bytes32[] calldata proof,
        uint256 nodeOperatorId,
        uint256 shares
    ) public view returns (uint256) {
        bool isValid = MerkleProof.verifyCalldata(
            proof,
            ICSFeeOracle(ORACLE).treeRoot(),
            ICSFeeOracle(ORACLE).hashLeaf(nodeOperatorId, shares)
        );
        if (!isValid) revert InvalidProof();

        if (distributedShares[nodeOperatorId] > shares) {
            revert InvalidShares();
        }

        return shares - distributedShares[nodeOperatorId];
    }

    /// @notice Distribute fees to the BondManager in favor of the NO
    /// @param proof Merkle proof of the leaf
    /// @param nodeOperatorId ID of the NO
    /// @param shares Total amount of shares earned as fees
    /// @return Amount of shares distributed
    function distributeFees(
        bytes32[] calldata proof,
        uint256 nodeOperatorId,
        uint256 shares
    ) external returns (uint256) {
        if (msg.sender != ACCOUNTING) revert NotBondManager();

        uint256 sharesToDistribute = getFeesToDistribute(
            proof,
            nodeOperatorId,
            shares
        );
        if (sharesToDistribute == 0) {
            // To avoid breaking claim rewards logic
            return 0;
        }
        distributedShares[nodeOperatorId] += sharesToDistribute;
        IStETH(STETH).transferShares(ACCOUNTING, sharesToDistribute);
        emit FeeDistributed(nodeOperatorId, sharesToDistribute);

        return sharesToDistribute;
    }

    /// Transfers shares from the CSM to the distributor
    /// @param amount Amount of shares to transfer
    function receiveFees(uint256 amount) external {
        if (msg.sender != ORACLE) revert NotOracle();
        IStETH(STETH).transferSharesFrom(CSM, address(this), amount);
    }
}
