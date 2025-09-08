// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { BeaconBlockHeader, Slot } from "../lib/Types.sol";
import { GIndex } from "../lib/GIndex.sol";
import { ICSModule } from "./ICSModule.sol";

interface ICSVerifier {
    struct GIndices {
        GIndex gIFirstWithdrawalPrev;
        GIndex gIFirstWithdrawalCurr;
        GIndex gIFirstValidatorPrev;
        GIndex gIFirstValidatorCurr;
        GIndex gIFirstHistoricalSummaryPrev;
        GIndex gIFirstHistoricalSummaryCurr;
        GIndex gIFirstBlockRootInSummaryPrev;
        GIndex gIFirstBlockRootInSummaryCurr;
    }

    struct ProvableBeaconBlockHeader {
        BeaconBlockHeader header; // Header of a block which root is a root at rootsTimestamp.
        uint64 rootsTimestamp; // To be passed to the EIP-4788 block roots contract.
    }

    struct SlashingWitness {
        uint64 validatorIndex;
        bytes32 withdrawalCredentials;
        uint64 effectiveBalance;
        uint64 activationEligibilityEpoch;
        uint64 activationEpoch;
        uint64 exitEpoch;
        uint64 withdrawableEpoch;
        bytes32[] validatorProof;
    }

    struct WithdrawalWitness {
        // ── Withdrawal fields ─────────────────────────────────────────────────
        uint8 withdrawalOffset; // In the withdrawals list.
        uint64 withdrawalIndex; // Network-wise.
        uint64 validatorIndex;
        uint64 amount;
        // ── Validator fields ──────────────────────────────────────────────────
        bytes32 withdrawalCredentials;
        uint64 effectiveBalance;
        bool slashed;
        uint64 activationEligibilityEpoch;
        uint64 activationEpoch;
        uint64 exitEpoch;
        uint64 withdrawableEpoch;
        // ── Proofs ────────────────────────────────────────────────────────────
        // We accept the `withdrawalProof` against a state root, because it saves a few hops.
        bytes32[] withdrawalProof;
        bytes32[] validatorProof;
    }

    // A witness for a block header which root is accessible via `historical_summaries` field.
    struct HistoricalHeaderWitness {
        BeaconBlockHeader header;
        bytes32[] proof;
    }

    error RootNotFound();
    error InvalidBlockHeader();
    error InvalidChainConfig();
    error PartialWithdrawal();
    error ValidatorNotWithdrawn();
    error InvalidWithdrawalAddress();
    error UnsupportedSlot(Slot slot);
    error ZeroModuleAddress();
    error ZeroWithdrawalAddress();
    error ZeroAdminAddress();
    error InvalidPivotSlot();
    error InvalidCapellaSlot();

    function PAUSE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function BEACON_ROOTS() external view returns (address);

    function SLOTS_PER_EPOCH() external view returns (uint64);

    function SLOTS_PER_HISTORICAL_ROOT() external view returns (uint64);

    function GI_FIRST_WITHDRAWAL_PREV() external view returns (GIndex);

    function GI_FIRST_WITHDRAWAL_CURR() external view returns (GIndex);

    function GI_FIRST_VALIDATOR_PREV() external view returns (GIndex);

    function GI_FIRST_VALIDATOR_CURR() external view returns (GIndex);

    function GI_FIRST_HISTORICAL_SUMMARY_PREV() external view returns (GIndex);

    function GI_FIRST_HISTORICAL_SUMMARY_CURR() external view returns (GIndex);

    function GI_FIRST_BLOCK_ROOT_IN_SUMMARY_PREV()
        external
        view
        returns (GIndex);

    function GI_FIRST_BLOCK_ROOT_IN_SUMMARY_CURR()
        external
        view
        returns (GIndex);

    function FIRST_SUPPORTED_SLOT() external view returns (Slot);

    function PIVOT_SLOT() external view returns (Slot);

    function CAPELLA_SLOT() external view returns (Slot);

    function WITHDRAWAL_ADDRESS() external view returns (address);

    function MODULE() external view returns (ICSModule);

    /// @notice Pause write methods calls for `duration` seconds
    /// @param duration Duration of the pause in seconds
    function pauseFor(uint256 duration) external;

    /// @notice Resume write methods calls
    function resume() external;

    /// @notice Verify withdrawal proof and report withdrawal to the module for valid proofs
    /// @param beaconBlock Beacon block header
    /// @param witness Withdrawal witness against the `beaconBlock`'s state root.
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the validator key in the Node Operator's key storage
    function processWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    /// @notice Verify withdrawal proof against historical summaries data and report withdrawal to the module for valid proofs
    /// @param beaconBlock Beacon block header
    /// @param oldBlock Historical block header witness
    /// @param witness Withdrawal witness
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the validator key in the Node Operator's key storage
    function processHistoricalWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        HistoricalHeaderWitness calldata oldBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;
}
