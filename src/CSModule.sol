// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSModule, NodeOperator, NodeOperatorManagementProperties, ValidatorWithdrawalInfo } from "./interfaces/ICSModule.sol";

import { QueueLib, Batch } from "./lib/QueueLib.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";
import { NOAddresses } from "./lib/NOAddresses.sol";
import { TransientUintUintMap, TransientUintUintMapLib } from "./lib/TransientUintUintMapLib.sol";

import { SigningKeys } from "./lib/SigningKeys.sol";
import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";

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
    bytes32 public constant STAKING_ROUTER_ROLE =
        keccak256("STAKING_ROUTER_ROLE");
    bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE");
    bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
    bytes32 public constant CREATE_NODE_OPERATOR_ROLE =
        keccak256("CREATE_NODE_OPERATOR_ROLE");

    uint256 private constant DEPOSIT_SIZE = 32 ether;
    // @dev see IStakingModule.sol
    uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2;

    bytes32 private immutable MODULE_TYPE;
    ILidoLocator public immutable LIDO_LOCATOR;
    IStETH public immutable STETH;
    ICSParametersRegistry public immutable PARAMETERS_REGISTRY;

    /// @dev QUEUE_LOWEST_PRIORITY identifies the range of available priorities: [0; QUEUE_LOWEST_PRIORITY].
    uint256 public immutable QUEUE_LOWEST_PRIORITY;
    uint256 public immutable QUEUE_LEGACY_PRIORITY;

    ////////////////////////
    // State variables below
    ////////////////////////

    /// @custom:oz-renamed-from keyRemovalCharge
    /// @custom:oz-retyped-from uint256
    mapping(uint256 queuePriority => QueueLib.Queue queue)
        internal _queueByPriority;

    /// @dev Legacy queue (priority=QUEUE_LEGACY_PRIORITY), that we will probably may be able to remove in the future.
    /// @custom:oz-renamed-from depositQueue
    QueueLib.Queue public legacyQueue;

    ICSAccounting public accounting;

    /// @custom:oz-renamed-from earlyAdoption
    /// @custom:oz-retyped-from address
    mapping(uint256 noKeyIndexPacked => uint256)
        private _isValidatorExitDelayed;

    uint256 private _nonce;
    mapping(uint256 => NodeOperator) private _nodeOperators;
    /// @dev see _keyPointer function for details of noKeyIndexPacked structure
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorWithdrawn;
    /// @dev DEPRECATED! No writes expected after Pectra hard-fork
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorSlashed;

    uint64 private _totalDepositedValidators;
    uint64 private _totalExitedValidators;
    uint64 private _depositableValidatorsCount;
    uint64 private _nodeOperatorsCount;

    constructor(
        bytes32 moduleType,
        address lidoLocator,
        address parametersRegistry
    ) {
        if (lidoLocator == address(0)) {
            revert ZeroLocatorAddress();
        }

        if (parametersRegistry == address(0)) {
            revert ZeroParametersRegistryAddress();
        }

        MODULE_TYPE = moduleType;
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        STETH = IStETH(LIDO_LOCATOR.lido());
        PARAMETERS_REGISTRY = ICSParametersRegistry(parametersRegistry);
        QUEUE_LOWEST_PRIORITY = PARAMETERS_REGISTRY.QUEUE_LOWEST_PRIORITY();
        QUEUE_LEGACY_PRIORITY = PARAMETERS_REGISTRY.QUEUE_LEGACY_PRIORITY();

        _disableInitializers();
    }

    /// @notice initialize the module from scratch
    function initialize(
        address _accounting,
        address admin
    ) external reinitializer(2) {
        if (_accounting == address(0)) {
            revert ZeroAccountingAddress();
        }

        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        __AccessControlEnumerable_init();

        accounting = ICSAccounting(_accounting);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(STAKING_ROUTER_ROLE, address(LIDO_LOCATOR.stakingRouter()));

        // CSM is on pause initially and should be resumed during the vote
        _pauseFor(PausableUntil.PAUSE_INFINITELY);
    }

    /// @dev should be called after update on the proxy
    function finalizeUpgradeV2() external reinitializer(2) {
        assembly ("memory-safe") {
            sstore(_queueByPriority.slot, 0x00)
            sstore(_isValidatorExitDelayed.slot, 0x00)
        }
    }

    /// @inheritdoc ICSModule
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc ICSModule
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @inheritdoc ICSModule
    function createNodeOperator(
        address from,
        NodeOperatorManagementProperties calldata managementProperties,
        address referrer
    )
        external
        onlyRole(CREATE_NODE_OPERATOR_ROLE)
        whenResumed
        returns (uint256 nodeOperatorId)
    {
        if (from == address(0)) {
            revert ZeroSenderAddress();
        }

        nodeOperatorId = _nodeOperatorsCount;
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        address managerAddress = managementProperties.managerAddress ==
            address(0)
            ? from
            : managementProperties.managerAddress;
        address rewardAddress = managementProperties.rewardAddress == address(0)
            ? from
            : managementProperties.rewardAddress;
        no.managerAddress = managerAddress;
        no.rewardAddress = rewardAddress;
        if (managementProperties.extendedManagerPermissions) {
            no.extendedManagerPermissions = true;
        }

        unchecked {
            ++_nodeOperatorsCount;
        }

        emit NodeOperatorAdded(nodeOperatorId, managerAddress, rewardAddress);

        if (referrer != address(0)) {
            emit ReferrerSet(nodeOperatorId, referrer);
        }

        _incrementModuleNonce();
    }

    /// @inheritdoc ICSModule
    function addValidatorKeysETH(
        address from,
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable whenResumed {
        _checkCanAddKeys(nodeOperatorId, from);

        if (
            msg.value <
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount)
        ) {
            revert InvalidAmount();
        }

        if (msg.value != 0) {
            accounting.depositETH{ value: msg.value }(from, nodeOperatorId);
        }

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addValidatorKeysStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        _checkCanAddKeys(nodeOperatorId, from);

        uint256 amount = accounting.getRequiredBondForNextKeys(
            nodeOperatorId,
            keysCount
        );

        if (amount != 0) {
            accounting.depositStETH(from, nodeOperatorId, amount, permit);
        }

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addValidatorKeysWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        _checkCanAddKeys(nodeOperatorId, from);

        uint256 amount = accounting.getRequiredBondForNextKeysWstETH(
            nodeOperatorId,
            keysCount
        );

        if (amount != 0) {
            accounting.depositWstETH(from, nodeOperatorId, amount, permit);
        }

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        NOAddresses.proposeNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @inheritdoc ICSModule
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external {
        NOAddresses.confirmNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @inheritdoc ICSModule
    function proposeNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        NOAddresses.proposeNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @inheritdoc ICSModule
    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external {
        NOAddresses.confirmNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @inheritdoc ICSModule
    function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external {
        NOAddresses.resetNodeOperatorManagerAddress(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @inheritdoc ICSModule
    function changeNodeOperatorRewardAddress(
        uint256 nodeOperatorId,
        address newAddress
    ) external {
        if (newAddress == address(0)) {
            revert ZeroRewardAddress();
        }

        NOAddresses.changeNodeOperatorRewardAddress(
            _nodeOperators,
            nodeOperatorId,
            newAddress
        );
    }

    /// @inheritdoc IStakingModule
    /// @dev Passes through the minted stETH shares to the fee distributor
    function onRewardsMinted(
        uint256 totalShares
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        STETH.transferShares(address(accounting.feeDistributor()), totalShares);
    }

    /// @inheritdoc IStakingModule
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
            _updateExitedValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                exitedValidatorsCount: exitedValidatorsCount,
                allowDecrease: false
            });
        }
        _incrementModuleNonce();
    }

    /// @inheritdoc IStakingModule
    function updateTargetValidatorsLimits(
        uint256 nodeOperatorId,
        uint256 targetLimitMode,
        uint256 targetLimit
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        if (targetLimitMode > FORCED_TARGET_LIMIT_MODE_ID) {
            revert InvalidInput();
        }
        if (targetLimit > type(uint32).max) {
            revert InvalidInput();
        }
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (targetLimitMode == 0) {
            targetLimit = 0;
        }

        if (
            no.targetLimitMode == targetLimitMode &&
            no.targetLimit == targetLimit
        ) {
            return;
        }

        // @dev No need to safe cast due to conditions above
        no.targetLimitMode = uint8(targetLimitMode);
        no.targetLimit = uint32(targetLimit);

        emit TargetValidatorsCountChanged(
            nodeOperatorId,
            targetLimitMode,
            targetLimit
        );

        // Nonce will be updated below even if depositable count was not changed
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false
        });
        _incrementModuleNonce();
    }

    /// @inheritdoc IStakingModule
    /// @dev This method is not used in CSM, hence it is do nothing
    function onExitedAndStuckValidatorsCountsUpdated()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // solhint-disable-previous-line no-empty-blocks
        // Nothing to do, rewards are distributed by a performance oracle.
    }

    /// @inheritdoc IStakingModule
    function unsafeUpdateValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsKeysCount,
        uint256 stuckValidatorsKeysCount
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        // NOTE: Silence the unused argument warning.
        stuckValidatorsKeysCount;

        _updateExitedValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            exitedValidatorsCount: exitedValidatorsKeysCount,
            allowDecrease: true
        });
        _incrementModuleNonce();
    }

    /// @inheritdoc IStakingModule
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

            _onlyExistingNodeOperator(nodeOperatorId);

            NodeOperator storage no = _nodeOperators[nodeOperatorId];

            if (vettedSigningKeysCount >= no.totalVettedKeys) {
                revert InvalidVetKeysPointer();
            }

            if (vettedSigningKeysCount < no.totalDepositedKeys) {
                revert InvalidVetKeysPointer();
            }

            // @dev No need to safe cast due to conditions above
            no.totalVettedKeys = uint32(vettedSigningKeysCount);
            emit VettedSigningKeysCountChanged(
                nodeOperatorId,
                vettedSigningKeysCount
            );

            // @dev separate event for intentional decrease from Staking Router
            emit VettedSigningKeysCountDecreased(nodeOperatorId);

            // Nonce will be updated below once
            _updateDepositableValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                incrementNonceIfUpdated: false
            });
        }

        _incrementModuleNonce();
    }

    /// @inheritdoc ICSModule
    function removeKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external {
        _onlyNodeOperatorManager(nodeOperatorId, msg.sender);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (startIndex < no.totalDepositedKeys) {
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
        uint256 curveId = accounting.getBondCurveId(nodeOperatorId);
        uint256 amountToCharge = PARAMETERS_REGISTRY.getKeyRemovalCharge(
            curveId
        ) * keysCount;
        if (amountToCharge != 0) {
            accounting.chargeFee(nodeOperatorId, amountToCharge);
            emit KeyRemovalChargeApplied(nodeOperatorId);
        }

        // @dev No need to safe cast due to checks in the func above
        no.totalAddedKeys = uint32(newTotalSigningKeys);
        emit TotalSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        // @dev No need to safe cast due to checks in the func above
        no.totalVettedKeys = uint32(newTotalSigningKeys);
        emit VettedSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        // Nonce is updated below due to keys state change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false
        });
        _incrementModuleNonce();
    }

    /// TODO: Consider renaming
    /// @inheritdoc ICSModule
    function updateDepositableValidatorsCount(uint256 nodeOperatorId) external {
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @dev TODO: Remove the method in the next major release.
    /// @inheritdoc ICSModule
    function migrateToPriorityQueue(uint256 nodeOperatorId) external {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (no.usedPriorityQueue) {
            revert PriorityQueueAlreadyUsed();
        }

        uint256 curveId = accounting.getBondCurveId(nodeOperatorId);
        (uint32 priority, uint32 maxDeposits) = PARAMETERS_REGISTRY
            .getQueueConfig(curveId);

        if (priority < QUEUE_LEGACY_PRIORITY) {
            uint32 deposited = no.totalDepositedKeys;

            if (maxDeposits > deposited) {
                uint32 toMigrate = uint32(
                    Math.min(maxDeposits - deposited, no.enqueuedCount)
                );

                unchecked {
                    no.enqueuedCount -= toMigrate;
                }
                _enqueueNodeOperatorKeys(nodeOperatorId, priority, toMigrate);
            }

            no.usedPriorityQueue = true;
        }

        // An alternative version to fit into the bytecode requirements is below. Please consider
        // the described caveat of the approach.

        // NOTE: We allow a node operator (NO) to reset their enqueued counter to zero only once to
        // migrate their keys from the legacy queue to a priority queue, if any. As a downside, the
        // node operator effectively can have their seats doubled in the queue.
        // Let's say we have a priority queue with a maximum of 10 deposits. Imagine a NO has 20
        // keys queued in the legacy queue. Then, the NO calls this method and gets their enqueued
        // counter reset to zero. As a result, the module will place 10 keys into the priority queue
        // and 10 more keys at the end of the overall queue. The original batches are kept in the
        // queue, so in total, the NO will have batches with 40 keys queued altogether.
        // _nodeOperators[nodeOperatorId].enqueuedCount = 0;
        // _enqueueNodeOperatorKeys(nodeOperatorId);
    }

    /// @inheritdoc ICSModule
    function reportELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        bytes32 blockHash,
        uint256 amount
    ) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        if (amount == 0) {
            revert InvalidAmount();
        }
        uint256 curveId = accounting.getBondCurveId(nodeOperatorId);
        uint256 additionalFine = PARAMETERS_REGISTRY
            .getElRewardsStealingAdditionalFine(curveId);
        accounting.lockBondETH(nodeOperatorId, amount + additionalFine);
        emit ELRewardsStealingPenaltyReported(
            nodeOperatorId,
            blockHash,
            amount
        );

        // Nonce should be updated if depositableValidators change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
    function cancelELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 amount
    ) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.releaseLockedBondETH(nodeOperatorId, amount);

        emit ELRewardsStealingPenaltyCancelled(nodeOperatorId, amount);

        // Nonce should be updated if depositableValidators change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
    function settleELRewardsStealingPenalty(
        uint256[] calldata nodeOperatorIds
    ) external onlyRole(SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE) {
        ICSAccounting _accounting = accounting;
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            _onlyExistingNodeOperator(nodeOperatorId);
            uint256 lockedBondBefore = _accounting.getActualLockedBond(
                nodeOperatorId
            );

            _accounting.settleLockedBondETH(nodeOperatorId);

            // settled amount might be zero either if the lock expired, or the bond is zero
            // so we need to check actual locked bond before to determine if the penalty was settled
            if (lockedBondBefore > 0) {
                // Bond curve should be reset to default in case of confirmed MEV stealing. See https://hackmd.io/@lido/SygBLW5ja
                _accounting.resetBondCurve(nodeOperatorId);
                // Nonce should be updated if depositableValidators change
                _updateDepositableValidatorsCount({
                    nodeOperatorId: nodeOperatorId,
                    incrementNonceIfUpdated: true
                });
                emit ELRewardsStealingPenaltySettled(nodeOperatorId);
            }
        }
    }

    /// @inheritdoc ICSModule
    function compensateELRewardsStealingPenalty(
        uint256 nodeOperatorId
    ) external payable {
        _onlyNodeOperatorManager(nodeOperatorId, msg.sender);
        accounting.compensateLockedBondETH{ value: msg.value }(nodeOperatorId);
        // Nonce should be updated if depositableValidators change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
        emit ELRewardsStealingPenaltyCompensated(nodeOperatorId, msg.value);
    }

    /// @inheritdoc ICSModule
    function submitWithdrawals(
        ValidatorWithdrawalInfo[] calldata withdrawalsInfo
    ) external onlyRole(VERIFIER_ROLE) {
        for (uint256 i; i < withdrawalsInfo.length; ++i) {
            ValidatorWithdrawalInfo memory withdrawalInfo = withdrawalsInfo[i];

            _onlyExistingNodeOperator(withdrawalInfo.nodeOperatorId);
            NodeOperator storage no = _nodeOperators[
                withdrawalInfo.nodeOperatorId
            ];

            if (withdrawalInfo.keyIndex >= no.totalDepositedKeys) {
                revert SigningKeysInvalidOffset();
            }

            uint256 pointer = _keyPointer(
                withdrawalInfo.nodeOperatorId,
                withdrawalInfo.keyIndex
            );
            if (_isValidatorWithdrawn[pointer]) {
                revert AlreadyWithdrawn();
            }

            _isValidatorWithdrawn[pointer] = true;
            unchecked {
                ++no.totalWithdrawnKeys;
            }

            bytes memory pubkey = SigningKeys.loadKeys(
                withdrawalInfo.nodeOperatorId,
                withdrawalInfo.keyIndex,
                1
            );

            emit WithdrawalSubmitted(
                withdrawalInfo.nodeOperatorId,
                withdrawalInfo.keyIndex,
                withdrawalInfo.amount,
                pubkey
            );

            if (withdrawalInfo.isSlashed) {
                // Bond curve should be reset to default in case of slashing. See https://hackmd.io/@lido/SygBLW5ja
                accounting.resetBondCurve(withdrawalInfo.nodeOperatorId);
            }

            if (DEPOSIT_SIZE > withdrawalInfo.amount) {
                unchecked {
                    accounting.penalize(
                        withdrawalInfo.nodeOperatorId,
                        DEPOSIT_SIZE - withdrawalInfo.amount
                    );
                }
            }

            // Nonce should be updated if depositableValidators change
            _updateDepositableValidatorsCount({
                nodeOperatorId: withdrawalInfo.nodeOperatorId,
                incrementNonceIfUpdated: true
            });
        }
    }

    /// @inheritdoc IStakingModule
    /// @dev Does nothing
    /// @dev Changing the WC means that the current deposit data in the queue is not valid anymore and can't be deposited.
    ///      DSM will unvet current keys.
    ///      The key removal charge should be reset to 0 to allow Node Operators to remove the keys without any charge.
    ///      After keys removal the DAO should set the new key removal charge.
    function onWithdrawalCredentialsChanged()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // solhint-disable-previous-line no-empty-blocks
        // Nothing to do. The key removal charge should be reset separately to 0 to allow Node Operators to remove the keys without any charge.
    }

    /// @inheritdoc IStakingModule
    function reportValidatorExitDelay(
        uint256 /* _nodeOperatorId */,
        uint256 /* _proofSlotTimestamp */,
        bytes calldata /* _publicKey */,
        uint256 /* _eligibleToExitInSec */
    ) external {}

    /// @inheritdoc IStakingModule
    function onValidatorExitTriggered(
        uint256 /* _nodeOperatorId */,
        bytes calldata /* _publicKey */,
        uint256 /* _withdrawalRequestPaidFee */,
        uint256 /* _exitType */
    ) external {}

    /// @inheritdoc IStakingModule
    /// @notice Get the next `depositsCount` of depositable keys with signatures from the queue
    /// @dev Second param `depositCalldata` is not used
    function obtainDepositData(
        uint256 depositsCount,
        bytes calldata /* depositCalldata */
    )
        external
        onlyRole(STAKING_ROUTER_ROLE)
        returns (bytes memory publicKeys, bytes memory signatures)
    {
        (publicKeys, signatures) = SigningKeys.initKeysSigsBuf(depositsCount);
        if (depositsCount == 0) {
            return (publicKeys, signatures);
        }

        uint256 depositsLeft = depositsCount;
        uint256 loadedKeysCount = 0;

        QueueLib.Queue storage queue;
        // Note: The highest priority to start iterations with. Priorities are ordered like 0, 1, 2, ...
        uint256 priority = 0;

        while (true) {
            if (priority > QUEUE_LOWEST_PRIORITY || depositsLeft == 0) {
                break;
            }

            queue = _getQueue(priority);
            unchecked {
                ++priority;
            }

            for (
                Batch item = queue.peek();
                !item.isNil();
                item = queue.peek()
            ) {
                // NOTE: see the `enqueuedCount` note below.
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
                        // @dev No need to safe cast due to internal logic
                        no.enqueuedCount -= uint32(keysInBatch);
                        // We've consumed all the keys in the batch, so we dequeue it.
                        queue.dequeue();
                    } else {
                        // This branch covers the case when we stop in the middle of the batch.
                        // We release the amount of keys consumed only, the rest will be kept.
                        // @dev No need to safe cast due to internal logic
                        no.enqueuedCount -= uint32(keysCount);
                        // NOTE: `keysInBatch` can't be less than `keysCount` at this point.
                        // We update the batch with the remaining keys.
                        item = item.setKeys(keysInBatch - keysCount);
                        // Store the updated batch back to the queue.
                        queue.queue[queue.head] = item;
                    }

                    // Note: This condition is located here to allow for the correct removal of the batch for the Node Operators with no depositable keys
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
                    // @dev No need to safe cast due to internal logic
                    uint32 totalDepositedKeys = no.totalDepositedKeys +
                        uint32(keysCount);
                    no.totalDepositedKeys = totalDepositedKeys;

                    emit DepositedSigningKeysCountChanged(
                        noId,
                        totalDepositedKeys
                    );

                    // No need for `_updateDepositableValidatorsCount` call since we update the number directly.
                    // `keysCount` is min of `depositableValidatorsCount` and `depositsLeft`.
                    // @dev No need to safe cast due to internal logic
                    uint32 newCount = no.depositableValidatorsCount -
                        uint32(keysCount);
                    no.depositableValidatorsCount = newCount;
                    emit DepositableSigningKeysCountChanged(noId, newCount);

                    depositsLeft -= keysCount;
                    if (depositsLeft == 0) {
                        break;
                    }
                }
            }
        }

        if (loadedKeysCount != depositsCount) {
            revert NotEnoughKeys();
        }

        unchecked {
            // @dev depositsCount can not overflow in practice due to memory and gas limits
            _depositableValidatorsCount -= uint64(depositsCount);
            _totalDepositedValidators += uint64(depositsCount);
        }

        _incrementModuleNonce();
    }

    /// @inheritdoc ICSModule
    function cleanDepositQueue(
        uint256 maxItems
    ) external returns (uint256 removed, uint256 lastRemovedAtDepth) {
        // NOTE: We need one unique hash map per function invocation to be able to track batches of
        // the same operator across multiple queues.
        TransientUintUintMap queueLookup = TransientUintUintMapLib.create();

        QueueLib.Queue storage queue;

        uint256 totalVisited = 0;
        // Note: The highest priority to start iterations with. Priorities are ordered like 0, 1, 2, ...
        uint256 priority = 0;

        while (true) {
            if (priority > QUEUE_LOWEST_PRIORITY) {
                break;
            }

            queue = _getQueue(priority);
            unchecked {
                ++priority;
            }

            (
                uint256 removedPerQueue,
                uint256 lastRemovedAtDepthPerQueue,
                uint256 visited,
                bool isFinished
            ) = queue.clean(_nodeOperators, maxItems, queueLookup);

            if (removedPerQueue > 0) {
                unchecked {
                    // 1234 56 789A     <- cumulative depth (A=10)
                    // 1234 12 1234     <- depth per queue
                    // **R*|**|**R*     <- queue with [R]emoved elements
                    //
                    // Given that we observed all 3 queues:
                    // totalVisited: 4+2=6
                    // lastRemovedAtDepthPerQueue: 3
                    // lastRemovedAtDepth: 6+3=9

                    lastRemovedAtDepth =
                        totalVisited +
                        lastRemovedAtDepthPerQueue;
                    removed += removedPerQueue;
                }
            }

            // NOTE: If `maxItems` is set to the total length of the queue(s), `isFinished` is equal
            // to false, effectively breaking the cycle, because in `QueueLib.clean` we don't reach
            // an empty batch after the end of a queue.
            if (!isFinished) {
                break;
            }

            unchecked {
                totalVisited += visited;
                maxItems -= visited;
            }
        }
    }

    /// @inheritdoc ICSModule
    function getInitializedVersion() external view returns (uint64) {
        return _getInitializedVersion();
    }

    /// @inheritdoc ICSModule
    function depositQueuePointers(
        uint256 queuePriority
    ) external view returns (uint128 head, uint128 tail) {
        QueueLib.Queue storage q = _getQueue(queuePriority);
        return (q.head, q.tail);
    }

    /// @inheritdoc ICSModule
    function depositQueueItem(
        uint256 queuePriority,
        uint128 index
    ) external view returns (Batch) {
        return _getQueue(queuePriority).at(index);
    }

    /// @inheritdoc ICSModule
    function isValidatorWithdrawn(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorWithdrawn[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @inheritdoc IStakingModule
    function getType() external view returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @inheritdoc IStakingModule
    function getStakingModuleSummary()
        external
        view
        returns (
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        )
    {
        totalExitedValidators = _totalExitedValidators;
        totalDepositedValidators = _totalDepositedValidators;
        depositableValidatorsCount = _depositableValidatorsCount;
    }

    /// @inheritdoc ICSModule
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory) {
        return _nodeOperators[nodeOperatorId];
    }

    /// @inheritdoc ICSModule
    function getNodeOperatorManagementProperties(
        uint256 nodeOperatorId
    ) external view returns (NodeOperatorManagementProperties memory) {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        return (
            NodeOperatorManagementProperties(
                no.managerAddress,
                no.rewardAddress,
                no.extendedManagerPermissions
            )
        );
    }

    /// @inheritdoc ICSModule
    function getNodeOperatorNonWithdrawnKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256) {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        unchecked {
            return no.totalAddedKeys - no.totalWithdrawnKeys;
        }
    }

    /// @inheritdoc IStakingModule
    /// @notice depositableValidatorsCount depends on:
    ///      - totalVettedKeys
    ///      - totalDepositedKeys
    ///      - totalExitedKeys
    ///      - targetLimitMode
    ///      - targetValidatorsCount
    ///      - totalUnbondedKeys
    ///      - totalStuckKeys
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
        uint256 totalNonDepositedKeys = no.totalAddedKeys -
            no.totalDepositedKeys;
        // Force mode enabled and unbonded deposited keys
        if (
            totalUnbondedKeys > totalNonDepositedKeys &&
            no.targetLimitMode == FORCED_TARGET_LIMIT_MODE_ID
        ) {
            targetLimitMode = FORCED_TARGET_LIMIT_MODE_ID;
            unchecked {
                targetValidatorsCount = Math.min(
                    no.targetLimit,
                    no.totalAddedKeys -
                        no.totalWithdrawnKeys -
                        totalUnbondedKeys
                );
            }
            // No force mode enabled but unbonded deposited keys
        } else if (totalUnbondedKeys > totalNonDepositedKeys) {
            targetLimitMode = FORCED_TARGET_LIMIT_MODE_ID;
            unchecked {
                targetValidatorsCount =
                    no.totalAddedKeys -
                    no.totalWithdrawnKeys -
                    totalUnbondedKeys;
            }
        } else {
            targetLimitMode = no.targetLimitMode;
            targetValidatorsCount = no.targetLimit;
        }
        // TODO: Unused in CSM, remove with TW.
        // stuckValidatorsCount = 0;
        // refundedValidatorsCount = 0;
        // stuckPenaltyEndTimestamp = 0;
        totalExitedValidators = no.totalExitedKeys;
        totalDepositedValidators = no.totalDepositedKeys;
        depositableValidatorsCount = no.depositableValidatorsCount;
    }

    /// @inheritdoc ICSModule
    function getNodeOperatorTotalDepositedKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256 totalDepositedKeys) {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        totalDepositedKeys = no.totalDepositedKeys;
    }

    /// @inheritdoc ICSModule
    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory) {
        _onlyValidIndexRange(nodeOperatorId, startIndex, keysCount);

        return SigningKeys.loadKeys(nodeOperatorId, startIndex, keysCount);
    }

    /// @inheritdoc ICSModule
    function getSigningKeysWithSignatures(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory keys, bytes memory signatures) {
        _onlyValidIndexRange(nodeOperatorId, startIndex, keysCount);

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

    /// @inheritdoc IStakingModule
    function getNodeOperatorsCount() external view returns (uint256) {
        return _nodeOperatorsCount;
    }

    /// @inheritdoc IStakingModule
    function getActiveNodeOperatorsCount() external view returns (uint256) {
        return _nodeOperatorsCount;
    }

    /// @inheritdoc IStakingModule
    function getNodeOperatorIsActive(
        uint256 nodeOperatorId
    ) external view returns (bool) {
        return nodeOperatorId < _nodeOperatorsCount;
    }

    /// @inheritdoc IStakingModule
    function getNodeOperatorIds(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory nodeOperatorIds) {
        uint256 nodeOperatorsCount = _nodeOperatorsCount;
        if (offset >= nodeOperatorsCount || limit == 0) {
            return new uint256[](0);
        }

        uint256 idsCount = limit < nodeOperatorsCount - offset
            ? limit
            : nodeOperatorsCount - offset;
        nodeOperatorIds = new uint256[](idsCount);
        for (uint256 i = 0; i < nodeOperatorIds.length; ++i) {
            nodeOperatorIds[i] = offset + i;
        }
    }

    /// @inheritdoc IStakingModule
    function isValidatorExitDelayPenaltyApplicable(
        uint256 /* _nodeOperatorId */,
        uint256 /* _proofSlotTimestamp */,
        bytes calldata /* _publicKey */,
        uint256 /* _eligibleToExitInSec */
    ) external view returns (bool) {
        return false;
    }

    /// @inheritdoc IStakingModule
    function exitDeadlineThreshold(
        uint256 nodeOperatorId
    ) external view returns (uint256) {
        return
            PARAMETERS_REGISTRY.getAllowedExitDelay(
                accounting.getBondCurveId(nodeOperatorId)
            );
    }

    function _incrementModuleNonce() internal {
        unchecked {
            ++_nonce;
        }
        emit NonceChanged(_nonce);
    }

    function _addKeysAndUpdateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint256 totalAddedKeys = no.totalAddedKeys;

        uint256 curveId = accounting.getBondCurveId(nodeOperatorId);
        uint256 keysLimit = PARAMETERS_REGISTRY.getKeysLimit(curveId);

        if (totalAddedKeys + keysCount - no.totalExitedKeys > keysLimit) {
            revert KeysLimitExceeded();
        }

        // solhint-disable-next-line func-named-parameters
        SigningKeys.saveKeysSigs(
            nodeOperatorId,
            totalAddedKeys,
            keysCount,
            publicKeys,
            signatures
        );
        unchecked {
            // Optimistic vetting takes place.
            if (totalAddedKeys == no.totalVettedKeys) {
                // @dev No need to safe cast due to internal logic
                uint32 totalVettedKeys = no.totalVettedKeys + uint32(keysCount);
                no.totalVettedKeys = totalVettedKeys;
                emit VettedSigningKeysCountChanged(
                    nodeOperatorId,
                    totalVettedKeys
                );
            }

            totalAddedKeys += keysCount;

            // @dev No need to safe cast due to internal logic
            no.totalAddedKeys = uint32(totalAddedKeys);
        }
        emit TotalSigningKeysCountChanged(nodeOperatorId, totalAddedKeys);

        // Nonce is updated below since in case of target limit depositable keys might not change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false
        });
        _incrementModuleNonce();
    }

    /// @dev Update exited validators count for a single Node Operator
    /// @dev Allows decrease the count for unsafe updates
    function _updateExitedValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsCount,
        bool allowDecrease
    ) internal {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint32 totalExitedKeys = no.totalExitedKeys;
        if (exitedValidatorsCount == totalExitedKeys) {
            return;
        }
        if (exitedValidatorsCount > no.totalDepositedKeys) {
            revert ExitedKeysHigherThanTotalDeposited();
        }
        if (!allowDecrease && exitedValidatorsCount < totalExitedKeys) {
            revert ExitedKeysDecrease();
        }

        unchecked {
            // @dev No need to safe cast due to conditions above
            _totalExitedValidators =
                (_totalExitedValidators - totalExitedKeys) +
                uint64(exitedValidatorsCount);
        }
        // @dev No need to safe cast due to conditions above
        no.totalExitedKeys = uint32(exitedValidatorsCount);

        emit ExitedSigningKeysCountChanged(
            nodeOperatorId,
            exitedValidatorsCount
        );
    }

    function _updateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        bool incrementNonceIfUpdated
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        uint32 totalDepositedKeys = no.totalDepositedKeys;
        uint256 newCount = no.totalVettedKeys - totalDepositedKeys;
        uint256 unbondedKeys = accounting.getUnbondedKeysCount(nodeOperatorId);

        {
            uint256 nonDeposited = no.totalAddedKeys - totalDepositedKeys;
            if (unbondedKeys >= nonDeposited) {
                newCount = 0;
            } else if (unbondedKeys > no.totalAddedKeys - no.totalVettedKeys) {
                newCount = nonDeposited - unbondedKeys;
            }
        }

        if (no.targetLimitMode > 0 && newCount > 0) {
            unchecked {
                uint256 nonWithdrawnValidators = totalDepositedKeys -
                    no.totalWithdrawnKeys;
                newCount = Math.min(
                    no.targetLimit > nonWithdrawnValidators
                        ? no.targetLimit - nonWithdrawnValidators
                        : 0,
                    newCount
                );
            }
        }

        if (no.depositableValidatorsCount != newCount) {
            // Updating the global counter.
            // @dev No need to safe cast due to internal logic
            unchecked {
                _depositableValidatorsCount =
                    _depositableValidatorsCount -
                    no.depositableValidatorsCount +
                    uint64(newCount);
            }
            // @dev No need to safe cast due to internal logic
            no.depositableValidatorsCount = uint32(newCount);
            emit DepositableSigningKeysCountChanged(nodeOperatorId, newCount);
            if (incrementNonceIfUpdated) {
                _incrementModuleNonce();
            }
            _enqueueNodeOperatorKeys(nodeOperatorId);
        }
    }

    function _enqueueNodeOperatorKeys(uint256 nodeOperatorId) internal {
        uint256 curveId = accounting.getBondCurveId(nodeOperatorId);
        (uint32 priority, uint32 maxDeposits) = PARAMETERS_REGISTRY
            .getQueueConfig(curveId);
        // Replace QUEUE_LEGACY_PRIORITY with QUEUE_LOWEST_PRIORITY after legacy queue removal in CSM v3
        if (priority < QUEUE_LEGACY_PRIORITY) {
            NodeOperator storage no = _nodeOperators[nodeOperatorId];
            uint32 enqueuedSoFar = no.totalDepositedKeys + no.enqueuedCount;

            if (maxDeposits > enqueuedSoFar) {
                uint32 leftForQueue = maxDeposits - enqueuedSoFar;
                _enqueueNodeOperatorKeys(
                    nodeOperatorId,
                    priority,
                    leftForQueue
                );
                no.usedPriorityQueue = true;
            }
        }

        _enqueueNodeOperatorKeys(
            nodeOperatorId,
            QUEUE_LOWEST_PRIORITY,
            type(uint32).max
        );
    }

    function _enqueueNodeOperatorKeys(
        uint256 nodeOperatorId,
        uint256 queuePriority,
        uint32 maxKeys
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint32 depositable = no.depositableValidatorsCount;
        uint32 enqueued = no.enqueuedCount;

        if (enqueued < depositable) {
            uint32 count;

            unchecked {
                count = depositable - enqueued;
                if (count > maxKeys) {
                    count = maxKeys;
                }

                no.enqueuedCount = enqueued + count;
            }

            QueueLib.Queue storage q = _getQueue(queuePriority);
            q.enqueue(nodeOperatorId, count);
            emit BatchEnqueued(queuePriority, nodeOperatorId, count);
        }
    }

    /// @dev Acts as a proxy to `_queueByPriority` till `legacyQueue` deprecation.
    /// @dev TODO: Remove in CSM v3.
    function _getQueue(
        uint256 priority
    ) internal view returns (QueueLib.Queue storage q) {
        if (priority == QUEUE_LEGACY_PRIORITY) {
            assembly {
                q.slot := legacyQueue.slot
            }
        } else {
            q = _queueByPriority[priority];
        }
    }

    function _checkCanAddKeys(
        uint256 nodeOperatorId,
        address who
    ) internal view {
        // Most likely a direct call, so check the sender is a manager.
        if (who == msg.sender) {
            _onlyNodeOperatorManager(nodeOperatorId, msg.sender);
        } else {
            // We're trying to add keys via gate, check if we can do it.
            _checkRole(CREATE_NODE_OPERATOR_ROLE);
            if (_nodeOperators[nodeOperatorId].totalAddedKeys > 0) {
                revert NodeOperatorHasKeys();
            }
        }
    }

    function _onlyNodeOperatorManager(
        uint256 nodeOperatorId,
        address from
    ) internal view {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) {
            revert NodeOperatorDoesNotExist();
        }

        if (no.managerAddress != from) {
            revert SenderIsNotEligible();
        }
    }

    function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view {
        if (nodeOperatorId < _nodeOperatorsCount) {
            return;
        }

        revert NodeOperatorDoesNotExist();
    }

    function _onlyValidIndexRange(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) internal view {
        if (
            startIndex + keysCount >
            _nodeOperators[nodeOperatorId].totalAddedKeys
        ) {
            revert SigningKeysInvalidOffset();
        }
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
