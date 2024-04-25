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

import { QueueLib, Batch, createBatch } from "./lib/QueueLib.sol";
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

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE"); // 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE"); // 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7
    bytes32 public constant MODULE_MANAGER_ROLE =
        keccak256("MODULE_MANAGER_ROLE"); // 0x79dfcec784e591aafcf60db7db7b029a5c8b12aac4afd4e8c4eb740430405fa6
    bytes32 public constant STAKING_ROUTER_ROLE =
        keccak256("STAKING_ROUTER_ROLE"); // 0xbb75b874360e0bfd87f964eadd8276d8efb7c942134fc329b513032d0803e0c6
    bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE"); // 0x59911a6aa08a72fe3824aec4500dc42335c6d0702b6d5c5c72ceb265a0de9302
    bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE =
        keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE"); // 0xe85fdec10fe0f93d0792364051df7c3d73e37c17b3a954bffe593960e3cd3012
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); // 0x0ce23c3e399818cfee81a7ab0880f714e53d7672b08df0fa62f2843416e1ea09
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE"); // 0xb3e25b5404b87e5a838579cb5d7481d61ad96ee284d38ec1e97c07ba64e7f6fc

    uint256 public constant DEPOSIT_SIZE = 32 ether;
    uint256 private constant MIN_SLASHING_PENALTY_QUOTIENT = 32; // TODO: consider to move to immutable variable
    uint256 public constant INITIAL_SLASHING_PENALTY =
        DEPOSIT_SIZE / MIN_SLASHING_PENALTY_QUOTIENT;
    uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2;

    uint256 public immutable EL_REWARDS_STEALING_FINE;
    uint256
        public immutable MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE;
    bytes32 private immutable MODULE_TYPE;
    ILidoLocator public immutable LIDO_LOCATOR;

    bool public publicRelease;
    uint256 public keyRemovalCharge;
    QueueLib.Queue public queue; // TODO: depositQueue? public?

    ICSAccounting public accounting;
    ICSEarlyAdoption public earlyAdoption;
    // @dev max number of node operators is limited by uint64 due to Batch serialization in 32 bytes
    // it seems to be enough
    // TODO: ^^ comment
    uint256 private _nodeOperatorsCount; // TODO: pack more efficinetly
    uint256 private _activeNodeOperatorsCount;
    uint256 private _nonce;
    mapping(uint256 => NodeOperator) private _nodeOperators;
    mapping(uint256 noIdWithKeyIndex => bool) private _isValidatorWithdrawn; // TODO: noIdWithKeyIndex naming
    mapping(uint256 noIdWithKeyIndex => bool) private _isValidatorSlashed;

    uint256 private _totalDepositedValidators; // TODO: think about more efficient way to store this
    uint256 private _totalExitedValidators;
    uint256 private _totalAddedValidators;
    uint256 private _depositableValidatorsCount;
    uint256 private _totalRewardsShares;

    TransientUintUintMap private _queueLookup;

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

    // TODO: do we want event for queue cursor moving as well?
    event BatchEnqueued(uint256 indexed nodeOperatorId, uint256 count);

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
    error StuckKeysHigherThanTotalDepositedMinusTotalExited();
    error ExitedKeysHigherThanTotalDeposited();
    error ExitedKeysDecrease();

    error QueueLookupNoLimit();
    error NotEnoughKeys();

    error SigningKeysInvalidOffset();

    error AlreadySubmitted();

    error AlreadySet();
    error InvalidAmount();
    error NotAllowedToJoinYet();
    error MaxSigningKeysCountExceeded();

    constructor(
        bytes32 moduleType,
        uint256 elStealingFine,
        uint256 maxKeysPerOperatorEA,
        address lidoLocator
    ) {
        MODULE_TYPE = moduleType;
        EL_REWARDS_STEALING_FINE = elStealingFine;
        MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE = maxKeysPerOperatorEA;
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
    }

    function initialize(
        address _accounting,
        address _earlyAdoption,
        address verifier,
        address admin
    ) external initializer {
        __AccessControlEnumerable_init();

        accounting = ICSAccounting(_accounting);
        earlyAdoption = ICSEarlyAdoption(_earlyAdoption);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFIER_ROLE, verifier);
        _grantRole(STAKING_ROUTER_ROLE, address(LIDO_LOCATOR.stakingRouter()));

        // CSM is on pause initially and should be resumed by voting
        _pauseFor(type(uint256).max);
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

    function activatePublicRelease() external onlyRole(MODULE_MANAGER_ROLE) {
        if (publicRelease) {
            revert AlreadySet();
        }
        publicRelease = true;
        emit PublicRelease();
    }

    /// @notice Sets the key deletion fine
    /// @param amount Amount of wei to be charged for removing a single key.
    function setKeyRemovalCharge(
        uint256 amount
    ) external onlyRole(MODULE_MANAGER_ROLE) {
        // TODO: think about limits
        _setKeyRemovalCharge(amount);
    }

    function _setKeyRemovalCharge(uint256 amount) internal {
        keyRemovalCharge = amount;
        emit KeyRemovalChargeSet(amount);
    }

    /// @notice Gets the module type
    /// @return Module type
    function getType() external view returns (bytes32) {
        return MODULE_TYPE;
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
    /// @param signatures Signatures of (deposit_message_root, domain) tuples.
    ///                   https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#signingdata
    /// @param managerAddress Optional. Used as managerAddress for the Node Operator. If not passed msg.sender will be used
    /// @param rewardAddress Optional. Used as rewardAddress for the Node Operator. If not passed msg.sender will be used
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
        _checkEarlyAdoptionEligibility(nodeOperatorId, eaProof);

        if (
            msg.value !=
            accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            )
        ) {
            revert InvalidAmount();
        }

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Adds a new node operator with stETH bond
    /// @notice Due to the stETH rouding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of (deposit_message_root, domain) tuples.
    ///                   https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#signingdata
    /// @param managerAddress Optional. Used as managerAddress for the Node Operator. If not passed msg.sender will be used
    /// @param rewardAddress Optional. Used as rewardAddress for the Node Operator. If not passed msg.sender will be used
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
        _checkEarlyAdoptionEligibility(nodeOperatorId, eaProof);

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        {
            uint256 amount = accounting.getBondAmountByKeysCount(
                keysCount,
                accounting.getBondCurve(nodeOperatorId)
            );
            accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);
        }

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Adds a new node operator with wstETH bond
    /// @notice Due to the stETH rouding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of (deposit_message_root, domain) tuples.
    ///                   https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#signingdata
    /// @param managerAddress Optional. Used as managerAddress for the Node Operator. If not passed msg.sender will be used
    /// @param rewardAddress Optional. Used as rewardAddress for the Node Operator. If not passed msg.sender will be used
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
        _checkEarlyAdoptionEligibility(nodeOperatorId, eaProof);

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

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

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Adds a new keys to the node operator with ETH bond
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of (deposit_message_root, domain) tuples.
    ///                   https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#signingdata
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

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Adds a new keys to the node operator with stETH bond
    /// @notice Due to the stETH rouding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of (deposit_message_root, domain) tuples.
    ///                   https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#signingdata
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

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositStETH(msg.sender, nodeOperatorId, amount, permit);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Adds a new keys to the node operator with wstETH bond
    /// @notice Due to the stETH rouding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param nodeOperatorId ID of the node operator
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of (deposit_message_root, domain) tuples.
    ///                   https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#signingdata
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

        // Reverts if keysCount is 0
        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);

        accounting.depositWstETH(msg.sender, nodeOperatorId, amount, permit);

        // Due to new bonded keys nonce update is required and normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Stake user's ETH to Lido and make deposit in stETH to the bond
    /// @param nodeOperatorId id of the node operator to stake ETH and deposit stETH for
    function depositETH(uint256 nodeOperatorId) external payable {
        _onlyExistingNodeOperator(nodeOperatorId);
        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        // Due to new bond nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param stETHAmount amount of stETH to deposit
    /// @param permit Optional. Permit to use stETH as bond
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
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param wstETHAmount amount of wstETH to deposit
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
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Claims full reward (fee + bond) in stETH for the given node operator with desirable value
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param stETHAmount amount of stETH to claim.
    /// @param cumulativeFeeShares Optional. Cumulative fee shares for the node operator.
    /// @param rewardsProof Optional. Merkle proof of the rewards.
    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManagerOrRewardAddresses(nodeOperatorId);

        accounting.claimRewardsStETH(
            nodeOperatorId,
            stETHAmount,
            cumulativeFeeShares,
            rewardsProof
        );

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Claims full reward (fee + bond) in wstETH for the given node operator available for this moment
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param wstETHAmount amount of wstETH to claim.
    /// @param cumulativeFeeShares Optional. Cumulative fee shares for the node operator.
    /// @param rewardsProof Optional. Merkle proof of the rewards.
    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManagerOrRewardAddresses(nodeOperatorId);

        accounting.claimRewardsWstETH(
            nodeOperatorId,
            wstETHAmount,
            cumulativeFeeShares,
            rewardsProof
        );

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Request a full reward (fee + bond) in Withdrawal NFT (unstETH) for the given node operator that is available at this moment.
    /// @notice Amounts less than MIN_STETH_WITHDRAWAL_AMOUNT (see LidoWithdrawalQueue contract) are not allowed
    /// @notice Amounts above MAX_STETH_WITHDRAWAL_AMOUNT should be requested in several transactions
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param ethAmount amount of ETH to request.
    /// @param cumulativeFeeShares Optional. Cumulative fee shares for the node operator.
    /// @param rewardsProof Optional. Merkle proof of the rewards.
    function requestRewardsETH(
        uint256 nodeOperatorId,
        uint256 ethAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManagerOrRewardAddresses(nodeOperatorId);

        accounting.requestRewardsETH(
            nodeOperatorId,
            ethAmount,
            cumulativeFeeShares,
            rewardsProof
        );

        // Due to possible missing bond compensation nonce update might be required and normalize queue might be required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: true
        });
    }

    /// @notice Proposes a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
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

    /// @notice Confirms a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
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
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
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
    ) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        NOAddresses.confirmNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Resets the manager address to the reward address
    /// @param nodeOperatorId ID of the node operator
    function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external {
        _onlyExistingNodeOperator(nodeOperatorId);
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
    ) external view returns (NodeOperator memory) {
        _onlyExistingNodeOperator(nodeOperatorId);
        return _nodeOperators[nodeOperatorId];
    }

    /// @notice Gets node operator non-withdrawn keys
    /// @param nodeOperatorId ID of the node operator
    /// @return Non-withdrawn keys count
    function getNodeOperatorNonWithdrawnKeys(
        uint256 nodeOperatorId
    ) external view returns (uint256) {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        return no.totalAddedKeys - no.totalWithdrawnKeys;
    }

    /// @notice Gets node operator reward address
    /// @param nodeOperatorId ID of the node operator
    /// @return Reward address
    function getNodeOperatorRewardAddress(
        uint256 nodeOperatorId
    ) external view returns (address) {
        _onlyExistingNodeOperator(nodeOperatorId);
        return _nodeOperators[nodeOperatorId].rewardAddress;
    }

    /// @notice Gets node operator summary
    /// @param nodeOperatorId ID of the node operator
    /// @return targetLimitMode Target limit mode
    /// @return targetValidatorsCount Target validators count
    /// @return stuckValidatorsCount Stuck validators count
    /// @return refundedValidatorsCount Refunded validators count
    /// @return stuckPenaltyEndTimestamp Stuck penalty end timestamp
    /// @return totalExitedValidators Total exited validators
    /// @return totalDepositedValidators Total deposited validators
    /// @return depositableValidatorsCount Depositable validators count
    /// @dev depositableValidatorsCount depends on:
    ///      - totalVettedKeys
    ///      - totalDepositedKeys
    ///      - totalExitedKeys
    ///      - targetLimitMode
    ///      - targetValidatorsCount
    function getNodeOperatorSummary(
        uint256 nodeOperatorId
    )
        external
        view
        returns (
            uint8 targetLimitMode,
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
    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory) {
        _onlyExistingNodeOperator(nodeOperatorId);
        if (
            startIndex + keysCount >
            _nodeOperators[nodeOperatorId].totalAddedKeys
        ) {
            revert SigningKeysInvalidOffset();
        }

        return SigningKeys.loadKeys(nodeOperatorId, startIndex, keysCount);
    }

    /// @notice Gets node operator signing keys with signatures
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    /// @param keysCount Count of keys to get
    /// @return keys Signing keys
    /// @return signatures Signatures of (deposit_message, domain) tuples
    function getSigningKeysWithSignatures(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory keys, bytes memory signatures) {
        _onlyExistingNodeOperator(nodeOperatorId);
        if (
            startIndex + keysCount >
            _nodeOperators[nodeOperatorId].totalAddedKeys
        ) {
            revert SigningKeysInvalidOffset();
        }

        // TODO: think about universal interface to interact with loadKeysSigs and loadKeys
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
    function onRewardsMinted(
        uint256 totalShares
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        IStETH(LIDO_LOCATOR.lido()).transferShares(
            accounting.feeDistributor(),
            totalShares
        );
    }

    function _updateDepositableValidatorsCount(
        uint256 nodeOperatorId,
        bool incrementNonceIfUpdated,
        bool normilizeQueueIfUpdated
    ) private {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        uint256 newCount = no.totalVettedKeys - no.totalDepositedKeys;

        // NOTE: Probably this check can be extracted to a separate function to reduce gas costs for the methods
        // requiring only it.
        uint256 unbondedKeys = accounting.getUnbondedKeysCount(nodeOperatorId);
        if (unbondedKeys > newCount) {
            newCount = 0;
        } else {
            unchecked {
                newCount -= unbondedKeys;
            }
        }

        if (no.stuckValidatorsCount > 0) {
            newCount = 0;
        }

        if (no.targetLimitMode > 0) {
            uint256 activeValidators = no.totalDepositedKeys -
                no.totalWithdrawnKeys;
            newCount = Math.min(
                no.targetLimit > activeValidators
                    ? no.targetLimit - activeValidators
                    : 0,
                newCount
            );
        }

        if (no.depositableValidatorsCount != newCount) {
            // Updating the global counter.
            _depositableValidatorsCount =
                _depositableValidatorsCount -
                no.depositableValidatorsCount +
                newCount;
            // TODO: think about event emitting for depositableValidatorsCount changing.
            // Note: it also changes outisde this method
            no.depositableValidatorsCount = newCount;
            if (incrementNonceIfUpdated) {
                _incrementModuleNonce();
            }
            if (normilizeQueueIfUpdated) {
                _normalizeQueue(nodeOperatorId);
            }
        }
    }

    /// @notice Updates stuck validators count for node operators by StakingRouter
    /// @dev If the stuck keys count is above zero, the depositable validators count is set to 0 for this Node Operator
    /// @param nodeOperatorIds bytes packed array of node operator ids
    /// @param stuckValidatorsCounts bytes packed array of stuck validators counts
    function updateStuckValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata stuckValidatorsCounts
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        ValidatorCountsReport.validate(nodeOperatorIds, stuckValidatorsCounts);

        uint256 operatorsInReport = ValidatorCountsReport.count(
            nodeOperatorIds
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

    function _updateStuckValidatorsCount(
        uint256 nodeOperatorId,
        uint256 stuckValidatorsCount
    ) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (stuckValidatorsCount == no.stuckValidatorsCount) return;
        if (stuckValidatorsCount > no.totalDepositedKeys - no.totalExitedKeys)
            revert StuckKeysHigherThanTotalDepositedMinusTotalExited();

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
                incrementNonceIfUpdated: false,
                normilizeQueueIfUpdated: false
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

        uint256 operatorsInReport = ValidatorCountsReport.count(
            nodeOperatorIds
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

    /// @dev updates exited validators count for a single node operator. allows decrease the count for unsafe updates
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
        uint256 refundedValidatorsCount
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        no.refundedValidatorsCount = refundedValidatorsCount;
        emit RefundedKeysCountChanged(nodeOperatorId, refundedValidatorsCount);
        _incrementModuleNonce();
    }

    /// @notice Updates target limits for node operator by StakingRouter
    /// @dev Target limit decreasing (or appearing) must unvet node operator's keys from the queue
    /// @param nodeOperatorId ID of the node operator
    /// @param targetLimitMode Is target limit active for the node operator
    /// @param targetLimit Target limit of validators
    function updateTargetValidatorsLimits(
        uint256 nodeOperatorId,
        uint8 targetLimitMode,
        uint256 targetLimit
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (
            no.targetLimitMode == targetLimitMode &&
            no.targetLimit == targetLimit
        ) return;

        if (no.targetLimitMode != targetLimitMode) {
            no.targetLimitMode = targetLimitMode;
        }

        if (no.targetLimit != targetLimit) {
            no.targetLimit = targetLimit;
        }

        emit TargetValidatorsCountChangedByRequest(
            nodeOperatorId,
            targetLimitMode,
            targetLimit
        );

        // Nonce will be updated below even if depositable count was not changed
        // In case of targetLimit removal queue should be normalised
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normilizeQueueIfUpdated: true
        });
        _incrementModuleNonce();
    }

    /// @notice Called when exited and stuck validators counts updated by StakingRouter
    function onExitedAndStuckValidatorsCountsUpdated()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // solhint-disable-previous-line no-empty-blocks
        // Nothing to do, rewards are distributed by a performance oracle.
    }

    /// @notice Unsafe updates of validators count for node operators by DAO
    function unsafeUpdateValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsKeysCount,
        uint256 stuckValidatorsKeysCount
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);
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
                incrementNonceIfUpdated: false,
                normilizeQueueIfUpdated: false
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

    function normalizeQueue(uint256 nodeOperatorId) external {
        _onlyExistingNodeOperator(nodeOperatorId);
        _onlyNodeOperatorManager(nodeOperatorId);
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
    /// @param blockHash execution layer block hash of the proposed block with EL rewards stealing.
    /// @param amount amount of stolen EL rewards in ETH.
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
            normilizeQueueIfUpdated: false
        });
    }

    /// @notice Cancel EL rewards stealing for the given node operator.
    /// @dev The funds will be unlocked.
    /// @param nodeOperatorId id of the node operator to cancel penalty for.
    /// @param amount amount of cancelled penalty.
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
            normilizeQueueIfUpdated: true
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
            emit ELRewardsStealingPenaltySettled(nodeOperatorId, settled);
            if (settled > 0) {
                accounting.resetBondCurve(nodeOperatorId);
                // Nonce should be updated if depositableValidators change
                // No need to normalize queue due to only decrease in depositable possible
                _updateDepositableValidatorsCount({
                    nodeOperatorId: nodeOperatorId,
                    incrementNonceIfUpdated: true,
                    normilizeQueueIfUpdated: false
                });
            }
        }
    }

    /// @notice Compensate EL rewards stealing penalty for the given node operator to prevent further validator exits.
    /// @param nodeOperatorId id of the node operator.
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
            normilizeQueueIfUpdated: true
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
            normilizeQueueIfUpdated: true
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
        emit InitialSlashingSubmitted(nodeOperatorId, keyIndex);

        accounting.penalize(nodeOperatorId, INITIAL_SLASHING_PENALTY);

        // Nonce should be updated if depositableValidators change
        // Normalize queue should not be called due to only possible decrease in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normilizeQueueIfUpdated: false
        });
    }

    /// @dev both nodeOperatorId and keyIndex are limited to uint64 by the contract.
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }

    /// @notice Called when withdrawal credentials changed by DAO and resets the key removal charge
    /// @dev Changing the WC means that the current keys in the queue are not valid anymore and can't be vetted to deposit
    ///     So, the key removal charge should be reset to 0 to allow the node operator to remove the keys without any charge.
    ///     Then the DAO should set the new key removal charge.
    function onWithdrawalCredentialsChanged()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        _setKeyRemovalCharge(0);
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
            nodeOperatorId,
            startIndex,
            keysCount,
            no.totalAddedKeys
        );

        // We charge the node operator for the every removed key. It's motivated by the fact that the DAO should cleanup
        // the queue from the empty batches of the node operator. It's possible to have multiple batches with only one
        // key in it, so it means the DAO should have remove as much batches as keys removed in this case.
        uint256 amountToCharge = keyRemovalCharge * keysCount;
        accounting.chargeFee(nodeOperatorId, amountToCharge);
        emit KeyRemovalChargeApplied(nodeOperatorId, amountToCharge);

        no.totalAddedKeys = newTotalSigningKeys;
        emit TotalSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        no.totalVettedKeys = newTotalSigningKeys;
        emit VettedSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

        // Nonce is updated below due to keys state change
        // Normalize queue should be called due to possible increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normilizeQueueIfUpdated: true
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

    function recoverStETHShares() external {
        _onlyRecoverer();
        IStETH stETH = IStETH(LIDO_LOCATOR.lido());

        AssetRecovererLib.recoverStETHShares(
            address(stETH),
            stETH.sharesOf(address(this))
        );
    }

    function _incrementModuleNonce() internal {
        _nonce++;
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
        no.active = true;

        unchecked {
            _nodeOperatorsCount++;
            _activeNodeOperatorsCount++;
        }

        emit NodeOperatorAdded(id, no.managerAddress, no.rewardAddress);

        if (referrer != address(0)) emit ReferrerSet(id, referrer);

        return id;
    }

    /// @notice it's possible to join with proof even after public release
    function _checkEarlyAdoptionEligibility(
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
}
