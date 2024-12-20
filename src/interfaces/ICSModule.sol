// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { IStakingModule } from "./IStakingModule.sol";
import { ICSAccounting } from "./ICSAccounting.sol";
import { IQueueLib } from "../lib/QueueLib.sol";
import { INOAddresses } from "../lib/NOAddresses.sol";
import { IAssetRecovererLib } from "../lib/AssetRecovererLib.sol";
import { Batch } from "../lib/QueueLib.sol";
import { ILidoLocator } from "./ILidoLocator.sol";
import { ICSEarlyAdoption } from "./ICSEarlyAdoption.sol";
import { IStETH } from "./IStETH.sol";

struct NodeOperator {
    // All the counters below are used together e.g. in the _updateDepositableValidatorsCount
    /* 1 */ uint32 totalAddedKeys; // @dev increased and decreased when removed
    /* 1 */ uint32 totalWithdrawnKeys; // @dev only increased
    /* 1 */ uint32 totalDepositedKeys; // @dev only increased
    /* 1 */ uint32 totalVettedKeys; // @dev both increased and decreased
    /* 1 */ uint32 stuckValidatorsCount; // @dev both increased and decreased
    /* 1 */ uint32 depositableValidatorsCount; // @dev any value
    /* 1 */ uint32 targetLimit;
    /* 1 */ uint8 targetLimitMode;
    /* 2 */ uint32 totalExitedKeys; // @dev only increased except for the unsafe updates
    /* 2 */ uint32 enqueuedCount; // Tracks how many places are occupied by the node operator's keys in the queue.
    /* 2 */ address managerAddress;
    /* 3 */ address proposedManagerAddress;
    /* 4 */ address rewardAddress;
    /* 5 */ address proposedRewardAddress;
    /* 5 */ bool extendedManagerPermissions;
}

struct NodeOperatorManagementProperties {
    address managerAddress;
    address rewardAddress;
    bool extendedManagerPermissions;
}

/// @title Lido's Community Staking Module interface
interface ICSModule is IQueueLib, INOAddresses, IAssetRecovererLib {
    error NodeOperatorDoesNotExist();
    error SenderIsNotEligible();
    error InvalidVetKeysPointer();
    error StuckKeysHigherThanNonExited();
    error ExitedKeysHigherThanTotalDeposited();
    error ExitedKeysDecrease();

    error InvalidInput();
    error NotEnoughKeys();

    error SigningKeysInvalidOffset();

    error AlreadySubmitted();

    error AlreadyActivated();
    error InvalidAmount();
    error NotAllowedToJoinYet();
    error MaxSigningKeysCountExceeded();

    error NotSupported();
    error ZeroLocatorAddress();
    error ZeroAccountingAddress();
    error ZeroAdminAddress();
    error ZeroRewardAddress();

    event NodeOperatorAdded(
        uint256 indexed nodeOperatorId,
        address indexed managerAddress,
        address indexed rewardAddress
    );
    event ReferrerSet(uint256 indexed nodeOperatorId, address indexed referrer);
    event DepositableSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositableKeysCount
    );
    event VettedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 vettedKeysCount
    );
    event VettedSigningKeysCountDecreased(uint256 indexed nodeOperatorId);
    event DepositedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositedKeysCount
    );
    event ExitedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 exitedKeysCount
    );
    event StuckSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 stuckKeysCount
    );
    event TotalSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 totalKeysCount
    );
    event TargetValidatorsCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 targetLimitMode,
        uint256 targetValidatorsCount
    );
    event WithdrawalSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex,
        uint256 amount,
        bytes pubkey
    );
    event InitialSlashingSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex,
        bytes pubkey
    );

    event PublicRelease();
    event KeyRemovalChargeSet(uint256 amount);

    event KeyRemovalChargeApplied(uint256 indexed nodeOperatorId);
    event ELRewardsStealingPenaltyReported(
        uint256 indexed nodeOperatorId,
        bytes32 proposedBlockHash,
        uint256 stolenAmount
    );
    event ELRewardsStealingPenaltyCancelled(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );
    event ELRewardsStealingPenaltyCompensated(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );
    event ELRewardsStealingPenaltySettled(uint256 indexed nodeOperatorId);

    function EL_REWARDS_STEALING_ADDITIONAL_FINE()
        external
        view
        returns (uint256);

    function INITIAL_SLASHING_PENALTY() external view returns (uint256);

    function LIDO_LOCATOR() external view returns (ILidoLocator);

    function MAX_KEY_REMOVAL_CHARGE() external view returns (uint256);

    function MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE()
        external
        view
        returns (uint256);

    function PAUSE_ROLE() external view returns (bytes32);

    function RECOVERER_ROLE() external view returns (bytes32);

    function REPORT_EL_REWARDS_STEALING_PENALTY_ROLE()
        external
        view
        returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE()
        external
        view
        returns (bytes32);

    function STAKING_ROUTER_ROLE() external view returns (bytes32);

    function STETH() external view returns (IStETH);

    function VERIFIER_ROLE() external view returns (bytes32);

    /// @notice Returns the address of the accounting contract
    function accounting() external view returns (ICSAccounting);

    /// @notice Returns the early adoption contract address
    function earlyAdoption() external view returns (ICSEarlyAdoption);

    /// @notice Pause creation of the Node Operators and keys upload for `duration` seconds.
    ///         Existing NO management and reward claims are still available.
    ///         To pause reward claims use pause method on CSAccounting
    /// @param duration Duration of the pause in seconds
    function pauseFor(uint256 duration) external;

    /// @notice Resume creation of the Node Operators and keys upload
    function resume() external;

    /// @notice Public release mode status
    function publicRelease() external view returns (bool);

    /// @notice Activate public release mode
    ///         Enable permissionless creation of the Node Operators
    ///         Remove the keys limit for the Node Operators
    function activatePublicRelease() external;

    /// @notice Add a new Node Operator using ETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        bytes32[] memory eaProof,
        address referrer
    ) external payable;

    /// @notice Add a new Node Operator using stETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param permit Optional. Permit to use stETH as bond
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        ICSAccounting.PermitInput memory permit,
        bytes32[] memory eaProof,
        address referrer
    ) external;

    /// @notice Add a new Node Operator using wstETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param permit Optional. Permit to use wstETH as bond
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        ICSAccounting.PermitInput memory permit,
        bytes32[] memory eaProof,
        address referrer
    ) external;

    /// @notice Add new keys to the existing Node Operator using ETH as a bond
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    function addValidatorKeysETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures
    ) external payable;

    /// @notice Add new keys to the existing Node Operator using stETH as a bond
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param permit Optional. Permit to use stETH as bond
    function addValidatorKeysStETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        ICSAccounting.PermitInput memory permit
    ) external;

    /// @notice Add new keys to the existing Node Operator using wstETH as a bond
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param permit Optional. Permit to use wstETH as bond
    function addValidatorKeysWstETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        ICSAccounting.PermitInput memory permit
    ) external;

    /// @notice Stake user's ETH with Lido and make a deposit in stETH to the bond of the existing Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    function depositETH(uint256 nodeOperatorId) external payable;

    /// @notice Deposit user's stETH to the bond of the existing Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stETHAmount Amount of stETH to deposit
    /// @param permit Optional. Permit to use stETH as bond
    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        ICSAccounting.PermitInput memory permit
    ) external;

    /// @notice Unwrap the user's wstETH and make a deposit in stETH to the bond of the existing Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param wstETHAmount Amount of wstETH to deposit
    /// @param permit Optional. Permit to use wstETH as bond
    function depositWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        ICSAccounting.PermitInput memory permit
    ) external;

    /// @notice Claim full reward (fees + bond rewards) in stETH for the given Node Operator
    /// @notice If `stETHAmount` exceeds the current claimable amount, the claimable amount will be used instead
    /// @notice If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stETHAmount Amount of stETH to claim
    /// @param cumulativeFeeShares Optional. Cumulative fee stETH shares for the Node Operator
    /// @param rewardsProof Optional. Merkle proof of the rewards
    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    /// @notice Request full reward (fees + bond rewards) in Withdrawal NFT (unstETH) for the given Node Operator
    /// @notice Amounts less than `MIN_STETH_WITHDRAWAL_AMOUNT` (see LidoWithdrawalQueue contract) are not allowed
    /// @notice Amounts above `MAX_STETH_WITHDRAWAL_AMOUNT` should be requested in several transactions
    /// @notice If `ethAmount` exceeds the current claimable amount, the claimable amount will be used instead
    /// @notice If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim
    /// @dev Reverts if amount isn't between `MIN_STETH_WITHDRAWAL_AMOUNT` and `MAX_STETH_WITHDRAWAL_AMOUNT`
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stEthAmount Amount of ETH to request
    /// @param cumulativeFeeShares Optional. Cumulative fee stETH shares for the Node Operator
    /// @param rewardsProof Optional. Merkle proof of the rewards
    function claimRewardsUnstETH(
        uint256 nodeOperatorId,
        uint256 stEthAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    /// @notice Claim full reward (fees + bond rewards) in wstETH for the given Node Operator
    /// @notice If `wstETHAmount` exceeds the current claimable amount, the claimable amount will be used instead
    /// @notice If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim
    /// @param nodeOperatorId ID of the Node Operator
    /// @param wstETHAmount Amount of wstETH to claim
    /// @param cumulativeFeeShares Optional. Cumulative fee stETH shares for the Node Operator
    /// @param rewardsProof Optional. Merkle proof of the rewards
    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    /// @notice Report EL rewards stealing for the given Node Operator
    /// @notice The final locked amount will be equal to the stolen funds plus EL stealing additional fine
    /// @param nodeOperatorId ID of the Node Operator
    /// @param blockHash Execution layer block hash of the proposed block with EL rewards stealing
    /// @param amount Amount of stolen EL rewards in ETH
    function reportELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        bytes32 blockHash,
        uint256 amount
    ) external;

    /// @notice Compensate EL rewards stealing penalty for the given Node Operator to prevent further validator exits
    /// @dev Can only be called by the Node Operator manager
    /// @param nodeOperatorId ID of the Node Operator
    function compensateELRewardsStealingPenalty(
        uint256 nodeOperatorId
    ) external payable;

    /// @notice Cancel previously reported and not settled EL rewards stealing penalty for the given Node Operator
    /// @notice The funds will be unlocked
    /// @param nodeOperatorId ID of the Node Operator
    /// @param amount Amount of penalty to cancel
    function cancelELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 amount
    ) external;

    /// @notice Settle locked bond for the given Node Operators
    /// @dev SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE role is expected to be assigned to Easy Track
    /// @param nodeOperatorIds IDs of the Node Operators
    function settleELRewardsStealingPenalty(
        uint256[] memory nodeOperatorIds
    ) external;

    /// @notice Propose a new manager address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external;

    /// @notice Confirm a new manager address for the Node Operator.
    ///         Should be called from the currently proposed address
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external;

    /// @notice Reset the manager address to the reward address.
    ///         Should be called from the reward address
    /// @param nodeOperatorId ID of the Node Operator
    function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external;

    /// @notice Propose a new reward address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed reward address
    function proposeNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external;

    /// @notice Confirm a new reward address for the Node Operator.
    ///         Should be called from the currently proposed address
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external;

    /// @notice Change rewardAddress if extendedManagerPermissions is enabled for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param newAddress Proposed reward address
    function changeNodeOperatorRewardAddress(
        uint256 nodeOperatorId,
        address newAddress
    ) external;

    /// @notice Returns the deposit queue head and tail
    function depositQueue() external view returns (uint128 head, uint128 tail);

    /// @notice Get the deposit queue item by an index
    /// @param index Index of a queue item
    /// @return Deposit queue item
    function depositQueueItem(uint128 index) external view returns (Batch);

    /// @notice Clean the deposit queue from batches with no depositable keys
    /// @dev Use **eth_call** to check how many items will be removed
    /// @param maxItems How many queue items to review
    /// @return removed Count of batches to be removed by visiting `maxItems` batches
    /// @return lastRemovedAtDepth The value to use as `maxItems` to remove `removed` batches if the static call of the method was used
    function cleanDepositQueue(
        uint256 maxItems
    ) external returns (uint256 removed, uint256 lastRemovedAtDepth);

    /// @notice Perform queue normalization for the given Node Operator
    /// @notice Normalization stands for adding vetted but not enqueued keys to the queue
    /// @param nodeOperatorId ID of the Node Operator
    function normalizeQueue(uint256 nodeOperatorId) external;

    /// @notice Get Node Operator info
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Node Operator info
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory);

    /// @notice Get Node Operator non-withdrawn keys
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Non-withdrawn keys count
    function getNodeOperatorNonWithdrawnKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    /// @notice Get Node Operator signing keys
    /// @param nodeOperatorId ID of the Node Operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return Signing keys
    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory);

    /// @notice Get Node Operator signing keys with signatures
    /// @param nodeOperatorId ID of the Node Operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return keys Signing keys
    /// @return signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                    https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    function getSigningKeysWithSignatures(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory keys, bytes memory signatures);

    /// @notice Report Node Operator's key as slashed and apply the initial slashing penalty
    /// @notice Called by the Verifier contract.
    ///         See `CSVerifier.processSlashingProof` to use this method permissionless
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the slashed key in the Node Operator's keys storage
    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    /// @notice Report Node Operator's key as withdrawn and settle withdrawn amount
    /// @notice Called by the Verifier contract.
    ///         See `CSVerifier.processWithdrawalProof` to use this method permissionless
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the withdrawn key in the Node Operator's keys storage
    /// @param amount Amount of withdrawn ETH in wei
    /// @param isSlashed Validator is slashed or not
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount,
        bool isSlashed
    ) external;

    /// @notice Check if the given Node Operator's key is reported as slashed
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the key to check
    /// @return Validator reported as slashed flag
    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool);

    /// @notice Check if the given Node Operator's key is reported as withdrawn
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex index of the key to check
    /// @return Validator reported as withdrawn flag
    function isValidatorWithdrawn(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool);

    /// @notice Remove keys for the Node Operator and confiscate removal charge for each deleted key
    /// @param nodeOperatorId ID of the Node Operator
    /// @param startIndex Index of the first key
    /// @param keysCount Keys count to delete
    function removeKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external;

    /// @notice Returns the key removal charge amount
    function keyRemovalCharge() external view returns (uint256);

    /// @notice Set the key removal charge amount.
    ///         A charge is taken from the bond for each removed key
    /// @param amount Amount of stETH in wei to be charged for removing a single key
    function setKeyRemovalCharge(uint256 amount) external;
}
