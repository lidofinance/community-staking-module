// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { NodeOperator, ICSModule } from "../interfaces/ICSModule.sol";

/// Library for changing and reset node operator's manager and reward addresses
/// @dev the only use of this to be a library is to save CSModule contract size via delegatecalls
interface INOAddresses {
    event NodeOperatorManagerAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address indexed oldProposedAddress,
        address indexed newProposedAddress
    );
    event NodeOperatorRewardAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address indexed oldProposedAddress,
        address indexed newProposedAddress
    );
    // args order as in https://github.com/OpenZeppelin/openzeppelin-contracts/blob/11dc5e3809ebe07d5405fe524385cbe4f890a08b/contracts/access/Ownable.sol#L33
    event NodeOperatorManagerAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed oldAddress,
        address indexed newAddress
    );
    // args order as in https://github.com/OpenZeppelin/openzeppelin-contracts/blob/11dc5e3809ebe07d5405fe524385cbe4f890a08b/contracts/access/Ownable.sol#L33
    event NodeOperatorRewardAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed oldAddress,
        address indexed newAddress
    );

    error AlreadyProposed();
    error SameAddress();
    error SenderIsNotManagerAddress();
    error SenderIsNotRewardAddress();
    error SenderIsNotProposedAddress();
    error MethodCallIsNotAllowed();
    error ZeroRewardAddress();
}

library NOAddresses {
    /// @notice Propose a new manager address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) {
            revert ICSModule.NodeOperatorDoesNotExist();
        }

        if (no.managerAddress != msg.sender) {
            revert INOAddresses.SenderIsNotManagerAddress();
        }

        if (no.managerAddress == proposedAddress) {
            revert INOAddresses.SameAddress();
        }

        if (no.proposedManagerAddress == proposedAddress) {
            revert INOAddresses.AlreadyProposed();
        }

        address oldProposedAddress = no.proposedManagerAddress;
        no.proposedManagerAddress = proposedAddress;

        emit INOAddresses.NodeOperatorManagerAddressChangeProposed(
            nodeOperatorId,
            oldProposedAddress,
            proposedAddress
        );
    }

    /// @notice Confirm a new manager address for the Node Operator.
    ///         Should be called from the currently proposed address
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorManagerAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) {
            revert ICSModule.NodeOperatorDoesNotExist();
        }

        if (no.proposedManagerAddress != msg.sender) {
            revert INOAddresses.SenderIsNotProposedAddress();
        }

        address oldAddress = no.managerAddress;
        no.managerAddress = msg.sender;
        delete no.proposedManagerAddress;

        emit INOAddresses.NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            oldAddress,
            msg.sender
        );
    }

    /// @notice Propose a new reward address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed reward address
    function proposeNodeOperatorRewardAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.rewardAddress == address(0)) {
            revert ICSModule.NodeOperatorDoesNotExist();
        }

        if (no.rewardAddress != msg.sender) {
            revert INOAddresses.SenderIsNotRewardAddress();
        }

        if (no.rewardAddress == proposedAddress) {
            revert INOAddresses.SameAddress();
        }

        if (no.proposedRewardAddress == proposedAddress) {
            revert INOAddresses.AlreadyProposed();
        }

        address oldProposedAddress = no.proposedRewardAddress;
        no.proposedRewardAddress = proposedAddress;

        emit INOAddresses.NodeOperatorRewardAddressChangeProposed(
            nodeOperatorId,
            oldProposedAddress,
            proposedAddress
        );
    }

    /// @notice Confirm a new reward address for the Node Operator.
    ///         Should be called from the currently proposed address
    /// @param nodeOperatorId ID of the Node Operator
    function confirmNodeOperatorRewardAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.rewardAddress == address(0)) {
            revert ICSModule.NodeOperatorDoesNotExist();
        }

        if (no.proposedRewardAddress != msg.sender) {
            revert INOAddresses.SenderIsNotProposedAddress();
        }

        address oldAddress = no.rewardAddress;
        no.rewardAddress = msg.sender;
        delete no.proposedRewardAddress;

        emit INOAddresses.NodeOperatorRewardAddressChanged(
            nodeOperatorId,
            oldAddress,
            msg.sender
        );
    }

    /// @notice Reset the manager address to the reward address.
    ///         Should be called from the reward address
    /// @param nodeOperatorId ID of the Node Operator
    function resetNodeOperatorManagerAddress(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.rewardAddress == address(0)) {
            revert ICSModule.NodeOperatorDoesNotExist();
        }

        if (no.extendedManagerPermissions) {
            revert INOAddresses.MethodCallIsNotAllowed();
        }

        if (no.rewardAddress != msg.sender) {
            revert INOAddresses.SenderIsNotRewardAddress();
        }

        if (no.managerAddress == no.rewardAddress) {
            revert INOAddresses.SameAddress();
        }

        address previousManagerAddress = no.managerAddress;

        no.managerAddress = no.rewardAddress;
        // @dev Gas golfing
        if (no.proposedManagerAddress != address(0)) {
            delete no.proposedManagerAddress;
        }

        emit INOAddresses.NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            previousManagerAddress,
            no.rewardAddress
        );
    }

    /// @notice Change rewardAddress if extendedManagerPermissions is enabled for the Node Operator.
    ///         Should be called from the current manager address
    /// @param nodeOperatorId ID of the Node Operator
    /// @param newAddress New reward address
    function changeNodeOperatorRewardAddress(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address newAddress
    ) external {
        if (newAddress == address(0)) {
            revert INOAddresses.ZeroRewardAddress();
        }
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) {
            revert ICSModule.NodeOperatorDoesNotExist();
        }

        if (!no.extendedManagerPermissions) {
            revert INOAddresses.MethodCallIsNotAllowed();
        }

        if (no.managerAddress != msg.sender) {
            revert INOAddresses.SenderIsNotManagerAddress();
        }

        address oldAddress = no.rewardAddress;
        no.rewardAddress = newAddress;
        // @dev Gas golfing
        if (no.proposedRewardAddress != address(0)) {
            delete no.proposedRewardAddress;
        }

        emit INOAddresses.NodeOperatorRewardAddressChanged(
            nodeOperatorId,
            oldAddress,
            newAddress
        );
    }
}
