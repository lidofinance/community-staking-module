// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStakingModule } from "./interfaces/IStakingModule.sol";
import "./interfaces/ICommunityStakingBondManager.sol";

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

    ICommunityStakingBondManager private BOND_MANAGER;

    constructor(bytes32 _type) {
        moduleType = _type;
        nodeOperatorsCount = 0;
    }

    function setBondManager(address _bondManager) external {
        // TODO add role check
        require(address(BOND_MANAGER) == address(0), "already initialized");
        BOND_MANAGER = ICommunityStakingBondManager(_bondManager);
    }

    function getBondManager() external view returns (address) {
        return address(BOND_MANAGER);
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

    function addNodeOperator(
        string calldata _name,
        address _rewardAddress,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
    ) external {
        // TODO sanity checks
        // TODO store keys
        uint256 id = getNodeOperatorsCount();
        NodeOperator storage no = nodeOperators[id];
        no.name = _name;
        no.rewardAddress = _rewardAddress;
        no.active = true;
        no.totalAddedValidators = _keysCount;
        nodeOperatorsCount++;
        activeNodeOperatorsCount++;

        uint256 shares = BOND_MANAGER.getRequiredBondShares(id);
        BOND_MANAGER.deposit(msg.sender, id, shares);

        _incrementNonce();
    }

    function addValidatorKeys(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes calldata /*_publicKeys*/,
        bytes calldata /*_signatures*/
    ) external {
        // TODO sanity checks
        // TODO store keys
        require(
            nodeOperators[_nodeOperatorId].active,
            "node operator is not active"
        );
        NodeOperator storage no = nodeOperators[_nodeOperatorId];
        no.totalAddedValidators += _keysCount;
        uint256 shares = BOND_MANAGER.getRequiredBondShares(_nodeOperatorId);
        BOND_MANAGER.deposit(msg.sender, _nodeOperatorId, shares);

        _incrementNonce();
    }

    function depositBond(uint256 _nodeOperatorId, uint256 _shares) external {
        // TODO sanity checks
        require(
            nodeOperators[_nodeOperatorId].active,
            "node operator is not active"
        );
        BOND_MANAGER.deposit(msg.sender, _nodeOperatorId, _shares);

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
}
