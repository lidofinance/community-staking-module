// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

contract CSParametersRegistryMock {
    uint256 public keyRemovalCharge = 0.01 ether;

    uint256 public strikesLifetime = 6;
    uint256 public strikesThreshold = 3;

    uint256 public badPerformancePenalty = 0.01 ether;

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
}
