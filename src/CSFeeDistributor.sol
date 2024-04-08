// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { AssetRecoverer } from "./AssetRecoverer.sol";
import { AssetRecovererLib } from "./lib/AssetRecovererLib.sol";

/// @author madlabman
contract CSFeeDistributorBase {
    /// @dev Emitted when fees are distributed
    event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);

    error ZeroAddress(string field);

    error NotAccounting();

    error InvalidShares();
    error InvalidProof();
}

/// @author madlabman
contract CSFeeDistributor is
    ICSFeeDistributor,
    CSFeeDistributorBase,
    AccessControlEnumerable,
    AssetRecoverer
{
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // 0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE"); // 0xb3e25b5404b87e5a838579cb5d7481d61ad96ee284d38ec1e97c07ba64e7f6fc

    address public immutable STETH;
    address public immutable ACCOUNTING;

    /// @notice Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the published Merkle tree
    string public treeCid;

    /// @notice Amount of shares sent to the Accounting in favor of the NO
    mapping(uint256 => uint256) public distributedShares;

    /// @notice Total amount of shares available for claiming by NOs
    uint256 public claimableShares;

    constructor(address stETH, address accounting, address admin) {
        if (accounting == address(0)) revert ZeroAddress("accounting");
        if (stETH == address(0)) revert ZeroAddress("stETH");
        if (admin == address(0)) revert ZeroAddress("admin");

        ACCOUNTING = accounting;
        STETH = stETH;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Returns the amount of shares that are pending to be distributed
    function pendingToDistribute() external view returns (uint256) {
        return IStETH(STETH).sharesOf(address(this)) - claimableShares;
    }

    /// @notice Returns the amount of shares that can be distributed in favor of the NO
    /// @param proof Merkle proof of the leaf
    /// @param nodeOperatorId ID of the NO
    /// @param shares Total amount of shares earned as fees
    /// @return Amount of shares that can be distributed
    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) public view returns (uint256) {
        bool isValid = MerkleProof.verifyCalldata(
            proof,
            treeRoot,
            hashLeaf(nodeOperatorId, shares)
        );
        if (!isValid) revert InvalidProof();

        if (distributedShares[nodeOperatorId] > shares) {
            revert InvalidShares();
        }

        return shares - distributedShares[nodeOperatorId];
    }

    /// @notice Distribute fees to the Accounting in favor of the NO
    /// @param proof Merkle proof of the leaf
    /// @param nodeOperatorId ID of the NO
    /// @param shares Total amount of shares earned as fees
    /// @return Amount of shares distributed
    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external onlyAccounting returns (uint256) {
        uint256 sharesToDistribute = getFeesToDistribute(
            nodeOperatorId,
            shares,
            proof
        );

        if (sharesToDistribute == 0) {
            // To avoid breaking claim rewards logic
            return 0;
        }

        claimableShares -= sharesToDistribute;
        distributedShares[nodeOperatorId] += sharesToDistribute;

        IStETH(STETH).transferShares(ACCOUNTING, sharesToDistribute);
        emit FeeDistributed(nodeOperatorId, sharesToDistribute);

        return sharesToDistribute;
    }

    // @notice Receives the data of the Merkle tree from the Oracle contract and process it
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid,
        uint256 _distributedShares
    ) external onlyRole(ORACLE_ROLE) {
        if (
            claimableShares + _distributedShares >
            IStETH(STETH).sharesOf(address(this))
        ) {
            revert InvalidShares();
        }

        unchecked {
            claimableShares += _distributedShares;
        }

        treeRoot = _treeRoot;
        treeCid = _treeCid;
    }

    /// @notice Get a hash of a leaf
    /// @param nodeOperatorId ID of the node operator
    /// @param shares Amount of shares
    /// @dev Double hash the leaf to prevent second preimage attacks
    function hashLeaf(
        uint256 nodeOperatorId,
        uint256 shares
    ) public pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(keccak256(abi.encode(nodeOperatorId, shares)))
            );
    }

    function recoverERC20(
        address token,
        uint256 amount
    ) external override onlyRecoverer {
        if (token == STETH) {
            revert NotAllowedToRecover();
        }
        AssetRecovererLib.recoverERC20(token, amount);
    }

    modifier onlyAccounting() {
        if (msg.sender != ACCOUNTING) revert NotAccounting();
        _;
    }

    modifier onlyRecoverer() override {
        _checkRole(RECOVERER_ROLE);
        _;
    }
}
