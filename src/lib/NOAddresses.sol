// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { NodeOperator } from "../CSModule.sol";

/// Library for changing and reset node operator's manager and reward addresses
/// @dev the only use of this to be a library is to save CSModule contract size via delegatecalls
library NOAddresses {
    event NodeOperatorManagerAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address proposedAddress
    );
    event NodeOperatorRewardAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address proposedAddress
    );
    event NodeOperatorRewardAddressChanged(
        uint256 indexed nodeOperatorId,
        address oldAddress,
        address newAddress
    );
    event NodeOperatorManagerAddressChanged(
        uint256 indexed nodeOperatorId,
        address oldAddress,
        address newAddress
    );

    error AlreadyProposed();
    error SameAddress();
    error SenderIsNotManagerAddress();
    error SenderIsNotRewardAddress();
    error SenderIsNotProposedAddress();

    function proposeNodeOperatorManagerAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        if (nodeOperators[nodeOperatorId].managerAddress != msg.sender)
            revert SenderIsNotManagerAddress();
        if (nodeOperators[nodeOperatorId].managerAddress == proposedAddress)
            revert SameAddress();
        if (
            nodeOperators[nodeOperatorId].proposedManagerAddress ==
            proposedAddress
        ) revert AlreadyProposed();

        nodeOperators[nodeOperatorId].proposedManagerAddress = proposedAddress;
        emit NodeOperatorManagerAddressChangeProposed(
            nodeOperatorId,
            proposedAddress
        );
    }

    function confirmNodeOperatorManagerAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        if (nodeOperators[nodeOperatorId].proposedManagerAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = nodeOperators[nodeOperatorId].managerAddress;
        nodeOperators[nodeOperatorId].managerAddress = msg.sender;
        nodeOperators[nodeOperatorId].proposedManagerAddress = address(0);
        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            oldAddress,
            msg.sender
        );
    }

    function proposeNodeOperatorRewardAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        if (nodeOperators[nodeOperatorId].rewardAddress != msg.sender)
            revert SenderIsNotRewardAddress();
        if (nodeOperators[nodeOperatorId].rewardAddress == proposedAddress)
            revert SameAddress();
        if (
            nodeOperators[nodeOperatorId].proposedRewardAddress ==
            proposedAddress
        ) revert AlreadyProposed();

        nodeOperators[nodeOperatorId].proposedRewardAddress = proposedAddress;
        emit NodeOperatorRewardAddressChangeProposed(
            nodeOperatorId,
            proposedAddress
        );
    }

    function confirmNodeOperatorRewardAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        if (nodeOperators[nodeOperatorId].proposedRewardAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = nodeOperators[nodeOperatorId].rewardAddress;
        nodeOperators[nodeOperatorId].rewardAddress = msg.sender;
        nodeOperators[nodeOperatorId].proposedRewardAddress = address(0);
        emit NodeOperatorRewardAddressChanged(
            nodeOperatorId,
            oldAddress,
            msg.sender
        );
    }

    function resetNodeOperatorManagerAddress(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        if (nodeOperators[nodeOperatorId].rewardAddress != msg.sender)
            revert SenderIsNotRewardAddress();
        if (
            nodeOperators[nodeOperatorId].managerAddress ==
            nodeOperators[nodeOperatorId].rewardAddress
        ) revert SameAddress();
        address previousManagerAddress = nodeOperators[nodeOperatorId]
            .managerAddress;
        nodeOperators[nodeOperatorId].managerAddress = msg.sender;
        if (nodeOperators[nodeOperatorId].proposedManagerAddress != address(0))
            nodeOperators[nodeOperatorId].proposedManagerAddress = address(0);
        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            previousManagerAddress,
            nodeOperators[nodeOperatorId].rewardAddress
        );
    }
}
