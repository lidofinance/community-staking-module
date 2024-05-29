// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { NodeOperator } from "../interfaces/ICSModule.sol";

/// Library for changing and reset node operator's manager and reward addresses
/// @dev the only use of this to be a library is to save CSModule contract size via delegatecalls
library NOAddresses {
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
    event NodeOperatorRewardAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed oldAddress,
        address indexed newAddress
    );
    event NodeOperatorManagerAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed oldAddress,
        address indexed newAddress
    );

    error AlreadyProposed();
    error SameAddress();
    error SenderIsNotManagerAddress();
    error SenderIsNotRewardAddress();
    error SenderIsNotProposedAddress();
    error NodeOperatorDoesNotExist();

    /// @notice Propose a new manager address for the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param proposedAddress Proposed manager address
    function proposeNodeOperatorManagerAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.managerAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.managerAddress != msg.sender) revert SenderIsNotManagerAddress();
        if (no.managerAddress == proposedAddress) revert SameAddress();
        if (no.proposedManagerAddress == proposedAddress)
            revert AlreadyProposed();

        address oldProposedAddress = no.proposedManagerAddress;
        no.proposedManagerAddress = proposedAddress;
        emit NodeOperatorManagerAddressChangeProposed(
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
        if (no.managerAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.proposedManagerAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = no.managerAddress;
        no.managerAddress = msg.sender;
        delete no.proposedManagerAddress;

        emit NodeOperatorManagerAddressChanged(
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
        if (no.rewardAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.rewardAddress != msg.sender) revert SenderIsNotRewardAddress();
        if (no.rewardAddress == proposedAddress) revert SameAddress();
        if (no.proposedRewardAddress == proposedAddress)
            revert AlreadyProposed();

        address oldProposedAddress = no.proposedRewardAddress;
        no.proposedRewardAddress = proposedAddress;
        emit NodeOperatorRewardAddressChangeProposed(
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
        if (no.rewardAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.proposedRewardAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = no.rewardAddress;
        no.rewardAddress = msg.sender;
        delete no.proposedRewardAddress;

        emit NodeOperatorRewardAddressChanged(
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
        if (no.rewardAddress == address(0)) revert NodeOperatorDoesNotExist();
        if (no.rewardAddress != msg.sender) revert SenderIsNotRewardAddress();
        if (no.managerAddress == no.rewardAddress) revert SameAddress();
        address previousManagerAddress = no.managerAddress;

        no.managerAddress = no.rewardAddress;
        // @dev Gas golfing
        if (no.proposedManagerAddress != address(0))
            delete no.proposedManagerAddress;

        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            previousManagerAddress,
            no.rewardAddress
        );
    }
}
