// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { PausableUntil } from "base-oracle/utils/PausableUntil.sol";
import { BaseOracle } from "base-oracle/oracle/BaseOracle.sol";

import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { ICSFeeOracle } from "./interfaces/ICSFeeOracle.sol";

contract CSFeeOracle is ICSFeeOracle, BaseOracle, PausableUntil {
    struct ReportData {
        /// @dev Version of the oracle consensus rules. Current version expected
        /// by the oracle can be obtained by calling getConsensusVersion().
        uint256 consensusVersion;
        /// @dev Reference slot for which the report was calculated. If the slot
        /// contains a block, the state being reported should include all state
        /// changes resulting from that block. The epoch containing the slot
        /// should be finalized prior to calculating the report.
        uint256 refSlot;
        /// @notice Merkle Tree root
        bytes32 treeRoot;
        /// @notice CID of the published Merkle tree
        string treeCid;
        /// @notice Total amount of fees distributed
        uint256 distributed;
    }

    /// @notice An ACL role granting the permission to submit the data for a committee report.
    bytes32 public constant MANAGE_FEE_DISTRIBUTOR_CONTRACT_ROLE =
        keccak256("MANAGE_FEE_DISTRIBUTOR_CONTRACT_ROLE");

    /// @notice An ACL role granting the permission to submit the data for a committee report.
    bytes32 public constant SUBMIT_DATA_ROLE = keccak256("SUBMIT_DATA_ROLE");

    /// @notice An ACL role granting the permission to pause accepting oracle reports
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    /// @notice An ACL role granting the permission to resume accepting oracle reports
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");

    ICSFeeDistributor public feeDistributor;

    /// @notice Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the published Merkle tree
    string public treeCid;

    /// @dev Emitted when a new fee distributor contract is set
    event FeeDistributorContractSet(address feeDistributorContract);

    /// @dev Emitted when a report is consolidated
    event ReportConsolidated(
        uint256 indexed refSlot,
        uint256 distributed,
        bytes32 newRoot,
        string treeCid
    );

    error TreeRootCannotBeZero();
    error TreeCidCannotBeEmpty();
    error NothingToDistribute();
    error AdminCannotBeZero();
    error SenderNotAllowed();

    constructor(
        uint256 secondsPerSlot,
        uint256 genesisTime
    ) BaseOracle(secondsPerSlot, genesisTime) {}

    function initialize(
        address admin,
        address feeDistributorContract,
        address consensusContract,
        uint256 consensusVersion,
        uint256 lastProcessingRefSlot // will be the first ref slot in getConsensusReport()
    ) external {
        if (admin == address(0)) revert AdminCannotBeZero();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        BaseOracle._initialize(
            consensusContract,
            consensusVersion,
            lastProcessingRefSlot
        );
        /// @dev _setFeeDistributorContract() reverts if zero address
        _setFeeDistributorContract(feeDistributorContract);
    }

    /// @notice Sets a new fee distributor contract
    /// @param feeDistributorContract Address of the new fee distributor contract
    function setFeeDistributorContract(
        address feeDistributorContract
    ) external onlyRole(MANAGE_FEE_DISTRIBUTOR_CONTRACT_ROLE) {
        _setFeeDistributorContract(feeDistributorContract);
    }

    /// @notice Submits the data for a committee report
    /// @param data Data for a committee report
    /// @param contractVersion Version of the oracle consensus rules
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

    /// @notice Resume accepting oracle reports
    function resume() external whenPaused onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @notice Pause accepting oracle reports for a duration
    /// @param duration Duration of the pause
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
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

    /// @notice Pause accepting oracle reports until a timestamp
    /// @param pauseUntilInclusive Timestamp until which the oracle reports are paused
    function pauseUntil(
        uint256 pauseUntilInclusive
    ) external onlyRole(PAUSE_ROLE) {
        _pauseUntil(pauseUntilInclusive);
    }

    function _setFeeDistributorContract(
        address feeDistributorContract
    ) internal {
        if (feeDistributorContract == address(0)) revert AddressCannotBeZero();
        feeDistributor = ICSFeeDistributor(feeDistributorContract);
        emit FeeDistributorContractSet(feeDistributorContract);
    }

    function _handleConsensusReport(
        ConsensusReport memory /* report */,
        uint256 /* prevSubmittedRefSlot */,
        uint256 /* prevProcessingRefSlot */
    ) internal override {
        // TODO: Implement me
        // NOTE: if we implement sending all leafs directly, we probably will need to support the sending in batches,
        // which means, we'll be ought to check the processing state and revert if not all data was send so far.
        // For reference look at the ValidatorExitBusOracle.
    }

    function _handleConsensusReportData(ReportData calldata data) internal {
        _reportDataSanityCheck(data);

        feeDistributor.receiveFees(data.distributed);
        treeRoot = data.treeRoot;
        treeCid = data.treeCid;
        emit ReportConsolidated(
            data.refSlot,
            data.distributed,
            data.treeRoot,
            data.treeCid
        );
    }

    function _reportDataSanityCheck(ReportData calldata data) internal pure {
        if (bytes(data.treeCid).length == 0) revert TreeCidCannotBeEmpty();
        if (data.treeRoot == bytes32(0)) revert TreeRootCannotBeZero();
        if (data.distributed == 0) revert NothingToDistribute();
        // refSlot is checked by HashConsensus
    }

    function _checkMsgSenderIsAllowedToSubmitData() internal view {
        address sender = _msgSender();
        if (!hasRole(SUBMIT_DATA_ROLE, sender) && !_isConsensusMember(sender)) {
            revert SenderNotAllowed();
        }
    }
}
