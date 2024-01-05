// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { BeaconBlockHeader } from "../lib/Types.sol";
import { GIndex } from "../lib/GIndex.sol";

interface ICSVerifier {
    struct WithdrawalProofContext {
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
        // All proofs are relative to the block header state root.
        bytes32[] withdrawalProof;
        bytes32[] validatorProof;
    }

    struct ProvableBeaconBlockHeader {
        BeaconBlockHeader blockHeader; // Header of a block which root is a root at rootsTimestamp.
        uint64 rootsTimestamp; // To be passed to the EIP-4788 block roots contract.
    }

    struct ProvableHistoricalBlockHeader {
        ProvableBeaconBlockHeader anchorBlock;
        GIndex blockRootGIndex;
        bytes32[] blockRootProof;
        BeaconBlockHeader historicalBlock;
    }

    function processWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        WithdrawalProofContext calldata ctx,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    function processHistoricalWithdrawalProof(
        ProvableHistoricalBlockHeader calldata beaconBlock,
        WithdrawalProofContext calldata ctx,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;
}
