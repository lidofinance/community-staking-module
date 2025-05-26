// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

struct MarkedQueueConfig {
    uint32 priority;
    uint32 maxDeposits;
    bool isValue;
}

contract CSParametersRegistryMock {
    uint256 public keyRemovalCharge = 0.01 ether;

    uint256 public keysLimit = 100_000;

    uint256 public strikesLifetime = 6;
    uint256 public strikesThreshold = 3;

    uint256 public badPerformancePenalty = 0.01 ether;

    uint256 public QUEUE_LOWEST_PRIORITY = 5;
    uint256 public QUEUE_LEGACY_PRIORITY = 4;

    uint256 public allowedExitDelay = 1 weeks;
    uint256 public exitDelayPenalty = 0.1 ether;
    uint256 public maxWithdrawalRequestFee = 1 ether;

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

    function getKeysLimit(
        uint256 /* curveId */
    ) external view returns (uint256) {
        return keysLimit;
    }

    function setKeysLimit(uint256 /* curveId */, uint256 limit) external {
        keysLimit = limit;
    }

    function getElRewardsStealingAdditionalFine(
        uint256 /* curveId */
    ) external pure returns (uint256) {
        return 0.1 ether;
    }

    function getStrikesParams(
        uint256 /* curveId */
    ) external view returns (uint256, uint256) {
        return (strikesLifetime, strikesThreshold);
    }

    function setStrikesParams(
        uint256 /* curveId */,
        uint256 lifetime,
        uint256 threshold
    ) external {
        strikesLifetime = lifetime;
        strikesThreshold = threshold;
    }

    function getBadPerformancePenalty(
        uint256 /* curveId */
    ) external view returns (uint256) {
        return badPerformancePenalty;
    }

    function setBadPerformancePenalty(
        uint256 /* curveId */,
        uint256 penalty
    ) external {
        badPerformancePenalty = penalty;
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

    function getAllowedExitDelay(
        uint256 /* curveId */
    ) external view returns (uint256) {
        return allowedExitDelay;
    }

    function getExitDelayPenalty(
        uint256 /* curveId */
    ) external view returns (uint256) {
        return exitDelayPenalty;
    }

    function setExitDelayPenalty(
        uint256 /* curveId */,
        uint256 penalty
    ) external {
        exitDelayPenalty = penalty;
    }

    function getMaxWithdrawalRequestFee(
        uint256 /* curveId */
    ) external view returns (uint256) {
        return maxWithdrawalRequestFee;
    }

    function setMaxWithdrawalRequestFee(
        uint256 /* curveId */,
        uint256 _maxWithdrawalRequestFee
    ) external {
        maxWithdrawalRequestFee = _maxWithdrawalRequestFee;
    }
}
