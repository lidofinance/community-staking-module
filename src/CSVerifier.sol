// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import { BeaconBlockHeader, Slot, Validator, Withdrawal, PendingConsolidation } from "./lib/Types.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { GIndex } from "./lib/GIndex.sol";
import { SSZ } from "./lib/SSZ.sol";

import { ICSVerifier } from "./interfaces/ICSVerifier.sol";
import { ICSModule, ValidatorWithdrawalInfo } from "./interfaces/ICSModule.sol";

/// @notice Convert withdrawal amount to wei
/// @param withdrawal Withdrawal struct
function amountWei(Withdrawal memory withdrawal) pure returns (uint256) {
    return gweiToWei(withdrawal.amount);
}

/// @notice Convert gwei to wei
/// @param amount Amount in gwei
function gweiToWei(uint64 amount) pure returns (uint256) {
    return uint256(amount) * 1 gwei;
}

contract CSVerifier is ICSVerifier, AccessControlEnumerable, PausableUntil {
    using { amountWei } for Withdrawal;

    using SSZ for PendingConsolidation;
    using SSZ for BeaconBlockHeader;
    using SSZ for Withdrawal;
    using SSZ for Validator;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");

    // See `BEACON_ROOTS_ADDRESS` constant in the EIP-4788.
    address public constant BEACON_ROOTS =
        0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;

    uint64 public immutable SLOTS_PER_EPOCH;

    /// @dev Count of historical roots per accumulator.
    /// @dev See https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#time-parameters
    uint64 public immutable SLOTS_PER_HISTORICAL_ROOT;

    /// @dev This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`.
    GIndex public immutable GI_FIRST_WITHDRAWAL_PREV;

    /// @dev This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`.
    GIndex public immutable GI_FIRST_WITHDRAWAL_CURR;

    /// @dev This index is relative to a state like: `BeaconState.validators[0]`.
    GIndex public immutable GI_FIRST_VALIDATOR_PREV;

    /// @dev This index is relative to a state like: `BeaconState.validators[0]`.
    GIndex public immutable GI_FIRST_VALIDATOR_CURR;

    /// @dev This index is relative to a state like: `BeaconState.historical_summaries[0]`.
    GIndex public immutable GI_FIRST_HISTORICAL_SUMMARY_PREV;

    /// @dev This index is relative to a state like: `BeaconState.historical_summaries[0]`.
    GIndex public immutable GI_FIRST_HISTORICAL_SUMMARY_CURR;

    /// @dev This index is relative to HistoricalSummary like: HistoricalSummary.blockRoots[0].
    GIndex public immutable GI_FIRST_BLOCK_ROOT_IN_SUMMARY_PREV;

    /// @dev This index is relative to HistoricalSummary like: HistoricalSummary.blockRoots[0].
    GIndex public immutable GI_FIRST_BLOCK_ROOT_IN_SUMMARY_CURR;

    /// @dev This index is relative to a state like: `BeaconState.balances[0]`.
    GIndex public immutable GI_FIRST_BALANCES_NODE_PREV;

    /// @dev This index is relative to a state like: `BeaconState.balances[0]`.
    GIndex public immutable GI_FIRST_BALANCES_NODE_CURR;

    /// @dev This index is relative to a state like: `BeaconState.pending_consolidations[0]`.
    GIndex public immutable GI_FIRST_PENDING_CONSOLIDATION_PREV;

    /// @dev This index is relative to a state like: `BeaconState.pending_consolidations[0]`.
    GIndex public immutable GI_FIRST_PENDING_CONSOLIDATION_CURR;

    /// @dev The very first slot the verifier is supposed to accept proofs for.
    Slot public immutable FIRST_SUPPORTED_SLOT;

    /// @dev The first slot of the currently compatible fork.
    Slot public immutable PIVOT_SLOT;

    /// @dev Historical summaries started accumulating from the slot of Capella fork.
    Slot public immutable CAPELLA_SLOT;

    /// @dev An address withdrawals are supposed to happen to (Lido withdrawal credentials).
    address public immutable WITHDRAWAL_ADDRESS;

    /// @dev Staking module contract.
    ICSModule public immutable MODULE;

    /// @dev The previous and current forks can be essentially the same.
    constructor(
        address withdrawalAddress,
        address module,
        uint64 slotsPerEpoch,
        uint64 slotsPerHistoricalRoot,
        GIndices memory gindices,
        Slot firstSupportedSlot,
        Slot pivotSlot,
        Slot capellaSlot,
        address admin
    ) {
        if (withdrawalAddress == address(0)) {
            revert ZeroWithdrawalAddress();
        }

        if (module == address(0)) {
            revert ZeroModuleAddress();
        }

        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        if (slotsPerEpoch == 0) {
            revert InvalidChainConfig();
        }

        if (slotsPerHistoricalRoot == 0) {
            revert InvalidChainConfig();
        }

        if (firstSupportedSlot > pivotSlot) {
            revert InvalidPivotSlot();
        }

        if (capellaSlot > firstSupportedSlot) {
            revert InvalidCapellaSlot();
        }

        WITHDRAWAL_ADDRESS = withdrawalAddress;
        MODULE = ICSModule(module);

        SLOTS_PER_EPOCH = slotsPerEpoch;
        SLOTS_PER_HISTORICAL_ROOT = slotsPerHistoricalRoot;

        GI_FIRST_WITHDRAWAL_PREV = gindices.gIFirstWithdrawalPrev;
        GI_FIRST_WITHDRAWAL_CURR = gindices.gIFirstWithdrawalCurr;

        GI_FIRST_VALIDATOR_PREV = gindices.gIFirstValidatorPrev;
        GI_FIRST_VALIDATOR_CURR = gindices.gIFirstValidatorCurr;

        GI_FIRST_HISTORICAL_SUMMARY_PREV = gindices
            .gIFirstHistoricalSummaryPrev;
        GI_FIRST_HISTORICAL_SUMMARY_CURR = gindices
            .gIFirstHistoricalSummaryCurr;

        GI_FIRST_BLOCK_ROOT_IN_SUMMARY_PREV = gindices
            .gIFirstBlockRootInSummaryPrev;
        GI_FIRST_BLOCK_ROOT_IN_SUMMARY_CURR = gindices
            .gIFirstBlockRootInSummaryCurr;

        FIRST_SUPPORTED_SLOT = firstSupportedSlot;
        PIVOT_SLOT = pivotSlot;
        CAPELLA_SLOT = capellaSlot;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICSVerifier
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc ICSVerifier
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @inheritdoc ICSVerifier
    function processWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external whenResumed {
        if (beaconBlock.header.slot < FIRST_SUPPORTED_SLOT) {
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

        uint256 withdrawalAmount = _processWithdrawalProof({
            witness: witness,
            stateSlot: beaconBlock.header.slot,
            stateRoot: beaconBlock.header.stateRoot,
            pubkey: pubkey
        });

        ValidatorWithdrawalInfo[]
            memory withdrawalsInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalsInfo[0] = ValidatorWithdrawalInfo(
            nodeOperatorId,
            keyIndex,
            withdrawalAmount,
            0
        );
        MODULE.submitWithdrawals(withdrawalsInfo);
    }

    /// @inheritdoc ICSVerifier
    function processHistoricalWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        HistoricalHeaderWitness calldata oldBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external whenResumed {
        if (witness.slashed) {
            revert ValidatorIsSlashed();
        }

        if (beaconBlock.header.slot < FIRST_SUPPORTED_SLOT) {
            revert UnsupportedSlot(beaconBlock.header.slot);
        }

        if (oldBlock.header.slot < FIRST_SUPPORTED_SLOT) {
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

        SSZ.verifyProof({
            proof: oldBlock.proof,
            root: beaconBlock.header.stateRoot,
            leaf: oldBlock.header.hashTreeRoot(),
            gI: _getHistoricalBlockRootGI(
                beaconBlock.header.slot,
                oldBlock.header.slot
            )
        });

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        uint256 withdrawalAmount = _processWithdrawalProof({
            witness: witness,
            stateSlot: oldBlock.header.slot,
            stateRoot: oldBlock.header.stateRoot,
            pubkey: pubkey
        });

        ValidatorWithdrawalInfo[]
            memory withdrawalsInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalsInfo[0] = ValidatorWithdrawalInfo(
            nodeOperatorId,
            keyIndex,
            withdrawalAmount,
            0 // no slashing penalty
        );
        MODULE.submitWithdrawals(withdrawalsInfo);
    }

    function processConsolidation(
        RecentHeaderWitness calldata recentBlock,
        HistoricalHeaderWitness calldata withdrawableBlock,
        HistoricalHeaderWitness calldata consolidationBlock,
        PendingConsolidationWitness calldata consolidationWitness,
        ValidatorWitness calldata validatorWitness,
        BalanceWitness calldata balanceWitness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        if (recentBlock.header.slot < FIRST_SUPPORTED_SLOT) {
            revert UnsupportedSlot(recentBlock.header.slot);
        }

        if (withdrawableBlock.header.slot < FIRST_SUPPORTED_SLOT) {
            revert UnsupportedSlot(withdrawableBlock.header.slot);
        }

        if (consolidationBlock.header.slot < FIRST_SUPPORTED_SLOT) {
            revert UnsupportedSlot(consolidationBlock.header.slot);
        }

        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                recentBlock.rootsTimestamp
            );
            bytes32 headerRoot = recentBlock.header.hashTreeRoot();
            if (trustedHeaderRoot != headerRoot) {
                revert InvalidBlockHeader();
            }
        }

        SSZ.verifyProof({
            proof: consolidationBlock.proof,
            root: recentBlock.header.stateRoot,
            leaf: consolidationBlock.header.hashTreeRoot(),
            gI: _getHistoricalBlockRootGI(
                recentBlock.header.slot,
                consolidationBlock.header.slot
            )
        });

        SSZ.verifyProof({
            proof: consolidationWitness.proof,
            root: consolidationBlock.header.stateRoot,
            leaf: consolidationWitness.consolidation.hashTreeRoot(),
            gI: _getPendingConsolidationGI(
                consolidationWitness.offset,
                consolidationBlock.header.slot
            )
        });

        SSZ.verifyProof({
            proof: withdrawableBlock.proof,
            root: recentBlock.header.stateRoot,
            leaf: withdrawableBlock.header.hashTreeRoot(),
            gI: _getHistoricalBlockRootGI(
                recentBlock.header.slot,
                withdrawableBlock.header.slot
            )
        });

        {
            bytes memory pubkey = MODULE.getSigningKeys(
                nodeOperatorId,
                keyIndex,
                1
            );

            Validator memory validator = Validator({
                pubkey: pubkey,
                withdrawalCredentials: validatorWitness.withdrawalCredentials,
                effectiveBalance: validatorWitness.effectiveBalance,
                slashed: false,
                activationEligibilityEpoch: validatorWitness
                    .activationEligibilityEpoch,
                activationEpoch: validatorWitness.activationEpoch,
                exitEpoch: validatorWitness.exitEpoch,
                withdrawableEpoch: validatorWitness.withdrawableEpoch
            });

            SSZ.verifyProof({
                proof: validatorWitness.proof,
                root: withdrawableBlock.header.stateRoot,
                leaf: validator.hashTreeRoot(),
                gI: _getValidatorGI(
                    validatorWitness.index, // don't like it in the ValidatorWitness
                    withdrawableBlock.header.slot
                )
            });
        }

        if (
            consolidationWitness.consolidation.sourceIndex !=
            validatorWitness.index
        ) {
            revert InvalidConsolidationSource();
        }

        if (
            _computeEpochAtSlot(withdrawableBlock.header.slot) <
            validatorWitness.withdrawableEpoch
        ) {
            revert ValidatorNotWithdrawn(); // change to ValidatorNotWithdrawable?
        }

        uint256 balance = _verifyValidatorBalance({
            validatorIndex: validatorWitness.index,
            balanceNode: balanceWitness.node,
            stateRoot: consolidationBlock.header.stateRoot,
            stateSlot: consolidationBlock.header.slot,
            proof: balanceWitness.proof
        });

        ValidatorWithdrawalInfo[]
            memory withdrawalsInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalsInfo[0] = ValidatorWithdrawalInfo(
            nodeOperatorId,
            keyIndex,
            balance,
            0
        );
        MODULE.submitWithdrawals(withdrawalsInfo);
    }

    function _getParentBlockRoot(
        uint64 blockTimestamp
    ) internal view returns (bytes32) {
        (bool success, bytes memory data) = BEACON_ROOTS.staticcall(
            abi.encode(blockTimestamp)
        );

        if (!success || data.length == 0) {
            revert RootNotFound();
        }

        return abi.decode(data, (bytes32));
    }

    /// @dev `stateRoot` is supposed to be trusted at this point.
    function _processWithdrawalProof(
        WithdrawalWitness calldata witness,
        Slot stateSlot,
        bytes32 stateRoot,
        bytes memory pubkey
    ) internal view returns (uint256 withdrawalAmount) {
        if (witness.slashed) {
            revert ValidatorIsSlashed();
        }

        // WC to address
        address withdrawalAddress = address(
            uint160(uint256(witness.withdrawalCredentials))
        );
        if (withdrawalAddress != WITHDRAWAL_ADDRESS) {
            revert InvalidWithdrawalAddress();
        }

        if (_computeEpochAtSlot(stateSlot) < witness.withdrawableEpoch) {
            revert ValidatorNotWithdrawn();
        }

        // See https://hackmd.io/1wM8vqeNTjqt4pC3XoCUKQ
        //
        // ISSUE:
        // There is a possible way to bypass this check:
        // - wait for full withdrawal & sweep
        // - be lucky enough that no one provides proof for this withdrawal for at least 1 sweep cycle
        //  (~8 days with the network of 1M active validators)
        // - deposit 15 ETH for non-slashed validator
        // - wait for a sweep of this deposit
        // - provide proof of the last withdrawal
        // As a result, the Node Operator's bond will be penalized for 32 ETH - additional deposit value
        // However, all ETH involved,
        // including 15 ETH deposited by the attacker will remain in the Lido on Ethereum protocol
        // Hence, the only consequence of the attack is an inconsistency in the bond accounting that can be resolved
        // through the bond deposit approved by the corresponding DAO decision
        //
        // Resolution:
        // Given no losses for the protocol,
        // significant cost of attack (15 ETH),
        // and lack of feasible ways to mitigate it in the smart contract's code,
        // it is proposed to acknowledge possibility of the attack
        // and be ready to propose a corresponding vote to the DAO if it will ever happen
        if (gweiToWei(witness.amount) < 15 ether) {
            revert PartialWithdrawal();
        }

        Validator memory validator = Validator({
            pubkey: pubkey,
            withdrawalCredentials: witness.withdrawalCredentials,
            effectiveBalance: witness.effectiveBalance,
            slashed: false,
            activationEligibilityEpoch: witness.activationEligibilityEpoch,
            activationEpoch: witness.activationEpoch,
            exitEpoch: witness.exitEpoch,
            withdrawableEpoch: witness.withdrawableEpoch
        });

        SSZ.verifyProof({
            proof: witness.validatorProof,
            root: stateRoot,
            leaf: validator.hashTreeRoot(),
            gI: _getValidatorGI(witness.validatorIndex, stateSlot)
        });

        Withdrawal memory withdrawal = Withdrawal({
            index: witness.withdrawalIndex,
            validatorIndex: witness.validatorIndex,
            withdrawalAddress: withdrawalAddress,
            amount: witness.amount
        });

        SSZ.verifyProof({
            proof: witness.withdrawalProof,
            root: stateRoot,
            leaf: withdrawal.hashTreeRoot(),
            gI: _getWithdrawalGI(witness.withdrawalOffset, stateSlot)
        });

        return withdrawal.amountWei();
    }

    function _verifyValidatorBalance(
        uint256 validatorIndex,
        bytes32 balanceNode,
        bytes32 stateRoot,
        Slot stateSlot,
        bytes32[] calldata proof
    ) internal view returns (uint256 balance) {
        (
            uint256 balancesOffset,
            uint256 nodeOffset
        ) = _getValidatorBalanceNodeInfo(validatorIndex);

        SSZ.verifyProof({
            proof: proof,
            root: stateRoot,
            leaf: balanceNode,
            gI: _getValidatorBalanceGI(balancesOffset, stateSlot)
        });

        balance = uint64(uint256(balanceNode >> nodeOffset));
    }

    function _getValidatorGI(
        uint256 offset,
        Slot stateSlot
    ) internal view returns (GIndex) {
        GIndex gI = stateSlot < PIVOT_SLOT
            ? GI_FIRST_VALIDATOR_PREV
            : GI_FIRST_VALIDATOR_CURR;
        return gI.shr(offset);
    }

    function _getWithdrawalGI(
        uint256 offset,
        Slot stateSlot
    ) internal view returns (GIndex) {
        GIndex gI = stateSlot < PIVOT_SLOT
            ? GI_FIRST_WITHDRAWAL_PREV
            : GI_FIRST_WITHDRAWAL_CURR;
        return gI.shr(offset);
    }

    function _getValidatorBalanceGI(
        uint256 offset,
        Slot stateSlot
    ) internal view returns (GIndex) {
        GIndex gI = stateSlot < PIVOT_SLOT
            ? GI_FIRST_WITHDRAWAL_PREV
            : GI_FIRST_WITHDRAWAL_CURR;
        return gI.shr(offset);
    }

    function _getValidatorBalanceNodeInfo(
        uint256 validatorIndex
    ) internal view returns (uint256 balancesOffset, uint256 nodeOffset) {
        // `BeaconState.balances` is a list of uint64 values, SSZ packs 4 values into a single 32-byte node. Hence,
        // balances[0-3] will share same generalized index.
        balancesOffset = validatorIndex / 4;
        nodeOffset = validatorIndex % 4;
    }

    function _getPendingConsolidationGI(
        uint256 offset,
        Slot stateSlot
    ) internal view returns (GIndex) {
        GIndex gI = stateSlot < PIVOT_SLOT
            ? GI_FIRST_PENDING_CONSOLIDATION_PREV
            : GI_FIRST_PENDING_CONSOLIDATION_CURR;
        return gI.shr(offset);
    }

    function _getHistoricalBlockRootGI(
        Slot recentSlot,
        Slot targetSlot
    ) internal view returns (GIndex gI) {
        uint64 targetSlotShifted = targetSlot.unwrap() - CAPELLA_SLOT.unwrap();
        uint64 summaryIndex = targetSlotShifted / SLOTS_PER_HISTORICAL_ROOT;
        uint64 rootIndex = targetSlot.unwrap() % SLOTS_PER_HISTORICAL_ROOT;

        Slot summaryCreatedAtSlot = Slot.wrap(
            targetSlot.unwrap() - rootIndex + SLOTS_PER_HISTORICAL_ROOT
        );
        if (summaryCreatedAtSlot > recentSlot) {
            revert HistoricalSummaryDoesNotExist();
        }

        gI = recentSlot < PIVOT_SLOT
            ? GI_FIRST_HISTORICAL_SUMMARY_PREV
            : GI_FIRST_HISTORICAL_SUMMARY_CURR;

        gI = gI.shr(summaryIndex); // historicalSummaries[summaryIndex]
        gI = gI.concat(
            summaryCreatedAtSlot < PIVOT_SLOT
                ? GI_FIRST_BLOCK_ROOT_IN_SUMMARY_PREV
                : GI_FIRST_BLOCK_ROOT_IN_SUMMARY_CURR
        ); // historicalSummaries[summaryIndex].blockRoots[0]
        gI = gI.shr(rootIndex); // historicalSummaries[summaryIndex].blockRoots[rootIndex]
    }

    // From HashConsensus contract.
    function _computeEpochAtSlot(Slot slot) internal view returns (uint256) {
        // See: github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#compute_epoch_at_slot
        return slot.unwrap() / SLOTS_PER_EPOCH;
    }
}
