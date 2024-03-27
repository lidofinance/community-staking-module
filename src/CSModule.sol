// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.24;

import { PausableUntil } from "base-oracle/utils/PausableUntil.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";

import { QueueLib, Batch, createBatch } from "./lib/QueueLib.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";
import { TransientUintUintMap } from "./lib/TransientUintUintMapLib.sol";

import { SigningKeys } from "./lib/SigningKeys.sol";

struct NodeOperator {
    address managerAddress;
    address proposedManagerAddress;
    address rewardAddress;
    address proposedRewardAddress;
    bool active;
    uint256 targetLimit;
    bool isTargetLimitActive;
    uint256 stuckPenaltyEndTimestamp;
    uint256 totalExitedKeys; // @dev only increased
    uint256 totalAddedKeys; // @dev increased and decreased when removed
    uint256 totalWithdrawnKeys; // @dev only increased
    uint256 totalDepositedKeys; // @dev only increased
    uint256 totalVettedKeys; // @dev both increased and decreased
    uint256 stuckValidatorsCount; // @dev both increased and decreased
    uint256 refundedValidatorsCount; // @dev only increased
    uint256 depositableValidatorsCount; // @dev any value
    uint256 enqueuedCount; // Tracks how many places are occupied by the node operator's keys in the queue.
}

contract CSModuleBase {
    event NodeOperatorAdded(uint256 indexed nodeOperatorId, address from);
    event NodeOperatorManagerAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address proposedAddress
    );
    event NodeOperatorRewardAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address proposedAddress
    );
    event NodeOperatorRewardAddressChanged(
        uint256 indexed nodeOperatorId,
        address oldAddress,
        address newAddress
    );
    event NodeOperatorManagerAddressChanged(
        uint256 indexed nodeOperatorId,
        address oldAddress,
        address newAddress
    );

    event VettedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 approvedValidatorsCount
    );
    event DepositedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositedValidatorsCount
    );
    event ExitedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 exitedValidatorsCount
    );
    event TotalSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 totalValidatorsCount
    );
    event StuckSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 stuckValidatorsCount
    );
    event TargetValidatorsCountChanged(
        uint256 indexed nodeOperatorId,
        bool isTargetLimitActive,
        uint256 targetValidatorsCount
    );
    event WithdrawalSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    );
    event InitialSlashingSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex
    );

    event BatchEnqueued(uint256 indexed nodeOperatorId, uint256 count);

    event StakingModuleTypeSet(bytes32 moduleType);
    event PublicReleaseTimestampSet(uint256 timestamp);
    event RemovalChargeSet(uint256 amount);

    event RemovalChargeApplied(uint256 indexed nodeOperatorId, uint256 amount);
    event ELRewardsStealingPenaltyReported(
        uint256 indexed nodeOperatorId,
        uint256 proposedBlockNumber,
        uint256 stolenAmount
    );

    error NodeOperatorDoesNotExist();
    error SenderIsNotManagerAddress();
    error SenderIsNotRewardAddress();
    error SenderIsNotProposedAddress();
    error SenderIsNotManagerOrKeyValidator();
    error SameAddress();
    error AlreadyProposed();
    error InvalidVetKeysPointer();
    error TargetLimitExceeded();
    error StuckKeysPresent();
    error UnbondedKeysPresent();
    error StuckKeysHigherThanTotalDeposited();
    error ExitedKeysHigherThanTotalDeposited();
    error ExitedKeysDecrease();

    error QueueLookupNoLimit();
    error QueueEmptyBatch();
    error QueueBatchInvalidNonce(bytes32 batch);
    error QueueBatchInvalidStart(bytes32 batch);
    error QueueBatchInvalidCount(bytes32 batch);
    error TooManyKeys();
    error NotEnoughKeys();

    error SigningKeysInvalidOffset();

    error AlreadySubmitted();

    error Expired();
    error AlreadyInitialized();
    error InvalidAmount();
    error NotAllowedToJoinYet();
    error MaxSigningKeysCountExceeded();
}

contract CSModule is ICSModule, CSModuleBase, AccessControl, PausableUntil {
    using QueueLib for QueueLib.Queue;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE"); // 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE"); // 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7

    bytes32 public constant SET_ACCOUNTING_ROLE =
        keccak256("SET_ACCOUNTING_ROLE"); // 0xbad3cb5f7add8fade9c376f76021c1c4106ee82e38abc73f6e8d234042d33f7d
    bytes32 public constant SET_EARLY_ADOPTION_ROLE =
        keccak256("SET_EARLY_ADOPTION_ROLE"); // 0xe0d27b865f229f5162f7b9ae24065c2d5cdae1ed1eaabf46a5f7809b1edf2ec1
    bytes32 public constant SET_PUBLIC_RELEASE_TIMESTAMP_ROLE =
        keccak256("SET_PUBLIC_RELEASE_TIMESTAMP_ROLE"); // 0x66d6616db95aac3b33b9261e42ab01ad71f311cff562503c33c742c54f22bbcd
    bytes32 public constant SET_REMOVAL_CHARGE_ROLE =
        keccak256("SET_REMOVAL_CHARGE_ROLE"); // 0xec192e8f5533ece8d0718d6180775a3e45c9499f95d7b1b0d2858b2c536b4d40
    bytes32 public constant STAKING_ROUTER_ROLE =
        keccak256("STAKING_ROUTER_ROLE"); // 0xbb75b874360e0bfd87f964eadd8276d8efb7c942134fc329b513032d0803e0c6
    bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE"); // 0x59911a6aa08a72fe3824aec4500dc42335c6d0702b6d5c5c72ceb265a0de9302
    bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE"); // 0xe85fdec10fe0f93d0792364051df7c3d73e37c17b3a954bffe593960e3cd3012
    bytes32 public constant WITHDRAWAL_SUBMITTER_ROLE =
        keccak256("WITHDRAWAL_SUBMITTER_ROLE"); // 0x2938d532d58b8c4c6a0b79de9ab9d63ffc286cbbc262cbd6cbebe54dd3431dec
    bytes32 public constant SLASHING_SUBMITTER_ROLE =
        keccak256("SLASHING_SUBMITTER_ROLE"); // 0x1490d8fc0656a30996bd2e7374c51790f74c101556ce56c87b64719da11a23dd
    bytes32 public constant PENALIZE_ROLE = keccak256("PENALIZE_ROLE"); // 0x014ffee5f075680f5690d491d67de8e1aba5c4a88326c3be77d991796b44f86b

    uint8 public constant MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE = 10;
    // might be received dynamically in case of increasing possible deposit size
    uint256 public constant DEPOSIT_SIZE = 32 ether;
    uint256 private constant MIN_SLASHING_PENALTY_QUOTIENT = 32;
    uint256 public constant INITIAL_SLASHING_PENALTY =
        DEPOSIT_SIZE / MIN_SLASHING_PENALTY_QUOTIENT;
    bytes32 private constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    uint256 public constant EL_REWARDS_STEALING_FINE = 0.1 ether;
    uint256 private constant ONE_YEAR = 365 days;

    uint256 private immutable TEMP_METHODS_EXPIRE_TIME;

    uint256 public publicReleaseTimestamp;
    uint256 public removalCharge;
    QueueLib.Queue public queue;

    ICSAccounting public accounting;
    ICSEarlyAdoption public earlyAdoption;
    // @dev max number of node operators is limited by uint64 due to Batch serialization in 32 bytes
    // it seems to be enough
    uint256 private _nodeOperatorsCount;
    uint256 private _activeNodeOperatorsCount;
    bytes32 private _moduleType;
    uint256 private _nonce;
    mapping(uint256 => NodeOperator) private _nodeOperators;
    mapping(uint256 noIdWithKeyIndex => bool) private _isValidatorWithdrawn;
    mapping(uint256 noIdWithKeyIndex => bool) private _isValidatorSlashed;

    uint256 private _totalDepositedValidators;
    uint256 private _totalExitedValidators;
    uint256 private _totalAddedValidators;
    uint256 private _depositableValidatorsCount;

    TransientUintUintMap private _queueLookup;

    constructor(
        bytes32 moduleType,
        uint256 _publicReleaseTimestamp,
        address admin
    ) {
        TEMP_METHODS_EXPIRE_TIME = block.timestamp + ONE_YEAR;
        _moduleType = moduleType;
        emit StakingModuleTypeSet(moduleType);

        publicReleaseTimestamp = _publicReleaseTimestamp;
        emit PublicReleaseTimestampSet(_publicReleaseTimestamp);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Resume module
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @notice Pause module
    /// @param duration Duration of the pause in seconds
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @notice Sets the accounting contract
    /// @param _accounting Address of the accounting contract
    function setAccounting(
        address _accounting
    ) external onlyRole(SET_ACCOUNTING_ROLE) {
        if (address(accounting) != address(0)) {
            revert AlreadyInitialized();
        }
        accounting = ICSAccounting(_accounting);
    }

    /// @notice Sets the early adoption contract
    /// @param _earlyAdoption Address of the early adoption contract
    function setEarlyAdoption(
        address _earlyAdoption
    ) external onlyRole(SET_EARLY_ADOPTION_ROLE) {
        if (address(earlyAdoption) != address(0)) {
            revert AlreadyInitialized();
        }
        earlyAdoption = ICSEarlyAdoption(_earlyAdoption);
    }

    function setPublicReleaseTimestamp(
        uint256 timestamp
    ) external onlyRole(SET_PUBLIC_RELEASE_TIMESTAMP_ROLE) {
        publicReleaseTimestamp = timestamp;
        emit PublicReleaseTimestampSet(timestamp);
    }

    /// @notice Sets the key deletion fine
    /// @param amount Amount of wei to be charged for removing a single key.
    function setRemovalCharge(
        uint256 amount
    ) external onlyRole(SET_REMOVAL_CHARGE_ROLE) {
        removalCharge = amount;
        emit RemovalChargeSet(amount);
    }

    /// @notice Gets the module type
    /// @return Module type
    function getType() external view returns (bytes32) {
        return _moduleType;
    }

    /// @notice Gets staking summary of the module
    function getStakingModuleSummary()
        external
        view
        returns (
            uint256 /* totalExitedValidators */,
            uint256 /* totalDepositedValidators */,
            uint256 /* depositableValidatorsCount */
        )
    {
        return (
            _totalExitedValidators,
            _totalDepositedValidators,
            _depositableValidatorsCount
        );
    }

    /// @notice Adds a new node operator with ETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// TODO consider splitting into methods with proof and without
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        bytes32[] calldata eaProof
    ) external payable whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator();
        _processEarlyAdoption(nodeOperatorId, eaProof);

        if (
            msg.value !=
            accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            )
        ) {
            revert InvalidAmount();
        }

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);
    }

    /// @notice Adds a new node operator with stETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        bytes32[] calldata eaProof
    ) external whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator();
        _processEarlyAdoption(nodeOperatorId, eaProof);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositStETH(
            msg.sender,
            nodeOperatorId,
            accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            )
        );
    }

    /// @notice Adds a new node operator with permit to use stETH as bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use stETH as bond
    function addNodeOperatorStETHWithPermit(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        bytes32[] calldata eaProof,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator();
        _processEarlyAdoption(nodeOperatorId, eaProof);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositStETHWithPermit(
            msg.sender,
            nodeOperatorId,
            accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            ),
            permit
        );
    }

    /// @notice Adds a new node operator with wstETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        bytes32[] calldata eaProof
    ) external whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator();
        _processEarlyAdoption(nodeOperatorId, eaProof);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositWstETH(
            msg.sender,
            nodeOperatorId,
            accounting.getBondAmountByKeysCountWstETH(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            )
        );
    }

    /// @notice Adds a new node operator with permit to use wstETH as bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use wstETH as bond
    function addNodeOperatorWstETHWithPermit(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        bytes32[] calldata eaProof,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator();
        _processEarlyAdoption(nodeOperatorId, eaProof);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositWstETHWithPermit(
            msg.sender,
            nodeOperatorId,
            accounting.getBondAmountByKeysCountWstETH(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            ),
            permit
        );
    }

    /// @notice Adds a new keys to the node operator with ETH bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addValidatorKeysETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable whenResumed {
        // TODO: sanity checks

        if (
            msg.value !=
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount)
        ) {
            revert InvalidAmount();
        }

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);
    }

    /// @notice Adds a new keys to the node operator with stETH bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addValidatorKeysStETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external whenResumed {
        // TODO: sanity checks

        uint256 amount = accounting.getRequiredBondForNextKeys(
            nodeOperatorId,
            keysCount
        );
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositStETH(msg.sender, nodeOperatorId, amount);
    }

    /// @notice Adds a new keys to the node operator with permit to use stETH as bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use stETH as bond
    function addValidatorKeysStETHWithPermit(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        // TODO: sanity checks

        uint256 amount = accounting.getRequiredBondForNextKeys(
            nodeOperatorId,
            keysCount
        );
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositStETHWithPermit(
            msg.sender,
            nodeOperatorId,
            amount,
            permit
        );
    }

    /// @notice Adds a new keys to the node operator with wstETH bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addValidatorKeysWstETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external whenResumed {
        // TODO: sanity checks

        uint256 amount = accounting.getRequiredBondForNextKeysWstETH(
            nodeOperatorId,
            keysCount
        );
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositWstETH(msg.sender, nodeOperatorId, amount);
    }

    /// @notice Adds a new keys to the node operator with permit to use wstETH as bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use wstETH as bond
    function addValidatorKeysWstETHWithPermit(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        // TODO: sanity checks

        uint256 amount = accounting.getRequiredBondForNextKeysWstETH(
            nodeOperatorId,
            keysCount
        );
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
        accounting.depositWstETHWithPermit(
            msg.sender,
            nodeOperatorId,
            amount,
            permit
        );
    }

    /// @notice Notify the module about the operator's bond change.
    function onBondChanged(uint256 nodeOperatorId) external {
        _updateDepositableValidatorsCount(nodeOperatorId);
        _normalizeQueue(nodeOperatorId);
    }

    /// @notice Proposes a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);
        if (_nodeOperators[nodeOperatorId].managerAddress == proposedAddress)
            revert SameAddress();
        if (
            _nodeOperators[nodeOperatorId].proposedManagerAddress ==
            proposedAddress
        ) revert AlreadyProposed();

        _nodeOperators[nodeOperatorId].proposedManagerAddress = proposedAddress;
        emit NodeOperatorManagerAddressChangeProposed(
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirms a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        if (_nodeOperators[nodeOperatorId].proposedManagerAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = _nodeOperators[nodeOperatorId].managerAddress;
        _nodeOperators[nodeOperatorId].managerAddress = msg.sender;
        _nodeOperators[nodeOperatorId].proposedManagerAddress = address(0);
        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            oldAddress,
            msg.sender
        );
    }

    /// @notice Proposes a new reward address for the node operator
    /// @param nodeOperatorId ID of the node operator
    /// @param proposedAddress Proposed reward address
    function proposeNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorRewardAddress(nodeOperatorId);
        if (_nodeOperators[nodeOperatorId].rewardAddress == proposedAddress)
            revert SameAddress();
        if (
            _nodeOperators[nodeOperatorId].proposedRewardAddress ==
            proposedAddress
        ) revert AlreadyProposed();

        _nodeOperators[nodeOperatorId].proposedRewardAddress = proposedAddress;
        emit NodeOperatorRewardAddressChangeProposed(
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirms a new reward address for the node operator
    /// @param nodeOperatorId ID of the node operator
    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        if (_nodeOperators[nodeOperatorId].proposedRewardAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = _nodeOperators[nodeOperatorId].rewardAddress;
        _nodeOperators[nodeOperatorId].rewardAddress = msg.sender;
        _nodeOperators[nodeOperatorId].proposedRewardAddress = address(0);
        emit NodeOperatorRewardAddressChanged(
            nodeOperatorId,
            oldAddress,
            msg.sender
        );
    }

    /// @notice Resets the manager address to the reward address
    /// @param nodeOperatorId ID of the node operator
    function resetNodeOperatorManagerAddress(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorRewardAddress(nodeOperatorId);
        if (
            _nodeOperators[nodeOperatorId].managerAddress ==
            _nodeOperators[nodeOperatorId].rewardAddress
        ) revert SameAddress();
        address previousManagerAddress = _nodeOperators[nodeOperatorId]
            .managerAddress;
        _nodeOperators[nodeOperatorId].managerAddress = msg.sender;
        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            previousManagerAddress,
            _nodeOperators[nodeOperatorId].rewardAddress
        );
    }

    /// @notice Gets node operator info
    /// @param nodeOperatorId ID of the node operator
    /// @return Node operator info
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperatorInfo memory) {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        NodeOperatorInfo memory info;
        info.active = no.active;
        info.managerAddress = no.managerAddress;
        info.rewardAddress = no.rewardAddress;
        info.totalVettedValidators = no.totalVettedKeys;
        info.totalExitedValidators = no.totalExitedKeys;
        info.totalWithdrawnValidators = no.totalWithdrawnKeys;
        info.totalAddedValidators = no.totalAddedKeys;
        info.totalDepositedValidators = no.totalDepositedKeys;
        info.enqueuedCount = no.enqueuedCount;
        return info;
    }

    /// @notice Gets node operator summary
    /// @param nodeOperatorId ID of the node operator
    /// @dev depositableValidatorsCount depends on:
    ///      - totalVettedKeys
    ///      - totalDepositedKeys
    ///      - totalExitedKeys
    ///      - isTargetLimitActive
    ///      - targetValidatorsCount
    function getNodeOperatorSummary(
        uint256 nodeOperatorId
    )
        external
        view
        returns (
            bool isTargetLimitActive,
            uint256 targetValidatorsCount,
            uint256 stuckValidatorsCount,
            uint256 refundedValidatorsCount,
            uint256 stuckPenaltyEndTimestamp,
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        )
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        isTargetLimitActive = no.isTargetLimitActive;
        targetValidatorsCount = no.targetLimit;
        stuckValidatorsCount = no.stuckValidatorsCount;
        refundedValidatorsCount = no.refundedValidatorsCount;
        stuckPenaltyEndTimestamp = no.stuckPenaltyEndTimestamp;
        totalExitedValidators = no.totalExitedKeys;
        totalDepositedValidators = no.totalDepositedKeys;
        depositableValidatorsCount = no.depositableValidatorsCount;
    }

    /// @notice Gets node operator signing keys
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return Signing keys
    function getNodeOperatorSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    )
        external
        view
        onlyExistingNodeOperator(nodeOperatorId)
        returns (bytes memory)
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (startIndex + keysCount > no.totalAddedKeys) {
            revert SigningKeysInvalidOffset();
        }

        return
            SigningKeys.loadKeys(
                SIGNING_KEYS_POSITION,
                nodeOperatorId,
                startIndex,
                keysCount
            );
    }

    /// @notice Gets nonce of the module.
    function getNonce() external view returns (uint256) {
        return _nonce;
    }

    /// @notice Gets the total number of node operators
    function getNodeOperatorsCount() external view returns (uint256) {
        return _nodeOperatorsCount;
    }

    /// @notice Gets the total number of active node operators
    function getActiveNodeOperatorsCount() external view returns (uint256) {
        return _activeNodeOperatorsCount;
    }

    /// @notice Gets node operator active status
    /// @param nodeOperatorId ID of the node operator
    function getNodeOperatorIsActive(
        uint256 nodeOperatorId
    ) external view returns (bool) {
        return _nodeOperators[nodeOperatorId].active;
    }

    /// @notice Gets IDs of node operators
    /// @param offset Offset of the first node operator
    /// @param limit Count of node operators to get
    function getNodeOperatorIds(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory nodeOperatorIds) {
        uint256 nodeOperatorsCount = _nodeOperatorsCount;
        if (offset >= nodeOperatorsCount || limit == 0) return new uint256[](0);
        uint256 idsCount = limit < nodeOperatorsCount - offset
            ? limit
            : nodeOperatorsCount - offset;
        nodeOperatorIds = new uint256[](idsCount);
        for (uint256 i = 0; i < nodeOperatorIds.length; ++i) {
            nodeOperatorIds[i] = offset + i;
        }
    }

    /// @notice Called when rewards minted for the module
    /// @dev Empty due to oracle using CSM balance for distribution
    function onRewardsMinted(
        uint256 /*_totalShares*/
    ) external onlyRole(STAKING_ROUTER_ROLE) {}

    function _updateDepositableValidatorsCount(uint256 nodeOperatorId) private {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        uint256 newCount = no.totalVettedKeys - no.totalDepositedKeys;
        if (no.isTargetLimitActive) {
            uint256 activeKeys = no.totalDepositedKeys - no.totalWithdrawnKeys;
            newCount = Math.min(
                no.targetLimit > activeKeys ? no.targetLimit - activeKeys : 0,
                newCount
            );
        }

        // NOTE: Probably this check can be extracted to a separate function to reduce gas costs for the methods
        // requiring only it.
        uint256 unbondedKeys = accounting.getUnbondedKeysCount(nodeOperatorId);
        if (unbondedKeys > newCount) {
            newCount = 0;
        } else {
            newCount -= unbondedKeys;
        }

        if (no.stuckValidatorsCount != 0) {
            newCount = 0;
        }

        if (no.depositableValidatorsCount != newCount) {
            // Updating the global counter.
            _depositableValidatorsCount =
                _depositableValidatorsCount -
                no.depositableValidatorsCount +
                newCount;
            no.depositableValidatorsCount = newCount;
        }
    }

    /// @notice Updates stuck validators count for node operators by StakingRouter
    /// @dev Presence of stuck validators leads to stop vetting for the node operator
    ///      to prevent further deposits and clean batches from the deposit queue.
    /// @dev stuck keys doesn't affect depositable keys count, so no need to recalculate it here
    /// @param nodeOperatorIds bytes packed array of node operator ids
    /// @param stuckValidatorsCounts bytes packed array of stuck validators counts
    function updateStuckValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata stuckValidatorsCounts
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        ValidatorCountsReport.validate(nodeOperatorIds, stuckValidatorsCounts);

        for (
            uint256 i = 0;
            i < ValidatorCountsReport.count(nodeOperatorIds);
            i++
        ) {
            (
                uint256 nodeOperatorId,
                uint256 stuckValidatorsCount
            ) = ValidatorCountsReport.next(
                    nodeOperatorIds,
                    stuckValidatorsCounts,
                    i
                );
            if (nodeOperatorId >= _nodeOperatorsCount)
                revert NodeOperatorDoesNotExist();
            NodeOperator storage no = _nodeOperators[nodeOperatorId];
            if (stuckValidatorsCount > no.totalDepositedKeys)
                revert StuckKeysHigherThanTotalDeposited();
            if (stuckValidatorsCount == no.stuckValidatorsCount) continue;

            no.stuckValidatorsCount = stuckValidatorsCount;
            emit StuckSigningKeysCountChanged(
                nodeOperatorId,
                stuckValidatorsCount
            );

            if (stuckValidatorsCount > 0 && no.depositableValidatorsCount > 0) {
                // INFO: The only consequence of stuck keys from the on-chain perspective is suspending deposits to the
                // node operator. To do that, we set the depositableValidatorsCount to 0 for this node operator. Hence
                // we can omit the call to the _updateDepositableValidatorsCount function here to save gas.
                _depositableValidatorsCount -= no.depositableValidatorsCount;
                no.depositableValidatorsCount = 0;
            } else {
                _updateDepositableValidatorsCount(nodeOperatorId);
            }
        }
        _incrementModuleNonce();
    }

    /// @notice Updates exited validators count for node operators by StakingRouter
    /// @param nodeOperatorIds bytes packed array of node operator ids
    /// @param exitedValidatorsCounts bytes packed array of exited validators counts
    function updateExitedValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata exitedValidatorsCounts
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        ValidatorCountsReport.validate(nodeOperatorIds, exitedValidatorsCounts);

        for (
            uint256 i = 0;
            i < ValidatorCountsReport.count(nodeOperatorIds);
            i++
        ) {
            (
                uint256 nodeOperatorId,
                uint256 exitedValidatorsCount
            ) = ValidatorCountsReport.next(
                    nodeOperatorIds,
                    exitedValidatorsCounts,
                    i
                );
            if (nodeOperatorId >= _nodeOperatorsCount)
                revert NodeOperatorDoesNotExist();

            NodeOperator storage no = _nodeOperators[nodeOperatorId];
            if (exitedValidatorsCount > no.totalDepositedKeys)
                revert ExitedKeysHigherThanTotalDeposited();
            if (exitedValidatorsCount < no.totalExitedKeys)
                revert ExitedKeysDecrease();
            if (exitedValidatorsCount == no.totalExitedKeys) continue;

            _totalExitedValidators +=
                exitedValidatorsCount -
                no.totalExitedKeys;
            no.totalExitedKeys = exitedValidatorsCount;
            emit ExitedSigningKeysCountChanged(
                nodeOperatorId,
                exitedValidatorsCount
            );
        }
        _incrementModuleNonce();
    }

    /// @notice Updates refunded validators count by StakingRouter
    /// @param nodeOperatorId ID of the node operator
    function updateRefundedValidatorsCount(
        uint256 nodeOperatorId,
        uint256 /* refundedValidatorsCount */
    )
        external
        onlyRole(STAKING_ROUTER_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        // TODO: implement
        _incrementModuleNonce();
    }

    /// @notice Updates target limits for node operator by StakingRouter
    /// @dev Target limit decreasing (or appearing) must unvet node operator's keys from the queue
    /// @param nodeOperatorId ID of the node operator
    /// @param isTargetLimitActive Is target limit active for the node operator
    /// @param targetLimit Target limit of validators
    function updateTargetValidatorsLimits(
        uint256 nodeOperatorId,
        bool isTargetLimitActive,
        uint256 targetLimit
    )
        external
        onlyRole(STAKING_ROUTER_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (
            no.isTargetLimitActive == isTargetLimitActive &&
            no.targetLimit == targetLimit
        ) return;

        if (no.isTargetLimitActive != isTargetLimitActive) {
            no.isTargetLimitActive = isTargetLimitActive;
        }

        if (no.targetLimit != targetLimit) {
            no.targetLimit = targetLimit;
        }

        emit TargetValidatorsCountChanged(
            nodeOperatorId,
            isTargetLimitActive,
            targetLimit
        );

        _updateDepositableValidatorsCount(nodeOperatorId);
        _normalizeQueue(nodeOperatorId);
        _incrementModuleNonce();
    }

    /// @notice Called when exited and stuck validators counts updated by StakingRouter
    function onExitedAndStuckValidatorsCountsUpdated()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // Nothing to do, rewards are distributed by a performance oracle.
    }

    /// @notice Unsafe updates of validators count for node operators by DAO
    function unsafeUpdateValidatorsCount(
        uint256 nodeOperatorId,
        uint256 /* exitedValidatorsKeysCount */,
        uint256 /* stuckValidatorsKeysCount */
    )
        external
        onlyRole(STAKING_ROUTER_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        // TODO: implement
        _updateDepositableValidatorsCount(nodeOperatorId);
        _incrementModuleNonce();
    }

    function decreaseOperatorVettedKeys(
        uint256[] calldata nodeOperatorIds,
        uint256[] calldata vettedKeysByOperator
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        // INFO: It seems it does not  make sense to implement any sanity checks.
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            if (nodeOperatorId >= _nodeOperatorsCount) {
                revert NodeOperatorDoesNotExist();
            }

            NodeOperator storage no = _nodeOperators[nodeOperatorId];

            if (vettedKeysByOperator[i] > no.totalVettedKeys) {
                revert InvalidVetKeysPointer();
            }

            no.totalVettedKeys = vettedKeysByOperator[i];
            emit VettedSigningKeysCountChanged(
                nodeOperatorId,
                vettedKeysByOperator[i]
            );

            _updateDepositableValidatorsCount(nodeOperatorId);
        }

        _incrementModuleNonce();
    }

    /// @notice Removes keys from the node operator and charges fee if there are vetted keys among them
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    function removeKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);
        _removeSigningKeys(nodeOperatorId, startIndex, keysCount);
    }

    /// @notice Node Operator should be able to voluntary eject own validators
    /// @notice Validator private key might be lost
    function voluntaryEjectValidator(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);
        // TODO: implement
        // Mark validators for priority ejection
        // Confiscate ejection fee from the bond
    }

    function normalizeQueue(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);
        _normalizeQueue(nodeOperatorId);
    }

    function _normalizeQueue(uint256 nodeOperatorId) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint256 depositable = no.depositableValidatorsCount;
        uint256 enqueued = no.enqueuedCount;

        if (enqueued < depositable) {
            unchecked {
                uint256 count = depositable - enqueued;
                Batch item = createBatch(nodeOperatorId, count);
                no.enqueuedCount += count;
                queue.enqueue(item);
                emit BatchEnqueued(nodeOperatorId, count);
            }
        }
    }

    /// @notice reset benefits for the Node Operator
    /// @param nodeOperatorId ID of the node operator
    function _resetBenefits(uint256 nodeOperatorId) internal {
        accounting.resetBondCurve(nodeOperatorId);
        _updateDepositableValidatorsCount(nodeOperatorId);
    }

    /// @notice Reports EL rewards stealing for the given node operator.
    /// @dev The funds will be locked, so if there any unbonded keys after that, they will be unvetted.
    /// @param nodeOperatorId id of the node operator to report EL rewards stealing for.
    /// @param blockNumber consensus layer block number of the proposed block with EL rewards stealing.
    /// @param amount amount of stolen EL rewards in ETH.
    function reportELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 blockNumber,
        uint256 amount
    )
        external
        onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        emit ELRewardsStealingPenaltyReported(
            nodeOperatorId,
            blockNumber,
            amount
        );

        accounting.lockBondETH(
            nodeOperatorId,
            amount + EL_REWARDS_STEALING_FINE
        );

        _updateDepositableValidatorsCount(nodeOperatorId);
    }

    /// @dev Should be called by the committee.
    /// @notice Settles blocked bond for the given node operators.
    /// @param nodeOperatorIds ids of the node operators to settle blocked bond for.
    function settleELRewardsStealingPenalty(
        uint256[] memory nodeOperatorIds
    ) external onlyRole(SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE) {
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            if (nodeOperatorId >= _nodeOperatorsCount)
                revert NodeOperatorDoesNotExist();
            uint256 settled = accounting.settleLockedBondETH(nodeOperatorId);
            if (settled > 0) {
                _resetBenefits(nodeOperatorId);
            }
        }
    }

    /// @notice Penalize bond by burning shares of the given node operator.
    /// @dev Have a limited lifetime. Reverts when expired
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to penalize.
    function penalize(
        uint256 nodeOperatorId,
        uint256 amount
    ) public onlyRole(PENALIZE_ROLE) onlyExistingNodeOperator(nodeOperatorId) {
        if (block.timestamp > TEMP_METHODS_EXPIRE_TIME) {
            revert Expired();
        }
        accounting.penalize(nodeOperatorId, amount);
        _resetBenefits(nodeOperatorId);
    }

    /// @notice Checks if the given node operators's key is proved as withdrawn.
    /// @param nodeOperatorId id of the node operator to check.
    /// @param keyIndex index of the key to check.
    function isValidatorWithdrawn(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorWithdrawn[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Report node operator's key as withdrawn and settle withdrawn amount.
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the withdrawn key in the node operator's keys.
    /// @param amount Amount of withdrawn ETH in wei.
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    )
        external
        onlyRole(WITHDRAWAL_SUBMITTER_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (keyIndex >= no.totalDepositedKeys) {
            revert SigningKeysInvalidOffset();
        }

        uint256 pointer = _keyPointer(nodeOperatorId, keyIndex);
        if (_isValidatorWithdrawn[pointer]) {
            revert AlreadySubmitted();
        }

        _isValidatorWithdrawn[pointer] = true;
        no.totalWithdrawnKeys++;

        emit WithdrawalSubmitted(nodeOperatorId, keyIndex, amount);

        if (_isValidatorSlashed[pointer]) amount += INITIAL_SLASHING_PENALTY;
        if (amount < DEPOSIT_SIZE) {
            accounting.penalize(nodeOperatorId, DEPOSIT_SIZE - amount);
        }

        _updateDepositableValidatorsCount(nodeOperatorId);
        _normalizeQueue(nodeOperatorId);
        _incrementModuleNonce();
    }

    /// @notice Checks if the given node operators's key is proved as slashed.
    /// @param nodeOperatorId id of the node operator to check.
    /// @param keyIndex index of the key to check.
    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorSlashed[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Report node operator's key as slashed and apply initial slashing penalty.
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the slashed key in the node operator's keys.
    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    )
        external
        onlyRole(SLASHING_SUBMITTER_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (keyIndex >= no.totalDepositedKeys) {
            revert SigningKeysInvalidOffset();
        }

        uint256 pointer = _keyPointer(nodeOperatorId, keyIndex);

        if (_isValidatorSlashed[pointer]) {
            revert AlreadySubmitted();
        }
        _isValidatorSlashed[pointer] = true;
        emit InitialSlashingSubmitted(nodeOperatorId, keyIndex);

        accounting.penalize(nodeOperatorId, INITIAL_SLASHING_PENALTY);
        _resetBenefits(nodeOperatorId);
        _incrementModuleNonce();
    }

    /// @dev both nodeOperatorId and keyIndex are limited to uint64 by the contract.
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }

    /// @notice Called when withdrawal credentials changed by DAO
    function onWithdrawalCredentialsChanged()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // TODO: implement it
    }

    function _addSigningKeys(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        // TODO: sanity checks
        uint256 startIndex = no.totalAddedKeys;
        if (
            block.timestamp < publicReleaseTimestamp &&
            startIndex + keysCount > MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE
        ) {
            revert MaxSigningKeysCountExceeded();
        }

        // solhint-disable-next-line func-named-parameters
        SigningKeys.saveKeysSigs(
            SIGNING_KEYS_POSITION,
            nodeOperatorId,
            startIndex,
            keysCount,
            publicKeys,
            signatures
        );

        _totalAddedValidators += keysCount;

        // Optimistic vetting takes place.
        if (no.totalAddedKeys == no.totalVettedKeys) {
            no.totalVettedKeys += keysCount;
            emit VettedSigningKeysCountChanged(
                nodeOperatorId,
                no.totalVettedKeys
            );
        }

        no.totalAddedKeys += keysCount;
        emit TotalSigningKeysCountChanged(nodeOperatorId, no.totalAddedKeys);

        _incrementModuleNonce();
    }

    function _removeSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (startIndex < no.totalDepositedKeys) {
            revert SigningKeysInvalidOffset();
        }

        if (startIndex + keysCount > no.totalAddedKeys) {
            revert SigningKeysInvalidOffset();
        }

        // solhint-disable-next-line func-named-parameters
        uint256 newTotalSigningKeys = SigningKeys.removeKeysSigs(
            SIGNING_KEYS_POSITION,
            nodeOperatorId,
            startIndex,
            keysCount,
            no.totalAddedKeys
        );

        // We charge the node operator for the every removed key. It's motivated by the fact that the DAO should cleanup
        // the queue from the empty batches of the node operator. It's possible to have multiple batches with only one
        // key in it, so it means the DAO should have remove as much batches as keys removed in this case.
        uint256 amountToCharge = removalCharge * keysCount;
        accounting.chargeFee(nodeOperatorId, amountToCharge);
        emit RemovalChargeApplied(nodeOperatorId, amountToCharge);

        no.totalAddedKeys = newTotalSigningKeys;
        emit TotalSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        no.totalVettedKeys = newTotalSigningKeys;
        emit VettedSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        _updateDepositableValidatorsCount(nodeOperatorId);
        _normalizeQueue(nodeOperatorId);
        _incrementModuleNonce();
    }

    /// @notice Gets the depositable keys with signatures from the queue
    /// @param depositsCount Count of deposits to get
    /// @param /* depositCalldata */ (unused) Deposit calldata
    /// @return publicKeys Public keys
    /// @return signatures Signatures
    function obtainDepositData(
        uint256 depositsCount,
        bytes calldata /* depositCalldata */
    )
        external
        onlyRole(STAKING_ROUTER_ROLE)
        returns (bytes memory publicKeys, bytes memory signatures)
    {
        (publicKeys, signatures) = SigningKeys.initKeysSigsBuf(depositsCount);
        uint256 depositsLeft = depositsCount;
        uint256 loadedKeysCount = 0;

        for (Batch item = queue.peek(); !item.isNil(); item = queue.peek()) {
            // NOTE: see the `enqueuedCount` note below.
            // TODO: write invariant test for that.
            unchecked {
                uint256 noId = item.noId();
                uint256 keysInBatch = item.keys();
                NodeOperator storage no = _nodeOperators[noId];

                uint256 keysCount = Math.min(
                    Math.min(no.depositableValidatorsCount, keysInBatch),
                    depositsLeft
                );
                // `depositsLeft` is non-zero at this point all the time, so the check `depositsLeft > keysCount`
                // covers the case when no depositable keys on the node operator have been left.
                if (depositsLeft > keysCount || keysCount == keysInBatch) {
                    // NOTE: `enqueuedCount` >= keysInBatch invariant should be checked.
                    no.enqueuedCount -= keysInBatch;
                    // We've consumed all the keys in the batch, so we dequeue it.
                    queue.dequeue();
                } else {
                    // This branch covers the case when we stop in the middle of the batch.
                    // We release the amount of keys consumed only, the rest will be kept.
                    no.enqueuedCount -= keysCount;
                    // NOTE: `keysInBatch` can't be less than `keysCount` at this point.
                    // We update the batch with the remaining keys.
                    item = item.setKeys(keysInBatch - keysCount);
                    // Store the updated batch back to the queue.
                    queue.queue[queue.head] = item;
                }

                if (keysCount == 0) {
                    continue;
                }

                // solhint-disable-next-line func-named-parameters
                SigningKeys.loadKeysSigs(
                    SIGNING_KEYS_POSITION,
                    noId,
                    no.totalDepositedKeys,
                    keysCount,
                    publicKeys,
                    signatures,
                    loadedKeysCount
                );

                // It's impossible in practice to reach the limit of these variables.
                loadedKeysCount += keysCount;
                no.totalDepositedKeys += keysCount;

                emit DepositedSigningKeysCountChanged(
                    noId,
                    no.totalDepositedKeys
                );

                // No need for `_updateDepositableValidatorsCount` call, we can update the number directly.
                // `keysCount` is min of `depositableValidatorsCount` and `depositsLeft`.
                no.depositableValidatorsCount -= keysCount;
                depositsLeft -= keysCount;
                if (depositsLeft == 0) {
                    break;
                }
            }
        }
        if (loadedKeysCount != depositsCount) {
            revert NotEnoughKeys();
        }

        unchecked {
            _depositableValidatorsCount -= depositsCount;
            _totalDepositedValidators += depositsCount;
        }

        _incrementModuleNonce();
    }

    /// @notice Cleans the deposit queue from batches with no depositable keys.
    /// @dev Use **eth_call** to check how many items will be removed.
    /// @param maxItems How many queue items to review.
    /// @return toRemove How many items were removed from the queue.
    function cleanDepositQueue(
        uint256 maxItems
    ) external returns (uint256 toRemove) {
        if (maxItems == 0) revert QueueLookupNoLimit();

        Batch prev;
        uint128 indexOfPrev;

        uint128 head = queue.head;
        uint128 curr = head;

        // Make sure we don't have any leftovers from the previous call.
        _queueLookup.clear();

        for (uint256 i; i < maxItems; ++i) {
            Batch item = queue.queue[curr];
            if (item.isNil()) {
                return toRemove;
            }

            uint256 noId = item.noId();
            NodeOperator storage no = _nodeOperators[noId];
            uint256 enqueuedSoFar = _queueLookup.get(noId);
            if (enqueuedSoFar >= no.depositableValidatorsCount) {
                // NOTE: Since we reached that point there's no way for a node operator to have a depositable batch
                // later in the queue, and hence we don't update _queueLookup for the node operator.
                if (curr == head) {
                    queue.dequeue();
                    head = queue.head;
                } else {
                    // There's no `prev` item while we call `dequeue`, and removing an item will keep the `prev` intact
                    // other than changing its `next` field.
                    prev = queue.remove(indexOfPrev, prev, item);
                }

                unchecked {
                    // We assume that the invariant `enqueuedCount` >= `keys` is kept.
                    uint256 keysInBatch = item.keys();
                    no.enqueuedCount -= keysInBatch;
                    ++toRemove;
                }
            } else {
                _queueLookup.add(noId, item.keys());
                indexOfPrev = curr;
                prev = item;
            }

            curr = item.next();
        }
    }

    /// @notice Gets the deposit queue item by an index.
    /// @param index Index of a queue item.
    function depositQueueItem(
        uint128 index
    ) external view returns (Batch item) {
        return queue.at(index);
    }

    function _incrementModuleNonce() internal {
        _nonce++;
    }

    function _createNodeOperator() internal returns (uint256) {
        uint256 id = _nodeOperatorsCount;
        NodeOperator storage no = _nodeOperators[id];

        no.managerAddress = msg.sender;
        no.rewardAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        emit NodeOperatorAdded(id, msg.sender);
        return id;
    }

    /// @notice it's possible to join with proof even after public release
    function _processEarlyAdoption(
        uint256 nodeOperatorId,
        bytes32[] calldata proof
    ) internal {
        if (block.timestamp < publicReleaseTimestamp && proof.length == 0) {
            revert NotAllowedToJoinYet();
        }
        if (proof.length == 0) return;

        earlyAdoption.consume(msg.sender, proof);
        accounting.setBondCurve(nodeOperatorId, earlyAdoption.curveId());
    }

    function onlyNodeOperatorManager(uint256 nodeOperatorId) internal {
        if (_nodeOperators[nodeOperatorId].managerAddress != msg.sender)
            revert SenderIsNotManagerAddress();
    }

    function onlyNodeOperatorRewardAddress(uint256 nodeOperatorId) internal {
        if (_nodeOperators[nodeOperatorId].rewardAddress != msg.sender)
            revert SenderIsNotRewardAddress();
    }

    modifier onlyExistingNodeOperator(uint256 nodeOperatorId) {
        if (nodeOperatorId >= _nodeOperatorsCount)
            revert NodeOperatorDoesNotExist();
        _;
    }
}
