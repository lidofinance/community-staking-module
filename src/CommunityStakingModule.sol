// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ICommunityStakingBondManager } from "./interfaces/ICommunityStakingBondManager.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ILido } from "./interfaces/ILido.sol";

import { QueueLib } from "./lib/QueueLib.sol";
import { Batch } from "./lib/Batch.sol";

import "./lib/SigningKeys.sol";
import "./lib/StringToUint256WithZeroMap.sol";

struct NodeOperator {
    string name;
    address rewardAddress;
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
}

contract CommunityStakingModuleBase {
    event NodeOperatorAdded(
        uint256 indexed nodeOperatorId,
        string name,
        address rewardAddress
    );
    event NodeOperatorNameSet(uint256 indexed nodeOperatorId, string name);

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
}

contract CommunityStakingModule is IStakingModule, CommunityStakingModuleBase {
    using StringToUint256WithZeroMap for mapping(string => uint256);
    using QueueLib for QueueLib.Queue;

    uint256 public constant MAX_NODE_OPERATOR_NAME_LENGTH = 255;
    bytes32 public constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    uint256 public unvettingFee;
    QueueLib.Queue public queue;

    ICommunityStakingBondManager public bondManager;
    ILidoLocator public lidoLocator;

    uint256 private nodeOperatorsCount;
    uint256 private activeNodeOperatorsCount;
    bytes32 private moduleType;
    uint256 private nonce;
    mapping(uint256 => NodeOperator) private nodeOperators;
    mapping(string => uint256) private nodeOperatorIdsByName;

    uint256 private _totalDepositedValidators;
    uint256 private _totalExitedValidators;
    uint256 private _totalAddedValidators;

    modifier onlyActiveNodeOperator(uint256 _nodeOperatorId) {
        require(
            _nodeOperatorId < nodeOperatorsCount,
            "node operator does not exist"
        );
        require(
            nodeOperators[_nodeOperatorId].active,
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

    constructor(bytes32 _type, address _locator) {
        moduleType = _type;
        emit StakingModuleTypeSet(_type);

        require(_locator != address(0), "lido locator is zero address");
        lidoLocator = ILidoLocator(_locator);
        emit LocatorContractSet(_locator);
    }

    function setBondManager(address _bondManager) external {
        // TODO: add role check
        require(address(bondManager) == address(0), "already initialized");
        bondManager = ICommunityStakingBondManager(_bondManager);
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
        return moduleType;
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
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external payable {
        // TODO sanity checks
        _onlyValidNodeOperatorName(_name);

        require(
            msg.value == bondManager.getRequiredBondETHForKeys(_keysCount),
            "eth value is not equal to required bond"
        );

        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        nodeOperatorIdsByName.set(_name, id);
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositETH{ value: msg.value }(msg.sender, id);

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addNodeOperatorStETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external {
        // TODO: sanity checks
        _onlyValidNodeOperatorName(_name);

        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        nodeOperatorIdsByName.set(_name, id);
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositStETH(
            msg.sender,
            id,
            bondManager.getRequiredBondStETHForKeys(_keysCount)
        );

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addNodeOperatorStETHWithPermit(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addNodeOperatorStETHWithPermit(
                msg.sender,
                _name,
                _rewardAddress,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function addNodeOperatorStETHWithPermit(
        address _from,
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addNodeOperatorStETHWithPermit(
                _from,
                _name,
                _rewardAddress,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function _addNodeOperatorStETHWithPermit(
        address _from,
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) internal {
        // TODO sanity checks
        _onlyValidNodeOperatorName(_name);

        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        nodeOperatorIdsByName.set(_name, id);
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositStETHWithPermit(
            _from,
            id,
            bondManager.getRequiredBondStETHForKeys(_keysCount),
            _permit
        );

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addNodeOperatorWstETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external {
        // TODO sanity checks
        _onlyValidNodeOperatorName(_name);

        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        nodeOperatorIdsByName.set(_name, id);
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositWstETH(
            msg.sender,
            id,
            bondManager.getRequiredBondWstETHForKeys(_keysCount)
        );

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addNodeOperatorWstETHWithPermit(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addNodeOperatorWstETHWithPermit(
                msg.sender,
                _name,
                _rewardAddress,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function addNodeOperatorWstETHWithPermit(
        address _from,
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addNodeOperatorWstETHWithPermit(
                _from,
                _name,
                _rewardAddress,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function _addNodeOperatorWstETHWithPermit(
        address _from,
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) internal {
        // TODO sanity checks
        _onlyValidNodeOperatorName(_name);

        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        nodeOperatorIdsByName.set(_name, id);
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositWstETHWithPermit(
            _from,
            id,
            bondManager.getRequiredBondWstETHForKeys(_keysCount),
            _permit
        );

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addValidatorKeysETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external payable onlyExistingNodeOperator(_nodeOperatorId) {
        // TODO: sanity checks

        require(
            msg.value ==
                bondManager.getRequiredBondETH(_nodeOperatorId, _keysCount),
            "eth value is not equal to required bond"
        );

        bondManager.depositETH{ value: msg.value }(msg.sender, _nodeOperatorId);

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function addValidatorKeysStETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external onlyExistingNodeOperator(_nodeOperatorId) {
        // TODO: sanity checks

        bondManager.depositStETH(
            msg.sender,
            _nodeOperatorId,
            bondManager.getRequiredBondStETH(_nodeOperatorId, _keysCount)
        );

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function addValidatorKeysStETHWithPermit(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addValidatorKeysStETHWithPermit(
                msg.sender,
                _nodeOperatorId,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function addValidatorKeysStETHWithPermit(
        address _from,
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addValidatorKeysStETHWithPermit(
                _from,
                _nodeOperatorId,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function _addValidatorKeysStETHWithPermit(
        address _from,
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) internal onlyExistingNodeOperator(_nodeOperatorId) {
        // TODO sanity checks
        // TODO store keys

        bondManager.depositStETHWithPermit(
            _from,
            _nodeOperatorId,
            bondManager.getRequiredBondStETH(_nodeOperatorId, _keysCount),
            _permit
        );

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function addValidatorKeysWstETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external onlyExistingNodeOperator(_nodeOperatorId) {
        // TODO: sanity checks

        bondManager.depositWstETH(
            msg.sender,
            _nodeOperatorId,
            bondManager.getRequiredBondWstETH(_nodeOperatorId, _keysCount)
        );

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function addValidatorKeysWstETHWithPermit(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addValidatorKeysWstETHWithPermit(
                msg.sender,
                _nodeOperatorId,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function addValidatorKeysWstETHWithPermit(
        address _from,
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) external {
        return
            _addValidatorKeysWstETHWithPermit(
                _from,
                _nodeOperatorId,
                _keysCount,
                _publicKeys,
                _signatures,
                _permit
            );
    }

    function _addValidatorKeysWstETHWithPermit(
        address _from,
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures,
        ICommunityStakingBondManager.PermitInput calldata _permit
    ) internal onlyExistingNodeOperator(_nodeOperatorId) {
        // TODO sanity checks
        // TODO store keys

        bondManager.depositWstETHWithPermit(
            _from,
            _nodeOperatorId,
            bondManager.getRequiredBondWstETH(_nodeOperatorId, _keysCount),
            _permit
        );

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function setNodeOperatorName(
        uint256 _nodeOperatorId,
        string memory _name
    )
        external
        onlyExistingNodeOperator(_nodeOperatorId)
        onlyNodeOperatorManager(_nodeOperatorId)
    {
        require(
            keccak256(bytes(_name)) !=
                keccak256(bytes(nodeOperators[_nodeOperatorId].name)),
            "SAME_NAME"
        );
        _onlyValidNodeOperatorName(_name);

        nodeOperatorIdsByName.remove(nodeOperators[_nodeOperatorId].name);
        nodeOperators[_nodeOperatorId].name = _name;
        nodeOperatorIdsByName.set(_name, _nodeOperatorId);
        emit NodeOperatorNameSet(_nodeOperatorId, _name);
    }

    function getNodeOperatorIdByName(
        string memory _name
    ) external view returns (uint256) {
        return nodeOperatorIdsByName.get(_name);
    }

    function getNodeOperator(
        uint256 _nodeOperatorId,
        bool _fullInfo
    )
        external
        view
        returns (
            bool active,
            string memory name,
            address rewardAddress,
            uint256 totalVettedValidators,
            uint256 totalExitedValidators,
            uint256 totalWithdrawnValidators,
            uint256 totalAddedValidators,
            uint256 totalDepositedValidators
        )
    {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        active = no.active;
        name = _fullInfo ? no.name : "";
        rewardAddress = no.rewardAddress;
        totalExitedValidators = no.totalExitedKeys;
        totalDepositedValidators = no.totalDepositedKeys;
        totalAddedValidators = no.totalAddedKeys;
        totalWithdrawnValidators = no.totalWithdrawnKeys;
        totalVettedValidators = no.totalVettedKeys;
    }

    function getNodeOperatorSummary(
        uint256 _nodeOperatorId
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
        NodeOperator memory no = nodeOperators[_nodeOperatorId];
        isTargetLimitActive = no.isTargetLimitActive;
        targetValidatorsCount = no.targetLimit;
        stuckValidatorsCount = no.stuckValidatorsCount;
        refundedValidatorsCount = no.refundedValidatorsCount;
        stuckPenaltyEndTimestamp = no.stuckPenaltyEndTimestamp;
        totalExitedValidators = no.totalExitedKeys;
        totalDepositedValidators = no.totalDepositedKeys;
        depositableValidatorsCount = no.totalAddedKeys - no.totalExitedKeys;
    }

    function getNonce() external view returns (uint256) {
        return nonce;
    }

    function getNodeOperatorsCount() public view returns (uint256) {
        return nodeOperatorsCount;
    }

    function getActiveNodeOperatorsCount() external view returns (uint256) {
        return activeNodeOperatorsCount;
    }

    function getNodeOperatorIsActive(
        uint256 _nodeOperatorId
    ) external view returns (bool) {
        return nodeOperators[_nodeOperatorId].active;
    }

    function getNodeOperatorIds(
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256[] memory nodeOperatorIds) {
        uint256 _nodeOperatorsCount = getNodeOperatorsCount();
        if (_offset >= _nodeOperatorsCount || _limit == 0)
            return new uint256[](0);
        uint256 idsCount = _limit < _nodeOperatorsCount - _offset
            ? _limit
            : _nodeOperatorsCount - _offset;
        nodeOperatorIds = new uint256[](idsCount);
        for (uint256 i = 0; i < nodeOperatorIds.length; ++i) {
            nodeOperatorIds[i] = _offset + i;
        }
    }

    function onRewardsMinted(uint256 /*_totalShares*/) external {
        // TODO: implement
    }

    function updateStuckValidatorsCount(
        bytes calldata /*_nodeOperatorIds*/,
        bytes calldata /*_stuckValidatorsCounts*/
    ) external {
        // TODO: implement
    }

    function updateExitedValidatorsCount(
        bytes calldata _nodeOperatorIds,
        bytes calldata _exitedValidatorsCounts
    ) external {
        // TODO: implement
        //        emit ExitedSigningKeysCountChanged(
        //            _nodeOperatorId,
        //            _exitedValidatorsCount
        //        );
    }

    function updateRefundedValidatorsCount(
        uint256 /*_nodeOperatorId*/,
        uint256 /*_refundedValidatorsCount*/
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
        uint64 vettedKeysCount
    ) external onlyKeyValidator {
        NodeOperator storage no = nodeOperators[nodeOperatorId];

        require(
            vettedKeysCount > no.totalVettedKeys,
            "Wrong vettedKeysCount: less than already vetted"
        );
        require(
            vettedKeysCount <= no.totalAddedKeys,
            "Wrong vettedKeysCount: more than added"
        );

        uint64 count = SafeCast.toUint64(vettedKeysCount - no.totalVettedKeys);
        uint64 start = SafeCast.toUint64(
            no.totalVettedKeys == 0 ? 0 : no.totalVettedKeys - 1
        );

        bytes32 pointer = Batch.serialize({
            nodeOperatorId: SafeCast.toUint128(nodeOperatorId),
            start: start,
            count: count
        });

        no.totalVettedKeys = vettedKeysCount;
        queue.enqueue(pointer);

        emit BatchEnqueued(nodeOperatorId, start, count);
        emit VettedSigningKeysCountChanged(nodeOperatorId, vettedKeysCount);

        _incrementNonce();
    }

    function unvetKeys(
        uint256 nodeOperatorId
    ) external onlyKeyValidatorOrNodeOperatorManager {
        _unvetKeys(nodeOperatorId);
        bondManager.penalize(nodeOperatorId, unvettingFee);
    }

    function unsafeUnvetKeys(uint256 nodeOperatorId) external onlyKeyValidator {
        _unvetKeys(nodeOperatorId);
    }

    function _unvetKeys(uint256 nodeOperatorId) internal {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        no.totalVettedKeys = no.totalDepositedKeys;
        emit VettedSigningKeysCountChanged(nodeOperatorId, no.totalVettedKeys);
        _incrementNonce();
    }

    function onWithdrawalCredentialsChanged() external {
        revert("NOT_IMPLEMENTED");
    }

    function _addSigningKeys(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) internal {
        // TODO: sanity checks
        uint256 _startIndex = nodeOperators[_nodeOperatorId].totalAddedKeys;

        SigningKeys.saveKeysSigs(
            SIGNING_KEYS_POSITION,
            _nodeOperatorId,
            _startIndex,
            _keysCount,
            _publicKeys,
            _signatures
        );

        _totalAddedValidators += _keysCount;
        nodeOperators[_nodeOperatorId].totalAddedKeys += _keysCount;
        emit TotalSigningKeysCountChanged(
            _nodeOperatorId,
            nodeOperators[_nodeOperatorId].totalAddedKeys
        );

        _incrementNonce();
    }

    function obtainDepositData(
        uint256 _depositsCount,
        bytes calldata /* _depositCalldata */
    ) external returns (bytes memory publicKeys, bytes memory signatures) {
        (publicKeys, signatures) = SigningKeys.initKeysSigsBuf(_depositsCount);
        uint256 limit = _depositsCount;
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
            NodeOperator storage no = nodeOperators[nodeOperatorId];
            no.totalDepositedKeys += keysCount;
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

        require(loadedKeysCount == _depositsCount, "NOT_ENOUGH_KEYS");
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

        (nodeOperatorId, start, count) = Batch.deserialize(batch);

        NodeOperator storage no = nodeOperators[nodeOperatorId];
        _assertIsValidBatch(no, start, count);

        startIndex = Math.max(start, no.totalDepositedKeys);
        depositableKeysCount = start + count - startIndex;
    }

    function _assertIsValidBatch(
        NodeOperator storage no,
        uint256 _start,
        uint256 _count
    ) internal view {
        require(_count != 0, "Empty batch given");
        require(
            _unvettedKeysInBatch(no, _start, _count) == false,
            "Batch contains unvetted keys"
        );
        require(
            _start + _count <= no.totalAddedKeys,
            "Invalid batch range: not enough keys"
        );
        require(
            _start <= no.totalDepositedKeys,
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

            (uint256 nodeOperatorId, uint256 start, uint256 count) = Batch
                .deserialize(item);
            NodeOperator storage no = nodeOperators[nodeOperatorId];
            if (_unvettedKeysInBatch(no, start, count)) {
                queue.remove(pointer, item);
            }

            pointer = item;
        }

        return pointer;
    }

    function depositQueue(
        uint256 maxItems,
        bytes32 pointer
    )
        external
        view
        returns (
            bytes32[] memory items,
            bytes32 /* pointer */,
            uint256 /* count */
        )
    {
        require(maxItems > 0, "Queue walkthrough limit is not set");

        if (Batch.isNil(pointer)) {
            pointer = queue.front;
        }

        return queue.list(pointer, maxItems);
    }

    /// @dev returns the next pointer to start check from
    function isQueueHasUnvettedKeys(
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

            (uint256 nodeOperatorId, uint256 start, uint256 count) = Batch
                .deserialize(item);
            NodeOperator storage no = nodeOperators[nodeOperatorId];
            if (_unvettedKeysInBatch(no, start, count)) {
                return (true, pointer);
            }

            pointer = item;
        }

        return (false, pointer);
    }

    function _unvettedKeysInBatch(
        NodeOperator storage no,
        uint256 _start,
        uint256 _count
    ) internal view returns (bool) {
        return _start + _count > no.totalVettedKeys;
    }

    function _incrementNonce() internal {
        nonce++;
    }

    function _onlyValidNodeOperatorName(string memory _name) internal view {
        require(
            bytes(_name).length > 0 &&
                bytes(_name).length <= MAX_NODE_OPERATOR_NAME_LENGTH,
            "WRONG_NAME_LENGTH"
        );
        require(!nodeOperatorIdsByName.exists(_name), "NAME_ALREADY_EXISTS");
    }

    modifier onlyExistingNodeOperator(uint256 _nodeOperatorId) {
        require(
            _nodeOperatorId < nodeOperatorsCount,
            "node operator does not exist"
        );
        _;
    }

    modifier onlyNodeOperatorManager(uint256 _nodeOperatorId) {
        require(
            nodeOperators[_nodeOperatorId].rewardAddress == msg.sender,
            "sender is not eligible to manage node operator"
        );
        _;
    }
}
