// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract CSParametersRegistry is
    ICSParametersRegistry,
    Initializable,
    AccessControlEnumerableUpgradeable
{
    using SafeCast for uint256;

    uint256 internal constant MAX_BP = 10000;

    uint256 public defaultKeyRemovalCharge;
    mapping(uint256 => markedUint248) internal _keyRemovalCharges;

    uint256 public defaultElRewardsStealingAdditionalFine;
    mapping(uint256 => markedUint248) internal _elRewardsStealingAdditionalFine;

    uint256 public defaultPriorityQueueLimit;
    mapping(uint256 => markedUint248) internal _priorityQueueLimits;

    /// @dev Default value for the reward share. Can be only be set as a flat value due to possible sybil attacks
    uint256 public defaultRewardShare;
    mapping(uint256 => uint256[]) internal _rewardSharePivotsData;
    mapping(uint256 => uint256[]) internal _rewardShareValuesData;

    /// @dev Default value for the reward share. Can be only be set as a flat value due to possible sybil attacks
    uint256 public defaultPerformanceLeeway;
    mapping(uint256 => uint256[]) internal _performanceLeewayPivotsData;
    mapping(uint256 => uint256[]) internal _performanceLeewayValuesData;

    uint256 public defaultStrikesLifetime;
    mapping(uint256 => markedUint248) internal _strikesLifetimes;

    uint256 public defaultStrikesThreshold;
    mapping(uint256 => markedUint248) internal _strikesThresholds;

    constructor() {
        _disableInitializers();
    }

    /// @notice initialize contract
    function initialize(
        address admin,
        initializationData calldata data
    ) external initializer {
        if (admin == address(0)) revert ZeroAdminAddress();

        _setDefaultKeyRemovalCharge(data.keyRemovalCharge);
        _setElRewardsStealingAdditionalFine(
            data.elRewardsStealingAdditionalFine
        );
        _setDefaultPriorityQueueLimit(data.priorityQueueLimit);
        _setDefaultRewardShare(data.rewardShare);
        _setDefaultPerformanceLeeway(data.performanceLeeway);
        _setDefaultStrikesLifetime(data.strikesLifetime);
        _setDefaultStrikesThreshold(data.strikesThreshold);

        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultKeyRemovalCharge(
        uint256 keyRemovalCharge
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultKeyRemovalCharge(keyRemovalCharge);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultElRewardsStealingAdditionalFine(
        uint256 fine
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setElRewardsStealingAdditionalFine(fine);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultPriorityQueueLimit(
        uint256 limit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultPriorityQueueLimit(limit);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultRewardShare(
        uint256 share
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRewardShare(share);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultPerformanceLeeway(
        uint256 leeway
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultPerformanceLeeway(leeway);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultStrikesLifetime(
        uint256 lifetime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultStrikesLifetime(lifetime);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultStrikesThreshold(
        uint256 threshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultStrikesThreshold(threshold);
    }

    /// @inheritdoc ICSParametersRegistry
    function setKeyRemovalCharge(
        uint256 curveId,
        uint256 keyRemovalCharge
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _keyRemovalCharges[curveId] = markedUint248(
            keyRemovalCharge.toUint248(),
            true
        );
        emit KeyRemovalChargeSet(curveId, keyRemovalCharge);
    }

    /// @inheritdoc ICSParametersRegistry
    function setElRewardsStealingAdditionalFine(
        uint256 curveId,
        uint256 fine
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _elRewardsStealingAdditionalFine[curveId] = markedUint248(
            fine.toUint248(),
            true
        );
        emit ElRewardsStealingAdditionalFineSet(curveId, fine);
    }

    /// @inheritdoc ICSParametersRegistry
    function setPriorityQueueLimit(
        uint256 curveId,
        uint256 limit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _priorityQueueLimits[curveId] = markedUint248(limit.toUint248(), true);
        emit PriorityQueueLimitSet(curveId, limit);
    }

    /// @inheritdoc ICSParametersRegistry
    function setRewardShareData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata rewardShares
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (keyPivots.length + 1 != rewardShares.length)
            revert InvalidRewardShareData();
        if (keyPivots.length > 0 && keyPivots[0] == 0)
            revert InvalidRewardShareData();
        if (keyPivots.length > 1) {
            for (uint256 i = 0; i < keyPivots.length - 1; ++i) {
                if (keyPivots[i] >= keyPivots[i + 1])
                    revert InvalidRewardShareData();
            }
        }
        for (uint256 i = 0; i < rewardShares.length; ++i) {
            if (rewardShares[i] > MAX_BP) revert InvalidRewardShareData();
        }
        _rewardSharePivotsData[curveId] = keyPivots;
        _rewardShareValuesData[curveId] = rewardShares;

        emit RewardShareDataSet(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setPerformanceLeewayData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata performanceLeeways
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (keyPivots.length + 1 != performanceLeeways.length)
            revert InvalidPerformanceLeewayData();
        if (keyPivots.length > 0 && keyPivots[0] == 0)
            revert InvalidPerformanceLeewayData();
        if (keyPivots.length > 1) {
            for (uint256 i = 0; i < keyPivots.length - 1; ++i) {
                if (keyPivots[i] >= keyPivots[i + 1])
                    revert InvalidPerformanceLeewayData();
            }
        }
        for (uint256 i = 0; i < performanceLeeways.length; ++i) {
            if (performanceLeeways[i] > MAX_BP)
                revert InvalidPerformanceLeewayData();
        }
        _performanceLeewayPivotsData[curveId] = keyPivots;
        _performanceLeewayValuesData[curveId] = performanceLeeways;

        emit PerformanceLeewayDataSet(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setStrikesLifetime(
        uint256 curveId,
        uint256 lifetime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _strikesLifetimes[curveId] = markedUint248(lifetime.toUint248(), true);
        emit StrikesLifetimeSet(curveId, lifetime);
    }

    /// @inheritdoc ICSParametersRegistry
    function setStrikesThreshold(
        uint256 curveId,
        uint256 threshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _strikesThresholds[curveId] = markedUint248(
            threshold.toUint248(),
            true
        );
        emit StrikesThresholdSet(curveId, threshold);
    }

    /// @inheritdoc ICSParametersRegistry
    function getKeyRemovalCharge(
        uint256 curveId
    ) external view returns (uint256 keyRemovalCharge) {
        markedUint248 memory data = _keyRemovalCharges[curveId];
        return data.isValue ? data.value : defaultKeyRemovalCharge;
    }

    /// @inheritdoc ICSParametersRegistry
    function getElRewardsStealingAdditionalFine(
        uint256 curveId
    ) external view returns (uint256 fine) {
        markedUint248 memory data = _elRewardsStealingAdditionalFine[curveId];
        return
            data.isValue ? data.value : defaultElRewardsStealingAdditionalFine;
    }

    /// @inheritdoc ICSParametersRegistry
    function getPriorityQueueLimit(
        uint256 curveId
    ) external view returns (uint256 limit) {
        markedUint248 memory data = _priorityQueueLimits[curveId];
        return data.isValue ? data.value : defaultPriorityQueueLimit;
    }

    /// @inheritdoc ICSParametersRegistry
    function getRewardShareData(
        uint256 curveId
    )
        external
        view
        returns (uint256[] memory keyPivots, uint256[] memory rewardShares)
    {
        if (_rewardShareValuesData[curveId].length == 0) {
            uint256[] memory values = new uint256[](1);
            values[0] = defaultRewardShare;
            return (new uint256[](0), values);
        }
        return (
            _rewardSharePivotsData[curveId],
            _rewardShareValuesData[curveId]
        );
    }

    /// @inheritdoc ICSParametersRegistry
    function getPerformanceLeewayData(
        uint256 curveId
    )
        external
        view
        returns (
            uint256[] memory keyPivots,
            uint256[] memory performanceLeeways
        )
    {
        if (_performanceLeewayValuesData[curveId].length == 0) {
            uint256[] memory values = new uint256[](1);
            values[0] = defaultPerformanceLeeway;
            return (new uint256[](0), values);
        }
        return (
            _performanceLeewayPivotsData[curveId],
            _performanceLeewayValuesData[curveId]
        );
    }

    /// @inheritdoc ICSParametersRegistry
    function getStrikesLifetime(
        uint256 curveId
    ) external view returns (uint256 lifetime) {
        markedUint248 memory data = _strikesLifetimes[curveId];
        return data.isValue ? data.value : defaultStrikesLifetime;
    }

    /// @inheritdoc ICSParametersRegistry
    function getStrikesThreshold(
        uint256 curveId
    ) external view returns (uint256 threshold) {
        markedUint248 memory data = _strikesThresholds[curveId];
        return data.isValue ? data.value : defaultStrikesThreshold;
    }

    function _setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) internal {
        defaultKeyRemovalCharge = keyRemovalCharge;
        emit DefaultKeyRemovalChargeSet(keyRemovalCharge);
    }

    function _setElRewardsStealingAdditionalFine(uint256 fine) internal {
        defaultElRewardsStealingAdditionalFine = fine;
        emit DefaultElRewardsStealingAdditionalFineSet(fine);
    }

    function _setDefaultPriorityQueueLimit(uint256 limit) internal {
        defaultPriorityQueueLimit = limit;
        emit DefaultPriorityQueueLimitSet(limit);
    }

    function _setDefaultRewardShare(uint256 share) internal {
        if (share > MAX_BP) revert InvalidRewardShareData();
        defaultRewardShare = share;
        emit DefaultRewardShareSet(share);
    }

    function _setDefaultPerformanceLeeway(uint256 leeway) internal {
        if (leeway > MAX_BP) revert InvalidPerformanceLeewayData();
        defaultPerformanceLeeway = leeway;
        emit DefaultPerformanceLeewaySet(leeway);
    }

    function _setDefaultStrikesLifetime(uint256 lifetime) internal {
        defaultStrikesLifetime = lifetime;
        emit DefaultStrikesLifetimeSet(lifetime);
    }

    function _setDefaultStrikesThreshold(uint256 threshold) internal {
        defaultStrikesThreshold = threshold;
        emit DefaultStrikesThresholdSet(threshold);
    }
}
