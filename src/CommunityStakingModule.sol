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

    event VettedKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 approvedKeysCount
    );
    event DepositedKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 depositedKeysCount
    );
    event ExitedKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 exitedKeysCount
    );
    event TotalKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 totalKeysCount
    );
}

contract CommunityStakingModule is IStakingModule, CommunityStakingModuleBase {
    using QueueLib for QueueLib.Queue;

    uint256 private nodeOperatorsCount;
    uint256 private activeNodeOperatorsCount;
    bytes32 private moduleType;
    uint256 private nonce;
    mapping(uint256 => NodeOperator) private nodeOperators;

    bytes32 public constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    QueueLib.Queue public queue;

    ICommunityStakingBondManager public bondManager;
    ILidoLocator public lidoLocator;

    event VettedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 approvedValidatorsCount
    );

    event StakingModuleTypeSet(bytes32 moduleType);

    constructor(bytes32 _type, address _locator) {
        moduleType = _type;
        emit StakingModuleTypeSet(_type);

        require(_locator != address(0), "lido locator is zero address");
        lidoLocator = ILidoLocator(_locator);
    }

    function setBondManager(address _bondManager) external {
        // TODO: add role check
        require(address(bondManager) == address(0), "already initialized");
        bondManager = ICommunityStakingBondManager(_bondManager);
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
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        )
    {
        for (uint256 i = 0; i < nodeOperatorsCount; i++) {
            totalExitedValidators += nodeOperators[i].totalExitedKeys;
            totalDepositedValidators += nodeOperators[i].totalDepositedKeys;
            depositableValidatorsCount +=
                nodeOperators[i].totalAddedKeys -
                nodeOperators[i].totalExitedKeys;
        }
        return (
            totalExitedValidators,
            totalDepositedValidators,
            depositableValidatorsCount
        );
    }

    function addNodeOperatorWstETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external {
        // TODO: sanity checks
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        uint256 requiredEth = _lido().getPooledEthByShares(
            bondManager.getRequiredBondSharesForKeys(_keysCount)
        );

        bondManager.depositWstETH(
            msg.sender,
            id,
            _lido().getSharesByPooledEth(requiredEth) // to get wstETH amount
        );

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
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositStETH(
            msg.sender,
            id,
            _lido().getPooledEthByShares(
                bondManager.getRequiredBondSharesForKeys(_keysCount)
            )
        );

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addNodeOperatorETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external payable {
        // TODO: sanity checks

        require(
            msg.value >=
                _lido().getPooledEthByShares(
                    bondManager.getRequiredBondSharesForKeys(_keysCount)
                ),
            "not enough eth to deposit"
        );

        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        bondManager.depositETH{ value: msg.value }(msg.sender, id);

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addValidatorKeysWstETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external onlyActiveNodeOperator(_nodeOperatorId) {
        // TODO: sanity checks

        uint256 requiredEth = _lido().getPooledEthByShares(
            bondManager.getRequiredBondShares(_nodeOperatorId, _keysCount)
        );

        bondManager.depositWstETH(
            msg.sender,
            _nodeOperatorId,
            _lido().getSharesByPooledEth(requiredEth) // to get wstETH amount
        );

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function addValidatorKeysStETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external onlyActiveNodeOperator(_nodeOperatorId) {
        // TODO: sanity checks

        bondManager.depositStETH(
            msg.sender,
            _nodeOperatorId,
            _lido().getPooledEthByShares(
                bondManager.getRequiredBondShares(_nodeOperatorId, _keysCount)
            )
        );

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function addValidatorKeysETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external payable onlyActiveNodeOperator(_nodeOperatorId) {
        // TODO: sanity checks

        require(
            msg.value >=
                _lido().getPooledEthByShares(
                    bondManager.getRequiredBondShares(
                        _nodeOperatorId,
                        _keysCount
                    )
                ),
            "not enough eth to deposit"
        );

        bondManager.depositETH{ value: msg.value }(msg.sender, _nodeOperatorId);

        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
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
        //        emit ExitedKeysCountChanged(
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

    // NOR signature
    function setNodeOperatorStakingLimit(
        uint256 _nodeOperatorId,
        uint64 _vettedKeysCount
    ) external {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];

        require(
            _vettedKeysCount > no.totalVettedKeys,
            "Current vetted keys pointer is too far"
        );
        require(
            _vettedKeysCount <= no.totalAddedKeys,
            "New vetted keys pointer is too far"
        );

        uint64 start = SafeCast.toUint64(
            no.totalVettedKeys == 0 ? 0 : no.totalVettedKeys - 1
        );

        bytes32 pointer = Batch.serialize({
            nodeOperatorId: SafeCast.toUint128(_nodeOperatorId),
            start: start,
            count: _vettedKeysCount
        });

        no.totalVettedKeys = _vettedKeysCount;
        queue.enqueue(pointer);
        emit VettedSigningKeysCountChanged(_nodeOperatorId, _vettedKeysCount);
    }

    function unvetKeys(uint64 _nodeOperatorId) external {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        no.totalVettedKeys = no.totalDepositedKeys;
        emit VettedSigningKeysCountChanged(_nodeOperatorId, no.totalVettedKeys);
    }

    function onWithdrawalCredentialsChanged() external {
        revert("NOT_IMPLEMENTED");
    }

    function _addSigningKeys(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) internal onlyActiveNodeOperator(_nodeOperatorId) {
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

        nodeOperators[_nodeOperatorId].totalAddedKeys += _keysCount;
        emit TotalKeysCountChanged(
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
                uint256 keysCount,
                bool noMoreKeys
            ) = _batchDepositableKeys(p, limit);

            if (noMoreKeys) {
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

            NodeOperator storage no = nodeOperators[nodeOperatorId];
            no.totalDepositedKeys += keysCount;
            emit DepositedKeysCountChanged(
                nodeOperatorId,
                no.totalDepositedKeys
            );

            // @dev keysCount <= limit, forced by _batchDepositableKeys
            limit = limit - keysCount;
            if (limit == 0) {
                break;
            }

            p = queue.peek();
        }

        require(loadedKeysCount == _depositsCount, "NOT_ENOUGH_KEYS");
    }

    function _batchDepositableKeys(
        bytes32 _batch,
        uint256 _limit
    )
        internal
        view
        returns (
            uint256 nodeOperatorId,
            uint256 startIndex,
            uint256 keysCount,
            bool noMoreKeys
        )
    {
        uint256 start;
        uint256 count;

        (nodeOperatorId, start, count) = Batch.deserialize(_batch);

        NodeOperator storage no = nodeOperators[nodeOperatorId];
        _assertIsValidBatch(no, start, count);

        startIndex = Math.max(start, no.totalDepositedKeys);
        uint256 depositableKeysCount = start + count - startIndex;
        keysCount = Math.min(_limit, depositableKeysCount);
        noMoreKeys = depositableKeysCount == keysCount;
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
}
