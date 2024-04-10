// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.24;

import { PausableUntil } from "base-oracle/utils/PausableUntil.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";

import { QueueLib, Batch, createBatch } from "./lib/QueueLib.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";
import { TransientUintUintMap } from "./lib/TransientUintUintMapLib.sol";
import { NOAddresses } from "./lib/NOAddresses.sol";

import { SigningKeys } from "./lib/SigningKeys.sol";
import { AssetRecoverer } from "./AssetRecoverer.sol";
import { AssetRecovererLib } from "./lib/AssetRecovererLib.sol";

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
    event NodeOperatorAdded(
        uint256 indexed nodeOperatorId,
        address indexed referral,
        address indexed from
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
    event PublicRelease();
    event RemovalChargeSet(uint256 amount);

    event RemovalChargeApplied(uint256 indexed nodeOperatorId, uint256 amount);
    event ELRewardsStealingPenaltyReported(
        uint256 indexed nodeOperatorId,
        uint256 proposedBlockNumber,
        uint256 stolenAmount
    );
    event ELRewardsStealingPenaltyCancelled(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );

    error NodeOperatorDoesNotExist();
    error SenderIsNotManagerAddress();
    error SenderIsNotManagerOrKeyValidator();
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

    error AlreadySet();
    error InvalidAmount();
    error NotAllowedToJoinYet();
    error MaxSigningKeysCountExceeded();
}

contract CSModule is
    ICSModule,
    CSModuleBase,
    AccessControl,
    PausableUntil,
    AssetRecoverer
{
    using SafeERC20 for IERC20;
    using QueueLib for QueueLib.Queue;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE"); // 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE"); // 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7

    bytes32 public constant INITIALIZE_ROLE = keccak256("INITIALIZE_ROLE"); // 0xf1d56a0879c1f3fb7b8db84f8f66a72839440915c8cc40c60b771b23d8349df0
    bytes32 public constant MODULE_MANAGER_ROLE =
        keccak256("MODULE_MANAGER_ROLE"); // 0x79dfcec784e591aafcf60db7db7b029a5c8b12aac4afd4e8c4eb740430405fa6
    bytes32 public constant STAKING_ROUTER_ROLE =
        keccak256("STAKING_ROUTER_ROLE"); // 0xbb75b874360e0bfd87f964eadd8276d8efb7c942134fc329b513032d0803e0c6
    bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE"); // 0x59911a6aa08a72fe3824aec4500dc42335c6d0702b6d5c5c72ceb265a0de9302
    bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE"); // 0xe85fdec10fe0f93d0792364051df7c3d73e37c17b3a954bffe593960e3cd3012
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); // 0x0ce23c3e399818cfee81a7ab0880f714e53d7672b08df0fa62f2843416e1ea09
    bytes32 public constant PENALIZE_ROLE = keccak256("PENALIZE_ROLE"); // 0x014ffee5f075680f5690d491d67de8e1aba5c4a88326c3be77d991796b44f86b
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE"); // 0xb3e25b5404b87e5a838579cb5d7481d61ad96ee284d38ec1e97c07ba64e7f6fc

    uint8 public constant MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE = 10;
    // might be received dynamically in case of increasing possible deposit size
    uint256 public constant DEPOSIT_SIZE = 32 ether;
    uint256 private constant MIN_SLASHING_PENALTY_QUOTIENT = 32;
    uint256 public constant INITIAL_SLASHING_PENALTY =
        DEPOSIT_SIZE / MIN_SLASHING_PENALTY_QUOTIENT;
    bytes32 private constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    uint256 public constant EL_REWARDS_STEALING_FINE = 0.1 ether;

    bool public publicRelease;
    uint256 public removalCharge;
    QueueLib.Queue public queue;

    ILidoLocator public lidoLocator;
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
    uint256 private _totalRewardsShares;

    TransientUintUintMap private _queueLookup;

    constructor(bytes32 moduleType, address _lidoLocator, address admin) {
        _moduleType = moduleType;
        lidoLocator = ILidoLocator(_lidoLocator);
        emit StakingModuleTypeSet(moduleType);

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
    ) external onlyRole(INITIALIZE_ROLE) {
        if (address(accounting) != address(0)) {
            revert AlreadySet();
        }
        accounting = ICSAccounting(_accounting);
    }

    /// @notice Sets the early adoption contract
    /// @param _earlyAdoption Address of the early adoption contract
    function setEarlyAdoption(
        address _earlyAdoption
    ) external onlyRole(INITIALIZE_ROLE) {
        if (address(earlyAdoption) != address(0)) {
            revert AlreadySet();
        }
        earlyAdoption = ICSEarlyAdoption(_earlyAdoption);
    }

    function activatePublicRelease() external onlyRole(MODULE_MANAGER_ROLE) {
        if (publicRelease) {
            revert AlreadySet();
        }
        publicRelease = true;
        emit PublicRelease();
    }

    /// @notice Sets the key deletion fine
    /// @param amount Amount of wei to be charged for removing a single key.
    function setRemovalCharge(
        uint256 amount
    ) external onlyRole(MODULE_MANAGER_ROLE) {
        _setRemovalCharge(amount);
    }

    function _setRemovalCharge(uint256 amount) internal {
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
    /// @param eaProof Merkle proof of the sender being eligible for the Early Adoption
    /// @param referral Optional referral address
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        bytes32[] calldata eaProof,
        address referral
    ) external payable whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator(referral);
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

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Adds a new node operator with stETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use stETH as bond
    /// @param eaProof Merkle proof of the sender being eligible for the Early Adoption
    /// @param referral Optional referral address
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata eaProof,
        address referral
    ) external whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator(referral);
        _processEarlyAdoption(nodeOperatorId, eaProof);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositStETH(
            msg.sender,
            nodeOperatorId,
            accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            ),
            permit
        );

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Adds a new node operator with wstETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use wstETH as bond
    /// @param eaProof Merkle proof of the sender being eligible for the Early Adoption
    /// @param referral Optional referral address
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata eaProof,
        address referral
    ) external whenResumed {
        // TODO: sanity checks

        uint256 nodeOperatorId = _createNodeOperator(referral);
        _processEarlyAdoption(nodeOperatorId, eaProof);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositWstETH(
            msg.sender,
            nodeOperatorId,
            accounting.getBondAmountByKeysCountWstETH(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            ),
            permit
        );

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
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
    ) external payable whenResumed onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks
        onlyNodeOperatorManager(nodeOperatorId);

        if (
            msg.value !=
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount)
        ) {
            revert InvalidAmount();
        }

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Adds a new keys to the node operator with stETH bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use stETH as bond
    function addValidatorKeysStETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks
        onlyNodeOperatorManager(nodeOperatorId);

        uint256 amount = accounting.getRequiredBondForNextKeys(
            nodeOperatorId,
            keysCount
        );
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Adds a new keys to the node operator with wstETH bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    /// @param permit Permit to use wstETH as bond
    function addValidatorKeysWstETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks
        onlyNodeOperatorManager(nodeOperatorId);

        uint256 amount = accounting.getRequiredBondForNextKeysWstETH(
            nodeOperatorId,
            keysCount
        );
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositWstETH(msg.sender, nodeOperatorId, amount, permit);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Stake user's ETH to Lido and make deposit in stETH to the bond
    /// @param nodeOperatorId id of the node operator to stake ETH and deposit stETH for
    function depositETH(
        uint256 nodeOperatorId
    ) external payable onlyExistingNodeOperator(nodeOperatorId) {
        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param stETHAmount amount of stETH to deposit
    /// @param permit stETH permit for the contract
    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        accounting.depositStETH(
            msg.sender,
            nodeOperatorId,
            stETHAmount,
            permit
        );

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param wstETHAmount amount of wstETH to deposit
    /// @param permit wstETH permit for the contract
    function depositWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        accounting.depositWstETH(
            msg.sender,
            nodeOperatorId,
            wstETHAmount,
            permit
        );

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Claims full reward (fee + bond) in stETH for the given node operator with desirable value
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param stETHAmount amount of stETH to claim.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param rewardsProof merkle proof of the rewards.
    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);

        accounting.claimRewardsStETH(
            nodeOperatorId,
            stETHAmount,
            cumulativeFeeShares,
            rewardsProof
        );

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Claims full reward (fee + bond) in wstETH for the given node operator available for this moment
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param wstETHAmount amount of wstETH to claim.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param rewardsProof merkle proof of the rewards.
    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);

        accounting.claimRewardsWstETH(
            nodeOperatorId,
            wstETHAmount,
            cumulativeFeeShares,
            rewardsProof
        );

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param ethAmount amount of ETH to request.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param rewardsProof merkle proof of the rewards.
    function requestRewardsETH(
        uint256 nodeOperatorId,
        uint256 ethAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        onlyNodeOperatorManager(nodeOperatorId);

        accounting.requestRewardsETH(
            nodeOperatorId,
            ethAmount,
            cumulativeFeeShares,
            rewardsProof
        );

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Proposes a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        NOAddresses.proposeNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirms a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        NOAddresses.confirmNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Proposes a new reward address for the node operator
    /// @param nodeOperatorId ID of the node operator
    /// @param proposedAddress Proposed reward address
    function proposeNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        NOAddresses.proposeNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirms a new reward address for the node operator
    /// @param nodeOperatorId ID of the node operator
    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        NOAddresses.confirmNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Resets the manager address to the reward address
    /// @param nodeOperatorId ID of the node operator
    function resetNodeOperatorManagerAddress(
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        NOAddresses.resetNodeOperatorManagerAddress(
            _nodeOperators,
            nodeOperatorId
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

    /// @notice Called when rewards minted for the module.
    /// @dev Passes through the minted shares to the fee distributor.
    /// XXX: Make sure the fee distributor is set before calling this function.
    function onRewardsMinted(
        uint256 totalShares
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        IStETH(lidoLocator.lido()).transferShares(
            accounting.feeDistributor(),
            totalShares
        );
    }

    function _updateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        bool doIncrementNonce,
        bool doNormalizeQueue
    ) private {
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
            if (doIncrementNonce) {
                _incrementModuleNonce();
            }
            if (doNormalizeQueue) {
                _normalizeQueue(nodeOperatorId);
            }
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
            _updateStuckValidatorsCount(nodeOperatorId, stuckValidatorsCount);
        }
        _incrementModuleNonce();
    }

    function _updateStuckValidatorsCount(
        uint256 nodeOperatorId,
        uint256 stuckValidatorsCount
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (stuckValidatorsCount == no.stuckValidatorsCount) return;
        if (stuckValidatorsCount > no.totalDepositedKeys)
            revert StuckKeysHigherThanTotalDeposited();

        no.stuckValidatorsCount = stuckValidatorsCount;
        emit StuckSigningKeysCountChanged(nodeOperatorId, stuckValidatorsCount);

        if (stuckValidatorsCount > 0 && no.depositableValidatorsCount > 0) {
            // INFO: The only consequence of stuck keys from the on-chain perspective is suspending deposits to the
            // node operator. To do that, we set the depositableValidatorsCount to 0 for this node operator. Hence
            // we can omit the call to the _updateDepositableValidatorsCount function here to save gas.
            _depositableValidatorsCount -= no.depositableValidatorsCount;
            no.depositableValidatorsCount = 0;
        } else {
            // Nonce will be updated on the top level once per call
            // Node Operator should normalize queue himself in case of unstuck
            _updateDepositableValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                doIncrementNonce: false,
                doNormalizeQueue: false
            });
        }
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

            _updateExitedValidatorsCount(
                nodeOperatorId,
                exitedValidatorsCount,
                false /* _allowDecrease */
            );
        }
        _incrementModuleNonce();
    }

    // @dev updates exited validators count for a single node operator. allows decrease the count for unsafe updates
    function _updateExitedValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsCount,
        bool allowDecrease
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (exitedValidatorsCount == no.totalExitedKeys) return;
        if (exitedValidatorsCount > no.totalDepositedKeys)
            revert ExitedKeysHigherThanTotalDeposited();
        if (!allowDecrease && exitedValidatorsCount < no.totalExitedKeys)
            revert ExitedKeysDecrease();

        _totalExitedValidators =
            (_totalExitedValidators - no.totalExitedKeys) +
            exitedValidatorsCount;
        no.totalExitedKeys = exitedValidatorsCount;

        emit ExitedSigningKeysCountChanged(
            nodeOperatorId,
            exitedValidatorsCount
        );
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

        // Nonce will be updated below even if depositable count was not changed
        // In case of targetLimit removal queue should be normalised
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: false,
            doNormalizeQueue: true
        });
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
        uint256 exitedValidatorsKeysCount,
        uint256 stuckValidatorsKeysCount
    )
        external
        onlyRole(STAKING_ROUTER_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        _updateExitedValidatorsCount(
            nodeOperatorId,
            exitedValidatorsKeysCount,
            true /* _allowDecrease */
        );
        _updateStuckValidatorsCount(nodeOperatorId, stuckValidatorsKeysCount);
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

            if (vettedKeysByOperator[i] >= no.totalVettedKeys) {
                revert InvalidVetKeysPointer();
            }

            no.totalVettedKeys = vettedKeysByOperator[i];
            emit VettedSigningKeysCountChanged(
                nodeOperatorId,
                vettedKeysByOperator[i]
            );

            // Nonce will be updated below once
            // No need to normalize queue due to vetted decrease
            _updateDepositableValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                doIncrementNonce: false,
                doNormalizeQueue: false
            });
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

    // @notice CSM will go live before EIP-7002
    // @notice to be implemented in CSM v2
    // /// @notice Node Operator should be able to voluntary eject own validators
    // /// @notice Validator private key might be lost
    // function voluntaryEjectValidator(
    //     uint256 nodeOperatorId,
    //     uint256 startIndex,
    //     uint256 keysCount
    // ) external onlyExistingNodeOperator(nodeOperatorId) {
    //     onlyNodeOperatorManager(nodeOperatorId);
    //     // TODO: implement
    //     // Mark validators for priority ejection
    //     // Confiscate ejection fee from the bond
    // }

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
                no.enqueuedCount = depositable;
                queue.enqueue(item);
                emit BatchEnqueued(nodeOperatorId, count);
            }
        }
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
        accounting.lockBondETH(
            nodeOperatorId,
            amount + EL_REWARDS_STEALING_FINE
        );

        emit ELRewardsStealingPenaltyReported(
            nodeOperatorId,
            blockNumber,
            amount
        );

        // Nonce should be updated if depositableValidators change
        // No need to normalize queue due to only decrease in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: false
        });
    }

    /// @notice Cancel EL rewards stealing for the given node operator.
    /// @dev The funds will be unlocked.
    /// @param nodeOperatorId id of the node operator to cancel penalty for.
    /// @param amount amount of cancelled penalty.
    function cancelELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 amount
    )
        external
        onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        accounting.releaseLockedBondETH(nodeOperatorId, amount);

        emit ELRewardsStealingPenaltyCancelled(nodeOperatorId, amount);

        // Nonce should be updated if depositableValidators change
        // Normalize queue should be called due to only increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
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
                accounting.resetBondCurve(nodeOperatorId);
                // Nonce should be updated if depositableValidators change
                // No need to normalize queue due to only decrease in depositable possible
                _updateDepositableValidatorsCount({
                    nodeOperatorId: nodeOperatorId,
                    doIncrementNonce: true,
                    doNormalizeQueue: false
                });
            }
        }
    }

    /// @notice Compensate EL rewards stealing penalty for the given node operator to prevent further validator exits.
    /// @param nodeOperatorId id of the node operator.
    function compensateELRewardsStealingPenalty(
        uint256 nodeOperatorId
    ) external payable onlyExistingNodeOperator(nodeOperatorId) {
        accounting.compensateLockedBondETH{ value: msg.value }(nodeOperatorId);
        // Nonce should be updated if depositableValidators change
        // Normalize queue should be called due to only increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Checks if the given node operator's key is proved as withdrawn.
    /// @param nodeOperatorId id of the node operator to check.
    /// @param keyIndex index of the key to check.
    function isValidatorWithdrawn(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorWithdrawn[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Report node operator's key as withdrawn and settle withdrawn amount.
    /// See CSVerifier.processWithdrawalProof to use this method permissionless
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the withdrawn key in the node operator's keys.
    /// @param amount Amount of withdrawn ETH in wei.
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    )
        external
        onlyRole(VERIFIER_ROLE)
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

        if (_isValidatorSlashed[pointer]) {
            amount += INITIAL_SLASHING_PENALTY;
            accounting.resetBondCurve(nodeOperatorId);
        }

        if (amount < DEPOSIT_SIZE) {
            accounting.penalize(nodeOperatorId, DEPOSIT_SIZE - amount);
        }

        // Nonce should be updated if depositableValidators change
        // Normalize queue should be called due to possible increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: true
        });
    }

    /// @notice Checks if the given node operator's key is proved as slashed.
    /// @param nodeOperatorId id of the node operator to check.
    /// @param keyIndex index of the key to check.
    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorSlashed[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Report node operator's key as slashed and apply initial slashing penalty.
    /// See CSVerifier.processSlashingProof to use this method permissionless
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the slashed key in the node operator's keys.
    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    )
        external
        onlyRole(VERIFIER_ROLE)
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

        // Nonce should be updated if depositableValidators change
        // Normalize queue should not be called due to only possible decrease in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: true,
            doNormalizeQueue: false
        });
    }

    /// @dev both nodeOperatorId and keyIndex are limited to uint64 by the contract.
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }

    /// @notice Called when withdrawal credentials changed by DAO and resets the keys removal charge
    /// @dev Changing the WC means that the current keys in the queue are not valid anymore and can't be vetted to deposit
    ///     So, the removal charge should be reset to 0 to allow the node operator to remove the keys without any charge.
    ///     Then the DAO should set the new removal charge.
    function onWithdrawalCredentialsChanged()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        _setRemovalCharge(0);
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
            !publicRelease &&
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

        // Nonce is updated below due to keys state change
        // Normalize queue should be called due to possible increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            doIncrementNonce: false,
            doNormalizeQueue: true
        });
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

                // No need for `_updateDepositableValidatorsCount` call since we update the number directly.
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

    function recoverStETHShares() external onlyRecoverer {
        IStETH stETH = IStETH(lidoLocator.lido());

        AssetRecovererLib.recoverStETHShares(
            address(stETH),
            stETH.sharesOf(address(this))
        );
    }

    modifier onlyRecoverer() override {
        _checkRole(RECOVERER_ROLE);
        _;
    }

    function _incrementModuleNonce() internal {
        _nonce++;
    }

    function _createNodeOperator(address referral) internal returns (uint256) {
        uint256 id = _nodeOperatorsCount;
        NodeOperator storage no = _nodeOperators[id];

        no.managerAddress = msg.sender;
        no.rewardAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        emit NodeOperatorAdded(id, referral, msg.sender);
        return id;
    }

    /// @notice it's possible to join with proof even after public release
    function _processEarlyAdoption(
        uint256 nodeOperatorId,
        bytes32[] calldata proof
    ) internal {
        if (!publicRelease && proof.length == 0) {
            revert NotAllowedToJoinYet();
        }
        if (proof.length == 0) return;

        earlyAdoption.consume(msg.sender, proof);
        accounting.setBondCurve(nodeOperatorId, earlyAdoption.curveId());
    }

    function onlyNodeOperatorManager(uint256 nodeOperatorId) internal view {
        if (_nodeOperators[nodeOperatorId].managerAddress != msg.sender)
            revert SenderIsNotManagerAddress();
    }

    modifier onlyExistingNodeOperator(uint256 nodeOperatorId) {
        if (nodeOperatorId >= _nodeOperatorsCount)
            revert NodeOperatorDoesNotExist();
        _;
    }
}
