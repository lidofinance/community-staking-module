// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ICSVerifier } from "./interfaces/ICSVerifier.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";

import { BeaconBlockHeader, Slot, Validator, Withdrawal } from "./lib/Types.sol";
import { GIndex } from "./lib/GIndex.sol";
import { SSZ } from "./lib/SSZ.sol";

/// @notice Convert withdrawal amount to wei
/// @param withdrawal Withdrawal struct
function amountWei(Withdrawal memory withdrawal) pure returns (uint256 result) {
    result = gweiToWei(withdrawal.amount);
}

/// @notice Convert gwei to wei
/// @param amount Amount in gwei
function gweiToWei(uint64 amount) pure returns (uint256 result) {
    result = uint256(amount) * 1 gwei;
}

contract CSVerifier is ICSVerifier {
    using { amountWei } for Withdrawal;

    using SSZ for BeaconBlockHeader;
    using SSZ for Withdrawal;
    using SSZ for Validator;

    // See `BEACON_ROOTS_ADDRESS` constant in the EIP-4788.
    address public constant BEACON_ROOTS =
        0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;

    uint64 public immutable SLOTS_PER_EPOCH;

    /// @dev This index is relative to a state like: `BeaconState.historical_summaries`.
    GIndex public immutable GI_HISTORICAL_SUMMARIES;

    /// @dev This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`.
    GIndex public immutable GI_FIRST_WITHDRAWAL;

    /// @dev This index is relative to a state like: `BeaconState.validators[0]`.
    GIndex public immutable GI_FIRST_VALIDATOR;

    /// @dev The very first slot the verifier is supposed to accept proofs for.
    Slot public immutable FIRST_SUPPORTED_SLOT;

    /// @dev Lido Locator contract
    ILidoLocator public immutable LOCATOR;

    /// @dev Staking module contract
    ICSModule public immutable MODULE;

    error RootNotFound();
    error InvalidGIndex();
    error InvalidBlockHeader();
    error InvalidChainConfig();
    error PartialWitdrawal();
    error ValidatorNotWithdrawn();
    error InvalidWithdrawalAddress();
    error UnsupportedSlot(uint256 slot);
    error ZeroLocatorAddress();
    error ZeroModuleAddress();

    constructor(
        address locator,
        address module,
        uint64 slotsPerEpoch,
        GIndex gIHistoricalSummaries,
        GIndex gIFirstWithdrawal,
        GIndex gIFirstValidator,
        Slot firstSupportedSlot
    ) {
        if (slotsPerEpoch == 0) revert InvalidChainConfig();
        if (module == address(0)) revert ZeroModuleAddress();
        if (locator == address(0)) revert ZeroLocatorAddress();

        MODULE = ICSModule(module);
        LOCATOR = ILidoLocator(locator);

        SLOTS_PER_EPOCH = slotsPerEpoch;

        GI_HISTORICAL_SUMMARIES = gIHistoricalSummaries;
        GI_FIRST_WITHDRAWAL = gIFirstWithdrawal;
        GI_FIRST_VALIDATOR = gIFirstValidator;

        FIRST_SUPPORTED_SLOT = firstSupportedSlot;
    }

    /// @notice Verify slashing proof and report slashing to the module for valid proofs
    /// @param beaconBlock Beacon block header
    /// @param witness Slashing witness
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the validator key in the Node Operator's key storage
    function processSlashingProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        SlashingWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        if (beaconBlock.header.slot < FIRST_SUPPORTED_SLOT.unwrap()) {
            revert UnsupportedSlot(beaconBlock.header.slot);
        }

        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.rootsTimestamp
            );
            if (trustedHeaderRoot != beaconBlock.header.hashTreeRoot()) {
                revert InvalidBlockHeader();
            }
        }

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        Validator memory validator = Validator({
            pubkey: pubkey,
            withdrawalCredentials: witness.withdrawalCredentials,
            effectiveBalance: witness.effectiveBalance,
            slashed: true,
            activationEligibilityEpoch: witness.activationEligibilityEpoch,
            activationEpoch: witness.activationEpoch,
            exitEpoch: witness.exitEpoch,
            withdrawableEpoch: witness.withdrawableEpoch
        });

        SSZ.verifyProof({
            proof: witness.validatorProof,
            root: beaconBlock.header.stateRoot,
            leaf: validator.hashTreeRoot(),
            gI: _getValidatorGI(witness.validatorIndex)
        });

        MODULE.submitInitialSlashing(nodeOperatorId, keyIndex);
    }

    /// @notice Verify withdrawal proof and report withdrawal to the module for valid proofs
    /// @param beaconBlock Beacon block header
    /// @param witness Withdrawal witness
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the validator key in the Node Operator's key storage
    function processWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        if (beaconBlock.header.slot < FIRST_SUPPORTED_SLOT.unwrap()) {
            revert UnsupportedSlot(beaconBlock.header.slot);
        }

        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.rootsTimestamp
            );
            if (trustedHeaderRoot != beaconBlock.header.hashTreeRoot()) {
                revert InvalidBlockHeader();
            }
        }

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        Withdrawal memory withdrawal = _processWithdrawalProof({
            witness: witness,
            stateEpoch: _computeEpochAtSlot(beaconBlock.header.slot),
            stateRoot: beaconBlock.header.stateRoot,
            pubkey: pubkey
        });

        MODULE.submitWithdrawal(
            nodeOperatorId,
            keyIndex,
            withdrawal.amountWei()
        );
    }

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
    ) external {
        if (beaconBlock.header.slot < FIRST_SUPPORTED_SLOT.unwrap()) {
            revert UnsupportedSlot(beaconBlock.header.slot);
        }

        if (oldBlock.header.slot < FIRST_SUPPORTED_SLOT.unwrap()) {
            revert UnsupportedSlot(oldBlock.header.slot);
        }

        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.rootsTimestamp
            );
            bytes32 headerRoot = beaconBlock.header.hashTreeRoot();
            if (trustedHeaderRoot != headerRoot) {
                revert InvalidBlockHeader();
            }
        }

        // It's up to a user to provide a valid generalized index of a historical block root in a summaries list.
        _checkRootGIndex(oldBlock.rootGIndex);
        SSZ.verifyProof({
            proof: oldBlock.proof,
            root: beaconBlock.header.stateRoot,
            leaf: oldBlock.header.hashTreeRoot(),
            gI: oldBlock.rootGIndex
        });

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        Withdrawal memory withdrawal = _processWithdrawalProof({
            witness: witness,
            stateEpoch: _computeEpochAtSlot(oldBlock.header.slot),
            stateRoot: oldBlock.header.stateRoot,
            pubkey: pubkey
        });

        MODULE.submitWithdrawal(
            nodeOperatorId,
            keyIndex,
            withdrawal.amountWei()
        );
    }

    function _getParentBlockRoot(
        uint64 blockTimestamp
    ) internal view returns (bytes32 root) {
        (bool success, bytes memory data) = BEACON_ROOTS.staticcall(
            abi.encode(blockTimestamp)
        );

        if (!success || data.length == 0) {
            revert RootNotFound();
        }

        root = abi.decode(data, (bytes32));
    }

    function _checkRootGIndex(GIndex gI) internal view {
        // Ensuring the provided generalized index is for a node somewhere below the historical_summaries root.
        if (!GI_HISTORICAL_SUMMARIES.isParentOf(gI)) {
            revert InvalidGIndex();
        }
    }

    /// @dev `stateRoot` is supposed to be trusted at this point.
    function _processWithdrawalProof(
        WithdrawalWitness calldata witness,
        uint256 stateEpoch,
        bytes32 stateRoot,
        bytes memory pubkey
    ) internal view returns (Withdrawal memory withdrawal) {
        address withdrawalAddress = _wcToAddress(witness.withdrawalCredentials);
        if (withdrawalAddress != LOCATOR.withdrawalVault()) {
            revert InvalidWithdrawalAddress();
        }

        if (stateEpoch < witness.withdrawableEpoch) {
            revert ValidatorNotWithdrawn();
        }

        // See https://hackmd.io/1wM8vqeNTjqt4pC3XoCUKQ
        if (!witness.slashed && gweiToWei(witness.amount) < 8 ether) {
            revert PartialWitdrawal();
        }

        Validator memory validator = Validator({
            pubkey: pubkey,
            withdrawalCredentials: witness.withdrawalCredentials,
            effectiveBalance: witness.effectiveBalance,
            slashed: witness.slashed,
            activationEligibilityEpoch: witness.activationEligibilityEpoch,
            activationEpoch: witness.activationEpoch,
            exitEpoch: witness.exitEpoch,
            withdrawableEpoch: witness.withdrawableEpoch
        });

        SSZ.verifyProof({
            proof: witness.validatorProof,
            root: stateRoot,
            leaf: validator.hashTreeRoot(),
            gI: _getValidatorGI(witness.validatorIndex)
        });

        withdrawal = Withdrawal({
            index: witness.withdrawalIndex,
            validatorIndex: witness.validatorIndex,
            withdrawalAddress: withdrawalAddress,
            amount: witness.amount
        });

        SSZ.verifyProof({
            proof: witness.withdrawalProof,
            root: stateRoot,
            leaf: withdrawal.hashTreeRoot(),
            gI: _getWithdrawalGI(witness.withdrawalOffset)
        });
    }

    function _getValidatorGI(
        uint256 offset
    ) internal view returns (GIndex gIndex) {
        gIndex = GI_FIRST_VALIDATOR.shr(offset);
    }

    function _getWithdrawalGI(
        uint256 offset
    ) internal view returns (GIndex gIndex) {
        gIndex = GI_FIRST_WITHDRAWAL.shr(offset);
    }

    // From HashConsensus contract.
    function _computeEpochAtSlot(
        uint256 slot
    ) internal view returns (uint256 epoch) {
        // See: github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#compute_epoch_at_slot
        epoch = slot / SLOTS_PER_EPOCH;
    }

    function _wcToAddress(
        bytes32 value
    ) internal pure returns (address result) {
        result = address(uint160(uint256(value)));
    }
}
