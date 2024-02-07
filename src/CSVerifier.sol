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

contract CSVerifier is ICSVerifier {
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
        WithdrawalProofContext calldata ctx,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.rootsTimestamp
            );
            bytes32 headerRoot = beaconBlock.blockHeader.hashTreeRoot();
            if (trustedHeaderRoot != headerRoot) {
                revert InvalidBlockHeader();
            }
        }

        ForkVersion fork = forkSelector.findFork(
            Slot.wrap(beaconBlock.blockHeader.slot)
        );

        bytes memory pubkey = module.getNodeOperatorSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        Withdrawal memory withdrawal = _processWithdrawalProof(
            ctx,
            beaconBlock.blockHeader.stateRoot,
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
        ProvableHistoricalBlockHeader calldata beaconBlock,
        WithdrawalProofContext calldata ctx,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external {
        {
            bytes32 trustedHeaderRoot = _getParentBlockRoot(
                beaconBlock.anchorBlock.rootsTimestamp
            );
            bytes32 headerRoot = beaconBlock
                .anchorBlock
                .blockHeader
                .hashTreeRoot();
            if (trustedHeaderRoot != headerRoot) {
                revert InvalidBlockHeader();
            }
        }

        {
            // Check the validity of the historical block root against the anchor block header (accessible from EIP-4788).
            bytes32 anchorStateRoot = beaconBlock
                .anchorBlock
                .blockHeader
                .stateRoot;
            ForkVersion anchorFork = forkSelector.findFork(
                Slot.wrap(beaconBlock.anchorBlock.blockHeader.slot)
            );
            // solhint-disable-next-line func-named-parameters
            _verifyBlockRootProof(
                anchorFork,
                anchorStateRoot,
                beaconBlock.historicalBlock.hashTreeRoot(),
                beaconBlock.blockRootGIndex,
                beaconBlock.blockRootProof
            );
        }

        // Fork may get a new value depends on the historical state root.
        bytes32 stateRoot = beaconBlock.historicalBlock.stateRoot;
        ForkVersion fork = forkSelector.findFork(
            Slot.wrap(beaconBlock.historicalBlock.slot)
        );

        bytes memory pubkey = module.getNodeOperatorSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );

        Withdrawal memory withdrawal = _processWithdrawalProof(
            ctx,
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

    // @dev `stateRoot` is already validated.
    function _processWithdrawalProof(
        WithdrawalProofContext calldata ctx,
        bytes32 stateRoot,
        ForkVersion fork,
        bytes memory pubkey
    ) internal view returns (Withdrawal memory withdrawal) {
        address withdrawalAddress = _wcToAddress(ctx.withdrawalCredentials);
        if (withdrawalAddress != locator.withdrawalVault()) {
            revert InvalidWithdrawalAddress();
        }

        if (_getEpoch() < ctx.withdrawableEpoch) {
            revert ValidatorNotWithdrawn();
        }

        Validator memory validator = Validator({
            pubkey: pubkey,
            withdrawalCredentials: ctx.withdrawalCredentials,
            effectiveBalance: ctx.effectiveBalance, // TODO: Should we accept zero effective balance only?
            slashed: ctx.slashed,
            activationEligibilityEpoch: ctx.activationEligibilityEpoch,
            activationEpoch: ctx.activationEpoch,
            exitEpoch: ctx.exitEpoch,
            withdrawableEpoch: ctx.withdrawableEpoch
        });

        SSZ.verifyProof(
            ctx.validatorProof,
            stateRoot,
            validator.hashTreeRoot(),
            _getValidatorGI(fork, ctx.validatorIndex)
        );

        withdrawal = Withdrawal({
            index: ctx.withdrawalIndex,
            validatorIndex: ctx.validatorIndex,
            withdrawalAddress: withdrawalAddress,
            amount: ctx.amount
        });

        SSZ.verifyProof(
            ctx.withdrawalProof,
            stateRoot,
            withdrawal.hashTreeRoot(),
            _getWithdrawalGI(fork, ctx.withdrawalOffset)
        );
    }

    function _getEpoch() internal view returns (uint256) {
        return _computeEpochAtTimestamp(_getTime());
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

    // ┌─────────────────────────────────────────────────────────┐
    // │ Methods below were copied from HashConsensus contract.  │
    // └─────────────────────────────────────────────────────────┘

    function _computeSlotAtTimestamp(
        uint256 timestamp
    ) internal view returns (Slot) {
        return Slot.wrap(uint64((timestamp - GENESIS_TIME) / SECONDS_PER_SLOT));
    }

    function _computeEpochAtSlot(Slot slot) internal view returns (uint256) {
        // See: github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#compute_epoch_at_slot
        return Slot.unwrap(slot) / SLOTS_PER_EPOCH;
    }

    function _computeEpochAtTimestamp(
        uint256 timestamp
    ) internal view returns (uint256) {
        return _computeEpochAtSlot(_computeSlotAtTimestamp(timestamp));
    }

    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }
}

function amountWei(Withdrawal memory withdrawal) pure returns (uint256) {
    return uint256(withdrawal.amount) * 1 gwei;
}

using { amountWei } for Withdrawal;
