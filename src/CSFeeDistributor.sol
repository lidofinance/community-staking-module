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

    /// @notice The latest Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the last published Merkle tree
    string public treeCid;

    /// @notice CID of the file with log for the last frame reported
    string public logCid;

    /// @notice Amount of stETH shares sent to the Accounting in favor of the NO
    mapping(uint256 => uint256) public distributedShares;

    /// @notice Total Amount of stETH shares available for claiming by NOs
    uint256 public totalClaimableShares;

    /// @notice Array of the distribution data history
    mapping(uint256 => DistributionData) internal _distributionDataHistory;

    /// @notice The number of _distributionDataHistory records
    uint256 public distributionDataHistoryCount;

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

    /// @inheritdoc ICSFeeDistributor
    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) external returns (uint256 sharesToDistribute) {
        if (msg.sender != ACCOUNTING) revert NotAccounting();
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
        emit OperatorFeeDistributed(nodeOperatorId, sharesToDistribute);
    }

    /// @inheritdoc ICSFeeDistributor
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid,
        string calldata _logCid,
        uint256 _distributedShares,
        uint256 refSlot
    ) external {
        if (msg.sender != ORACLE) revert NotOracle();
        if (
            totalClaimableShares + _distributedShares >
            STETH.sharesOf(address(this))
        ) {
            revert InvalidShares();
        }

        if (_distributedShares > 0) {
            if (bytes(_treeCid).length == 0) revert InvalidTreeCID();
            if (keccak256(bytes(_treeCid)) == keccak256(bytes(treeCid)))
                revert InvalidTreeCID();
            if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
            if (_treeRoot == treeRoot) revert InvalidTreeRoot();

            // Doesn't overflow because of the very first check.
            unchecked {
                totalClaimableShares += _distributedShares;
            }

            treeRoot = _treeRoot;
            treeCid = _treeCid;

            emit DistributionDataUpdated(
                totalClaimableShares,
                _treeRoot,
                _treeCid
            );
        }

        emit ModuleFeeDistributed(_distributedShares);

        // NOTE: Make sure off-chain tooling provides a distinct CID of a log even for empty reports, e.g. by mixing
        // in a frame identifier such as reference slot to a file.
        if (bytes(_logCid).length == 0) revert InvalidLogCID();
        if (keccak256(bytes(_logCid)) == keccak256(bytes(logCid)))
            revert InvalidLogCID();

        logCid = _logCid;
        emit DistributionLogUpdated(_logCid);

        _distributionDataHistory[
            distributionDataHistoryCount
        ] = DistributionData({
            refSlot: refSlot,
            treeRoot: treeRoot,
            treeCid: treeCid,
            logCid: _logCid,
            distributed: _distributedShares
        });

        unchecked {
            ++distributionDataHistoryCount;
        }
    }

    /// @inheritdoc AssetRecoverer
    function recoverERC20(address token, uint256 amount) external override {
        _onlyRecoverer();
        if (token == address(STETH)) {
            revert NotAllowedToRecover();
        }
        AssetRecovererLib.recoverERC20(token, amount);
    }

    /// @inheritdoc ICSFeeDistributor
    function pendingSharesToDistribute() external view returns (uint256) {
        return STETH.sharesOf(address(this)) - totalClaimableShares;
    }

    /// @inheritdoc ICSFeeDistributor
    function getHistoricalDistributionData(
        uint256 index
    ) external view returns (DistributionData memory) {
        return _distributionDataHistory[index];
    }

    /// @inheritdoc ICSFeeDistributor
    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] calldata proof
    ) public view returns (uint256 sharesToDistribute) {
        if (proof.length == 0) revert InvalidProof();
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

    /// @inheritdoc ICSFeeDistributor
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
