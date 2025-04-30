// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface IValidatorsExitBus {
    struct DirectExitData {
        uint256 stakingModuleId;
        uint256 nodeOperatorId;
        bytes validatorsPubkeys;
    }

    event DirectExitRequest(
        uint256 indexed stakingModuleId,
        uint256 indexed nodeOperatorId,
        bytes validatoPubkey,
        uint256 timestamp,
        address indexed refundRecipient
    );

    function triggerExitsDirectly(
        DirectExitData calldata exitData,
        address refundRecipient,
        uint8 exitType
    ) external payable;
}
