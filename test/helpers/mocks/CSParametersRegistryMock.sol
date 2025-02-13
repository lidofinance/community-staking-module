// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

struct MarkedQueueConfig {
    uint32 priority;
    uint32 maxDeposits;
    bool isValue;
}

contract CSParametersRegistryMock {
    uint256 public keyRemovalCharge = 0.01 ether;

    uint256 public QUEUE_LOWEST_PRIORITY = 5;
    uint256 public QUEUE_LEGACY_PRIORITY = 4;

    mapping(uint256 curveId => MarkedQueueConfig) internal _queueConfigs;

    function getKeyRemovalCharge(
        uint256 /* curveId */
    ) external view returns (uint256) {
        return keyRemovalCharge;
    }

    function setKeyRemovalCharge(
        uint256 /* curveId */,
        uint256 charge
    ) external {
        keyRemovalCharge = charge;
    }

    function getElRewardsStealingAdditionalFine(
        uint256 /* curveId */
    ) external pure returns (uint256) {
        return 0.1 ether;
    }

    function setQueueConfig(
        uint256 curveId,
        uint32 priority,
        uint32 maxDeposits
    ) external {
        _queueConfigs[curveId] = MarkedQueueConfig({
            priority: priority,
            maxDeposits: maxDeposits,
            isValue: true
        });
    }

    function getQueueConfig(
        uint256 curveId
    ) external view returns (uint32 priority, uint32 maxDeposits) {
        MarkedQueueConfig storage config = _queueConfigs[curveId];

        if (!config.isValue) {
            // NOTE: To preserve the old corpus of tests.
            return (uint32(QUEUE_LOWEST_PRIORITY), type(uint32).max);
        }

        return (config.priority, config.maxDeposits);
    }
}
