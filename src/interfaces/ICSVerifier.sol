// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSVerifier {
    type GIndex is bytes32;
    type Slot is uint64;

    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposerIndex;
        bytes32 parentRoot;
        bytes32 stateRoot;
        bytes32 bodyRoot;
    }

    struct HistoricalHeaderWitness {
        BeaconBlockHeader header;
        GIndex rootGIndex;
        bytes32[] proof;
    }

    struct ProvableBeaconBlockHeader {
        BeaconBlockHeader header;
        uint64 rootsTimestamp;
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
        uint8 withdrawalOffset;
        uint64 withdrawalIndex;
        uint64 validatorIndex;
        uint64 amount;
        bytes32 withdrawalCredentials;
        uint64 effectiveBalance;
        bool slashed;
        uint64 activationEligibilityEpoch;
        uint64 activationEpoch;
        uint64 exitEpoch;
        uint64 withdrawableEpoch;
        bytes32[] withdrawalProof;
        bytes32[] validatorProof;
    }

    error BranchHasExtraItem();
    error BranchHasMissingItem();
    error IndexOutOfRange();
    error InvalidBlockHeader();
    error InvalidChainConfig();
    error InvalidGIndex();
    error InvalidProof();
    error InvalidWithdrawalAddress();
    error PartialWitdrawal();
    error RootNotFound();
    error UnsupportedSlot(uint256 slot);
    error ValidatorNotWithdrawn();
    error ZeroLocatorAddress();
    error ZeroModuleAddress();

    function BEACON_ROOTS() external view returns (address);

    function FIRST_SUPPORTED_SLOT() external view returns (Slot);

    function GI_FIRST_VALIDATOR() external view returns (GIndex);

    function GI_FIRST_WITHDRAWAL() external view returns (GIndex);

    function GI_HISTORICAL_SUMMARIES() external view returns (GIndex);

    function LOCATOR() external view returns (address);

    function MODULE() external view returns (address);

    function SLOTS_PER_EPOCH() external view returns (uint64);

    function processHistoricalWithdrawalProof(
        ProvableBeaconBlockHeader memory beaconBlock,
        HistoricalHeaderWitness memory oldBlock,
        WithdrawalWitness memory witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    function processSlashingProof(
        ProvableBeaconBlockHeader memory beaconBlock,
        SlashingWitness memory witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    function processWithdrawalProof(
        ProvableBeaconBlockHeader memory beaconBlock,
        WithdrawalWitness memory witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;
}
