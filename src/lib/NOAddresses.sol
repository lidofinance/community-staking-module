// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { NodeOperator } from "../CSModule.sol";

/// Library for changing and reset node operator's manager and reward addresses
/// @dev the only use of this to be a library is to save CSModule contract size via delegatecalls
library NOAddresses {
    event NodeOperatorManagerAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address indexed proposedAddress
    );
    event NodeOperatorRewardAddressChangeProposed(
        uint256 indexed nodeOperatorId,
        address indexed proposedAddress
    );
    event NodeOperatorRewardAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed newAddress,
        address indexed oldAddress
    );
    event NodeOperatorManagerAddressChanged(
        uint256 indexed nodeOperatorId,
        address indexed newAddress,
        address indexed oldAddress
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
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.managerAddress != msg.sender) revert SenderIsNotManagerAddress();
        if (no.managerAddress == proposedAddress) revert SameAddress();
        if (no.proposedManagerAddress == proposedAddress)
            revert AlreadyProposed();

        no.proposedManagerAddress = proposedAddress;
        emit NodeOperatorManagerAddressChangeProposed(
            nodeOperatorId,
            proposedAddress
        );
    }

    function confirmNodeOperatorManagerAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.proposedManagerAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = no.managerAddress;
        no.managerAddress = msg.sender;
        delete no.proposedManagerAddress;

        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            msg.sender,
            oldAddress
        );
    }

    function proposeNodeOperatorRewardAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId,
        address proposedAddress
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.rewardAddress != msg.sender) revert SenderIsNotRewardAddress();
        if (no.rewardAddress == proposedAddress) revert SameAddress();
        if (no.proposedRewardAddress == proposedAddress)
            revert AlreadyProposed();

        no.proposedRewardAddress = proposedAddress;
        emit NodeOperatorRewardAddressChangeProposed(
            nodeOperatorId,
            proposedAddress
        );
    }

    function confirmNodeOperatorRewardAddressChange(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.proposedRewardAddress != msg.sender)
            revert SenderIsNotProposedAddress();
        address oldAddress = no.rewardAddress;
        no.rewardAddress = msg.sender;
        delete no.proposedRewardAddress;

        emit NodeOperatorRewardAddressChanged(
            nodeOperatorId,
            msg.sender,
            oldAddress
        );
    }

    function resetNodeOperatorManagerAddress(
        mapping(uint256 => NodeOperator) storage nodeOperators,
        uint256 nodeOperatorId
    ) external {
        NodeOperator storage no = nodeOperators[nodeOperatorId];
        if (no.rewardAddress != msg.sender) revert SenderIsNotRewardAddress();
        if (no.managerAddress == no.rewardAddress) revert SameAddress();
        address previousManagerAddress = no.managerAddress;

        no.managerAddress = msg.sender;
        if (no.proposedManagerAddress != address(0))
            delete no.proposedManagerAddress;

        // TODO: check owners ordering in OZ owner2step library
        emit NodeOperatorManagerAddressChanged(
            nodeOperatorId,
            no.rewardAddress,
            previousManagerAddress
        );
    }
}
