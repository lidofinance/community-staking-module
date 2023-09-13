// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract CommunityStakingModuleMock {
    struct NodeOperator {
        bool active;
        string name;
        address rewardAddress;
        uint64 totalVettedValidators;
        uint64 totalExitedValidators;
        uint64 totalWithdrawnValidators; // new
        uint64 totalAddedValidators;
        uint64 totalDepositedValidators;
    }

    mapping(uint256 => NodeOperator) public nodeOperators;
    uint256 public totalNodeOperatorsCount;

    constructor() {}

    function setNodeOperator(
        uint256 _nodeOperatorId,
        bool _active,
        string memory _name,
        address _rewardAddress,
        uint64 _totalVettedValidators,
        uint64 _totalExitedValidators,
        uint64 _totalWithdrawnValidators,
        uint64 _totalAddedValidators,
        uint64 _totalDepositedValidators
    ) external {
        nodeOperators[_nodeOperatorId] = NodeOperator(
            _active,
            _name,
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
    /// @param _nodeOperatorId Node Operator id
    /// @param _fullInfo If true, name will be returned as well
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
            uint64 totalVettedValidators,
            uint64 totalExitedValidators,
            uint64 totalWithdrawnValidators, // new
            uint64 totalAddedValidators,
            uint64 totalDepositedValidators
        )
    {
        NodeOperator memory nodeOperator = nodeOperators[_nodeOperatorId];
        active = nodeOperator.active;
        rewardAddress = nodeOperator.rewardAddress;
        totalVettedValidators = nodeOperator.totalVettedValidators;
        totalExitedValidators = nodeOperator.totalExitedValidators;
        totalWithdrawnValidators = nodeOperator.totalWithdrawnValidators;
        totalAddedValidators = nodeOperator.totalAddedValidators;
        totalDepositedValidators = nodeOperator.totalDepositedValidators;
        if (_fullInfo) {
            name = nodeOperator.name;
        }
    }

    function getNodeOperatorsCount() external view returns (uint256) {
        return totalNodeOperatorsCount;
    }
}
