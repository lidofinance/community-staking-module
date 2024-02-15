// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IForkSelector } from "./interfaces/IForkSelector.sol";
import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ICSVerifier } from "./interfaces/ICSVerifier.sol";
import { IGIProvider } from "./interfaces/IGIProvider.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";

import { BeaconBlockHeader, ForkVersion, Slot, Validator, Withdrawal } from "./lib/Types.sol";
import { GIndex } from "./lib/GIndex.sol";
import { SSZ } from "./lib/SSZ.sol";

function amountWei(Withdrawal memory withdrawal) pure returns (uint256) {
    return gweiToWei(withdrawal.amount);
}

function gweiToWei(uint64 amount) pure returns (uint256) {
    return uint256(amount) * 1 gwei;
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
    uint64 public immutable SECONDS_PER_SLOT;
    uint64 public immutable GENESIS_TIME;

    IForkSelector public forkSelector;
    IGIProvider public gIprovider;
    ILidoLocator public locator;
    ICSModule public module;

    error RootNotFound();
    error InvalidOffset();
    error InvalidGIndex();
    error InvalidBlockHeader();
    error InvalidChainConfig();
    error ProofTypeNotSupported();
    error PartialWitdrawal();
    error ValidatorNotWithdrawn();
    error InvalidWithdrawalAddress();

    constructor(
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    ) {
        if (secondsPerSlot == 0) revert InvalidChainConfig();
        if (slotsPerEpoch == 0) revert InvalidChainConfig();

        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_EPOCH = slotsPerEpoch;
        GENESIS_TIME = genesisTime;
    }

    function initialize(
        address _forkSelector,
        address _gIprovider,
        address _locator,
        address _module
    ) external {
        module = ICSModule(_module);
        locator = ILidoLocator(_locator);
        gIprovider = IGIProvider(_gIprovider);
        forkSelector = IForkSelector(_forkSelector);
    }

    function processWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.rootsTimestamp
            );
            bytes32 headerRoot = beaconBlock.header.hashTreeRoot();
            if (trustedHeaderRoot != headerRoot) {
                revert InvalidBlockHeader();
            }
        }

        ForkVersion fork = forkSelector.findFork(
            Slot.wrap(beaconBlock.header.slot)
        );

        bytes memory pubkey = module.getNodeOperatorSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        // solhint-disable-next-line func-named-parameters
        Withdrawal memory withdrawal = _processWithdrawalProof(
            witness,
            _computeEpochAtSlot(beaconBlock.header.slot),
            beaconBlock.header.stateRoot,
            fork,
            pubkey
        );

        module.submitWithdrawal(
            nodeOperatorId,
            keyIndex,
            withdrawal.amountWei()
        );
    }

    function processHistoricalWithdrawalProof(
        ProvableBeaconBlockHeader calldata beaconBlock,
        HistoricalHeaderWitness calldata oldBlock,
        WithdrawalWitness calldata witness,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.rootsTimestamp
            );
            bytes32 headerRoot = beaconBlock.header.hashTreeRoot();
            if (trustedHeaderRoot != headerRoot) {
                revert InvalidBlockHeader();
            }
        }

        {
            // Check the validity of the historical block root against the anchor block header (accessible from EIP-4788).
            bytes32 anchorStateRoot = beaconBlock.header.stateRoot;
            ForkVersion anchorFork = forkSelector.findFork(
                Slot.wrap(beaconBlock.header.slot)
            );
            // solhint-disable-next-line func-named-parameters
            _verifyBlockRootProof(
                anchorFork,
                anchorStateRoot,
                oldBlock.header.hashTreeRoot(),
                oldBlock.rootGIndex,
                oldBlock.proof
            );
        }

        // Fork may get a new value depending on the historical state root.
        bytes32 stateRoot = oldBlock.header.stateRoot;
        ForkVersion fork = forkSelector.findFork(
            Slot.wrap(oldBlock.header.slot)
        );

        bytes memory pubkey = module.getNodeOperatorSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        // solhint-disable-next-line func-named-parameters
        Withdrawal memory withdrawal = _processWithdrawalProof(
            witness,
            _computeEpochAtSlot(oldBlock.header.slot),
            stateRoot,
            fork,
            pubkey
        );

        module.submitWithdrawal(
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

    /// @dev It's up to a user to provide a valid generalized index of a historical block root in a summaries list.
    function _verifyBlockRootProof(
        ForkVersion fork,
        bytes32 stateRoot,
        bytes32 historicalBlockRoot,
        GIndex historicalBlockRootGIndex,
        bytes32[] calldata blockRootProof
    ) internal view {
        GIndex anchor = gIprovider.getIndex(
            fork,
            "BeaconState.historical_summaries"
        );

        // Ensuring the provided generalized index is for a node somewhere below the historical_summaries root.
        if (!anchor.isParentOf(historicalBlockRootGIndex)) {
            revert InvalidGIndex();
        }

        SSZ.verifyProof(
            blockRootProof,
            stateRoot,
            historicalBlockRoot,
            historicalBlockRootGIndex
        );
    }

    // @dev `stateRoot` is supposed to be trusted at this point.
    function _processWithdrawalProof(
        WithdrawalWitness calldata witness,
        uint256 stateEpoch,
        bytes32 stateRoot,
        ForkVersion fork,
        bytes memory pubkey
    ) internal view returns (Withdrawal memory withdrawal) {
        address withdrawalAddress = _wcToAddress(witness.withdrawalCredentials);
        if (withdrawalAddress != locator.withdrawalVault()) {
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

        SSZ.verifyProof(
            witness.validatorProof,
            stateRoot,
            validator.hashTreeRoot(),
            _getValidatorGI(fork, witness.validatorIndex)
        );

        withdrawal = Withdrawal({
            index: witness.withdrawalIndex,
            validatorIndex: witness.validatorIndex,
            withdrawalAddress: withdrawalAddress,
            amount: witness.amount
        });

        SSZ.verifyProof(
            witness.withdrawalProof,
            stateRoot,
            withdrawal.hashTreeRoot(),
            _getWithdrawalGI(fork, witness.withdrawalOffset)
        );
    }

    function _wcToAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function _getValidatorGI(
        ForkVersion fork,
        uint256 offset
    ) internal view returns (GIndex) {
        GIndex gI = gIprovider.getIndex(fork, "BeaconState.validators[0]");
        return gI.shr(offset);
    }

    function _getWithdrawalGI(
        ForkVersion fork,
        uint256 offset
    ) internal view returns (GIndex) {
        GIndex gI = gIprovider.getIndex(fork, "BeaconState.withdrawals[0]");
        if (offset == 0) return gI;
        return gI.shr(offset);
    }

    // From HashConsensus contract.
    function _computeEpochAtSlot(uint256 slot) internal view returns (uint256) {
        // See: github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#compute_epoch_at_slot
        return slot / SLOTS_PER_EPOCH;
    }
}
