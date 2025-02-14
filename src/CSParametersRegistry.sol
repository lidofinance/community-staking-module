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
    mapping(uint256 => MarkedUint248) internal _keyRemovalCharges;

    uint256 public defaultElRewardsStealingAdditionalFine;
    mapping(uint256 => MarkedUint248)
        internal _elRewardsStealingAdditionalFines;

    uint256 public defaultPriorityQueueLimit;
    mapping(uint256 => MarkedUint248) internal _priorityQueueLimits;

    /// @dev Default value for the reward share. Can be only be set as a flat value due to possible sybil attacks
    ///      Decreased reward share for some validators > N will promote sybils. Increased reward share for validators > N will give large operators an advantage
    uint256 public defaultRewardShare;
    mapping(uint256 => PivotsAndValues) internal _rewardShareData;

    /// @dev Default value for the performance leeway. Can be only be set as a flat value due to possible sybil attacks
    ///      Decreased performance leeway for some validators > N will promote sybils. Increased performance leeway for validators > N will give large operators an advantage
    uint256 public defaultPerformanceLeeway;
    mapping(uint256 => PivotsAndValues) internal _performanceLeewayData;

    StrikesParams public defaultStrikesParams;
    mapping(uint256 => MarkedStrikesParams) internal _strikesParams;

    uint256 public defaultBadPerformancePenalty;
    mapping(uint256 => MarkedUint248) internal _badPerformancePenalties;

    PerformanceCoefficients public defaultPerformanceCoefficients;
    mapping(uint256 => MarkedPerformanceCoefficients)
        internal _performanceCoefficients;

    constructor() {
        _disableInitializers();
    }

    /// @notice initialize contract
    function initialize(
        address admin,
        InitializationData calldata data
    ) external initializer {
        if (admin == address(0)) revert ZeroAdminAddress();

        _setDefaultKeyRemovalCharge(data.keyRemovalCharge);
        _setDefaultElRewardsStealingAdditionalFine(
            data.elRewardsStealingAdditionalFine
        );
        _setDefaultPriorityQueueLimit(data.priorityQueueLimit);
        _setDefaultRewardShare(data.rewardShare);
        _setDefaultPerformanceLeeway(data.performanceLeeway);
        _setDefaultStrikesParams(data.strikesLifetime, data.strikesThreshold);
        _setDefaultBadPerformancePenalty(data.badPerformancePenalty);
        _setDefaultPerformanceCoefficients(
            data.attestationsWeight,
            data.blocksWeight,
            data.syncWeight
        );

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
        _setDefaultElRewardsStealingAdditionalFine(fine);
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
    function setDefaultStrikesParams(
        uint256 lifetime,
        uint256 threshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultStrikesParams(lifetime, threshold);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultBadPerformancePenalty(
        uint256 penalty
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultBadPerformancePenalty(penalty);
    }

    /// @inheritdoc ICSParametersRegistry
    function setDefaultPerformanceCoefficients(
        uint256 attestationsWeight,
        uint256 blocksWeight,
        uint256 syncWeight
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultPerformanceCoefficients(
            attestationsWeight,
            blocksWeight,
            syncWeight
        );
    }

    /// @inheritdoc ICSParametersRegistry
    function setKeyRemovalCharge(
        uint256 curveId,
        uint256 keyRemovalCharge
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _keyRemovalCharges[curveId] = MarkedUint248(
            keyRemovalCharge.toUint248(),
            true
        );
        emit KeyRemovalChargeSet(curveId, keyRemovalCharge);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetKeyRemovalCharge(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _keyRemovalCharges[curveId];
        emit KeyRemovalChargeUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setElRewardsStealingAdditionalFine(
        uint256 curveId,
        uint256 fine
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _elRewardsStealingAdditionalFines[curveId] = MarkedUint248(
            fine.toUint248(),
            true
        );
        emit ElRewardsStealingAdditionalFineSet(curveId, fine);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetElRewardsStealingAdditionalFine(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _elRewardsStealingAdditionalFines[curveId];
        emit ElRewardsStealingAdditionalFineUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setPriorityQueueLimit(
        uint256 curveId,
        uint256 limit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _priorityQueueLimits[curveId] = MarkedUint248(limit.toUint248(), true);
        emit PriorityQueueLimitSet(curveId, limit);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetPriorityQueueLimit(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _priorityQueueLimits[curveId];
        emit PriorityQueueLimitUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setRewardShareData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata rewardShares
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 keyPivotsLength = keyPivots.length;
        uint256 rewardSharesLength = rewardShares.length;
        if (keyPivotsLength + 1 != rewardSharesLength)
            revert InvalidRewardShareData();
        if (keyPivotsLength > 0 && keyPivots[0] == 0)
            revert InvalidRewardShareData();
        if (keyPivotsLength > 1) {
            for (uint256 i = 0; i < keyPivotsLength - 1; ++i) {
                if (keyPivots[i] >= keyPivots[i + 1])
                    revert InvalidRewardShareData();
            }
        }
        for (uint256 i = 0; i < rewardSharesLength; ++i) {
            if (rewardShares[i] > MAX_BP) revert InvalidRewardShareData();
        }
        _rewardShareData[curveId] = PivotsAndValues({
            pivots: keyPivots,
            values: rewardShares
        });

        emit RewardShareDataSet(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetRewardShareData(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _rewardShareData[curveId];

        emit RewardShareDataUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setPerformanceLeewayData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata performanceLeeways
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 keyPivotsLength = keyPivots.length;
        uint256 performanceLeewaysLength = performanceLeeways.length;
        if (keyPivotsLength + 1 != performanceLeewaysLength)
            revert InvalidPerformanceLeewayData();
        if (keyPivotsLength > 0 && keyPivots[0] == 0)
            revert InvalidPerformanceLeewayData();
        if (keyPivotsLength > 1) {
            for (uint256 i = 0; i < keyPivotsLength - 1; ++i) {
                if (keyPivots[i] >= keyPivots[i + 1])
                    revert InvalidPerformanceLeewayData();
            }
        }
        for (uint256 i = 0; i < performanceLeewaysLength; ++i) {
            if (performanceLeeways[i] > MAX_BP)
                revert InvalidPerformanceLeewayData();
        }
        _performanceLeewayData[curveId] = PivotsAndValues({
            pivots: keyPivots,
            values: performanceLeeways
        });

        emit PerformanceLeewayDataSet(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetPerformanceLeewayData(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _performanceLeewayData[curveId];

        emit PerformanceLeewayDataUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setStrikesParams(
        uint256 curveId,
        uint256 lifetime,
        uint256 threshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _validateStrikesParams(lifetime, threshold);
        _strikesParams[curveId] = MarkedStrikesParams(
            lifetime.toUint32(),
            threshold.toUint32(),
            true
        );
        emit StrikesParamsSet(curveId, lifetime, threshold);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetStrikesParams(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _strikesParams[curveId];
        emit StrikesParamsUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setBadPerformancePenalty(
        uint256 curveId,
        uint256 penalty
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _badPerformancePenalties[curveId] = MarkedUint248(
            penalty.toUint248(),
            true
        );
        emit BadPerformancePenaltySet(curveId, penalty);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetBadPerformancePenalty(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _badPerformancePenalties[curveId];
        emit BadPerformancePenaltyUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setPerformanceCoefficients(
        uint256 curveId,
        uint256 attestationsWeight,
        uint256 blocksWeight,
        uint256 syncWeight
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _performanceCoefficients[curveId] = MarkedPerformanceCoefficients(
            attestationsWeight.toUint32(),
            blocksWeight.toUint32(),
            syncWeight.toUint32(),
            true
        );
        emit PerformanceCoefficientsSet(
            curveId,
            attestationsWeight,
            blocksWeight,
            syncWeight
        );
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetPerformanceCoefficients(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _performanceCoefficients[curveId];
        emit PerformanceCoefficientsUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function getKeyRemovalCharge(
        uint256 curveId
    ) external view returns (uint256 keyRemovalCharge) {
        MarkedUint248 memory data = _keyRemovalCharges[curveId];
        return data.isValue ? data.value : defaultKeyRemovalCharge;
    }

    /// @inheritdoc ICSParametersRegistry
    function getElRewardsStealingAdditionalFine(
        uint256 curveId
    ) external view returns (uint256 fine) {
        MarkedUint248 memory data = _elRewardsStealingAdditionalFines[curveId];
        return
            data.isValue ? data.value : defaultElRewardsStealingAdditionalFine;
    }

    /// @inheritdoc ICSParametersRegistry
    function getPriorityQueueLimit(
        uint256 curveId
    ) external view returns (uint256 limit) {
        MarkedUint248 memory data = _priorityQueueLimits[curveId];
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
        PivotsAndValues memory rewardShareData = _rewardShareData[curveId];
        if (rewardShareData.pivots.length == 0) {
            rewardShares = new uint256[](1);
            rewardShares[0] = defaultRewardShare;
            return (new uint256[](0), rewardShares);
        }
        return (rewardShareData.pivots, rewardShareData.values);
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
        PivotsAndValues memory performanceLeewayData = _performanceLeewayData[
            curveId
        ];
        if (performanceLeewayData.pivots.length == 0) {
            performanceLeeways = new uint256[](1);
            performanceLeeways[0] = defaultPerformanceLeeway;
            return (new uint256[](0), performanceLeeways);
        }
        return (performanceLeewayData.pivots, performanceLeewayData.values);
    }

    /// @inheritdoc ICSParametersRegistry
    function getStrikesParams(
        uint256 curveId
    ) external view returns (uint256 lifetime, uint256 threshold) {
        MarkedStrikesParams memory params = _strikesParams[curveId];
        if (!params.isValue) {
            return (
                defaultStrikesParams.lifetime,
                defaultStrikesParams.threshold
            );
        }
        return (params.lifetime, params.threshold);
    }

    /// @inheritdoc ICSParametersRegistry
    function getBadPerformancePenalty(
        uint256 curveId
    ) external view returns (uint256 penalty) {
        MarkedUint248 memory data = _badPerformancePenalties[curveId];
        return data.isValue ? data.value : defaultBadPerformancePenalty;
    }

    /// @inheritdoc ICSParametersRegistry
    function getPerformanceCoefficients(
        uint256 curveId
    )
        external
        view
        returns (
            uint256 attestationsWeight,
            uint256 blocksWeight,
            uint256 syncWeight
        )
    {
        MarkedPerformanceCoefficients
            memory coefficients = _performanceCoefficients[curveId];
        if (!coefficients.isValue) {
            return (
                defaultPerformanceCoefficients.attestationsWeight,
                defaultPerformanceCoefficients.blocksWeight,
                defaultPerformanceCoefficients.syncWeight
            );
        }
        return (
            coefficients.attestationsWeight,
            coefficients.blocksWeight,
            coefficients.syncWeight
        );
    }

    function _setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) internal {
        defaultKeyRemovalCharge = keyRemovalCharge;
        emit DefaultKeyRemovalChargeSet(keyRemovalCharge);
    }

    function _setDefaultElRewardsStealingAdditionalFine(uint256 fine) internal {
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

    function _setDefaultStrikesParams(
        uint256 lifetime,
        uint256 threshold
    ) internal {
        _validateStrikesParams(lifetime, threshold);
        defaultStrikesParams = StrikesParams({
            lifetime: lifetime.toUint32(),
            threshold: threshold.toUint32()
        });
        emit DefaultStrikesParamsSet(lifetime, threshold);
    }

    function _setDefaultBadPerformancePenalty(uint256 penalty) internal {
        defaultBadPerformancePenalty = penalty;
        emit DefaultBadPerformancePenaltySet(penalty);
    }

    function _setDefaultPerformanceCoefficients(
        uint256 attestationsWeight,
        uint256 blocksWeight,
        uint256 syncWeight
    ) internal {
        defaultPerformanceCoefficients = PerformanceCoefficients({
            attestationsWeight: attestationsWeight.toUint32(),
            blocksWeight: blocksWeight.toUint32(),
            syncWeight: syncWeight.toUint32()
        });
        emit DefaultPerformanceCoefficientsSet(
            attestationsWeight,
            blocksWeight,
            syncWeight
        );
    }

    function _validateStrikesParams(
        uint256 lifetime,
        uint256 threshold
    ) internal pure {
        if (lifetime < threshold || lifetime < 1) revert InvalidStrikesParams();
    }
}
