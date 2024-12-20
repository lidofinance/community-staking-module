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
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";
import { ICSModule, NodeOperator, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";

import { QueueLib, Batch } from "./lib/QueueLib.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";
import { NOAddresses } from "./lib/NOAddresses.sol";

import { SigningKeys } from "./lib/SigningKeys.sol";
import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";

contract CSModule is
    ICSModule,
    IStakingModule,
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

    uint256 private constant DEPOSIT_SIZE = 32 ether;
    // @dev see IStakingModule.sol
    uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2;

    uint256 public immutable INITIAL_SLASHING_PENALTY;
    uint256 public immutable EL_REWARDS_STEALING_ADDITIONAL_FINE;
    uint256
        public immutable MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE;
    uint256 public immutable MAX_KEY_REMOVAL_CHARGE;
    bytes32 private immutable MODULE_TYPE;
    ILidoLocator public immutable LIDO_LOCATOR;
    IStETH public immutable STETH;

    ////////////////////////
    // State variables below
    ////////////////////////
    uint256 public keyRemovalCharge;

    QueueLib.Queue public depositQueue;

    ICSAccounting public accounting;

    ICSEarlyAdoption public earlyAdoption;
    bool public publicRelease;

    uint256 private _nonce;
    mapping(uint256 => NodeOperator) private _nodeOperators;
    // @dev see _keyPointer function for details of noKeyIndexPacked structure
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorWithdrawn;
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorSlashed;

    uint64 private _totalDepositedValidators;
    uint64 private _totalExitedValidators;
    uint64 private _depositableValidatorsCount;
    uint64 private _nodeOperatorsCount;

    constructor(
        bytes32 moduleType,
        uint256 minSlashingPenaltyQuotient,
        uint256 elRewardsStealingAdditionalFine,
        uint256 maxKeysPerOperatorEA,
        uint256 maxKeyRemovalCharge,
        address lidoLocator
    ) {
        if (lidoLocator == address(0)) revert ZeroLocatorAddress();

        MODULE_TYPE = moduleType;
        INITIAL_SLASHING_PENALTY = DEPOSIT_SIZE / minSlashingPenaltyQuotient;
        EL_REWARDS_STEALING_ADDITIONAL_FINE = elRewardsStealingAdditionalFine;
        MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE = maxKeysPerOperatorEA;
        MAX_KEY_REMOVAL_CHARGE = maxKeyRemovalCharge;
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        STETH = IStETH(LIDO_LOCATOR.lido());

        _disableInitializers();
    }

    /// @notice initialize the module
    function initialize(
        address _accounting,
        address _earlyAdoption,
        uint256 _keyRemovalCharge,
        address admin
    ) external initializer {
        if (_accounting == address(0)) revert ZeroAccountingAddress();
        if (admin == address(0)) revert ZeroAdminAddress();

        __AccessControlEnumerable_init();

        accounting = ICSAccounting(_accounting);
        // it is possible to deploy module without EA contract
        earlyAdoption = ICSEarlyAdoption(_earlyAdoption);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(STAKING_ROUTER_ROLE, address(LIDO_LOCATOR.stakingRouter()));

        _setKeyRemovalCharge(_keyRemovalCharge);
        // CSM is on pause initially and should be resumed during the vote
        _pauseFor(PausableUntil.PAUSE_INFINITELY);
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
    function activatePublicRelease() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (publicRelease) revert AlreadyActivated();
        publicRelease = true;
        emit PublicRelease();
    }

    /// @inheritdoc ICSModule
    function setKeyRemovalCharge(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setKeyRemovalCharge(amount);
    }

    /// @inheritdoc ICSModule
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        bytes32[] calldata eaProof,
        address referrer
    ) external payable whenResumed {
        (uint256 nodeOperatorId, uint256 curveId) = _createNodeOperator(
            managementProperties,
            referrer,
            eaProof
        );

        if (
            msg.value < accounting.getBondAmountByKeysCount(keysCount, curveId)
        ) {
            revert InvalidAmount();
        }

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata eaProof,
        address referrer
    ) external whenResumed {
        (uint256 nodeOperatorId, uint256 curveId) = _createNodeOperator(
            managementProperties,
            referrer,
            eaProof
        );

        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            curveId
        );
        accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata eaProof,
        address referrer
    ) external whenResumed {
        (uint256 nodeOperatorId, uint256 curveId) = _createNodeOperator(
            managementProperties,
            referrer,
            eaProof
        );

        uint256 amount = accounting.getBondAmountByKeysCountWstETH(
            keysCount,
            curveId
        );
        accounting.depositWstETH(msg.sender, nodeOperatorId, amount, permit);

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addValidatorKeysETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable whenResumed {
        _onlyNodeOperatorManager(nodeOperatorId);

        if (
            msg.value <
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount)
        ) {
            revert InvalidAmount();
        }

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addValidatorKeysStETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        _onlyNodeOperatorManager(nodeOperatorId);

        uint256 amount = accounting.getRequiredBondForNextKeys(
            nodeOperatorId,
            keysCount
        );

        accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function addValidatorKeysWstETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external whenResumed {
        _onlyNodeOperatorManager(nodeOperatorId);

        uint256 amount = accounting.getRequiredBondForNextKeysWstETH(
            nodeOperatorId,
            keysCount
        );

        accounting.depositWstETH(msg.sender, nodeOperatorId, amount, permit);

        _addKeysAndUpdateDepositableValidatorsCount(
            nodeOperatorId,
            keysCount,
            publicKeys,
            signatures
        );
    }

    /// @inheritdoc ICSModule
    function depositETH(uint256 nodeOperatorId) external payable {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        ICSAccounting.PermitInput calldata permit
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.depositStETH(
            msg.sender,
            nodeOperatorId,
            stETHAmount,
            permit
        );

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
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
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] calldata rewardsProof
    ) external {
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
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] calldata rewardsProof
    ) external {
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
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
    function claimRewardsUnstETH(
        uint256 nodeOperatorId,
        uint256 stEthAmount,
        uint256 cumulativeFeeShares,
        bytes32[] calldata rewardsProof
    ) external {
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
            incrementNonceIfUpdated: true
        });
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
    /// @dev If the stuck keys count is above zero for the Node Operator,
    ///      the depositable validators count is set to 0 for this Node Operator
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
            _updateStuckValidatorsCount(nodeOperatorId, stuckValidatorsCount);
        }
        _incrementModuleNonce();
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
    /// @dev Always reverts. Non supported in CSM
    /// @dev `refundedValidatorsCount` is not used in the module
    function updateRefundedValidatorsCount(
        uint256 /* nodeOperatorId */,
        uint256 /* refundedValidatorsCount */
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        revert NotSupported();
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
        ) return;

        if (no.targetLimitMode != targetLimitMode) {
            // @dev No need to safe cast due to conditions above
            no.targetLimitMode = uint8(targetLimitMode);
        }

        if (no.targetLimit != targetLimit) {
            // @dev No need to safe cast due to conditions above
            no.targetLimit = uint32(targetLimit);
        }

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
        _updateExitedValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            exitedValidatorsCount: exitedValidatorsKeysCount,
            allowDecrease: true
        });
        _updateStuckValidatorsCount(nodeOperatorId, stuckValidatorsKeysCount);
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
        _onlyNodeOperatorManager(nodeOperatorId);
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
        uint256 amountToCharge = keyRemovalCharge * keysCount;
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

    /// @inheritdoc ICSModule
    function normalizeQueue(uint256 nodeOperatorId) external {
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
        // Direct call of `normalize` if depositable is not changed
        depositQueue.normalize(_nodeOperators, nodeOperatorId);
    }

    /// @inheritdoc ICSModule
    function reportELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        bytes32 blockHash,
        uint256 amount
    ) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        if (amount == 0) revert InvalidAmount();
        accounting.lockBondETH(
            nodeOperatorId,
            amount + EL_REWARDS_STEALING_ADDITIONAL_FINE
        );
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
        _onlyNodeOperatorManager(nodeOperatorId);
        accounting.compensateLockedBondETH{ value: msg.value }(nodeOperatorId);
        // Nonce should be updated if depositableValidators change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
        emit ELRewardsStealingPenaltyCompensated(nodeOperatorId, msg.value);
    }

    /// @inheritdoc ICSModule
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount,
        bool isSlashed
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
        unchecked {
            ++no.totalWithdrawnKeys;
        }

        bytes memory pubkey = SigningKeys.loadKeys(nodeOperatorId, keyIndex, 1);
        emit WithdrawalSubmitted(nodeOperatorId, keyIndex, amount, pubkey);

        if (isSlashed) {
            if (_isValidatorSlashed[pointer]) {
                // Account already burned value
                unchecked {
                    amount += INITIAL_SLASHING_PENALTY;
                }
            } else {
                _isValidatorSlashed[pointer] = true;
            }
            // Bond curve should be reset to default in case of slashing. See https://hackmd.io/@lido/SygBLW5ja
            accounting.resetBondCurve(nodeOperatorId);
        }

        if (DEPOSIT_SIZE > amount) {
            unchecked {
                accounting.penalize(nodeOperatorId, DEPOSIT_SIZE - amount);
            }
        }

        // Nonce should be updated if depositableValidators change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc ICSModule
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

        if (_isValidatorSlashed[pointer]) {
            revert AlreadySubmitted();
        }

        _isValidatorSlashed[pointer] = true;

        bytes memory pubkey = SigningKeys.loadKeys(nodeOperatorId, keyIndex, 1);
        emit InitialSlashingSubmitted(nodeOperatorId, keyIndex, pubkey);

        accounting.penalize(nodeOperatorId, INITIAL_SLASHING_PENALTY);

        // Nonce should be updated if depositableValidators change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true
        });
    }

    /// @inheritdoc IStakingModule
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
        if (depositsCount == 0) return (publicKeys, signatures);

        uint256 depositsLeft = depositsCount;
        uint256 loadedKeysCount = 0;

        for (
            Batch item = depositQueue.peek();
            !item.isNil();
            item = depositQueue.peek()
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
                    depositQueue.dequeue();
                } else {
                    // This branch covers the case when we stop in the middle of the batch.
                    // We release the amount of keys consumed only, the rest will be kept.
                    // @dev No need to safe cast due to internal logic
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
                // @dev No need to safe cast due to internal logic
                no.totalDepositedKeys += uint32(keysCount);

                emit DepositedSigningKeysCountChanged(
                    noId,
                    no.totalDepositedKeys
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
        (removed, lastRemovedAtDepth) = depositQueue.clean(
            _nodeOperators,
            maxItems
        );
    }

    /// @inheritdoc ICSModule
    function depositQueueItem(uint128 index) external view returns (Batch) {
        return depositQueue.at(index);
    }

    /// @inheritdoc ICSModule
    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorSlashed[_keyPointer(nodeOperatorId, keyIndex)];
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

    /// @dev DEPRECATED. Use `EL_REWARDS_STEALING_ADDITIONAL_FINE` instead
    // solhint-disable func-name-mixedcase
    function EL_REWARDS_STEALING_FINE() external view returns (uint256) {
        return EL_REWARDS_STEALING_ADDITIONAL_FINE;
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
        stuckValidatorsCount = no.stuckValidatorsCount;
        // @dev unused in CSM
        refundedValidatorsCount = 0;
        // @dev unused in CSM
        stuckPenaltyEndTimestamp = 0;
        totalExitedValidators = no.totalExitedKeys;
        totalDepositedValidators = no.totalDepositedKeys;
        depositableValidatorsCount = no.depositableValidatorsCount;
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
            ++_nonce;
        }
        emit NonceChanged(_nonce);
    }

    function _createNodeOperator(
        NodeOperatorManagementProperties calldata managementProperties,
        address referrer,
        bytes32[] calldata proof
    ) internal returns (uint256 noId, uint256 curveId) {
        if (!publicRelease) {
            if (proof.length == 0 || address(earlyAdoption) == address(0)) {
                revert NotAllowedToJoinYet();
            }
        }

        noId = _nodeOperatorsCount;
        NodeOperator storage no = _nodeOperators[noId];

        no.managerAddress = managementProperties.managerAddress == address(0)
            ? msg.sender
            : managementProperties.managerAddress;
        no.rewardAddress = managementProperties.rewardAddress == address(0)
            ? msg.sender
            : managementProperties.rewardAddress;
        if (managementProperties.extendedManagerPermissions)
            no.extendedManagerPermissions = managementProperties
                .extendedManagerPermissions;

        unchecked {
            ++_nodeOperatorsCount;
        }

        emit NodeOperatorAdded(noId, no.managerAddress, no.rewardAddress);

        if (referrer != address(0)) emit ReferrerSet(noId, referrer);

        // @dev It's possible to join with proof even after public release to get beneficial bond curve
        if (proof.length != 0 && address(earlyAdoption) != address(0)) {
            earlyAdoption.consume(msg.sender, proof);
            curveId = earlyAdoption.CURVE_ID();
            accounting.setBondCurve(noId, curveId);
        } else {
            curveId = accounting.DEFAULT_BOND_CURVE_ID();
        }
    }

    function _addKeysAndUpdateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        uint256 startIndex = no.totalAddedKeys;
        unchecked {
            // startIndex + keysCount can't overflow because of deposit check in the parent methods
            if (
                !publicRelease &&
                startIndex + keysCount >
                MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE
            ) {
                revert MaxSigningKeysCountExceeded();
            }
        }

        // solhint-disable-next-line func-named-parameters
        SigningKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            publicKeys,
            signatures
        );
        unchecked {
            // Optimistic vetting takes place.
            if (no.totalAddedKeys == no.totalVettedKeys) {
                // @dev No need to safe cast due to internal logic
                no.totalVettedKeys += uint32(keysCount);
                emit VettedSigningKeysCountChanged(
                    nodeOperatorId,
                    no.totalVettedKeys
                );
            }

            // @dev No need to safe cast due to internal logic
            no.totalAddedKeys += uint32(keysCount);
        }
        emit TotalSigningKeysCountChanged(nodeOperatorId, no.totalAddedKeys);

        // Nonce is updated below since in case of stuck keys depositable keys might not change
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false
        });
        _incrementModuleNonce();
    }

    function _setKeyRemovalCharge(uint256 amount) internal {
        if (amount > MAX_KEY_REMOVAL_CHARGE) revert InvalidInput();
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
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (exitedValidatorsCount == no.totalExitedKeys) return;
        if (exitedValidatorsCount > no.totalDepositedKeys)
            revert ExitedKeysHigherThanTotalDeposited();
        if (!allowDecrease && exitedValidatorsCount < no.totalExitedKeys)
            revert ExitedKeysDecrease();
        unchecked {
            // @dev No need to safe cast due to conditions above
            _totalExitedValidators =
                (_totalExitedValidators - no.totalExitedKeys) +
                uint64(exitedValidatorsCount);
        }
        // @dev No need to safe cast due to conditions above
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
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (stuckValidatorsCount == no.stuckValidatorsCount) return;
        unchecked {
            if (
                stuckValidatorsCount >
                no.totalDepositedKeys - no.totalExitedKeys
            ) revert StuckKeysHigherThanNonExited();
        }

        // @dev No need to safe cast due to conditions above
        no.stuckValidatorsCount = uint32(stuckValidatorsCount);
        emit StuckSigningKeysCountChanged(nodeOperatorId, stuckValidatorsCount);

        if (stuckValidatorsCount > 0 && no.depositableValidatorsCount > 0) {
            // INFO: The only consequence of stuck keys from the on-chain perspective is suspending deposits to the
            // Node Operator. To do that, we set the depositableValidatorsCount to 0 for this Node Operator. Hence
            // we can omit the call to the _updateDepositableValidatorsCount function here to save gas.
            unchecked {
                _depositableValidatorsCount -= no.depositableValidatorsCount;
            }
            no.depositableValidatorsCount = 0;
            emit DepositableSigningKeysCountChanged(nodeOperatorId, 0);
        } else {
            // Nonce will be updated on the top level once per call
            _updateDepositableValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                incrementNonceIfUpdated: false
            });
        }
    }

    function _updateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        bool incrementNonceIfUpdated
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        uint256 newCount = no.totalVettedKeys - no.totalDepositedKeys;
        uint256 unbondedKeys = accounting.getUnbondedKeysCount(nodeOperatorId);

        {
            uint256 nonDeposited = no.totalAddedKeys - no.totalDepositedKeys;
            if (unbondedKeys >= nonDeposited) {
                newCount = 0;
            } else if (unbondedKeys > no.totalAddedKeys - no.totalVettedKeys) {
                newCount = nonDeposited - unbondedKeys;
            }
        }

        if (no.stuckValidatorsCount > 0 && newCount > 0) {
            newCount = 0;
        }

        if (no.targetLimitMode > 0 && newCount > 0) {
            unchecked {
                uint256 nonWithdrawnValidators = no.totalDepositedKeys -
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
            depositQueue.normalize(_nodeOperators, nodeOperatorId);
        }
    }

    function _onlyNodeOperatorManager(uint256 nodeOperatorId) internal view {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.managerAddress != msg.sender) revert SenderIsNotEligible();
    }

    function _onlyNodeOperatorManagerOrRewardAddresses(
        uint256 nodeOperatorId
    ) internal view {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.managerAddress != msg.sender && no.rewardAddress != msg.sender)
            revert SenderIsNotEligible();
    }

    function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view {
        if (nodeOperatorId < _nodeOperatorsCount) return;
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
