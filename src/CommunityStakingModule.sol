// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStakingModule } from "./interfaces/IStakingModule.sol";
import "./interfaces/ICommunityStakingBondManager.sol";
import "./interfaces/ILidoLocator.sol";
import "./interfaces/ILido.sol";

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
        // TODO implement
        return (0, 0, 0);
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

        uint256 shares = _bondManager().getRequiredBondSharesForKeys(
            _keysCount
        );
        _bondManager().depositStETH(msg.sender, id, shares);

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

        uint256 requiredEth = _bondManager().getRequiredBondEthForKeys(
            _keysCount
        );
        require(msg.value == requiredEth);

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

    function addValidatorKeysStETH(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
    ) external onlyActiveNodeOperator(_nodeOperatorId) {
        // TODO sanity checks
        // TODO store keys

        // add validators before to affect required bond shares calculation
        nodeOperators[_nodeOperatorId].totalAddedValidators += _keysCount;

        uint256 requiredShares = _bondManager().getRequiredBondShares(
            _nodeOperatorId
        );
        uint256 actualShares = _bondManager().getBondShares(_nodeOperatorId);
        uint256 sharesToDeposit = requiredShares - actualShares;
        if (sharesToDeposit < 0) {
            sharesToDeposit = 0;
        }

        _bondManager().depositStETH(
            msg.sender,
            _nodeOperatorId,
            sharesToDeposit
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

        // add validators before to affect required bond shares calculation
        nodeOperators[_nodeOperatorId].totalAddedValidators += _keysCount;

        uint256 receivedShares = _lido().getSharesByPooledEth(msg.value);
        uint256 requiredShares = _bondManager().getRequiredBondShares(
            _nodeOperatorId
        );
        uint256 actualShares = _bondManager().getBondShares(_nodeOperatorId);
        // TODO should it be here? - 1
        require(
            receivedShares >= (requiredShares - actualShares) - 1,
            "not enough eth"
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
        NodeOperator memory no = nodeOperators[_nodeOperatorId];
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

    function onWithdrawalCredentialsChanged() external {
        revert("NOT_IMPLEMENTED");
    }

    function obtainDepositData(
        uint256,
        /*_depositsCount*/ bytes calldata
    )
        external
        returns (bytes memory, /*publicKeys*/ bytes memory /*signatures*/)
    {
        revert("NOT_IMPLEMENTED");
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
