// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

contract CommunityStakingModuleMock {
    struct NodeOperator {
        bool active;
        address rewardAddress;
        uint64 totalVettedValidators;
        uint64 totalExitedValidators;
        uint64 totalWithdrawnValidators; // new
        uint64 totalAddedValidators;
        uint64 totalDepositedValidators;
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

    mapping(uint256 => NodeOperator) public nodeOperators;
    uint256 public totalNodeOperatorsCount;

    constructor() {}

    function setNodeOperator(
        uint256 _nodeOperatorId,
        bool _active,
        address _rewardAddress,
        uint64 _totalVettedValidators,
        uint64 _totalExitedValidators,
        uint64 _totalWithdrawnValidators,
        uint64 _totalAddedValidators,
        uint64 _totalDepositedValidators
    ) external {
        nodeOperators[_nodeOperatorId] = NodeOperator(
            _active,
            _rewardAddress,
            _totalVettedValidators,
            _totalExitedValidators,
            _totalWithdrawnValidators,
            _totalAddedValidators,
            _totalDepositedValidators
        );
        totalNodeOperatorsCount++;
    }

    /// @notice Returns the node operator by id
    /// @param nodeOperatorId Node Operator id
    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperatorInfo memory) {
        NodeOperator memory no = nodeOperators[nodeOperatorId];
        NodeOperatorInfo memory info;
        info.active = no.active;
        info.managerAddress = no.rewardAddress;
        info.rewardAddress = no.rewardAddress;
        info.totalVettedValidators = no.totalVettedValidators;
        info.totalExitedValidators = no.totalExitedValidators;
        info.totalWithdrawnValidators = no.totalWithdrawnValidators;
        info.totalAddedValidators = no.totalAddedValidators;
        info.totalDepositedValidators = no.totalDepositedValidators;
        return info;
    }

    function addValidator(uint256 _nodeOperatorId, uint256 _valsToAdd) public {
        nodeOperators[_nodeOperatorId].totalAddedValidators += uint64(
            _valsToAdd
        );
    }

    function getNodeOperatorsCount() external view returns (uint256) {
        return totalNodeOperatorsCount;
    }

    function onBondChanged(uint256 nodeOperatorId) external {
        // do nothing
    }

    function onRewardsDistributed(uint256 totalShares) external {
        // do nothing
    }
}
