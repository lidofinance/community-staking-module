// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";
import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ILido } from "./interfaces/ILido.sol";

import { QueueLib } from "./lib/QueueLib.sol";
import { Batch } from "./lib/Batch.sol";
import { ValidatorCountsReport } from "./lib/ValidatorCountsReport.sol";

import "./lib/SigningKeys.sol";

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
    uint256 totalAddedKeys; // @dev only increased
    uint256 totalWithdrawnKeys; // @dev only increased
    uint256 totalDepositedKeys; // @dev only increased
    uint256 totalVettedKeys; // @dev both increased and decreased
    uint256 stuckValidatorsCount; // @dev both increased and decreased
    uint256 refundedValidatorsCount; // @dev only increased
    uint256 queueNonce;
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

    event BatchEnqueued(
        uint256 indexed nodeOperatorId,
        uint256 startIndex,
        uint256 count
    );

    event StakingModuleTypeSet(bytes32 moduleType);
    event LocatorContractSet(address locatorAddress);
    event UnvettingFeeSet(uint256 unvettingFee);

    event UnvettingFeeApplied(uint256 indexed nodeOperatorId);
    event ELRewardsStealingPenaltyReported(
        uint256 indexed nodeOperatorId,
        uint256 proposedBlockNumber,
        uint256 stolenAmount
    );

    error NodeOperatorDoesNotExist();
    error MaxNodeOperatorsCountReached();
    error SenderIsNotManagerAddress();
    error SenderIsNotRewardAddress();
    error SenderIsNotProposedAddress();
    error SameAddress();
    error AlreadyProposed();
    error InvalidVetKeysPointer();
    error TargetLimitExceeded();
    error StuckKeysPresent();
    error UnbondedKeysPresent();
    error InvalidTargetLimit();
    error StuckKeysHigherThanTotalDeposited();
    error ExitedKeysHigherThanTotalDeposited();
    error ExitedKeysDecrease();

    error QueueLookupNoLimit();
    error QueueEmptyBatch();
    error QueueBatchInvalidNonce(bytes32 batch);
    error QueueBatchInvalidStart(bytes32 batch);
    error QueueBatchInvalidCount(bytes32 batch);
    error QueueBatchUnvettedKeys(bytes32 batch);

    error SigningKeysInvalidOffset();

    error AlreadySubmitted();

    error Expired();
}

contract CSModule is ICSModule, CSModuleBase {
    using QueueLib for QueueLib.Queue;

    // @dev max number of node operators is limited by uint64 due to Batch serialization in 32 bytes
    // it seems to be enough
    uint64 public constant MAX_NODE_OPERATORS_COUNT = type(uint64).max;
    // might be received dynamically in case of increasing possible deposit size
    uint256 public constant DEPOSIT_SIZE = 32 ether;
    uint256 public constant MIN_SLASHING_PENALTY_QUOTIENT = 32;
    uint256 public constant INITIAL_SLASHING_PENALTY =
        DEPOSIT_SIZE / MIN_SLASHING_PENALTY_QUOTIENT;
    bytes32 public constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    uint256 public constant EL_REWARDS_STEALING_FINE = 0.1 ether;

    uint256 private constant ONE_YEAR = 60 * 60 * 24 * 365;

    uint256 private immutable _tempMethodsExpireTime;

    uint256 public unvettingFee;
    QueueLib.Queue public queue;

    ICSAccounting public accounting;
    ILidoLocator public lidoLocator;
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

    constructor(bytes32 moduleType, address locator) {
        _tempMethodsExpireTime = block.timestamp + ONE_YEAR;
        _moduleType = moduleType;
        emit StakingModuleTypeSet(moduleType);

        require(locator != address(0), "lido locator is zero address");
        lidoLocator = ILidoLocator(locator);
        emit LocatorContractSet(locator);
    }

    /// @notice Sets the accounting contract
    /// @param _accounting Address of the accounting contract
    function setAccounting(address _accounting) external {
        // TODO: add role check
        require(address(accounting) == address(0), "already initialized");
        accounting = ICSAccounting(_accounting);
    }

    /// @notice Sets the unvetting fee
    /// @param _unvettingFee Amount of wei to be charged for unvetting in some cases
    function setUnvettingFee(uint256 _unvettingFee) external {
        // TODO: add role check
        unvettingFee = _unvettingFee;
        emit UnvettingFeeSet(_unvettingFee);
    }

    /// @notice Pauses module by DAO decision
    /// @dev Disable NO creation, keys upload
    function pauseModule() external {
        // TODO: implement me
    }

    /// @notice Unpauses module by DAO decision
    /// @dev Enable NO creation, keys upload
    function unpauseModule() external {
        // TODO: implement me
    }

    /// @notice Remove unvetting fee and disable set again
    function removeUnvettingFee() external {
        // TODO: implement me
    }

    function _lido() internal view returns (ILido) {
        return ILido(lidoLocator.lido());
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
        // TODO: need to be implemented properly
        return (
            _totalExitedValidators,
            _totalDepositedValidators,
            _totalAddedValidators - _totalExitedValidators
        );
    }

    /// @notice Adds a new node operator with ETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable {
        // TODO: sanity checks

        require(
            msg.value == accounting.getBondAmountByKeysCount(keysCount),
            "eth value is not equal to required bond"
        );

        uint256 id = _nodeOperatorsCount;
        if (id == MAX_NODE_OPERATORS_COUNT)
            revert MaxNodeOperatorsCountReached();
        NodeOperator storage no = _nodeOperators[id];

        no.managerAddress = msg.sender;
        no.rewardAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        accounting.depositETH{ value: msg.value }(msg.sender, id);

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
    }

    /// @notice Adds a new node operator with stETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external {
        // TODO: sanity checks

        uint256 id = _nodeOperatorsCount;
        if (id == MAX_NODE_OPERATORS_COUNT)
            revert MaxNodeOperatorsCountReached();
        NodeOperator storage no = _nodeOperators[id];

        no.managerAddress = msg.sender;
        no.rewardAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        accounting.depositStETH(
            msg.sender,
            id,
            accounting.getBondAmountByKeysCount(keysCount)
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
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
        ICSAccounting.PermitInput calldata permit
    ) external {
        // TODO: sanity checks

        uint256 id = _nodeOperatorsCount;
        if (id == MAX_NODE_OPERATORS_COUNT)
            revert MaxNodeOperatorsCountReached();
        NodeOperator storage no = _nodeOperators[id];
        no.rewardAddress = msg.sender;
        no.managerAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        accounting.depositStETHWithPermit(
            msg.sender,
            id,
            accounting.getBondAmountByKeysCount(keysCount),
            permit
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
    }

    /// @notice Adds a new node operator with wstETH bond
    /// @param keysCount Count of signing keys
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of public keys
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external {
        // TODO: sanity checks

        uint256 id = _nodeOperatorsCount;
        if (id == MAX_NODE_OPERATORS_COUNT)
            revert MaxNodeOperatorsCountReached();
        NodeOperator storage no = _nodeOperators[id];

        no.managerAddress = msg.sender;
        no.rewardAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        accounting.depositWstETH(
            msg.sender,
            id,
            accounting.getBondAmountByKeysCountWstETH(keysCount)
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
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
        ICSAccounting.PermitInput calldata permit
    ) external {
        // TODO: sanity checks

        uint256 id = _nodeOperatorsCount;
        if (id == MAX_NODE_OPERATORS_COUNT)
            revert MaxNodeOperatorsCountReached();
        NodeOperator storage no = _nodeOperators[id];
        no.rewardAddress = msg.sender;
        no.managerAddress = msg.sender;
        no.active = true;
        _nodeOperatorsCount++;
        _activeNodeOperatorsCount++;

        accounting.depositWstETHWithPermit(
            msg.sender,
            id,
            accounting.getBondAmountByKeysCountWstETH(keysCount),
            permit
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
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
    ) external payable onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks

        require(
            msg.value ==
                accounting.getRequiredBondForNextKeys(
                    nodeOperatorId,
                    keysCount
                ),
            "eth value is not equal to required bond"
        );

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
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
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks

        accounting.depositStETH(
            msg.sender,
            nodeOperatorId,
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount)
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
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
    ) external {
        // TODO: sanity checks

        accounting.depositStETHWithPermit(
            msg.sender,
            nodeOperatorId,
            accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount),
            permit
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
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
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks

        accounting.depositWstETH(
            msg.sender,
            nodeOperatorId,
            accounting.getRequiredBondForNextKeysWstETH(
                nodeOperatorId,
                keysCount
            )
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
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
    ) external {
        // TODO: sanity checks

        accounting.depositWstETHWithPermit(
            msg.sender,
            nodeOperatorId,
            accounting.getRequiredBondForNextKeysWstETH(
                nodeOperatorId,
                keysCount
            ),
            permit
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
    }

    /// @notice Proposes a new manager address for the node operator
    /// @param nodeOperatorId ID of the node operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        uint256 nodeOperatorId,
        address proposedAddress
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyNodeOperatorManager(nodeOperatorId)
    {
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
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyNodeOperatorRewardAddress(nodeOperatorId)
    {
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
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyNodeOperatorRewardAddress(nodeOperatorId)
    {
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
        // TODO: it should be more clear and probably revisited later
        depositableValidatorsCount =
            no.totalVettedKeys -
            totalDepositedValidators;
        if (no.isTargetLimitActive) {
            uint256 activeValidatorsCount = no.totalDepositedKeys -
                no.totalExitedKeys;
            depositableValidatorsCount = Math.min(
                targetValidatorsCount > activeValidatorsCount
                    ? targetValidatorsCount - activeValidatorsCount
                    : 0,
                depositableValidatorsCount
            );
        }
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
    function getNodeOperatorsCount() public view returns (uint256) {
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
        uint256 nodeOperatorsCount = getNodeOperatorsCount();
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
    function onRewardsMinted(uint256 /*_totalShares*/) external {
        // TODO: staking router role only
    }

    /// @notice Updates stuck validators count for node operators by StakingRouter
    /// @dev Presence of stuck validators leads to stop vetting for the node operator
    ///      to prevent further deposits and clean batches from the deposit queue.
    /// @param nodeOperatorIds bytes packed array of node operator ids
    /// @param stuckValidatorsCounts bytes packed array of stuck validators counts
    function updateStuckValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata stuckValidatorsCounts
    ) external onlyStakingRouter {
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
        }
        _incrementModuleNonce();
    }

    /// @notice Updates exited validators count for node operators by StakingRouter
    /// @param nodeOperatorIds bytes packed array of node operator ids
    /// @param exitedValidatorsCounts bytes packed array of exited validators counts
    function updateExitedValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata exitedValidatorsCounts
    ) external onlyStakingRouter {
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
    /// @param refundedValidatorsCount Count of refunded validators
    function updateRefundedValidatorsCount(
        uint256 nodeOperatorId,
        uint256 refundedValidatorsCount
    ) external {
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
    ) external onlyExistingNodeOperator(nodeOperatorId) onlyStakingRouter {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (
            no.isTargetLimitActive == isTargetLimitActive &&
            no.targetLimit == targetLimit
        ) return;

        if (
            (!no.isTargetLimitActive && isTargetLimitActive) ||
            targetLimit < no.targetLimit
        ) {
            _unvetKeys(nodeOperatorId);
        }

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

        _incrementModuleNonce();
    }

    /// @notice Called when exited and stuck validators counts updated by StakingRouter
    function onExitedAndStuckValidatorsCountsUpdated() external {
        // TODO: implement
    }

    /// @notice Unsafe updates of validators count for node operators by DAO
    /// @param nodeOperatorId ID of the node operator
    /// @param exitedValidatorsKeysCount Count of exited validators
    /// @param stuckValidatorsKeysCount Count of stuck validators
    function unsafeUpdateValidatorsCount(
        uint256 nodeOperatorId,
        uint256 exitedValidatorsKeysCount,
        uint256 stuckValidatorsKeysCount
    ) external {
        // TODO: implement
        _incrementModuleNonce();
    }

    /// @notice Vet keys. Called when key validator oracle checks the queue
    /// @param nodeOperatorId ID of the node operator
    /// @param vetKeysPointer Pointer to keys to vet
    function vetKeys(
        uint256 nodeOperatorId,
        uint64 vetKeysPointer
    ) external onlyExistingNodeOperator(nodeOperatorId) onlyKeyValidator {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (vetKeysPointer <= no.totalVettedKeys)
            revert InvalidVetKeysPointer();
        if (vetKeysPointer > no.totalAddedKeys) revert InvalidVetKeysPointer();
        _validateVetKeys(nodeOperatorId, vetKeysPointer);

        uint64 count = SafeCast.toUint64(vetKeysPointer - no.totalVettedKeys);
        uint64 start = SafeCast.toUint64(no.totalVettedKeys);

        bytes32 pointer = Batch.serialize({
            nodeOperatorId: SafeCast.toUint64(nodeOperatorId),
            start: start,
            count: count,
            nonce: SafeCast.toUint64(no.queueNonce)
        });

        no.totalVettedKeys = vetKeysPointer;
        queue.enqueue(pointer);

        emit BatchEnqueued(nodeOperatorId, start, count);
        emit VettedSigningKeysCountChanged(nodeOperatorId, vetKeysPointer);

        _incrementModuleNonce();
    }

    function _validateVetKeys(
        uint256 nodeOperatorId,
        uint64 vetKeysPointer
    ) internal view {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (
            no.isTargetLimitActive &&
            vetKeysPointer > (no.totalExitedKeys + no.targetLimit)
        ) revert TargetLimitExceeded();
        if (no.stuckValidatorsCount > 0) revert StuckKeysPresent();
        if (accounting.getUnbondedKeysCount(nodeOperatorId) > 0)
            revert UnbondedKeysPresent();
    }

    /// @notice Unvets keys and charges fee. Called when key validator oracle checks the queue or manually by node operator manager
    /// @param nodeOperatorId ID of the node operator
    function unvetKeys(
        uint256 nodeOperatorId
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyKeyValidatorOrNodeOperatorManager
    {
        _unvetKeys(nodeOperatorId);
        _applyUnvettingFee(nodeOperatorId);
        _incrementModuleNonce();
    }

    /// @notice Unsafe unvetting of keys by DAO
    /// @dev Doesn't charge fee
    /// @param nodeOperatorId ID of the node operator
    function unsafeUnvetKeys(uint256 nodeOperatorId) external onlyKeyValidator {
        _unvetKeys(nodeOperatorId);
        _incrementModuleNonce();
    }

    /// @notice Removes keys from the node operator and charges fee if there are vetted keys among them
    /// @param nodeOperatorId ID of the node operator
    /// @param startIndex Index of the first key
    function removeKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyNodeOperatorManager(nodeOperatorId)
    {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (no.totalVettedKeys > startIndex) {
            _unvetKeys(nodeOperatorId);
            _applyUnvettingFee(nodeOperatorId);
        }

        _removeSigningKeys(nodeOperatorId, startIndex, keysCount);
    }

    /// @dev NB! doesn't increment module nonce
    function _unvetKeys(uint256 nodeOperatorId) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        no.totalVettedKeys = no.totalDepositedKeys;
        no.queueNonce++;
        emit VettedSigningKeysCountChanged(nodeOperatorId, no.totalVettedKeys);
    }

    function _checkForUnbondedKeys(uint256 nodeOperatorId) internal {
        if (accounting.getUnbondedKeysCount(nodeOperatorId) > 0) {
            _unvetKeys(nodeOperatorId);
            _incrementModuleNonce();
        }
    }

    /// @notice any penalty might cause bond out, so we need to clear any benefits from the node operator
    /// @param nodeOperatorId ID of the node operator
    function _checkForOutOfBond(uint256 nodeOperatorId) internal {
        // TODO: Should be done manually or automatically? Any penalty should reset bond curve or not?
        if (accounting.getBondShares(nodeOperatorId) == 0) {
            accounting.resetBondCurve(nodeOperatorId);
        }
    }

    function _applyUnvettingFee(uint256 nodeOperatorId) internal {
        accounting.penalize(nodeOperatorId, unvettingFee);
        emit UnvettingFeeApplied(nodeOperatorId);

        _checkForOutOfBond(nodeOperatorId);
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
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: check role
        emit ELRewardsStealingPenaltyReported(
            nodeOperatorId,
            blockNumber,
            amount
        );

        accounting.lockBondETH(
            nodeOperatorId,
            amount + EL_REWARDS_STEALING_FINE
        );

        _checkForUnbondedKeys(nodeOperatorId);
    }

    /// @dev Should be called by the committee.
    /// @notice Settles blocked bond for the given node operators.
    /// @param nodeOperatorIds ids of the node operators to settle blocked bond for.
    function settleELRewardsStealingPenalty(
        uint256[] memory nodeOperatorIds
    ) public {
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            if (nodeOperatorId >= _nodeOperatorsCount)
                revert NodeOperatorDoesNotExist();
            accounting.settleLockedBondETH(nodeOperatorId);
            _checkForOutOfBond(nodeOperatorId);
        }
    }

    /// @notice Penalize bond by burning shares of the given node operator.
    /// @dev Have a limited lifetime. Reverts when expired
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to penalize.
    function penalize(
        uint256 nodeOperatorId,
        uint256 amount
    )
        public
        onlyExistingNodeOperator(nodeOperatorId)
        onlyPenalizer
        whenNotExpired
    {
        // TODO: check role
        accounting.penalize(nodeOperatorId, amount);
        _checkForUnbondedKeys(nodeOperatorId);
        _checkForOutOfBond(nodeOperatorId);
    }

    /// @notice Report node operator's key as withdrawn and settle withdrawn amount.
    /// @param nodeOperatorId Operator ID in the module.
    /// @param keyIndex Index of the withdrawn key in the node operator's keys.
    /// @param amount Amount of withdrawn ETH in wei.
    function submitWithdrawal(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 amount
    ) external onlyExistingNodeOperator(nodeOperatorId) onlyWithdrawalReporter {
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
            _checkForUnbondedKeys(nodeOperatorId);
            _checkForOutOfBond(nodeOperatorId);
        }
    }

    function submitInitialSlashing(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: check for slashing proof or role
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        if (keyIndex >= no.totalDepositedKeys) {
            revert SigningKeysInvalidOffset();
        }

        uint256 pointer = _keyPointer(nodeOperatorId, keyIndex);

        if (_isValidatorSlashed[pointer]) {
            revert AlreadySubmitted();
        }
        _isValidatorSlashed[pointer] = true;

        accounting.penalize(nodeOperatorId, INITIAL_SLASHING_PENALTY);
        _checkForUnbondedKeys(nodeOperatorId);
        _checkForOutOfBond(nodeOperatorId);
        emit InitialSlashingSubmitted(nodeOperatorId, keyIndex);
    }

    /// @dev both nodeOperatorId and keyIndex are limited to uint64 by the contract.
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }

    /// @notice Called when withdrawal credentials changed by DAO
    function onWithdrawalCredentialsChanged() external {
        revert("NOT_IMPLEMENTED");
    }

    function _addSigningKeys(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) internal {
        // TODO: sanity checks
        uint256 startIndex = _nodeOperators[nodeOperatorId].totalAddedKeys;

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
        _nodeOperators[nodeOperatorId].totalAddedKeys += keysCount;
        emit TotalSigningKeysCountChanged(
            nodeOperatorId,
            _nodeOperators[nodeOperatorId].totalAddedKeys
        );

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

        no.totalAddedKeys = newTotalSigningKeys;
        emit TotalSigningKeysCountChanged(nodeOperatorId, newTotalSigningKeys);

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
    ) external returns (bytes memory publicKeys, bytes memory signatures) {
        (publicKeys, signatures) = SigningKeys.initKeysSigsBuf(depositsCount);
        uint256 limit = depositsCount;
        uint256 loadedKeysCount = 0;

        for (bytes32 p = queue.peek(); !Batch.isNil(p); ) {
            (
                uint256 nodeOperatorId,
                uint256 startIndex,
                uint256 depositableKeysCount
            ) = _depositableKeysInBatch(p);

            uint256 keysCount = Math.min(limit, depositableKeysCount);
            if (depositableKeysCount == keysCount) {
                queue.dequeue();
            }

            // solhint-disable-next-line func-named-parameters
            SigningKeys.loadKeysSigs(
                SIGNING_KEYS_POSITION,
                nodeOperatorId,
                startIndex,
                keysCount,
                publicKeys,
                signatures,
                loadedKeysCount
            );
            loadedKeysCount += keysCount;

            _totalDepositedValidators += keysCount;
            NodeOperator storage no = _nodeOperators[nodeOperatorId];
            no.totalDepositedKeys += keysCount;
            // redundant check, enforced by _assertIsValidBatch
            require(
                no.totalDepositedKeys <= no.totalVettedKeys,
                "too many keys"
            );

            emit DepositedSigningKeysCountChanged(
                nodeOperatorId,
                no.totalDepositedKeys
            );

            limit = limit - keysCount;
            if (limit == 0) {
                break;
            }

            p = queue.peek();
        }

        require(loadedKeysCount == depositsCount, "NOT_ENOUGH_KEYS");
        _incrementModuleNonce();
    }

    function _depositableKeysInBatch(
        bytes32 batch
    )
        internal
        view
        returns (
            uint256 nodeOperatorId,
            uint256 startIndex,
            uint256 depositableKeysCount
        )
    {
        uint256 start;
        uint256 count;
        uint256 nonce;

        (nodeOperatorId, start, count, nonce) = Batch.deserialize(batch);

        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        // solhint-disable-next-line func-named-parameters
        _assertIsValidBatch(no, batch, start, count, nonce);

        startIndex = Math.max(start, no.totalDepositedKeys);
        depositableKeysCount = start + count - startIndex;
    }

    function _assertIsValidBatch(
        NodeOperator storage no,
        bytes32 batch,
        uint256 start,
        uint256 count,
        uint256 nonce
    ) internal view {
        if (count == 0) revert QueueEmptyBatch();
        if (nonce != no.queueNonce) revert QueueBatchInvalidNonce(batch);
        if (start > no.totalDepositedKeys) revert QueueBatchInvalidStart(batch);
        if (start + count > no.totalAddedKeys)
            revert QueueBatchInvalidCount(batch);
        if (_unvettedKeysInBatch(no, start, count))
            revert QueueBatchUnvettedKeys(batch);
    }

    /// @notice Cleans the deposit queue from invalid batches
    /// @param maxItems Max count of items to clean
    /// @param pointer Pointer to the first item to clean
    /// @return pointer Pointer when cleaning is finished
    function cleanDepositQueue(
        uint256 maxItems,
        bytes32 pointer
    ) external returns (bytes32) {
        if (maxItems == 0) revert QueueLookupNoLimit();

        if (Batch.isNil(pointer)) {
            pointer = queue.front;
        }

        for (uint256 i; i < maxItems; i++) {
            bytes32 item = queue.at(pointer);
            if (Batch.isNil(item)) {
                break;
            }

            (
                uint256 nodeOperatorId,
                uint256 start,
                uint256 count,
                uint256 nonce
            ) = Batch.deserialize(item);
            NodeOperator storage no = _nodeOperators[nodeOperatorId];
            if (
                _unvettedKeysInBatch(no, start, count) || nonce != no.queueNonce
            ) {
                queue.remove(pointer, item);
                continue;
            }

            pointer = item;
        }

        return pointer;
    }

    /// @notice Gets the deposit queue
    /// @param maxItems Max count of items to get
    /// @param pointer Pointer to the first item to get
    /// @return items Items in the queue
    /// @return count Count of items in the queue
    function depositQueue(
        uint256 maxItems,
        bytes32 pointer
    ) external view returns (bytes32[] memory items, uint256 /* count */) {
        if (maxItems == 0) revert QueueLookupNoLimit();

        if (Batch.isNil(pointer)) {
            pointer = queue.front;
        }

        return queue.list(pointer, maxItems);
    }

    /// @notice Checks if the deposit queue is dirty
    /// @dev it is dirty if it contains a batch with unvetted keys
    ///      or with invalid nonce
    /// @return bool is queue dirty
    /// @return bytes32 next pointer to start check from
    function isQueueDirty(
        uint256 maxItems,
        bytes32 pointer
    ) external view returns (bool, bytes32) {
        if (maxItems == 0) revert QueueLookupNoLimit();

        if (Batch.isNil(pointer)) {
            pointer = queue.front;
        }

        for (uint256 i; i < maxItems; i++) {
            bytes32 item = queue.at(pointer);
            if (Batch.isNil(item)) {
                break;
            }

            (
                uint256 nodeOperatorId,
                uint256 start,
                uint256 count,
                uint256 nonce
            ) = Batch.deserialize(item);
            NodeOperator storage no = _nodeOperators[nodeOperatorId];
            if (
                _unvettedKeysInBatch(no, start, count) || nonce != no.queueNonce
            ) {
                return (true, pointer);
            }

            pointer = item;
        }

        return (false, pointer);
    }

    function _unvettedKeysInBatch(
        NodeOperator storage no,
        uint256 start,
        uint256 count
    ) internal view returns (bool) {
        return start + count > no.totalVettedKeys;
    }

    function _incrementModuleNonce() internal {
        _nonce++;
    }

    modifier onlyExistingNodeOperator(uint256 nodeOperatorId) {
        if (nodeOperatorId >= _nodeOperatorsCount)
            revert NodeOperatorDoesNotExist();
        _;
    }

    modifier onlyNodeOperatorManager(uint256 nodeOperatorId) {
        if (_nodeOperators[nodeOperatorId].managerAddress != msg.sender)
            revert SenderIsNotManagerAddress();
        _;
    }

    modifier onlyNodeOperatorRewardAddress(uint256 nodeOperatorId) {
        if (_nodeOperators[nodeOperatorId].rewardAddress != msg.sender)
            revert SenderIsNotRewardAddress();
        _;
    }

    modifier onlyActiveNodeOperator(uint256 nodeOperatorId) {
        require(
            nodeOperatorId < _nodeOperatorsCount,
            "node operator does not exist"
        );
        require(
            _nodeOperators[nodeOperatorId].active,
            "node operator is not active"
        );
        _;
    }

    modifier onlyKeyValidatorOrNodeOperatorManager() {
        // TODO: check the role
        _;
    }

    modifier onlyKeyValidator() {
        // TODO: check the role
        _;
    }

    modifier onlyStakingRouter() {
        // TODO: check the role
        _;
    }

    modifier onlyWithdrawalReporter() {
        // Here should be a role granted to the CSVerifier contract and/or to the DAO/Oracle.
        // TODO: check the role
        _;
    }

    modifier onlyPenalizer() {
        // Should be assigned to Aragon Agent
        // TODO: check the role
        _;
    }

    modifier whenNotExpired() {
        if (block.timestamp > _tempMethodsExpireTime) {
            revert Expired();
        }
        _;
    }
}
