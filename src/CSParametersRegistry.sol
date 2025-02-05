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
    mapping(uint256 => MarkedUint248) internal _elRewardsStealingAdditionalFine;

    PriorityQueueConfig public defaultPriorityQueueConfig;
    mapping(uint256 curveId => MarkedPriorityQueueConfig)
        internal _priorityQueueConfigs;

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

    uint256 public immutable LOWEST_PRIORITY;
    uint256 public immutable LEGACY_QUEUE_PRIORITY;

    constructor(uint256 lowestPriority) {
        _disableInitializers();
        LOWEST_PRIORITY = lowestPriority;
        LEGACY_QUEUE_PRIORITY = lowestPriority - 1;
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
        _setDefaultRewardShare(data.rewardShare);
        _setDefaultPerformanceLeeway(data.performanceLeeway);
        _setDefaultStrikesParams(data.strikesLifetime, data.strikesThreshold);

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
        _elRewardsStealingAdditionalFine[curveId] = MarkedUint248(
            fine.toUint248(),
            true
        );
        emit ElRewardsStealingAdditionalFineSet(curveId, fine);
    }

    /// @inheritdoc ICSParametersRegistry
    function unsetElRewardsStealingAdditionalFine(
        uint256 curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _elRewardsStealingAdditionalFine[curveId];
        emit ElRewardsStealingAdditionalFineUnset(curveId);
    }

    /// @inheritdoc ICSParametersRegistry
    function setRewardShareData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata rewardShares
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 keyPivotsLength = keyPivots.length;
        uint256 rewardSharesLength = rewardShares.length;
        if (keyPivotsLength + 1 != rewardSharesLength) {
            revert InvalidRewardShareData();
        }
        if (keyPivotsLength > 0 && keyPivots[0] == 0) {
            revert InvalidRewardShareData();
        }
        if (keyPivotsLength > 1) {
            for (uint256 i = 0; i < keyPivotsLength - 1; ++i) {
                if (keyPivots[i] >= keyPivots[i + 1]) {
                    revert InvalidRewardShareData();
                }
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
        if (keyPivotsLength + 1 != performanceLeewaysLength) {
            revert InvalidPerformanceLeewayData();
        }
        if (keyPivotsLength > 0 && keyPivots[0] == 0) {
            revert InvalidPerformanceLeewayData();
        }
        if (keyPivotsLength > 1) {
            for (uint256 i = 0; i < keyPivotsLength - 1; ++i) {
                if (keyPivots[i] >= keyPivots[i + 1]) {
                    revert InvalidPerformanceLeewayData();
                }
            }
        }
        for (uint256 i = 0; i < performanceLeewaysLength; ++i) {
            if (performanceLeeways[i] > MAX_BP) {
                revert InvalidPerformanceLeewayData();
            }
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
            lifetime.toUint128(),
            threshold.toUint120(),
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
        MarkedUint248 memory data = _elRewardsStealingAdditionalFine[curveId];
        return
            data.isValue ? data.value : defaultElRewardsStealingAdditionalFine;
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

    function setPriorityQueueConfig(
        uint256 curveId,
        PriorityQueueConfig memory config
    ) external {
        if (config.priority == LEGACY_QUEUE_PRIORITY) {
            revert QueueCannotBeUsed();
        }

        _priorityQueueConfigs[curveId] = MarkedPriorityQueueConfig({
            priority: config.priority,
            maxKeys: config.maxKeys,
            isValue: true
        });
    }

    function getPriorityQueueConfig(
        uint256 curveId
    ) external view returns (uint32 queuePriority, uint32 maxKeys) {
        MarkedPriorityQueueConfig storage config = _priorityQueueConfigs[
            curveId
        ];

        if (!config.isValue) {
            return (
                defaultPriorityQueueConfig.priority,
                defaultPriorityQueueConfig.maxKeys
            );
        }

        return (config.priority, config.maxKeys);
    }

    function _setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) internal {
        defaultKeyRemovalCharge = keyRemovalCharge;
        emit DefaultKeyRemovalChargeSet(keyRemovalCharge);
    }

    function _setDefaultElRewardsStealingAdditionalFine(uint256 fine) internal {
        defaultElRewardsStealingAdditionalFine = fine;
        emit DefaultElRewardsStealingAdditionalFineSet(fine);
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
            lifetime: lifetime.toUint128(),
            threshold: threshold.toUint128()
        });
        emit DefaultStrikesParamsSet(lifetime, threshold);
    }

    function _validateStrikesParams(
        uint256 lifetime,
        uint256 threshold
    ) internal pure {
        if (lifetime < threshold || lifetime < 1) revert InvalidStrikesParams();
    }
}
