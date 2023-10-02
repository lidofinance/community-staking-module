// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IStakingModule } from "./interfaces/IStakingModule.sol";
import "./interfaces/ICommunityStakingBondManager.sol";
import "./interfaces/ILidoLocator.sol";
import "./interfaces/IQueue.sol";
import "./interfaces/ILido.sol";

import { Batch } from "./lib/Batch.sol";

struct NodeOperator {
    string name;
    address rewardAddress;
    bool active;
    uint256 targetLimit;
    uint256 targetLimitTimestamp;
    uint256 stuckPenaltyEndTimestamp;
    uint256 totalExitedValidators;
    uint256 totalAddedValidators;
    uint256 totalWithdrawnValidators;
    uint256 totalDepositedValidators;
    uint256 totalVettedValidators;
    uint256 stuckValidatorsCount;
    uint256 refundedValidatorsCount;
    bool isTargetLimitActive;
}

contract CommunityStakingModule is IStakingModule {
    uint256 private nodeOperatorsCount;
    uint256 private activeNodeOperatorsCount;
    bytes32 private moduleType;
    uint256 private nonce;
    mapping(uint256 => NodeOperator) private nodeOperators;

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
        // TODO implement
        return (0, 0, 0);
    }

    function addNodeOperatorWstETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
    ) external {
        // TODO sanity checks
        // TODO store keys
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        no.totalAddedValidators = _keysCount;
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

        _incrementNonce();
    }

    function addNodeOperatorStETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
    ) external {
        // TODO sanity checks
        // TODO store keys
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        no.totalAddedValidators = _keysCount;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        _bondManager().depositStETH(
            msg.sender,
            id,
            _lido().getPooledEthByShares(
                _bondManager().getRequiredBondSharesForKeys(_keysCount)
            )
        );

        _incrementNonce();
    }

    function addNodeOperatorETH(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
    ) external payable {
        // TODO sanity checks
        // TODO store keys

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
        no.totalAddedValidators = _keysCount;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        _bondManager().depositETH{ value: msg.value }(msg.sender, id);

        _incrementNonce();
    }

    function addValidatorKeysWstETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
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

        _incrementNonce();
    }

    function addValidatorKeysStETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
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

        _incrementNonce();
    }

    function addValidatorKeysETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
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

        _incrementNonce();
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
        totalExitedValidators = no.totalExitedValidators;
        totalDepositedValidators = no.totalDepositedValidators;
        totalAddedValidators = no.totalAddedValidators;
        totalWithdrawnValidators = no.totalWithdrawnValidators;
        totalVettedValidators = no.totalVettedValidators;
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
        totalExitedValidators = no.totalExitedValidators;
        totalDepositedValidators = no.totalDepositedValidators;
        depositableValidatorsCount = no.isTargetLimitActive
            ? no.targetLimit - no.totalDepositedValidators
            : 0;
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
        bytes calldata /*_nodeOperatorIds*/,
        bytes calldata /*_exitedValidatorsCounts*/
    ) external {
        // TODO implement
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
            _vettedKeysCount > no.totalVettedValidators,
            "Current vetted keys pointer is too far"
        );
        require(
            _vettedKeysCount <= no.totalAddedValidators,
            "New vetted keys pointer is too far"
        );

        uint256 prevVettedKeysCount = no.totalVettedValidators;
        no.totalVettedValidators = _vettedKeysCount;

        uint64 start = SafeCast.toUint64(
            prevVettedKeysCount == 0 ? 0 : prevVettedKeysCount - 1
        );

        uint64 end = _vettedKeysCount - 1;

        bytes32 pointer = Batch.serialize({
            nodeOperatorId: SafeCast.toUint64(_nodeOperatorId),
            start: start,
            end: end
        });

        IQueue(queue).enqueue(pointer);
        emit VettedSigningKeysCountChanged(_nodeOperatorId, _vettedKeysCount);
    }

    function unvetKeys(uint64 _nodeOperatorId) external {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        no.totalVettedValidators = no.totalDepositedValidators;
        emit VettedSigningKeysCountChanged(
            _nodeOperatorId,
            no.totalVettedValidators
        );
    }

    function onWithdrawalCredentialsChanged() external {
        revert("NOT_IMPLEMENTED");
    }

    function obtainDepositData(
        uint256 _depositsCount,
        bytes calldata /* _depositCalldata */
    ) external returns (bytes memory publicKeys, bytes memory signatures) {
        uint256 limit = _depositsCount;

        for (;;) {
            bytes32 p = IQueue(queue).peek();
            if (p == bytes32(0)) {
                break;
            }

            (uint256 nodeOperatorId, uint256 start, uint256 end) = Batch
                .deserialize(p);

            (
                bytes memory _batchKeys,
                bytes memory _batchSigs,
                uint256 _batchSize
            ) = _obtainKeysForBatch(nodeOperatorId, start, end, limit);

            publicKeys = bytes.concat(publicKeys, _batchKeys);
            signatures = bytes.concat(signatures, _batchSigs);

            limit = limit - _batchSize;
            if (limit == 0) {
                break;
            }
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

        require(_end < no.totalVettedValidators, "NO was unvetted");
        require(_end < no.totalAddedValidators, "not enough keys");

        require(
            no.totalDepositedValidators >= _start,
            "invalid range: skipped keys"
        );

        uint256 _startIndex = Math.max(_start, no.totalDepositedValidators);
        uint256 _endIndex = Math.min(_end, _startIndex + limit);

        no.totalDepositedValidators = _endIndex + 1;
        if (_end == _endIndex) {
            IQueue(queue).dequeue();
        }

        // TODO implement
        return (new bytes(0), new bytes(0), _endIndex - _startIndex + 1);
    }

    function cleanDepositQueue(uint256 batchesLimit) external {
        bytes32 _prev = IQueue(queue).prev();

        for (uint256 i; i < batchesLimit; i++) {
            bytes32 _peek = IQueue(queue).peek(_prev);
            if (_peek == bytes32(0)) {
                break;
            }

            (uint256 nodeOperatorId, uint256 start, uint256 end) = Batch
                .deserialize(_peek);
            if (!_allKeysInBatchVetted(nodeOperatorId, start, end)) {
                IQueue(queue).squash(_prev, _peek);
            }

            _prev = _peek;
        }
    }

    function isQueueHasUnvettedKeys(
        uint256 batchesLimit
    ) external view returns (bool) {
        bytes32 _prev = IQueue(queue).prev();

        for (uint256 i; i < batchesLimit; i++) {
            bytes32 _peek = IQueue(queue).peek(_prev);
            if (_peek == bytes32(0)) {
                break;
            }

            (uint256 nodeOperatorId, uint256 start, uint256 end) = Batch
                .deserialize(_peek);
            if (!_allKeysInBatchVetted(nodeOperatorId, start, end)) {
                return true;
            }

            _prev = _peek;
        }

        return false;
    }

    function _allKeysInBatchVetted(
        uint256 _nodeOperatorId,
        uint256 _start,
        uint256 _end
    ) internal view returns (bool) {
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        require(
            no.totalDepositedValidators >= _start,
            "invalid range: skipped keys"
        );
        return _end < no.totalVettedValidators;
    }

    function _incrementNonce() internal {
        nonce++;
    }

    modifier onlyActiveNodeOperator(uint256 _nodeOperatorId) {
        require(
            nodeOperators[_nodeOperatorId].active,
            "node operator is not active"
        );
        _;
    }
}
