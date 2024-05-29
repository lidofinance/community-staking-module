// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";
import { ICSModule, NodeOperator } from "./interfaces/ICSModule.sol";

import { QueueLib, Batch } from "./lib/QueueLib.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";
import { TransientUintUintMap } from "./lib/TransientUintUintMapLib.sol";
import { NOAddresses } from "./lib/NOAddresses.sol";

import { SigningKeys } from "./lib/SigningKeys.sol";
import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";
import { AssetRecovererLib } from "./lib/AssetRecovererLib.sol";

contract CSModule is
    ICSModule,
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUntil,
    AssetRecoverer
{
    using QueueLib for QueueLib.Queue;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant MODULE_MANAGER_ROLE =
        keccak256("MODULE_MANAGER_ROLE");
    bytes32 public constant STAKING_ROUTER_ROLE =
        keccak256("STAKING_ROUTER_ROLE");
    bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE");
    bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");

    uint256 private constant DEPOSIT_SIZE = 32 ether;
    uint256 private constant MIN_SLASHING_PENALTY_QUOTIENT = 32; // TODO: consider to move to state variable due to EIP-7251
    uint256 public constant INITIAL_SLASHING_PENALTY =
        DEPOSIT_SIZE / MIN_SLASHING_PENALTY_QUOTIENT;
    uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2; // TODO: Add link to SR docs

    uint256 public immutable EL_REWARDS_STEALING_FINE;
    uint256
        public immutable MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE;
    bytes32 private immutable MODULE_TYPE;
    ILidoLocator public immutable LIDO_LOCATOR;

    ////////////////////////
    // State variables below
    ////////////////////////
    uint256 public keyRemovalCharge;

    QueueLib.Queue public depositQueue;

    ICSAccounting public accounting;

    ICSEarlyAdoption public earlyAdoption;
    bool public publicRelease;
    uint64 private _nodeOperatorsCount;

    uint256 private _nonce;
    mapping(uint256 => NodeOperator) private _nodeOperators;
    // @dev see _keyPointer function for details of noKeyIndexPacked structure
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorWithdrawn;
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorSlashed;

    TransientUintUintMap private _queueLookup; // TODO: Add explainer comment

    uint64 private _totalDepositedValidators;
    uint64 private _totalExitedValidators;
    uint64 private _totalAddedValidators;
    uint64 private _depositableValidatorsCount;

    event NodeOperatorAdded(
        uint256 indexed nodeOperatorId,
        address indexed managerAddress,
        address indexed rewardAddress
    );
    event ReferrerSet(uint256 indexed nodeOperatorId, address indexed referrer);
    event VettedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 vettedKeysCount
    );
    event DepositedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositedKeysCount
    );
    event ExitedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 exitedKeysCount
    );
    event TotalSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 totalKeysCount
    );
    event StuckSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 stuckKeysCount
    );
    event RefundedKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 refundedKeysCount
    );
    event TargetValidatorsCountChangedByRequest(
        uint256 indexed nodeOperatorId,
        uint8 targetLimitMode,
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

    event PublicRelease();
    event KeyRemovalChargeSet(uint256 amount);

    // TODO: check words "charge" & "stealing" with legal team
    event KeyRemovalChargeApplied(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );
    event ELRewardsStealingPenaltyReported(
        uint256 indexed nodeOperatorId,
        bytes32 proposedBlockHash,
        uint256 stolenAmount
    );
    event ELRewardsStealingPenaltyCancelled(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );
    event ELRewardsStealingPenaltySettled(
        uint256 indexed nodeOperatorId,
        uint256 amount
    );

    error NodeOperatorDoesNotExist();
    error SenderIsNotEligible();
    error InvalidVetKeysPointer();
    error StuckKeysHigherThanExited();
    error ExitedKeysHigherThanTotalDeposited();
    error ExitedKeysDecrease();

    error NotEnoughKeys();

    error SigningKeysInvalidOffset();

    error AlreadySubmitted();
    error AlreadyWithdrawn();

    error AlreadySet();
    error InvalidAmount();
    error NotAllowedToJoinYet();
    error MaxSigningKeysCountExceeded();

    constructor(
        bytes32 moduleType,
        uint256 elRewardsStealingFine,
        uint256 maxKeysPerOperatorEA,
        address lidoLocator
    ) {
        MODULE_TYPE = moduleType;
        EL_REWARDS_STEALING_FINE = elRewardsStealingFine;
        MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE = maxKeysPerOperatorEA;
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
    }

    function initialize(
        address _accounting,
        address _earlyAdoption,
        address verifier,
        uint256 _keyRemovalCharge,
        address admin
    ) external initializer {
        __AccessControlEnumerable_init();

        accounting = ICSAccounting(_accounting);
        earlyAdoption = ICSEarlyAdoption(_earlyAdoption);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, verifier);
        _grantRole(STAKING_ROUTER_ROLE, address(LIDO_LOCATOR.stakingRouter()));

        _setKeyRemovalCharge(_keyRemovalCharge);
        // CSM is on pause initially and should be resumed during the vote
        _pauseFor(type(uint256).max);
    }

    /// @notice Resume module
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @notice Pause module for `duration` seconds
    /// @param duration Duration of the pause in seconds
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @notice Activate public release mode
    ///         Enable permissionless creation of the Node Operators
    ///         Remove the keys limit for the Node Operators
    function activatePublicRelease() external onlyRole(MODULE_MANAGER_ROLE) {
        if (publicRelease) {
            revert AlreadySet();
        }
        publicRelease = true;
        emit PublicRelease();
    }

    /// @notice Set the key removal charge. A charge is taken from the bond for each removed key
    /// @param amount Amount of wei to be charged for removing a single key
    function setKeyRemovalCharge(
        uint256 amount
    ) external onlyRole(MODULE_MANAGER_ROLE) {
        _setKeyRemovalCharge(amount);
    }

    /// @notice Add a new Node Operator using ETH as a bond
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managerAddress Optional. Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used
    /// @param rewardAddress Optional. Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        address managerAddress,
        address rewardAddress,
        bytes32[] calldata eaProof,
        address referrer
    ) external payable whenResumed {
        uint256 nodeOperatorId = _createNodeOperator(
            managerAddress,
            rewardAddress,
            referrer
        );
        _processEarlyAdoptionData(nodeOperatorId, eaProof);

        if (
            msg.value !=
            accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            )
        ) {
            revert InvalidAmount();
        }

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Add a new Node Operator using stETH as a bond
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managerAddress Optional. Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used
    /// @param rewardAddress Optional. Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used
    /// @param permit Optional. Permit to use stETH as bond
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional, Referrer address
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        address managerAddress,
        address rewardAddress,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata eaProof,
        address referrer
    ) external whenResumed {
        uint256 nodeOperatorId = _createNodeOperator(
            managerAddress,
            rewardAddress,
            referrer
        );
        _processEarlyAdoptionData(nodeOperatorId, eaProof);

        {
            uint256 amount = accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            );
            accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);
        }

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Add a new Node Operator using wstETH as a bond
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managerAddress Optional. Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used
    /// @param rewardAddress Optional. Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used
    /// @param permit Optional. Permit to use wstETH as bond
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        address managerAddress,
        address rewardAddress,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata eaProof,
        address referrer
    ) external whenResumed {
        uint256 nodeOperatorId = _createNodeOperator(
            managerAddress,
            rewardAddress,
            referrer
        );
        _processEarlyAdoptionData(nodeOperatorId, eaProof);

        {
            uint256 amount = accounting.getBondAmountByKeysCountWstETH(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            );
            accounting.depositWstETH(
                msg.sender,
                nodeOperatorId,
                amount,
                permit
            );
        }

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Add new keys to the Node Operator using ETH as a bond
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    function addValidatorKeysETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable whenResumed {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManager(nodeOperatorId);

        if (
            msg.value !=
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount)
        ) {
            revert InvalidAmount();
        }

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Add new keys to the Node Operator using stETH as a bond
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
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManager(nodeOperatorId);

        uint256 amount = accounting.getRequiredBondForNextKeys(
            nodeOperatorId,
            keysCount
        );

        accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Add new keys to the Node Operator using wstETH as a bond
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
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManager(nodeOperatorId);

        uint256 amount = accounting.getRequiredBondForNextKeysWstETH(
            nodeOperatorId,
            keysCount
        );

        accounting.depositWstETH(msg.sender, nodeOperatorId, amount, permit);

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Stake user's ETH to Lido and make a deposit in stETH to the bond
    /// @param nodeOperatorId ID of the Node Operator
    function depositETH(uint256 nodeOperatorId) external payable {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stETHAmount Amount of stETH to deposit
    /// @param permit Optional. Permit to use stETH as bond
    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId); // TODO: think about it is needed or not
        accounting.depositStETH(
            msg.sender,
            nodeOperatorId,
            stETHAmount,
            permit
        );

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Unwrap the user's wstETH and make a deposit in stETH to the bond for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param wstETHAmount Amount of wstETH to deposit
    /// @param permit Optional. Permit to use wstETH as bond
    function depositWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.depositWstETH(
            msg.sender,
            nodeOperatorId,
            wstETHAmount,
            permit
        );

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Claim full reward (fees + bond rewards) in stETH for the given Node Operator
    /// @notice If `stETHAmount` exceeds the current claimable amount, the claimable amount will be used instead
    /// @notice If `rewardsProof` is not provided, only excess bond will be available for claim
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stETHAmount Amount of stETH to claim
    /// @param cumulativeFeeShares Optional. Cumulative fee stETH shares for the Node Operator
    /// @param rewardsProof Optional. Merkle proof of the rewards
    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManagerOrRewardAddresses(nodeOperatorId);

        accounting.claimRewardsStETH({
            nodeOperatorId: nodeOperatorId,
            stETHAmount: stETHAmount,
            rewardAddress: _nodeOperators[nodeOperatorId].rewardAddress,
            cumulativeFeeShares: cumulativeFeeShares,
            rewardsProof: rewardsProof
        });

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Claim full reward (fees + bond rewards) in wstETH for the given Node Operator
    /// @notice If `wstETHAmount` exceeds the current claimable amount, the claimable amount will be used instead
    /// @notice If `rewardsProof` is not provided, only excess bond will be available for claim
    /// @param nodeOperatorId ID of the Node Operator
    /// @param wstETHAmount Amount of wstETH to claim
    /// @param cumulativeFeeShares Optional. Cumulative fee stETH shares for the Node Operator
    /// @param rewardsProof Optional. Merkle proof of the rewards
    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManagerOrRewardAddresses(nodeOperatorId);

        accounting.claimRewardsWstETH({
            nodeOperatorId: nodeOperatorId,
            wstETHAmount: wstETHAmount,
            rewardAddress: _nodeOperators[nodeOperatorId].rewardAddress,
            cumulativeFeeShares: cumulativeFeeShares,
            rewardsProof: rewardsProof
        });

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Request full reward (fees + bond rewards) in Withdrawal NFT (unstETH) for the given Node Operator
    /// @notice Amounts less than `MIN_STETH_WITHDRAWAL_AMOUNT` (see LidoWithdrawalQueue contract) are not allowed
    /// @notice Amounts above `MAX_STETH_WITHDRAWAL_AMOUNT` should be requested in several transactions
    /// @notice If `ethAmount` exceeds the current claimable amount, the claimable amount will be used instead
    /// @notice If `rewardsProof` is not provided, only excess bond will be available for claim
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
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManagerOrRewardAddresses(nodeOperatorId);

        accounting.claimRewardsUnstETH({
            nodeOperatorId: nodeOperatorId,
            stEthAmount: stEthAmount,
            rewardAddress: _nodeOperators[nodeOperatorId].rewardAddress,
            cumulativeFeeShares: cumulativeFeeShares,
            rewardsProof: rewardsProof
        });

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Propose a new manager address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        NOAddresses.proposeNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirm a new manager address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        NOAddresses.confirmNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Propose a new reward address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed reward address
    function proposeNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        NOAddresses.proposeNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirm a new reward address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        NOAddresses.confirmNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Reset the manager address to the reward address
    /// @param nodeOperatorId ID of the Node Operator
    function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        NOAddresses.resetNodeOperatorManagerAddress(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Called when rewards are minted for the module
    /// @dev Called by StakingRouter
    /// @dev Passes through the minted stETH shares to the fee distributor
    function onRewardsMinted(
        uint256 totalShares
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        IStETH(LIDO_LOCATOR.lido()).transferShares(
            address(accounting.feeDistributor()),
            totalShares
        );
    }

    /// @notice Update stuck validators count for Node Operators
    /// @dev Called by StakingRouter
    /// @dev If the stuck keys count is above zero for the Node Operator,
    ///      the depositable validators count is set to 0 for this Node Operator
    /// @param nodeOperatorIds bytes packed array of Node Operator IDs
    /// @param stuckValidatorsCounts bytes packed array of stuck validators counts
    function updateStuckValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata stuckValidatorsCounts
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        uint256 operatorsInReport = ValidatorCountsReport.safeCountOperators(
            nodeOperatorIds,
            stuckValidatorsCounts
        );

        for (uint256 i = 0; i < operatorsInReport; ++i) {
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

    /// @notice Updates exited validators count for Node Operators
    /// @dev Called by StakingRouter
    /// @param nodeOperatorIds bytes packed array of Node Operator IDs
    /// @param exitedValidatorsCounts bytes packed array of exited validators counts
    function updateExitedValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata exitedValidatorsCounts
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        uint256 operatorsInReport = ValidatorCountsReport.safeCountOperators(
            nodeOperatorIds,
            exitedValidatorsCounts
        );

        for (uint256 i = 0; i < operatorsInReport; ++i) {
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

            _updateExitedValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                exitedValidatorsCount: exitedValidatorsCount,
                allowDecrease: false
            });
        }
        _incrementModuleNonce();
    }

    /// @notice Update refunded validators count for the Node Operator
    /// @dev Called by StakingRouter
    /// @dev `refundedValidatorsCount` is not used in the module
    /// @param nodeOperatorId ID of the Node Operator
    /// @param refundedValidatorsCount Number of refunded validators
    function updateRefundedValidatorsCount(
        uint256 nodeOperatorId,
        uint256 refundedValidatorsCount
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        no.refundedValidatorsCount = uint32(refundedValidatorsCount);
        emit RefundedKeysCountChanged(nodeOperatorId, refundedValidatorsCount);
        _incrementModuleNonce();
    }

    /// @notice Update target limits for Node Operator
    /// @dev Called by StakingRouter
    /// @param nodeOperatorId ID of the Node Operator
    /// @param targetLimitMode Target limit mode for the Node Operator
    ///                        0 - disabled
    ///                        1 - soft mode
    ///                        2 - forced mode
    /// @param targetLimit Target limit of validators
    function updateTargetValidatorsLimits(
        uint256 nodeOperatorId,
        uint256 targetLimitMode,
        uint256 targetLimit
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (
            no.targetLimitMode == targetLimitMode &&
            no.targetLimit == targetLimit
        ) return;

        if (no.targetLimitMode != targetLimitMode) {
            no.targetLimitMode = uint8(targetLimitMode);
        }

        if (no.targetLimit != targetLimit) {
            no.targetLimit = uint32(targetLimit);
        }

        emit TargetValidatorsCountChangedByRequest(
            nodeOperatorId,
            uint8(targetLimitMode),
            targetLimit
        );

        // Nonce will be updated below even if depositable count was not changed
        // In case of targetLimit removal queue should be normalised
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normalizeQueueIfUpdated: true
        });
        _incrementModuleNonce();
    }

    /// @notice Called by the Staking Router when exited and stuck validators counts updated
    function onExitedAndStuckValidatorsCountsUpdated()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // solhint-disable-previous-line no-empty-blocks
        // Nothing to do, rewards are distributed by a performance oracle.
    }

    /// @notice Unsafe update of validators count for Node Operators by DAO
    /// @notice Called by Staking Router
    function unsafeUpdateValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsKeysCount,
        uint256 stuckValidatorsKeysCount
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        _updateExitedValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            exitedValidatorsCount: exitedValidatorsKeysCount,
            allowDecrease: true
        });
        _updateStuckValidatorsCount(nodeOperatorId, stuckValidatorsKeysCount);
        _incrementModuleNonce();
    }

    /// @notice Called by StakingRouter to decrease the number of vetted keys for node operator with given id
    /// @param nodeOperatorIds bytes packed array of the node operators id
    /// @param vettedSigningKeysCounts bytes packed array of the new number of vetted keys for the node operators
    function decreaseVettedSigningKeysCount(
        bytes calldata nodeOperatorIds,
        bytes calldata vettedSigningKeysCounts
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        uint256 operatorsInReport = ValidatorCountsReport.safeCountOperators(
            nodeOperatorIds,
            vettedSigningKeysCounts
        );

        for (uint256 i = 0; i < operatorsInReport; ++i) {
            (
                uint256 nodeOperatorId,
                uint256 vettedSigningKeysCount
            ) = ValidatorCountsReport.next(
                    nodeOperatorIds,
                    vettedSigningKeysCounts,
                    i
                );
            if (nodeOperatorId >= _nodeOperatorsCount)
                revert NodeOperatorDoesNotExist();

            NodeOperator storage no = _nodeOperators[nodeOperatorId];

            if (vettedSigningKeysCount >= no.totalVettedKeys) {
                revert InvalidVetKeysPointer();
            }

            no.totalVettedKeys = uint32(vettedSigningKeysCount);
            emit VettedSigningKeysCountChanged(
                nodeOperatorId,
                vettedSigningKeysCount
            );

            // Nonce will be updated below once
            // No need to normalize queue due to vetted decrease
            _updateDepositableValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                incrementNonceIfUpdated: false,
                normalizeQueueIfUpdated: false
            });
        }

        _incrementModuleNonce();
    }

    /// @notice Remove keys for the Node Operator and confiscate removal charge for each deleted key
    /// @param nodeOperatorId ID of the Node Operator
    /// @param startIndex Index of the first key
    /// @param keysCount Keys count to delete
    function removeKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManager(nodeOperatorId);
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
    //     // Mark validators for priority ejection
    //     // Confiscate ejection fee from the bond
    // }

    /// @notice Perform queue normalization for the given Node Operator
    /// @notice Normalization stands for adding vetted but not enqueued keys to the queue
    /// @param nodeOperatorId ID of the Node Operator
    function normalizeQueue(uint256 nodeOperatorId) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManager(nodeOperatorId);
        depositQueue.normalize(_nodeOperators, nodeOperatorId);
    }

    /// @notice Report EL rewards stealing for the given Node Operator
    /// @notice The amount equal to the stolen funds plus EL stealing fine will be locked
    /// @param nodeOperatorId ID of the Node Operator
    /// @param blockHash Execution layer block hash of the proposed block with EL rewards stealing
    /// @param amount Amount of stolen EL rewards in ETH
    function reportELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        bytes32 blockHash,
        uint256 amount
    ) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.lockBondETH(
            nodeOperatorId,
            amount + EL_REWARDS_STEALING_FINE
        );

        emit ELRewardsStealingPenaltyReported(
            nodeOperatorId,
            blockHash,
            amount
        );

        // Nonce should be updated if depositableValidators change
        // No need to normalize queue due to only decrease in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: false
        });
    }

    /// @notice Cancel previously reported and not settled EL rewards stealing penalty for the given Node Operator
    /// @notice The funds will be unlocked
    /// @param nodeOperatorId ID of the Node Operator
    /// @param amount Amount of penalty to cancel
    function cancelELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 amount
    ) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.releaseLockedBondETH(nodeOperatorId, amount);

        emit ELRewardsStealingPenaltyCancelled(nodeOperatorId, amount);

        // Nonce should be updated if depositableValidators change
        // Normalize queue should be called due to only increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Settles blocked bond for the given Node Operators
    /// @dev Should be called by the Easy Track
    /// @param nodeOperatorIds IDs of the Node Operators
    function settleELRewardsStealingPenalty(
        uint256[] memory nodeOperatorIds
    ) external onlyRole(SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE) {
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            if (nodeOperatorId >= _nodeOperatorsCount)
                revert NodeOperatorDoesNotExist();
            uint256 settled = accounting.settleLockedBondETH(nodeOperatorId);
            emit ELRewardsStealingPenaltySettled(nodeOperatorId, settled);
            if (settled > 0) {
                // Bond curve should be reset to default in case of confirmed MEV stealing. See https://hackmd.io/@lido/SygBLW5ja
                accounting.resetBondCurve(nodeOperatorId);
                // Nonce should be updated if depositableValidators change
                // No need to normalize queue due to only decrease in depositable possible
                _updateDepositableValidatorsCount({
                    nodeOperatorId: nodeOperatorId,
                    incrementNonceIfUpdated: true,
                    normalizeQueueIfUpdated: false
                });
            }
        }
    }

    /// @notice Compensate EL rewards stealing penalty for the given Node Operator to prevent further validator exits
    /// @dev Expected to be called by the Node Operator, but can be called by anyone
    /// @param nodeOperatorId ID of the Node Operator
    function compensateELRewardsStealingPenalty(
        uint256 nodeOperatorId
    ) external payable {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.compensateLockedBondETH{ value: msg.value }(nodeOperatorId);
        // Nonce should be updated if depositableValidators change
        // Normalize queue should be called due to only increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Report Node Operator's key as withdrawn and settle withdrawn amount
    /// @notice Called by the Verifier contract.
    ///         See `CSVerifier.processWithdrawalProof` to use this method permissionless
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the withdrawn key in the Node Operator's keys storage
    /// @param amount Amount of withdrawn ETH in wei
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    ) external onlyRole(VERIFIER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
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
            // Bond curve should be reset to default in case of slashing. See https://hackmd.io/@lido/SygBLW5ja
            accounting.resetBondCurve(nodeOperatorId);
        }

        if (amount < DEPOSIT_SIZE) {
            accounting.penalize(nodeOperatorId, DEPOSIT_SIZE - amount);
        }

        // Nonce should be updated if depositableValidators change
        // Normalize queue should be called due to possible increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Report Node Operator's key as slashed and apply the initial slashing penalty
    /// @notice Called by the Verifier contract.
    ///         See `CSVerifier.processSlashingProof` to use this method permissionless
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the slashed key in the Node Operator's keys storage
    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external onlyRole(VERIFIER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (keyIndex >= no.totalDepositedKeys) {
            revert SigningKeysInvalidOffset();
        }

        uint256 pointer = _keyPointer(nodeOperatorId, keyIndex);

        if (_isValidatorWithdrawn[pointer]) {
            revert AlreadyWithdrawn();
        }

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
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: false
        });
    }

    /// @notice Called by the Staking Router when withdrawal credentials changed by DAO
    /// @dev Resets the key removal charge
    /// @dev Changing the WC means that the current deposit data in the queue is not valid anymore and can't be deposited
    ///      So, the key removal charge should be reset to 0 to allow Node Operators to remove the keys without any charge.
    ///      After keys removal the DAO should set the new key removal charge.
    function onWithdrawalCredentialsChanged()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        _setKeyRemovalCharge(0);
    }

    /// @notice Get the next `depositsCount` of depositable keys with signatures from the queue
    /// @dev Second param `depositCalldata` is not used
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

        for (
            Batch item = depositQueue.peek();
            !item.isNil();
            item = depositQueue.peek()
        ) {
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
                // covers the case when no depositable keys on the Node Operator have been left.
                if (depositsLeft > keysCount || keysCount == keysInBatch) {
                    // NOTE: `enqueuedCount` >= keysInBatch invariant should be checked.
                    no.enqueuedCount -= uint32(keysInBatch);
                    // We've consumed all the keys in the batch, so we dequeue it.
                    depositQueue.dequeue();
                } else {
                    // This branch covers the case when we stop in the middle of the batch.
                    // We release the amount of keys consumed only, the rest will be kept.
                    no.enqueuedCount -= uint32(keysCount);
                    // NOTE: `keysInBatch` can't be less than `keysCount` at this point.
                    // We update the batch with the remaining keys.
                    item = item.setKeys(keysInBatch - keysCount);
                    // Store the updated batch back to the queue.
                    depositQueue.queue[depositQueue.head] = item;
                }

                if (keysCount == 0) {
                    continue;
                }

                // solhint-disable-next-line func-named-parameters
                SigningKeys.loadKeysSigs(
                    noId,
                    no.totalDepositedKeys,
                    keysCount,
                    publicKeys,
                    signatures,
                    loadedKeysCount
                );

                // It's impossible in practice to reach the limit of these variables.
                loadedKeysCount += keysCount;
                no.totalDepositedKeys += uint32(keysCount);

                emit DepositedSigningKeysCountChanged(
                    noId,
                    no.totalDepositedKeys
                );

                // No need for `_updateDepositableValidatorsCount` call since we update the number directly.
                // `keysCount` is min of `depositableValidatorsCount` and `depositsLeft`.
                no.depositableValidatorsCount -= uint32(keysCount);
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
            _depositableValidatorsCount -= uint64(depositsCount);
            _totalDepositedValidators += uint64(depositsCount);
        }

        _incrementModuleNonce();
    }

    /// @notice Clean the deposit queue from batches with no depositable keys
    /// @dev Use **eth_call** to check how many items will be removed
    /// @param maxItems How many queue items to review
    /// @return toRemove Number of the deposit data removed from the queue
    function cleanDepositQueue(
        uint256 maxItems
    ) external returns (uint256 toRemove) {
        return depositQueue.clean(_nodeOperators, _queueLookup, maxItems);
    }

    /// @notice Recover all stETH shares from the contract
    /// @dev There should be no stETH shares on the contract balance during regular operation
    function recoverStETHShares() external {
        _onlyRecoverer();
        IStETH stETH = IStETH(LIDO_LOCATOR.lido());

        AssetRecovererLib.recoverStETHShares(
            address(stETH),
            stETH.sharesOf(address(this))
        );
    }

    /// @notice Get the deposit queue item by an index
    /// @param index Index of a queue item
    function depositQueueItem(
        uint128 index
    ) external view returns (Batch item) {
        return depositQueue.at(index);
    }

    /// @notice Check if the given Node Operator's key is reported as slashed
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the key to check
    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorSlashed[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Check if the given Node Operator's key is reported as withdrawn
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex index of the key to check
    function isValidatorWithdrawn(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorWithdrawn[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Get the module type
    /// @return Module type
    function getType() external view returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @notice Get staking module summary
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

    /// @notice Get Node Operator info
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Node Operator info
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory) {
        return _nodeOperators[nodeOperatorId];
    }

    /// @notice Get Node Operator non-withdrawn keys
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Non-withdrawn keys count
    function getNodeOperatorNonWithdrawnKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256) {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        return no.totalAddedKeys - no.totalWithdrawnKeys;
    }

    /// @notice Get Node Operator summary
    /// @notice depositableValidatorsCount depends on:
    ///      - totalVettedKeys
    ///      - totalDepositedKeys
    ///      - totalExitedKeys
    ///      - targetLimitMode
    ///      - targetValidatorsCount
    ///      - totalunbondedKeys
    ///      - totalStuckKeys
    /// @param nodeOperatorId ID of the Node Operator
    /// @return targetLimitMode Target limit mode
    /// @return targetValidatorsCount Target validators count
    /// @return stuckValidatorsCount Stuck validators count
    /// @return refundedValidatorsCount Refunded validators count
    /// @return stuckPenaltyEndTimestamp Stuck penalty end timestamp (unused)
    /// @return totalExitedValidators Total exited validators
    /// @return totalDepositedValidators Total deposited validators
    /// @return depositableValidatorsCount Depositable validators count
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
        )
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint256 totalUnbondedKeys = accounting.getUnbondedKeysCountToEject(
            nodeOperatorId
        );
        // Force mode enabled and unbonded
        if (
            no.targetLimitMode == FORCED_TARGET_LIMIT_MODE_ID &&
            totalUnbondedKeys > 0
        ) {
            targetLimitMode = FORCED_TARGET_LIMIT_MODE_ID;
            targetValidatorsCount = Math.min(
                no.targetLimit,
                no.totalAddedKeys - no.totalWithdrawnKeys - totalUnbondedKeys
            );
            // No force mode enabled but unbonded
        } else if (totalUnbondedKeys > 0) {
            targetLimitMode = FORCED_TARGET_LIMIT_MODE_ID;
            targetValidatorsCount =
                no.totalAddedKeys -
                no.totalWithdrawnKeys -
                totalUnbondedKeys;
        } else {
            targetLimitMode = no.targetLimitMode;
            targetValidatorsCount = no.targetLimit;
        }
        stuckValidatorsCount = no.stuckValidatorsCount;
        refundedValidatorsCount = no.refundedValidatorsCount;
        // @dev unused in CSM
        stuckPenaltyEndTimestamp = 0;
        totalExitedValidators = no.totalExitedKeys;
        totalDepositedValidators = no.totalDepositedKeys;
        depositableValidatorsCount = no.depositableValidatorsCount;
    }

    /// @notice Get Node Operator signing keys
    /// @param nodeOperatorId ID of the Node Operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return Signing keys
    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory) {
        if (
            startIndex + keysCount >
            _nodeOperators[nodeOperatorId].totalAddedKeys
        ) {
            revert SigningKeysInvalidOffset();
        }

        return SigningKeys.loadKeys(nodeOperatorId, startIndex, keysCount);
    }

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
    ) external view returns (bytes memory keys, bytes memory signatures) {
        if (
            startIndex + keysCount >
            _nodeOperators[nodeOperatorId].totalAddedKeys
        ) {
            revert SigningKeysInvalidOffset();
        }

        (keys, signatures) = SigningKeys.initKeysSigsBuf(keysCount);
        // solhint-disable-next-line func-named-parameters
        SigningKeys.loadKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            keys,
            signatures,
            0
        );
    }

    /// @notice Get nonce of the module
    function getNonce() external view returns (uint256) {
        return _nonce;
    }

    /// @notice Get total number of Node Operators
    function getNodeOperatorsCount() external view returns (uint256) {
        return _nodeOperatorsCount;
    }

    /// @notice Get total number of active Node Operators
    function getActiveNodeOperatorsCount() external view returns (uint256) {
        return _nodeOperatorsCount;
    }

    /// @notice Get Node Operator active status
    /// @param nodeOperatorId ID of the Node Operator
    function getNodeOperatorIsActive(
        uint256 nodeOperatorId
    ) external view returns (bool) {
        return nodeOperatorId < _nodeOperatorsCount;
    }

    /// @notice Get IDs of Node Operators
    /// @param offset Offset of the first Node Operator ID to get
    /// @param limit Count of Node Operator IDs to get
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

    function _incrementModuleNonce() internal {
        unchecked {
            _nonce++;
        }
        emit NonceChanged(_nonce);
    }

    function _createNodeOperator(
        address managerAddress,
        address rewardAddress,
        address referrer
    ) internal returns (uint256) {
        uint256 id = _nodeOperatorsCount;
        NodeOperator storage no = _nodeOperators[id];

        no.managerAddress = managerAddress == address(0)
            ? msg.sender
            : managerAddress;
        no.rewardAddress = rewardAddress == address(0)
            ? msg.sender
            : rewardAddress;

        unchecked {
            _nodeOperatorsCount++;
        }

        emit NodeOperatorAdded(id, no.managerAddress, no.rewardAddress);

        if (referrer != address(0)) emit ReferrerSet(id, referrer);

        return id;
    }

    function _addSigningKeys(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint256 startIndex = no.totalAddedKeys;
        if (
            !publicRelease &&
            startIndex + keysCount >
            MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE
        ) {
            revert MaxSigningKeysCountExceeded();
        }

        // solhint-disable-next-line func-named-parameters
        SigningKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            publicKeys,
            signatures
        );

        _totalAddedValidators += uint64(keysCount);

        // Optimistic vetting takes place.
        if (no.totalAddedKeys == no.totalVettedKeys) {
            no.totalVettedKeys += uint32(keysCount);
            emit VettedSigningKeysCountChanged(
                nodeOperatorId,
                no.totalVettedKeys
            );
        }

        no.totalAddedKeys += uint32(keysCount);
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
            nodeOperatorId,
            startIndex,
            keysCount,
            no.totalAddedKeys
        );

        // The Node Operator is charged for the every removed key. It's motivated by the fact that the DAO should cleanup
        // the queue from the empty batches related to the Node Operator. It's possible to have multiple batches with only one
        // key in it, so it means the DAO should be able to cover removal costs for as much batches as keys removed in this case.
        uint256 amountToCharge = keyRemovalCharge * keysCount;
        if (amountToCharge != 0) {
            accounting.chargeFee(nodeOperatorId, amountToCharge);
            emit KeyRemovalChargeApplied(nodeOperatorId, amountToCharge);
        }

        no.totalAddedKeys = uint32(newTotalSigningKeys);
        emit TotalSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        no.totalVettedKeys = uint32(newTotalSigningKeys);
        emit VettedSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        // Nonce is updated below due to keys state change
        // Normalize queue should be called due to possible increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normalizeQueueIfUpdated: true
        });
        _incrementModuleNonce();
    }

    /// @notice It's possible to join with proof even after public release to get beneficial bond curve
    function _processEarlyAdoptionData(
        uint256 nodeOperatorId,
        bytes32[] calldata proof
    ) internal {
        if (!publicRelease && proof.length == 0) {
            revert NotAllowedToJoinYet();
        }
        if (proof.length == 0) return;

        earlyAdoption.consume(msg.sender, proof);
        accounting.setBondCurve(nodeOperatorId, earlyAdoption.CURVE_ID());
    }

    function _setKeyRemovalCharge(uint256 amount) internal {
        keyRemovalCharge = amount;
        emit KeyRemovalChargeSet(amount);
    }

    /// @dev Update exited validators count for a single Node Operator
    /// @dev Allows decrease the count for unsafe updates
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
            uint64(exitedValidatorsCount);
        no.totalExitedKeys = uint32(exitedValidatorsCount);

        emit ExitedSigningKeysCountChanged(
            nodeOperatorId,
            exitedValidatorsCount
        );
    }

    function _updateStuckValidatorsCount(
        uint256 nodeOperatorId,
        uint256 stuckValidatorsCount
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (stuckValidatorsCount == no.stuckValidatorsCount) return;
        if (stuckValidatorsCount > no.totalDepositedKeys - no.totalExitedKeys)
            revert StuckKeysHigherThanExited();

        no.stuckValidatorsCount = uint32(stuckValidatorsCount);
        emit StuckSigningKeysCountChanged(nodeOperatorId, stuckValidatorsCount);

        // TODO: think about reforge the condition: is `no.depositableValidatorsCount > 0` required?
        if (stuckValidatorsCount > 0 && no.depositableValidatorsCount > 0) {
            // INFO: The only consequence of stuck keys from the on-chain perspective is suspending deposits to the
            // Node Operator. To do that, we set the depositableValidatorsCount to 0 for this Node Operator. Hence
            // we can omit the call to the _updateDepositableValidatorsCount function here to save gas.
            _depositableValidatorsCount -= no.depositableValidatorsCount;
            no.depositableValidatorsCount = 0;
        } else {
            // Nonce will be updated on the top level once per call
            // Node Operator should normalize queue himself in case of unstuck
            // TODO: remind on UI to normalize queue after unstuck
            _updateDepositableValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                incrementNonceIfUpdated: false,
                normalizeQueueIfUpdated: false
            });
        }
    }

    function _updateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        bool incrementNonceIfUpdated,
        bool normalizeQueueIfUpdated
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        uint256 newCount = no.totalVettedKeys - no.totalDepositedKeys;

        uint256 unbondedKeys = accounting.getUnbondedKeysCount(nodeOperatorId);
        if (unbondedKeys > newCount) {
            newCount = 0;
        } else {
            unchecked {
                newCount -= unbondedKeys;
            }
        }

        if (no.stuckValidatorsCount > 0 && newCount > 0) {
            newCount = 0;
        }

        if (no.targetLimitMode > 0 && newCount > 0) {
            uint256 nonWithdrawnValidators = no.totalDepositedKeys -
                no.totalWithdrawnKeys;
            newCount = Math.min(
                no.targetLimit > nonWithdrawnValidators
                    ? no.targetLimit - nonWithdrawnValidators
                    : 0,
                newCount
            );
        }

        if (no.depositableValidatorsCount != newCount) {
            // Updating the global counter.
            unchecked {
                _depositableValidatorsCount =
                    _depositableValidatorsCount -
                    no.depositableValidatorsCount +
                    uint32(newCount);
            }
            no.depositableValidatorsCount = uint32(newCount);
            if (incrementNonceIfUpdated) {
                _incrementModuleNonce();
            }
            if (normalizeQueueIfUpdated) {
                depositQueue.normalize(_nodeOperators, nodeOperatorId);
            }
        }
    }

    function _onlyNodeOperatorManager(uint256 nodeOperatorId) internal view {
        if (_nodeOperators[nodeOperatorId].managerAddress != msg.sender)
            revert SenderIsNotEligible();
    }

    function _onlyNodeOperatorManagerOrRewardAddresses(
        uint256 nodeOperatorId
    ) internal view {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (no.managerAddress != msg.sender && no.rewardAddress != msg.sender)
            revert SenderIsNotEligible();
    }

    function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view {
        if (nodeOperatorId >= _nodeOperatorsCount)
            revert NodeOperatorDoesNotExist();
    }

    function _onlyRecoverer() internal view override {
        _checkRole(RECOVERER_ROLE);
    }

    /// @dev Both nodeOperatorId and keyIndex are limited to uint64 by the contract
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }
}
