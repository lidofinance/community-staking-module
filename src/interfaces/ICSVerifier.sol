// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { BeaconBlockHeader } from "../lib/Types.sol";
import { GIndex } from "../lib/GIndex.sol";

interface ICSVerifier {
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
        GIndex rootGIndex;
        bytes32[] proof;
    }

    /// @notice `witness` is a slashing witness against the `beaconBlock`'s state root.
    function processSlashingProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        SlashingWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    /// @notice `witness` is a withdrawal witness against the `beaconBlock`'s state root.
    function processWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    /// @notice `oldHeader` is a beacon block header witness against the `beaconBlock`'s state root.
    /// @notice `witness` is a withdrawal witness against the `oldHeader`'s state root.
    function processHistoricalWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        HistoricalHeaderWitness calldata oldBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;
}
