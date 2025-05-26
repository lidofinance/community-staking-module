// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";

import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { BaseOracle } from "./lib/base-oracle/BaseOracle.sol";

import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { ICSStrikes } from "./interfaces/ICSStrikes.sol";
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

    ICSFeeDistributor public immutable FEE_DISTRIBUTOR;
    ICSStrikes public immutable STRIKES;

    /// @dev DEPRECATED
    /// @custom:oz-renamed-from feeDistributor
    ICSFeeDistributor internal _feeDistributor;
    /// @dev DEPRECATED
    /// @custom:oz-renamed-from avgPerfLeewayBP
    uint256 internal _avgPerfLeewayBP;

    constructor(
        address feeDistributor,
        address strikes,
        uint256 secondsPerSlot,
        uint256 genesisTime
    ) BaseOracle(secondsPerSlot, genesisTime) {
        if (feeDistributor == address(0)) {
            revert ZeroFeeDistributorAddress();
        }
        if (strikes == address(0)) {
            revert ZeroStrikesAddress();
        }

        FEE_DISTRIBUTOR = ICSFeeDistributor(feeDistributor);
        STRIKES = ICSStrikes(strikes);
    }

    /// @dev initialize contract from scratch
    function initialize(
        address admin,
        address consensusContract,
        uint256 consensusVersion
    ) external {
        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        BaseOracle._initialize(consensusContract, consensusVersion, 0);

        _updateContractVersion(2);
    }

    /// @dev should be called after update on the proxy
    function finalizeUpgradeV2(uint256 consensusVersion) external {
        _setConsensusVersion(consensusVersion);

        // nullify storage slots
        assembly ("memory-safe") {
            sstore(_feeDistributor.slot, 0x00)
            sstore(_avgPerfLeewayBP.slot, 0x00)
        }

        _updateContractVersion(2);
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
        FEE_DISTRIBUTOR.processOracleReport({
            _treeRoot: data.treeRoot,
            _treeCid: data.treeCid,
            _logCid: data.logCid,
            distributed: data.distributed,
            rebate: data.rebate,
            refSlot: data.refSlot
        });
        STRIKES.processOracleReport(data.strikesTreeRoot, data.strikesTreeCid);
    }

    function _checkMsgSenderIsAllowedToSubmitData() internal view {
        if (
            _isConsensusMember(msg.sender) ||
            hasRole(SUBMIT_DATA_ROLE, msg.sender)
        ) {
            return;
        }
        revert SenderNotAllowed();
    }

    function _onlyRecoverer() internal view override {
        _checkRole(RECOVERER_ROLE);
    }
}
