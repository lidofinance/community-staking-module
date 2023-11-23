// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ILido } from "./interfaces/ILido.sol";

import { QueueLib } from "./lib/QueueLib.sol";
import { Batch } from "./lib/Batch.sol";

import "./lib/SigningKeys.sol";

struct NodeOperator {
    address managerAddress;
    address proposedManagerAddress;
    address rewardAddress;
    address proposedRewardAddress;
    bool active;
    uint256 targetLimit;
    uint256 targetLimitTimestamp;
    uint256 stuckPenaltyEndTimestamp;
    uint256 totalExitedKeys;
    uint256 totalAddedKeys;
    uint256 totalWithdrawnKeys;
    uint256 totalDepositedKeys;
    uint256 totalVettedKeys;
    uint256 stuckValidatorsCount;
    uint256 refundedValidatorsCount;
    bool isTargetLimitActive;
    uint256 queueNonce;
}

struct NodeOperatorInfo {
    bool active;
    address managerAddress;
    address rewardAddress;
    uint256 totalVettedValidators;
    uint256 totalExitedValidators;
    uint256 totalWithdrawnValidators;
    uint256 totalAddedValidators;
    uint256 totalDepositedValidators;
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

    event BatchEnqueued(
        uint256 indexed nodeOperatorId,
        uint256 startIndex,
        uint256 count
    );

    event StakingModuleTypeSet(bytes32 moduleType);
    event LocatorContractSet(address locatorAddress);
    event UnvettingFeeSet(uint256 unvettingFee);

    error NodeOperatorDoesNotExist();
    error MaxNodeOperatorsCountReached();
    error SenderIsNotManagerAddress();
    error SenderIsNotRewardAddress();
    error SenderIsNotProposedAddress();
    error SameAddress();
    error AlreadyProposed();
    error InvalidVetKeysPointer();
}

contract CSModule is IStakingModule, CSModuleBase {
    using QueueLib for QueueLib.Queue;

    // @dev max number of node operators is limited by uint64 due to Batch serialization in 32 bytes
    // it seems to be enough
    uint128 public constant MAX_NODE_OPERATORS_COUNT = type(uint64).max;
    bytes32 public constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    uint256 public unvettingFee;
    QueueLib.Queue public queue;

    ICSAccounting public accounting;
    ILidoLocator public lidoLocator;
    uint256 private _nodeOperatorsCount;
    uint256 private _activeNodeOperatorsCount;
    bytes32 private _moduleType;
    uint256 private _nonce;
    mapping(uint256 => NodeOperator) private _nodeOperators;

    uint256 private _totalDepositedValidators;
    uint256 private _totalExitedValidators;
    uint256 private _totalAddedValidators;

    constructor(bytes32 moduleType, address locator) {
        _moduleType = moduleType;
        emit StakingModuleTypeSet(moduleType);

        require(locator != address(0), "lido locator is zero address");
        lidoLocator = ILidoLocator(locator);
        emit LocatorContractSet(locator);
    }

    function setAccounting(address _accounting) external {
        // TODO: add role check
        require(address(accounting) == address(0), "already initialized");
        accounting = ICSAccounting(_accounting);
    }

    function setUnvettingFee(uint256 unvettingFee_) external {
        // TODO: add role check
        unvettingFee = unvettingFee_;
        emit UnvettingFeeSet(unvettingFee_);
    }

    function _lido() internal view returns (ILido) {
        return ILido(lidoLocator.lido());
    }

    function getType() external view returns (bytes32) {
        return _moduleType;
    }

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
            _totalAddedValidators - _totalExitedValidators
        );
    }

    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable {
        // TODO sanity checks

        require(
            msg.value == accounting.getRequiredBondETHForKeys(keysCount),
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
            accounting.getRequiredBondStETHForKeys(keysCount)
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
    }

    function addNodeOperatorStETHWithPermit(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external {
        // TODO sanity checks

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
            accounting.getRequiredBondStETHForKeys(keysCount),
            permit
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
    }

    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external {
        // TODO sanity checks

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
            accounting.getRequiredBondWstETHForKeys(keysCount)
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
    }

    function addNodeOperatorWstETHWithPermit(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external {
        // TODO sanity checks

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
            accounting.getRequiredBondWstETHForKeys(keysCount),
            permit
        );

        _addSigningKeys(id, keysCount, publicKeys, signatures);

        emit NodeOperatorAdded(id, msg.sender);
    }

    function addValidatorKeysETH(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: sanity checks

        require(
            msg.value ==
                accounting.getRequiredBondETH(nodeOperatorId, keysCount),
            "eth value is not equal to required bond"
        );

        accounting.depositETH{ value: msg.value }(msg.sender, nodeOperatorId);

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
    }

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
            accounting.getRequiredBondStETH(nodeOperatorId, keysCount)
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
    }

    function addValidatorKeysStETHWithPermit(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external {
        // TODO sanity checks

        accounting.depositStETHWithPermit(
            msg.sender,
            nodeOperatorId,
            accounting.getRequiredBondStETH(nodeOperatorId, keysCount),
            permit
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
    }

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
            accounting.getRequiredBondWstETH(nodeOperatorId, keysCount)
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
    }

    function addValidatorKeysWstETHWithPermit(
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external {
        // TODO sanity checks

        accounting.depositWstETHWithPermit(
            msg.sender,
            nodeOperatorId,
            accounting.getRequiredBondWstETH(nodeOperatorId, keysCount),
            permit
        );

        _addSigningKeys(nodeOperatorId, keysCount, publicKeys, signatures);
    }

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
        depositableValidatorsCount = no.totalVettedKeys - no.totalExitedKeys;
    }

    function getNonce() external view returns (uint256) {
        return _nonce;
    }

    function getNodeOperatorsCount() public view returns (uint256) {
        return _nodeOperatorsCount;
    }

    function getActiveNodeOperatorsCount() external view returns (uint256) {
        return _activeNodeOperatorsCount;
    }

    function getNodeOperatorIsActive(
        uint256 nodeOperatorId
    ) external view returns (bool) {
        return _nodeOperators[nodeOperatorId].active;
    }

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

    // called when rewards minted for the module
    // seems to be empty implementation due to oracle using csm balance for distribution
    function onRewardsMinted(uint256 /*_totalShares*/) external {
        // TODO: staking router role only
    }

    function updateStuckValidatorsCount(
        bytes calldata /*_nodeOperatorIds*/,
        bytes calldata /*_stuckValidatorsCounts*/
    ) external {
        // TODO: implement
    }

    function updateExitedValidatorsCount(
        bytes calldata nodeOperatorIds,
        bytes calldata exitedValidatorsCounts
    ) external {
        // TODO: implement
        //        emit ExitedSigningKeysCountChanged(
        //            nodeOperatorId,
        //            exitedValidatorsCount
        //        );
    }

    function updateRefundedValidatorsCount(
        uint256 /* nodeOperatorId */,
        uint256 /* refundedValidatorsCount */
    ) external {
        // TODO: implement
    }

    function updateTargetValidatorsLimits(
        uint256 /*_nodeOperatorId*/,
        bool /*_isTargetLimitActive*/,
        uint256 /*_targetLimit*/
    ) external {
        // TODO: implement
    }

    function onExitedAndStuckValidatorsCountsUpdated() external {
        // TODO: implement
    }

    function unsafeUpdateValidatorsCount(
        uint256 /*_nodeOperatorId*/,
        uint256 /*_exitedValidatorsKeysCount*/,
        uint256 /*_stuckValidatorsKeysCount*/
    ) external {
        // TODO: implement
    }

    function vetKeys(
        uint256 nodeOperatorId,
        uint64 vetKeysPointer
    ) external onlyExistingNodeOperator(nodeOperatorId) onlyKeyValidator {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];

        if (vetKeysPointer <= no.totalVettedKeys)
            revert InvalidVetKeysPointer();
        if (vetKeysPointer > no.totalAddedKeys) revert InvalidVetKeysPointer();

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

        _incrementNonce();
    }

    function unvetKeys(
        uint256 nodeOperatorId
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyKeyValidatorOrNodeOperatorManager
    {
        _unvetKeys(nodeOperatorId);
        accounting.penalize(nodeOperatorId, unvettingFee);
    }

    function unsafeUnvetKeys(uint256 nodeOperatorId) external onlyKeyValidator {
        _unvetKeys(nodeOperatorId);
    }

    function _unvetKeys(uint256 nodeOperatorId) internal {
        NodeOperator storage no = _nodeOperators[nodeOperatorId];
        no.totalVettedKeys = no.totalDepositedKeys;
        no.queueNonce++;
        emit VettedSigningKeysCountChanged(nodeOperatorId, no.totalVettedKeys);
        _incrementNonce();
    }

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

        _incrementNonce();
    }

    function obtainDepositData(
        uint256 depositsCount,
        bytes calldata /* _depositCalldata */
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
        _incrementNonce();
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
        _assertIsValidBatch(no, start, count, nonce);

        startIndex = Math.max(start, no.totalDepositedKeys);
        depositableKeysCount = start + count - startIndex;
    }

    function _assertIsValidBatch(
        NodeOperator storage no,
        uint256 start,
        uint256 count,
        uint256 nonce
    ) internal view {
        require(count != 0, "Empty batch given");
        require(nonce == no.queueNonce, "Invalid batch nonce");
        require(
            _unvettedKeysInBatch(no, start, count) == false,
            "Batch contains unvetted keys"
        );
        require(
            start + count <= no.totalAddedKeys,
            "Invalid batch range: not enough keys"
        );
        require(
            start <= no.totalDepositedKeys,
            "Invalid batch range: skipped keys"
        );
    }

    /// @dev returns the next pointer to start cleanup from
    function cleanDepositQueue(
        uint256 maxItems,
        bytes32 pointer
    ) external returns (bytes32) {
        require(maxItems > 0, "Queue walkthrough limit is not set");

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

    function depositQueue(
        uint256 maxItems,
        bytes32 pointer
    ) external view returns (bytes32[] memory items, uint256 /* count */) {
        require(maxItems > 0, "Queue walkthrough limit is not set");

        if (Batch.isNil(pointer)) {
            pointer = queue.front;
        }

        return queue.list(pointer, maxItems);
    }

    /// @dev returns the next pointer to start check from
    function isQueueDirty(
        uint256 maxItems,
        bytes32 pointer
    ) external view returns (bool, bytes32) {
        require(maxItems > 0, "Queue walkthrough limit is not set");

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

    function _incrementNonce() internal {
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
}
