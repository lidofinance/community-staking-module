// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSModule {
    type Batch is uint256;

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
        /* 2 */ uint32 totalExitedKeys; // @dev only increased
        /* 2 */ uint32 enqueuedCount; // Tracks how many places are occupied by the node operator's keys in the queue.
        /* 2 */ address managerAddress;
        /* 3 */ address proposedManagerAddress;
        /* 4 */ address rewardAddress;
        /* 5 */ address proposedRewardAddress;
    }

    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error AlreadyActivated();
    error AlreadyProposed();
    error AlreadySubmitted();
    error AlreadyWithdrawn();
    error EmptyKey();
    error ExitedKeysDecrease();
    error ExitedKeysHigherThanTotalDeposited();
    error FailedInnerCall();
    error FailedToSendEther();
    error InvalidAmount();
    error InvalidInitialization();
    error InvalidInput();
    error InvalidKeysCount();
    error InvalidLength();
    error InvalidReportData();
    error InvalidVetKeysPointer();
    error MaxSigningKeysCountExceeded();
    error NodeOperatorDoesNotExist();
    error NotAllowedToJoinYet();
    error NotAllowedToRecover();
    error NotEnoughKeys();
    error NotInitializing();
    error NotSupported();
    error PauseUntilMustBeInFuture();
    error PausedExpected();
    error QueueIsEmpty();
    error QueueLookupNoLimit();
    error ResumedExpected();
    error SafeERC20FailedOperation(address token);
    error SameAddress();
    error SenderIsNotEligible();
    error SenderIsNotManagerAddress();
    error SenderIsNotProposedAddress();
    error SenderIsNotRewardAddress();
    error SigningKeysInvalidOffset();
    error StuckKeysHigherThanNonExited();
    error ZeroAccountingAddress();
    error ZeroAdminAddress();
    error ZeroLocatorAddress();
    error ZeroPauseDuration();

    event BatchEnqueued(uint256 indexed nodeOperatorId, uint256 count);
    event DepositableSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositableKeysCount
    );
    event DepositedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositedKeysCount
    );
    event ELRewardsStealingPenaltyCancelled(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );
    event ELRewardsStealingPenaltyReported(
        uint256 indexed nodeOperatorId,
        bytes32 proposedBlockHash,
        uint256 stolenAmount
    );
    event ELRewardsStealingPenaltySettled(uint256 indexed nodeOperatorId);
    event ERC1155Recovered(
        address indexed token,
        uint256 tokenId,
        address indexed recipient,
        uint256 amount
    );
    event ERC20Recovered(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event ERC721Recovered(
        address indexed token,
        uint256 tokenId,
        address indexed recipient
    );
    event EtherRecovered(address indexed recipient, uint256 amount);
    event ExitedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 exitedKeysCount
    );
    event InitialSlashingSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex
    );
    event Initialized(uint64 version);
    event KeyRemovalChargeApplied(uint256 indexed nodeOperatorId);
    event KeyRemovalChargeSet(uint256 amount);
    event NodeOperatorAdded(
        uint256 indexed nodeOperatorId,
        address indexed managerAddress,
        address indexed rewardAddress
    );
    event NodeOperatorManagerAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address indexed oldProposedAddress,
        address indexed newProposedAddress
    );
    event NodeOperatorManagerAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed oldAddress,
        address indexed newAddress
    );
    event NodeOperatorRewardAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address indexed oldProposedAddress,
        address indexed newProposedAddress
    );
    event NodeOperatorRewardAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed oldAddress,
        address indexed newAddress
    );
    event NonceChanged(uint256 nonce);
    event Paused(uint256 duration);
    event PublicRelease();
    event ReferrerSet(uint256 indexed nodeOperatorId, address indexed referrer);
    event Resumed();
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event SigningKeyAdded(uint256 indexed nodeOperatorId, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);
    event StETHSharesRecovered(address indexed recipient, uint256 shares);
    event StuckSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 stuckKeysCount
    );
    event TargetValidatorsCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 targetLimitMode,
        uint256 targetValidatorsCount
    );
    event TotalSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 totalKeysCount
    );
    event VettedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 vettedKeysCount
    );
    event WithdrawalSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    );

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function EL_REWARDS_STEALING_FINE() external view returns (uint256);

    function INITIAL_SLASHING_PENALTY() external view returns (uint256);

    function LIDO_LOCATOR() external view returns (address);

    function MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE()
        external
        view
        returns (uint256);

    function MODULE_MANAGER_ROLE() external view returns (bytes32);

    function PAUSE_INFINITELY() external view returns (uint256);

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

    function STETH() external view returns (address);

    function VERIFIER_ROLE() external view returns (bytes32);

    function accounting() external view returns (address);

    function activatePublicRelease() external;

    function addNodeOperatorETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        address managerAddress,
        address rewardAddress,
        bytes32[] memory eaProof,
        address referrer
    ) external payable;

    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        address managerAddress,
        address rewardAddress,
        PermitInput memory permit,
        bytes32[] memory eaProof,
        address referrer
    ) external;

    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        address managerAddress,
        address rewardAddress,
        PermitInput memory permit,
        bytes32[] memory eaProof,
        address referrer
    ) external;

    function addValidatorKeysETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures
    ) external payable;

    function addValidatorKeysStETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        PermitInput memory permit
    ) external;

    function addValidatorKeysWstETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        PermitInput memory permit
    ) external;

    function cancelELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 amount
    ) external;

    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function claimRewardsUnstETH(
        uint256 nodeOperatorId,
        uint256 stEthAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function cleanDepositQueue(uint256 maxItems) external returns (uint256);

    function compensateELRewardsStealingPenalty(
        uint256 nodeOperatorId
    ) external payable;

    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external;

    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external;

    function decreaseVettedSigningKeysCount(
        bytes memory nodeOperatorIds,
        bytes memory vettedSigningKeysCounts
    ) external;

    function depositETH(uint256 nodeOperatorId) external payable;

    function depositQueue() external view returns (uint128 head, uint128 tail);

    function depositQueueItem(uint128 index) external view returns (Batch);

    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput memory permit
    ) external;

    function depositWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput memory permit
    ) external;

    function earlyAdoption() external view returns (address);

    function getActiveNodeOperatorsCount() external view returns (uint256);

    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory);

    function getNodeOperatorIds(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory nodeOperatorIds);

    function getNodeOperatorIsActive(
        uint256 nodeOperatorId
    ) external view returns (bool);

    function getNodeOperatorNonWithdrawnKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getNodeOperatorSummary(
        uint256 nodeOperatorId
    )
        external
        view
        returns (
            uint256 targetLimitMode,
            uint256 targetValidatorsCount,
            uint256 stuckValidatorsCount,
            uint256 refundedValidatorsCount,
            uint256 stuckPenaltyEndTimestamp,
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        );

    function getNodeOperatorsCount() external view returns (uint256);

    function getNonce() external view returns (uint256);

    function getResumeSinceTimestamp() external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory);

    function getSigningKeysWithSignatures(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory keys, bytes memory signatures);

    function getStakingModuleSummary()
        external
        view
        returns (
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        );

    function getType() external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function initialize(
        address _accounting,
        address _earlyAdoption,
        uint256 _keyRemovalCharge,
        address admin
    ) external;

    function isPaused() external view returns (bool);

    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool);

    function isValidatorWithdrawn(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool);

    function keyRemovalCharge() external view returns (uint256);

    function normalizeQueue(uint256 nodeOperatorId) external;

    function obtainDepositData(
        uint256 depositsCount,
        bytes memory
    ) external returns (bytes memory publicKeys, bytes memory signatures);

    function onExitedAndStuckValidatorsCountsUpdated() external;

    function onRewardsMinted(uint256 totalShares) external;

    function onWithdrawalCredentialsChanged() external;

    function pauseFor(uint256 duration) external;

    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external;

    function proposeNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external;

    function publicRelease() external view returns (bool);

    function recoverERC1155(address token, uint256 tokenId) external;

    function recoverERC20(address token, uint256 amount) external;

    function recoverERC721(address token, uint256 tokenId) external;

    function recoverEther() external;

    function recoverStETHShares() external;

    function removeKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function reportELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        bytes32 blockHash,
        uint256 amount
    ) external;

    function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external;

    function resume() external;

    function revokeRole(bytes32 role, address account) external;

    function setKeyRemovalCharge(uint256 amount) external;

    function settleELRewardsStealingPenalty(
        uint256[] memory nodeOperatorIds
    ) external;

    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external;

    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function unsafeUpdateValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsKeysCount,
        uint256 stuckValidatorsKeysCount
    ) external;

    function updateExitedValidatorsCount(
        bytes memory nodeOperatorIds,
        bytes memory exitedValidatorsCounts
    ) external;

    function updateRefundedValidatorsCount(uint256, uint256) external;

    function updateStuckValidatorsCount(
        bytes memory nodeOperatorIds,
        bytes memory stuckValidatorsCounts
    ) external;

    function updateTargetValidatorsLimits(
        uint256 nodeOperatorId,
        uint256 targetLimitMode,
        uint256 targetLimit
    ) external;
}
