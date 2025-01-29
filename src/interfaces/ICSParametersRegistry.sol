// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSParametersRegistry {
    struct MarkedUint248 {
        uint248 value;
        bool isValue;
    }

    struct StrikesParams {
        uint128 lifetime;
        uint128 threshold;
    }

    struct MarkedStrikesParams {
        uint128 lifetime;
        uint120 threshold;
        bool isValue;
    }

    struct InitializationData {
        uint256 keyRemovalCharge;
        uint256 elRewardsStealingAdditionalFine;
        uint256 priorityQueueLimit;
        uint256 rewardShare;
        uint256 performanceLeeway;
        uint256 strikesLifetime;
        uint256 strikesThreshold;
    }

    struct PivotsAndValues {
        uint256[] pivots;
        uint256[] values;
    }

    event DefaultKeyRemovalChargeSet(uint256 value);
    event DefaultElRewardsStealingAdditionalFineSet(uint256 value);
    event DefaultPriorityQueueLimitSet(uint256 value);
    event DefaultRewardShareSet(uint256 value);
    event DefaultPerformanceLeewaySet(uint256 value);
    event DefaultStrikesParamsSet(uint256 lifetime, uint256 threshold);

    event KeyRemovalChargeSet(
        uint256 indexed curveId,
        uint256 keyRemovalCharge
    );
    event ElRewardsStealingAdditionalFineSet(
        uint256 indexed curveId,
        uint256 fine
    );
    event PriorityQueueLimitSet(uint256 indexed curveId, uint256 limit);
    event RewardShareDataSet(uint256 indexed curveId);
    event PerformanceLeewayDataSet(uint256 indexed curveId);
    event StrikesParamsSet(
        uint256 indexed curveId,
        uint256 lifetime,
        uint256 threshold
    );
    event KeyRemovalChargeUnset(uint256 indexed curveId);
    event ElRewardsStealingAdditionalFineUnset(uint256 indexed curveId);
    event PriorityQueueLimitUnset(uint256 indexed curveId);
    event RewardShareDataUnset(uint256 indexed curveId);
    event PerformanceLeewayDataUnset(uint256 indexed curveId);
    event StrikesParamsUnset(uint256 indexed curveId);

    error InvalidRewardShareData();
    error InvalidPerformanceLeewayData();
    error InvalidStrikesParams();
    error ZeroAdminAddress();

    /// @notice Set default value for the key removal charge. Default value is used if a specific value is not set for the curveId
    /// @param keyRemovalCharge value to be set as default for the key removal charge
    function setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) external;

    /// @notice Get default value for the key removal charge
    function defaultKeyRemovalCharge() external returns (uint256);

    /// @notice Set default value for the EL rewards stealing additional fine. Default value is used if a specific value is not set for the curveId
    /// @param fine value to be set as default for the EL rewards stealing additional fine
    function setDefaultElRewardsStealingAdditionalFine(uint256 fine) external;

    /// @notice Get default value for the EL rewards stealing additional fine
    function defaultElRewardsStealingAdditionalFine()
        external
        returns (uint256);

    /// @notice Set default value for the priority queue limit. Default value is used if a specific value is not set for the curveId
    /// @param limit value to be set as default for the priority queue limit
    function setDefaultPriorityQueueLimit(uint256 limit) external;

    /// @notice Get default value for the priority queue limit
    function defaultPriorityQueueLimit() external returns (uint256);

    /// @notice Set default value for the reward share. Default value is used if a specific value is not set for the curveId
    /// @param share value to be set as default for the reward share
    function setDefaultRewardShare(uint256 share) external;

    /// @notice Get default value for the reward share
    function defaultRewardShare() external returns (uint256);

    /// @notice Set default value for the performance leeway. Default value is used if a specific value is not set for the curveId
    /// @param leeway value to be set as default for the performance leeway
    function setDefaultPerformanceLeeway(uint256 leeway) external;

    /// @notice Get default value for the performance leeway
    function defaultPerformanceLeeway() external returns (uint256);

    /// @notice Set default value for the strikes lifetime and threshold. Default value is used if a specific value is not set for the curveId
    /// @param lifetime value to be set as default for the strikes lifetime
    /// @param threshold value to be set as default for the strikes threshold
    function setDefaultStrikesParams(
        uint256 lifetime,
        uint256 threshold
    ) external;

    /// @notice Get default value for the strikes lifetime and threshold
    function defaultStrikesParams() external returns (uint128, uint128);

    /// @notice Set key removal charge for the curveId.
    /// @param curveId Curve Id to associate key removal charge with
    /// @param keyRemovalCharge Key removal charge
    function setKeyRemovalCharge(
        uint256 curveId,
        uint256 keyRemovalCharge
    ) external;

    /// @notice Unset key removal charge for the curveId
    /// @param curveId Curve Id to unset custom key removal charge for
    function unsetKeyRemovalCharge(uint256 curveId) external;

    /// @notice Get key removal charge by the curveId. A charge is taken from the bond for each removed key from CSM
    /// @dev `defaultKeyRemovalCharge` is returned if the value is not set for the given curveId.
    /// @param curveId Curve Id to get key removal charge for
    /// @return keyRemovalCharge Key removal charge
    function getKeyRemovalCharge(
        uint256 curveId
    ) external view returns (uint256 keyRemovalCharge);

    /// @notice Set EL rewards stealing additional fine for the curveId.
    /// @param curveId Curve Id to associate EL rewards stealing additional fine limit with
    /// @param fine EL rewards stealing additional fine
    function setElRewardsStealingAdditionalFine(
        uint256 curveId,
        uint256 fine
    ) external;

    /// @notice Unset EL rewards stealing additional fine for the curveId
    /// @param curveId Curve Id to unset custom EL rewards stealing additional fine for
    function unsetElRewardsStealingAdditionalFine(uint256 curveId) external;

    /// @notice Get EL rewards stealing additional fine by the curveId. Additional fine is added to the EL rewards stealing penalty by CSM
    /// @dev `defaultElRewardsStealingAdditionalFine` is returned if the value is not set for the given curveId.
    /// @param curveId Curve Id to get EL rewards stealing additional fine for
    /// @return fine EL rewards stealing additional fine
    function getElRewardsStealingAdditionalFine(
        uint256 curveId
    ) external view returns (uint256 fine);

    /// @notice Set priority queue limit for the curveId.
    /// @dev The first `limit` keys for the Node Operator with the given `curveId` will be placed in the priority queue.
    /// @param curveId Curve Id to associate priority queue limit with
    /// @param limit Priority queue limit
    function setPriorityQueueLimit(uint256 curveId, uint256 limit) external;

    /// @notice Unset priority queue limit for the curveId
    /// @param curveId Curve Id to unset custom priority queue limit for
    function unsetPriorityQueueLimit(uint256 curveId) external;

    /// @notice Get priority queue limit by the curveId.
    /// @dev Zero is returned if the value is not set for the given curveId.
    /// @dev The first `limit` keys for the Node Operator with the given `curveId` will be placed in the priority queue.
    /// @param curveId Curve Id to get priority queue limit for
    /// @return limit Priority queue limit
    function getPriorityQueueLimit(
        uint256 curveId
    ) external view returns (uint256 limit);

    /// @notice Set reward share parameters for the curveId
    /// @dev keyPivots = [10, 50] and rewardShares = [10000, 8000, 5000] stands for
    ///      100% rewards for the keys 1-10, 80% rewards for the keys 11-50, and 50% rewards for the keys > 50
    /// @param curveId Curve Id to associate reward share data with
    /// @param keyPivots Pivot numbers of the keys (ex. [10, 50])
    /// @param rewardShares Reward share percentages in BP (ex. [10000, 8000, 5000])
    function setRewardShareData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata rewardShares
    ) external;

    /// @notice Unset reward share parameters for the curveId
    /// @param curveId Curve Id to unset custom reward share parameters for
    function unsetRewardShareData(uint256 curveId) external;

    /// @notice Get reward share parameters by the curveId.
    /// @dev Reverts if the values are not set for the given curveId.
    /// @dev keyPivots = [10, 50] and rewardShares = [10000, 8000, 5000] stands for
    ///      100% rewards for the keys 1-10, 80% rewards for the keys 11-50, and 50% rewards for the keys > 50
    /// @param curveId Curve Id to get reward share data for
    /// @return keyPivots Pivot numbers of the keys (ex. [10, 50])
    /// @return rewardShares Reward share percentages in BP (ex. [10000, 8000, 5000])
    function getRewardShareData(
        uint256 curveId
    )
        external
        view
        returns (uint256[] memory keyPivots, uint256[] memory rewardShares);

    /// @notice Set performance leeway parameters for the curveId
    /// @dev keyPivots = [20, 100] and performanceLeeways = [500, 450, 400] stands for
    ///      5% performance leeway for the keys 1-20, 4.5% performance leeway for the keys 21-100, and 4% performance leeway for the keys > 100
    /// @param curveId Curve Id to associate performance leeway data with
    /// @param keyPivots Pivot numbers of the keys (ex. [20, 100])
    /// @param performanceLeeways Performance leeway percentages in BP (ex. [500, 450, 400])
    function setPerformanceLeewayData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata performanceLeeways
    ) external;

    /// @notice Unset performance leeway parameters for the curveId
    /// @param curveId Curve Id to unset custom performance leeway parameters for
    function unsetPerformanceLeewayData(uint256 curveId) external;

    /// @notice Get performance leeway parameters by the curveId
    /// @dev Reverts if the values are not set for the given curveId.
    /// @dev keyPivots = [100, 500] and performanceLeeways = [500, 450, 400] stands for
    ///      5% performance leeway for the keys 1-100, 4.5% performance leeway for the keys 101-500, and 4% performance leeway for the keys > 500
    /// @param curveId Curve Id to get performance leeway data for
    /// @return keyPivots Pivot numbers of the keys (ex. [100, 500])
    /// @return performanceLeeways Performance leeway percentages in BP (ex. [500, 450, 400])
    function getPerformanceLeewayData(
        uint256 curveId
    )
        external
        view
        returns (
            uint256[] memory keyPivots,
            uint256[] memory performanceLeeways
        );

    /// @notice Set performance strikes lifetime and threshold for the curveId
    /// @param curveId Curve Id to associate performance strikes lifetime and threshold with
    /// @param lifetime Number of CSM Perf Oracle frames after which performance strikes are no longer valid
    /// @param threshold Number of active strikes after which validator can be forcefully ejected
    function setStrikesParams(
        uint256 curveId,
        uint256 lifetime,
        uint256 threshold
    ) external;

    /// @notice Unset custom performance strikes lifetime and threshold for the curveId
    /// @param curveId Curve Id to unset custom performance strikes lifetime and threshold for
    function unsetStrikesParams(uint256 curveId) external;

    /// @notice Get performance strikes lifetime and threshold by the curveId
    /// @dev `defaultStrikesParams` are returned if the value is not set for the given curveId.
    /// @param curveId Curve Id to get performance strikes lifetime and threshold for
    /// @return lifetime Number of CSM Perf Oracle frames after which performance strikes are no longer valid
    /// @return threshold Number of active strikes after which validator can be forcefully ejected
    function getStrikesParams(
        uint256 curveId
    ) external view returns (uint256 lifetime, uint256 threshold);
}
