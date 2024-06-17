// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";
import { AssetRecovererLib } from "./lib/AssetRecovererLib.sol";

/// @author madlabman
contract CSFeeDistributor is
    ICSFeeDistributor,
    Initializable,
    AccessControlEnumerableUpgradeable,
    AssetRecoverer
{
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");

    IStETH public immutable STETH;
    address public immutable ACCOUNTING;
    address public immutable ORACLE;

    /// @notice Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the published Merkle tree
    string public treeCid;

    /// @notice Amount of stETH shares sent to the Accounting in favor of the NO
    mapping(uint256 => uint256) public distributedShares;

    /// @notice Total Amount of stETH shares available for claiming by NOs
    uint256 public totalClaimableShares;

    /// @dev Emitted when fees are distributed
    event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);

    /// @dev Emitted when distribution data is updated
    event DistributionDataUpdated(
        uint256 totalClaimableShares,
        bytes32 treeRoot,
        string treeCid
    );

    error ZeroAccountingAddress();
    error ZeroStEthAddress();
    error ZeroAdminAddress();
    error ZeroOracleAddress();
    error NotAccounting();
    error NotOracle();

    error InvalidTreeRoot();
    error InvalidTreeCID();
    error InvalidShares();
    error InvalidProof();
    error FeeSharesDecrease();
    error NotEnoughShares();

    modifier onlyAccounting() {
        if (msg.sender != ACCOUNTING) revert NotAccounting();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != ORACLE) revert NotOracle();
        _;
    }

    constructor(address stETH, address accounting, address oracle) {
        if (accounting == address(0)) revert ZeroAccountingAddress();
        if (oracle == address(0)) revert ZeroOracleAddress();
        if (stETH == address(0)) revert ZeroStEthAddress();

        ACCOUNTING = accounting;
        STETH = IStETH(stETH);
        ORACLE = oracle;

        _disableInitializers();
    }

    function initialize(address admin) external initializer {
        __AccessControlEnumerable_init();
        if (admin == address(0)) revert ZeroAdminAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Distribute fees to the Accounting in favor of the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Total Amount of stETH shares earned as fees
    /// @param proof Merkle proof of the leaf
    /// @return sharesToDistribute Amount of stETH shares distributed
    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external onlyAccounting returns (uint256 sharesToDistribute) {
        sharesToDistribute = getFeesToDistribute(nodeOperatorId, shares, proof);

        if (sharesToDistribute == 0) {
            return 0;
        }

        if (totalClaimableShares < sharesToDistribute) {
            revert NotEnoughShares();
        }

        unchecked {
            totalClaimableShares -= sharesToDistribute;
            distributedShares[nodeOperatorId] += sharesToDistribute;
        }

        STETH.transferShares(ACCOUNTING, sharesToDistribute);
        emit FeeDistributed(nodeOperatorId, sharesToDistribute);
    }

    /// @notice Receive the data of the Merkle tree from the Oracle contract and process it
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid,
        uint256 distributed
    ) external onlyOracle {
        if (
            totalClaimableShares + distributed > STETH.sharesOf(address(this))
        ) {
            revert InvalidShares();
        }

        if (distributed > 0) {
            if (bytes(_treeCid).length == 0) revert InvalidTreeCID();
            if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
            if (_treeRoot == treeRoot) revert InvalidTreeRoot();

            // Doesn't overflow because of the very first check.
            unchecked {
                totalClaimableShares += distributed;
            }

            treeRoot = _treeRoot;
            treeCid = _treeCid;

            emit DistributionDataUpdated(
                totalClaimableShares,
                _treeRoot,
                _treeCid
            );
        }
    }

    /// @notice Recover ERC20 tokens (except for stETH) from the contract
    /// @dev Any stETH transferred to feeDistributor is treated as a donation and can not be recovered
    /// @param token Address of the ERC20 token to recover
    /// @param amount Amount of the ERC20 token to recover
    function recoverERC20(address token, uint256 amount) external override {
        _onlyRecoverer();
        if (token == address(STETH)) {
            revert NotAllowedToRecover();
        }
        AssetRecovererLib.recoverERC20(token, amount);
    }

    /// @notice Get the Amount of stETH shares that are pending to be distributed
    /// @return pendingShares Amount shares that are pending to distribute
    function pendingSharesToDistribute() external view returns (uint256) {
        return STETH.sharesOf(address(this)) - totalClaimableShares;
    }

    /// @notice Get the Amount of stETH shares that can be distributed in favor of the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Total Amount of stETH shares earned as fees
    /// @param proof Merkle proof of the leaf
    /// @return sharesToDistribute Amount of stETH shares that can be distributed
    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) public view returns (uint256 sharesToDistribute) {
        bool isValid = MerkleProof.verifyCalldata(
            proof,
            treeRoot,
            hashLeaf(nodeOperatorId, shares)
        );
        if (!isValid) revert InvalidProof();

        uint256 _distributedShares = distributedShares[nodeOperatorId];
        if (_distributedShares > shares) {
            // This error means the fee oracle brought invalid data.
            revert FeeSharesDecrease();
        }

        unchecked {
            sharesToDistribute = shares - _distributedShares;
        }
    }

    /// @notice Get a hash of a leaf
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Amount of stETH shares
    /// @return Hash of the leaf
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

    function _onlyRecoverer() internal view override {
        _checkRole(RECOVERER_ROLE);
    }
}
