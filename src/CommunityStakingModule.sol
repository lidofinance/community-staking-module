// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStakingModule } from "./interfaces/IStakingModule.sol";
import "./interfaces/ICommunityStakingBondManager.sol";
import "./interfaces/ILidoLocator.sol";
import "./interfaces/ILido.sol";

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

    constructor(bytes32 _type, address _locator) {
        moduleType = _type;
        nodeOperatorsCount = 0;

        require(_locator != address(0), "lido locator is zero address");
        lidoLocator = _locator;
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
        // TODO store keys
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        no.totalAddedKeys = _keysCount;
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
        // TODO store keys
        uint256 id = nodeOperatorsCount;
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        no.totalAddedKeys = _keysCount;
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
        no.totalAddedKeys = _keysCount;
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

        nodeOperators[_nodeOperatorId].totalAddedKeys += _keysCount;
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

        nodeOperators[_nodeOperatorId].totalAddedKeys += _keysCount;
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

        nodeOperators[_nodeOperatorId].totalAddedKeys += _keysCount;
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
        NodeOperator memory no = nodeOperators[_nodeOperatorId];
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
        // totalAddedKeys must be incremented before _addSigningKeys call
        uint256 _startIndex = nodeOperators[_nodeOperatorId].totalAddedKeys -
            _keysCount;

        SigningKeys.saveKeysSigs(
            SIGNING_KEYS_POSITION,
            _nodeOperatorId,
            _startIndex,
            _keysCount,
            _publicKeys,
            _signatures
        );
        _incrementNonce();

        emit TotalKeysCountChanged(
            _nodeOperatorId,
            nodeOperators[_nodeOperatorId].totalAddedKeys
        );
    }

    function obtainDepositData(
        uint256 _depositsCount,
        bytes calldata /*_depositCalldata*/
    ) external returns (bytes memory publicKeys, bytes memory signatures) {
        (publicKeys, signatures) = SigningKeys.initKeysSigsBuf(_depositsCount);
        uint256 loadedKeysCount = 0;
        for (
            uint256 nodeOperatorId;
            nodeOperatorId < nodeOperatorsCount;
            nodeOperatorId++
        ) {
            NodeOperator storage no = nodeOperators[nodeOperatorId];
            // TODO replace total added to total vetted later
            uint256 availableKeys = no.totalAddedKeys - no.totalDepositedKeys;
            if (availableKeys == 0) continue;

            uint256 _startIndex = no.totalDepositedKeys;
            uint256 _keysCount = _depositsCount > availableKeys
                ? availableKeys
                : _depositsCount;
            SigningKeys.loadKeysSigs(
                SIGNING_KEYS_POSITION,
                nodeOperatorId,
                _startIndex,
                _keysCount,
                publicKeys,
                signatures,
                loadedKeysCount
            );
            loadedKeysCount += _keysCount;
            // TODO maybe depositor bot should initiate this increment
            no.totalDepositedKeys += _keysCount;
            emit DepositedKeysCountChanged(
                nodeOperatorId,
                no.totalDepositedKeys
            );
        }
        if (loadedKeysCount != _depositsCount) {
            revert("NOT_ENOUGH_KEYS");
        }
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
