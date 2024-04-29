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
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // 0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE"); // 0xb3e25b5404b87e5a838579cb5d7481d61ad96ee284d38ec1e97c07ba64e7f6fc

    IStETH public immutable STETH;
    address public immutable ACCOUNTING;

    /// @notice Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the published Merkle tree
    string public treeCid;

    /// @notice Amount of stETH shares sent to the Accounting in favor of the NO
    mapping(uint256 => uint256) public distributedShares;

    /// @notice Total Amount of stETH shares available for claiming by NOs
    uint256 public claimableShares;

    /// @dev Emitted when fees are distributed
    event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);

    error ZeroAddress(string field);
    error NotAccounting();

    error InvalidTreeRoot();
    error InvalidTreeCID();
    error InvalidShares();
    error InvalidProof();

    constructor(address stETH, address accounting) {
        if (accounting == address(0)) revert ZeroAddress("accounting");
        if (stETH == address(0)) revert ZeroAddress("stETH");

        ACCOUNTING = accounting;
        STETH = IStETH(stETH);
    }

    function initialize(address admin, address oracle) external initializer {
        __AccessControlEnumerable_init();
        if (admin == address(0)) revert ZeroAddress("admin");
        if (oracle == address(0)) revert ZeroAddress("oracle");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ROLE, oracle);
    }

    /// @notice Get the Amount of stETH shares that are pending to be distributed
    function pendingToDistribute() external view returns (uint256) {
        return STETH.sharesOf(address(this)) - claimableShares;
    }

    /// @notice Get the Amount of stETH shares that can be distributed in favor of the Node Operator
    /// @param proof Merkle proof of the leaf
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Total Amount of stETH shares earned as fees
    /// @return Amount of stETH shares that can be distributed
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

    /// @notice Distribute fees to the Accounting in favor of the Node Operator
    /// @param proof Merkle proof of the leaf
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Total Amount of stETH shares earned as fees
    /// @return Amount of stETH shares distributed
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

        STETH.transferShares(ACCOUNTING, sharesToDistribute);
        emit FeeDistributed(nodeOperatorId, sharesToDistribute);

        return sharesToDistribute;
    }

    /// @notice Receive the data of the Merkle tree from the Oracle contract and process it
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid,
        uint256 distributed
    ) external onlyRole(ORACLE_ROLE) {
        if (claimableShares + distributed > STETH.sharesOf(address(this))) {
            revert InvalidShares();
        }

        if (distributed > 0) {
            if (bytes(_treeCid).length == 0) revert InvalidTreeCID();
            if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
            if (_treeRoot == treeRoot) revert InvalidTreeRoot();

            // Doesn't overflow because of the very first check.
            unchecked {
                claimableShares += distributed;
            }

            treeRoot = _treeRoot;
            treeCid = _treeCid;
        }
    }

    /// @notice Get a hash of a leaf
    /// @param nodeOperatorId ID of the Node Operator
    /// @param shares Amount of stETH shares
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

    function _onlyRecoverer() internal view override {
        _checkRole(RECOVERER_ROLE);
    }

    modifier onlyAccounting() {
        if (msg.sender != ACCOUNTING) revert NotAccounting();
        _;
    }
}
