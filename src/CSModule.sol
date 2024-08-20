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
import { ICSModule, NodeOperator, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";

import { QueueLib, Batch } from "./lib/QueueLib.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";
import { NOAddresses } from "./lib/NOAddresses.sol";

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
    // @dev see IStakingModule.sol
    uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2;

    uint256 public immutable INITIAL_SLASHING_PENALTY;
    uint256 public immutable EL_REWARDS_STEALING_FINE;
    uint256
        public immutable MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE;
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
        uint256 amount
    );
    event InitialSlashingSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex
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
    event ELRewardsStealingPenaltySettled(uint256 indexed nodeOperatorId);

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

    constructor(
        bytes32 moduleType,
        uint256 minSlashingPenaltyQuotient,
        uint256 elRewardsStealingFine,
        uint256 maxKeysPerOperatorEA,
        address lidoLocator
    ) {
        if (lidoLocator == address(0)) revert ZeroLocatorAddress();

        MODULE_TYPE = moduleType;
        INITIAL_SLASHING_PENALTY = DEPOSIT_SIZE / minSlashingPenaltyQuotient;
        EL_REWARDS_STEALING_FINE = elRewardsStealingFine;
        MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE = maxKeysPerOperatorEA;
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        STETH = IStETH(LIDO_LOCATOR.lido());

        _disableInitializers();
    }

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

    /// @notice Resume creation of the Node Operators and keys upload
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @notice Pause creation of the Node Operators and keys upload for `duration` seconds.
    ///         Existing NO management and reward claims are still available.
    ///         To pause reward claims use pause method on CSAccounting
    /// @param duration Duration of the pause in seconds
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @notice Activate public release mode
    ///         Enable permissionless creation of the Node Operators
    ///         Remove the keys limit for the Node Operators
    function activatePublicRelease() external onlyRole(MODULE_MANAGER_ROLE) {
        if (publicRelease) {
            revert AlreadyActivated();
        }
        publicRelease = true;
        emit PublicRelease();
    }

    /// @notice Set the key removal charge amount.
    ///         A charge is taken from the bond for each removed key
    /// @param amount Amount of stETH in wei to be charged for removing a single key
    function setKeyRemovalCharge(
        uint256 amount
    ) external onlyRole(MODULE_MANAGER_ROLE) {
        _setKeyRemovalCharge(amount);
    }

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
            msg.value != accounting.getBondAmountByKeysCount(keysCount, curveId)
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

    /// @notice Add new keys to the existing Node Operator using ETH as a bond
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
        _onlyNodeOperatorManager(nodeOperatorId);

        if (
            msg.value !=
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

    /// @notice Stake user's ETH with Lido and make a deposit in stETH to the bond of the existing Node Operator
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

    /// @notice Deposit user's stETH to the bond of the existing Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stETHAmount Amount of stETH to deposit
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
            normalizeQueueIfUpdated: true
        });
    }

    /// @notice Unwrap the user's wstETH and make a deposit in stETH to the bond of the existing Node Operator
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
    /// @notice If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim
    /// @param nodeOperatorId ID of the Node Operator
    /// @param stETHAmount Amount of stETH to claim
    /// @param cumulativeFeeShares Optional. Cumulative fee stETH shares for the Node Operator
    /// @param rewardsProof Optional. Merkle proof of the rewards
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
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

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
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: true
        });
    }

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
        NOAddresses.proposeNodeOperatorManagerAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirm a new manager address for the Node Operator.
    ///         Should be called from the currently proposed address
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId
    ) external {
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
        NOAddresses.proposeNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId,
            proposedAddress
        );
    }

    /// @notice Confirm a new reward address for the Node Operator.
    ///         Should be called from the currently proposed address
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorRewardAddressChange(
        uint256 nodeOperatorId
    ) external {
        NOAddresses.confirmNodeOperatorRewardAddressChange(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Reset the manager address to the reward address.
    ///         Should be called from the reward address
    /// @param nodeOperatorId ID of the Node Operator
    function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external {
        NOAddresses.resetNodeOperatorManagerAddress(
            _nodeOperators,
            nodeOperatorId
        );
    }

    /// @notice Change rewardAddress if extendedManagerPermissions is enabled for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param newAddress Proposed reward address
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

    /// @notice Called when rewards are minted for the module
    /// @dev Called by StakingRouter
    /// @dev Passes through the minted stETH shares to the fee distributor
    function onRewardsMinted(
        uint256 totalShares
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        STETH.transferShares(address(accounting.feeDistributor()), totalShares);
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
            _updateStuckValidatorsCount(nodeOperatorId, stuckValidatorsCount);
        }
        _incrementModuleNonce();
    }

    /// @notice Update exited validators count for Node Operators
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
            _updateExitedValidatorsCount({
                nodeOperatorId: nodeOperatorId,
                exitedValidatorsCount: exitedValidatorsCount,
                allowDecrease: false
            });
        }
        _incrementModuleNonce();
    }

    /// @notice Update refunded validators count for the Node Operator.
    ///         Non supported in CSM
    /// @dev Called by StakingRouter
    /// @dev Always reverts
    /// @dev `refundedValidatorsCount` is not used in the module
    function updateRefundedValidatorsCount(
        uint256 /* nodeOperatorId */,
        uint256 /* refundedValidatorsCount */
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        revert NotSupported();
    }

    /// @notice Update target validators limits for Node Operator
    /// @dev Called by StakingRouter
    /// @param nodeOperatorId ID of the Node Operator
    /// @param targetLimitMode Target limit mode for the Node Operator (see https://hackmd.io/@lido/BJXRTxMRp)
    ///                        0 - disabled
    ///                        1 - soft mode
    ///                        2 - forced mode
    /// @param targetLimit Target limit of validators
    function updateTargetValidatorsLimits(
        uint256 nodeOperatorId,
        uint256 targetLimitMode,
        uint256 targetLimit
    ) external onlyRole(STAKING_ROUTER_ROLE) {
        if (targetLimitMode > type(uint8).max) {
            revert InvalidInput();
        }
        if (targetLimit > type(uint32).max) {
            revert InvalidInput();
        }
        _onlyExistingNodeOperator(nodeOperatorId);
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

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
        // In case of targetLimit removal queue should be normalised
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normalizeQueueIfUpdated: true
        });
        _incrementModuleNonce();
    }

    /// @notice Called when exited and stuck validators counts updated.
    ///         This method is not used in CSM, hence it is empty
    /// @dev Called by StakingRouter
    // @dev for some reason foundry coverage consider this function as not fully covered. Check tests to see it is covered indeed
    function onExitedAndStuckValidatorsCountsUpdated()
        external
        onlyRole(STAKING_ROUTER_ROLE)
    {
        // solhint-disable-previous-line no-empty-blocks
        // Nothing to do, rewards are distributed by a performance oracle.
    }

    /// @notice Unsafe update of validators count for Node Operator by the DAO
    /// @dev Called by StakingRouter
    /// @param nodeOperatorId ID of the Node Operator
    /// @param exitedValidatorsKeysCount Exited validators counts
    /// @param stuckValidatorsKeysCount Stuck validators counts
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

    /// @notice Called to decrease the number of vetted keys for Node Operators with given ids
    /// @dev Called by StakingRouter
    /// @param nodeOperatorIds Bytes packed array of the Node Operator ids
    /// @param vettedSigningKeysCounts Bytes packed array of the new numbers of vetted keys for the Node Operators
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
        // Normalize queue should be called due to possible increase in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normalizeQueueIfUpdated: true
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

    /// @notice Perform queue normalization for the given Node Operator
    /// @notice Normalization stands for adding vetted but not enqueued keys to the queue
    /// @param nodeOperatorId ID of the Node Operator
    function normalizeQueue(uint256 nodeOperatorId) external {
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: false
        });
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

    /// @notice Settle locked bond for the given Node Operators
    /// @dev SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE role is expected to be assigned to Easy Track
    /// @param nodeOperatorIds IDs of the Node Operators
    function settleELRewardsStealingPenalty(
        uint256[] calldata nodeOperatorIds
    ) external onlyRole(SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE) {
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            _onlyExistingNodeOperator(nodeOperatorId);
            uint256 lockedBondBefore = accounting.getActualLockedBond(
                nodeOperatorId
            );

            accounting.settleLockedBondETH(nodeOperatorId);

            // settled amount might be zero either if the lock expired, or the bond is zero
            // so we need to check actual locked bond before to determine if the penalty was settled
            if (lockedBondBefore > 0) {
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
            emit ELRewardsStealingPenaltySettled(nodeOperatorId);
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
    /// @param isSlashed Validator is slashed or not
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

        emit WithdrawalSubmitted(nodeOperatorId, keyIndex, amount);

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

        if (_isValidatorSlashed[pointer]) {
            revert AlreadySubmitted();
        }

        _isValidatorSlashed[pointer] = true;
        emit InitialSlashingSubmitted(nodeOperatorId, keyIndex);

        accounting.penalize(nodeOperatorId, INITIAL_SLASHING_PENALTY);

        // Nonce should be updated if depositableValidators change
        // Normalize queue should not be called due to only decrease in depositable possible
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: true,
            normalizeQueueIfUpdated: false
        });
    }

    /// @notice Called by the Staking Router when withdrawal credentials changed by DAO
    /// @dev Called by StakingRouter
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
    /// @dev Called by StakingRouter
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

    /// @notice Clean the deposit queue from batches with no depositable keys
    /// @dev Use **eth_call** to check how many items will be removed
    /// @param maxItems How many queue items to review
    /// @return removed Count of batches to be removed by visiting `maxItems` batches
    /// @return lastRemovedAtDepth The value to use as `maxItems` to remove `removed` batches if the static call of the method was used
    function cleanDepositQueue(
        uint256 maxItems
    ) external returns (uint256 removed, uint256 lastRemovedAtDepth) {
        (removed, lastRemovedAtDepth) = depositQueue.clean(
            _nodeOperators,
            maxItems
        );
    }

    /// @notice Get the deposit queue item by an index
    /// @param index Index of a queue item
    /// @return Deposit queue item
    function depositQueueItem(uint128 index) external view returns (Batch) {
        return depositQueue.at(index);
    }

    /// @notice Check if the given Node Operator's key is reported as slashed
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the key to check
    /// @return Validator reported as slashed flag
    function isValidatorSlashed(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorSlashed[_keyPointer(nodeOperatorId, keyIndex)];
    }

    /// @notice Check if the given Node Operator's key is reported as withdrawn
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex index of the key to check
    /// @return Validator reported as withdrawn flag
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
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        )
    {
        totalExitedValidators = _totalExitedValidators;
        totalDepositedValidators = _totalDepositedValidators;
        depositableValidatorsCount = _depositableValidatorsCount;
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
        unchecked {
            return no.totalAddedKeys - no.totalWithdrawnKeys;
        }
    }

    /// @notice Get Node Operator summary
    /// @notice depositableValidatorsCount depends on:
    ///      - totalVettedKeys
    ///      - totalDepositedKeys
    ///      - totalExitedKeys
    ///      - targetLimitMode
    ///      - targetValidatorsCount
    ///      - totalUnbondedKeys
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
            totalUnbondedKeys > 0 &&
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
            // No force mode enabled but unbonded
        } else if (totalUnbondedKeys > 0) {
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
        _onlyValidIndexRange(nodeOperatorId, startIndex, keysCount);

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
    /// @return active Operator is active flag
    function getNodeOperatorIsActive(
        uint256 nodeOperatorId
    ) external view returns (bool) {
        return nodeOperatorId < _nodeOperatorsCount;
    }

    /// @notice Get IDs of Node Operators
    /// @param offset Offset of the first Node Operator ID to get
    /// @param limit Count of Node Operator IDs to get
    /// @return nodeOperatorIds IDs of the Node Operators
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
        // Due to new bonded keys normalize queue is required
        _updateDepositableValidatorsCount({
            nodeOperatorId: nodeOperatorId,
            incrementNonceIfUpdated: false,
            normalizeQueueIfUpdated: true
        });
        _incrementModuleNonce();
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
            // Node Operator should normalize queue himself in case of unstuck
            // @dev remind on UI to normalize queue after unstuck
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
            if (normalizeQueueIfUpdated) {
                depositQueue.normalize(_nodeOperators, nodeOperatorId);
            }
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
