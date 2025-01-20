// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { BaseOracle } from "./lib/base-oracle/BaseOracle.sol";

import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";
import { ICSFeeOracle } from "./interfaces/ICSFeeOracle.sol";

contract CSFeeOracle is
    ICSFeeOracle,
    BaseOracle,
    PausableUntil,
    AssetRecoverer
{
    /// @notice No assets are stored in the contract

    /// @notice An ACL role granting the permission to submit the data for a committee report.
    bytes32 public constant SUBMIT_DATA_ROLE = keccak256("SUBMIT_DATA_ROLE");

    /// @notice An ACL role granting the permission to pause accepting oracle reports
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    /// @notice An ACL role granting the permission to resume accepting oracle reports
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");

    /// @notice An ACL role granting the permission to recover assets
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");

    uint256 internal constant MAX_BP = 10000;

    ICSFeeDistributor public feeDistributor;

    /// @notice Leeway in basis points is used to determine the under-performing validators threshold.
    /// `threshold` = `avgPerfBP` - `avgPerfLeewayBP`, where `avgPerfBP` is an average
    /// performance over the network computed by the off-chain oracle.
    uint256 public avgPerfLeewayBP;

    constructor(
        uint256 secondsPerSlot,
        uint256 genesisTime
    ) BaseOracle(secondsPerSlot, genesisTime) {}

    function initialize(
        address admin,
        address feeDistributorContract,
        address consensusContract,
        uint256 consensusVersion,
        uint256 _avgPerfLeewayBP
    ) external {
        if (admin == address(0)) revert ZeroAdminAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        BaseOracle._initialize(consensusContract, consensusVersion, 0);
        /// @dev _setFeeDistributorContract() reverts if zero address
        _setFeeDistributorContract(feeDistributorContract);
        _setPerformanceLeeway(_avgPerfLeewayBP);
    }

    /// @inheritdoc ICSFeeOracle
    function setFeeDistributorContract(
        address feeDistributorContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFeeDistributorContract(feeDistributorContract);
    }

    /// @inheritdoc ICSFeeOracle
    function setPerformanceLeeway(
        uint256 valueBP
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPerformanceLeeway(valueBP);
    }

    /// @inheritdoc ICSFeeOracle
    function submitReportData(
        ReportData calldata data,
        uint256 contractVersion
    ) external whenResumed {
        _checkMsgSenderIsAllowedToSubmitData();
        _checkContractVersion(contractVersion);
        _checkConsensusData(
            data.refSlot,
            data.consensusVersion,
            // it's a waste of gas to copy the whole calldata into mem but seems there's no way around
            keccak256(abi.encode(data))
        );
        _startProcessing();
        _handleConsensusReportData(data);
    }

    /// @inheritdoc ICSFeeOracle
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc ICSFeeOracle
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @inheritdoc ICSFeeOracle
    function pauseUntil(
        uint256 pauseUntilInclusive
    ) external onlyRole(PAUSE_ROLE) {
        _pauseUntil(pauseUntilInclusive);
    }

    function _setFeeDistributorContract(
        address feeDistributorContract
    ) internal {
        if (feeDistributorContract == address(0))
            revert ZeroFeeDistributorAddress();
        feeDistributor = ICSFeeDistributor(feeDistributorContract);
        emit FeeDistributorContractSet(feeDistributorContract);
    }

    function _setPerformanceLeeway(uint256 valueBP) internal {
        if (valueBP > MAX_BP) {
            revert InvalidPerfLeeway();
        }

        avgPerfLeewayBP = valueBP;
        emit PerfLeewaySet(valueBP);
    }

    /// @dev Called in `submitConsensusReport` after a consensus is reached.
    function _handleConsensusReport(
        ConsensusReport memory /* report */,
        uint256 /* prevSubmittedRefSlot */,
        uint256 /* prevProcessingRefSlot */
    ) internal override {
        // solhint-disable-previous-line no-empty-blocks
        // We do not require any type of async processing so far, so no actions required.
    }

    function _handleConsensusReportData(ReportData calldata data) internal {
        feeDistributor.processOracleReport({
            _treeRoot: data.treeRoot,
            _treeCid: data.treeCid,
            _logCid: data.logCid,
            distributed: data.distributed,
            rebate: data.rebate,
            refSlot: data.refSlot
        });
    }

    function _checkMsgSenderIsAllowedToSubmitData() internal view {
        address sender = _msgSender();
        if (!_isConsensusMember(sender) && !hasRole(SUBMIT_DATA_ROLE, sender)) {
            revert SenderNotAllowed();
        }
    }

    function _onlyRecoverer() internal view override {
        _checkRole(RECOVERER_ROLE);
    }
}
