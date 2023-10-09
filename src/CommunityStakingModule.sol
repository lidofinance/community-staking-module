// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ICommunityStakingBondManager } from "./interfaces/ICommunityStakingBondManager.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { IQueue } from "./interfaces/IQueue.sol";
import { ILido } from "./interfaces/ILido.sol";

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
    uint256 private nodeOperatorsCount;
    uint256 private activeNodeOperatorsCount;
    bytes32 private moduleType;
    uint256 private nonce;
    mapping(uint256 => NodeOperator) private nodeOperators;

    bytes32 public constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    address public bondManagerAddress;
    address public lidoLocator;
    address public queue;

    event VettedSigningKeysCountChanged(
        uint256 indexed nodeOperatorId,
        uint256 approvedValidatorsCount
    );

    constructor(bytes32 _type, address _locator, address _queue) {
        moduleType = _type;
        nodeOperatorsCount = 0;

        require(_locator != address(0), "lido locator is zero address");
        lidoLocator = _locator;

        require(_queue != address(0), "Queue address is zero address");
        queue = _queue;
    }

    function setBondManager(address _bondManagerAddress) external {
        // TODO add role check
        require(
            address(bondManagerAddress) == address(0),
            "already initialized"
        );
        bondManagerAddress = _bondManagerAddress;
    }

    function _bondManager()
        internal
        view
        returns (ICommunityStakingBondManager)
    {
        return ICommunityStakingBondManager(bondManagerAddress);
    }

    function _lidoLocator() internal view returns (ILidoLocator) {
        return ILidoLocator(lidoLocator);
    }

    function _lido() internal view returns (ILido) {
        return ILido(_lidoLocator().lido());
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
        // TODO sanity checks
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        uint256 requiredEth = _lido().getPooledEthByShares(
            _bondManager().getRequiredBondSharesForKeys(_keysCount)
        );

        _bondManager().depositWstETH(
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
        // TODO sanity checks
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        _bondManager().depositStETH(
            msg.sender,
            id,
            _lido().getPooledEthByShares(
                _bondManager().getRequiredBondSharesForKeys(_keysCount)
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
        // TODO sanity checks

        require(
            msg.value >=
                _lido().getPooledEthByShares(
                    _bondManager().getRequiredBondSharesForKeys(_keysCount)
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

        _bondManager().depositETH{ value: msg.value }(msg.sender, id);

        _addSigningKeys(id, _keysCount, _publicKeys, _signatures);

        emit NodeOperatorAdded(id, _name, _rewardAddress);
    }

    function addValidatorKeysWstETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata _publicKeys,
        bytes calldata _signatures
    ) external onlyActiveNodeOperator(_nodeOperatorId) {
        // TODO sanity checks
        // TODO store keys

        uint256 requiredEth = _lido().getPooledEthByShares(
            _bondManager().getRequiredBondShares(_nodeOperatorId, _keysCount)
        );

        _bondManager().depositWstETH(
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
        // TODO sanity checks
        // TODO store keys

        _bondManager().depositStETH(
            msg.sender,
            _nodeOperatorId,
            _lido().getPooledEthByShares(
                _bondManager().getRequiredBondShares(
                    _nodeOperatorId,
                    _keysCount
                )
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
        // TODO sanity checks
        // TODO store keys

        require(
            msg.value >=
                _lido().getPooledEthByShares(
                    _bondManager().getRequiredBondShares(
                        _nodeOperatorId,
                        _keysCount
                    )
                ),
            "not enough eth to deposit"
        );

        _bondManager().depositETH{ value: msg.value }(
            msg.sender,
            _nodeOperatorId
        );

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
        // TODO implement
    }

    function updateStuckValidatorsCount(
        bytes calldata /*_nodeOperatorIds*/,
        bytes calldata /*_stuckValidatorsCounts*/
    ) external {
        // TODO implement
    }

    function updateExitedValidatorsCount(
        bytes calldata _nodeOperatorIds,
        bytes calldata _exitedValidatorsCounts
    ) external {
        // TODO implement
        //        emit ExitedKeysCountChanged(
        //            _nodeOperatorId,
        //            _exitedValidatorsCount
        //        );
    }

    function updateRefundedValidatorsCount(
        uint256 /*_nodeOperatorId*/,
        uint256 /*_refundedValidatorsCount*/
    ) external {
        // TODO implement
    }

    function updateTargetValidatorsLimits(
        uint256 /*_nodeOperatorId*/,
        bool /*_isTargetLimitActive*/,
        uint256 /*_targetLimit*/
    ) external {
        // TODO implement
    }

    function onExitedAndStuckValidatorsCountsUpdated() external {
        // TODO implement
    }

    function unsafeUpdateValidatorsCount(
        uint256 /*_nodeOperatorId*/,
        uint256 /*_exitedValidatorsKeysCount*/,
        uint256 /*_stuckValidatorsKeysCount*/
    ) external {
        // TODO implement
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

        uint64 end = _vettedKeysCount - 1;

        bytes32 pointer = Batch.serialize({
            nodeOperatorId: SafeCast.toUint128(_nodeOperatorId),
            start: start,
            end: end
        });

        no.totalVettedKeys = _vettedKeysCount;
        IQueue(queue).enqueue(pointer);
        emit VettedSigningKeysCountChanged(_nodeOperatorId, _vettedKeysCount);
    }

    function unvetKeys(uint64 _nodeOperatorId) external {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        no.totalVettedKeys = no.totalDepositedKeys;
        emit VettedSigningKeysCountChanged(
            _nodeOperatorId,
            no.totalVettedKeys
        );
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
        uint256 limit = _depositsCount;

        for (bytes32 p = IQueue(queue).front(); !Batch.isNil(p); ) {
            (uint256 nodeOperatorId, uint256 start, uint256 end) = Batch
                .deserialize(p);

            (
                bytes memory _batchKeys,
                bytes memory _batchSigs,
                uint256 _batchSize
            ) = _obtainKeysForBatch(nodeOperatorId, start, end, limit);

            publicKeys = bytes.concat(publicKeys, _batchKeys);
            signatures = bytes.concat(signatures, _batchSigs);

            // @dev _batchSize <= limit, forced by _obtainKeysForBatch
            limit = limit - _batchSize;
            if (limit == 0) {
                break;
            }

            p = IQueue(queue).front();
        }
    }

    function _obtainKeysForBatch(
        uint256 _nodeOperatorId,
        uint256 _start,
        uint256 _end,
        uint256 limit
    )
        internal
        returns (
            bytes memory publicKeys,
            bytes memory signatures,
            uint256 count
        )
    {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];

        require(_start <= _end, "invalid range");

        require(_end < no.totalVettedKeys, "NO was unvetted");
        require(_end < no.totalAddedKeys, "not enough keys");

        require(
            no.totalDepositedKeys >= _start,
            "invalid range: skipped keys"
        );

        uint256 _startIndex = Math.max(_start, no.totalDepositedKeys);
        uint256 _endIndex = Math.min(_end, _startIndex + limit);
        count = _endIndex - _startIndex + 1;

        no.totalDepositedKeys = _endIndex + 1;
        if (_end == _endIndex) {
            IQueue(queue).dequeue();
        }

        SigningKeys.loadKeysSigs(
            SIGNING_KEYS_POSITION,
            _nodeOperatorId,
            _startIndex,
            count,
            publicKeys,
            signatures,
            0
        );
    }

    /// @dev returns the next pointer to start cleanup from
    function cleanDepositQueue(
        uint256 maxItems,
        bytes32 pointer
    ) external returns (bytes32) {
        if (Batch.isNil(pointer)) {
            pointer = IQueue(queue).frontPointer();
        }

        for (uint256 i; i < maxItems; i++) {
            bytes32 item = IQueue(queue).at(pointer);
            if (Batch.isNil(item)) {
                break;
            }

            (uint256 nodeOperatorId, , uint256 end) = Batch.deserialize(item);
            if (_unvettedKeysInBatch(nodeOperatorId, end)) {
                IQueue(queue).remove(pointer, item);
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
        if (Batch.isNil(pointer)) {
            pointer = IQueue(queue).frontPointer();
        }

        for (uint256 i; i < maxItems; i++) {
            bytes32 item = IQueue(queue).at(pointer);
            if (Batch.isNil(item)) {
                break;
            }

            (uint256 nodeOperatorId, , uint256 end) = Batch.deserialize(item);
            if (_unvettedKeysInBatch(nodeOperatorId, end)) {
                return (true, pointer);
            }

            pointer = item;
        }

        return (false, pointer);
    }

    function _unvettedKeysInBatch(
        uint256 _nodeOperatorId,
        uint256 _end
    ) internal view returns (bool) {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        return _end < no.totalVettedKeys;
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
