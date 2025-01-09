// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSBenefitsRegistry {
    event RewardShareDataSet(uint256 indexed curveId);
    event PerformanceLeewayDataSet(uint256 indexed curveId);
    event PriorityQueueLimitSet(uint256 indexed curveId, uint256 limit);

    error InvalidRewardShareData();
    error InvalidPerformanceLeewayData();
    error InvalidPriorityQueueLimit();
    error NoData();
    error ZeroAdminAddress();

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
    /// @dev keyPivots = [100, 500] and performanceLeeways = [500, 450, 400] stands for
    ///      5% performance leeway for the keys 1-100, 4.5% performance leeway for the keys 101-500, and 4% performance leeway for the keys > 500
    /// @param curveId Curve Id to associate performance leeway data with
    /// @param keyPivots Pivot numbers of the keys (ex. [100, 500])
    /// @param performanceLeeways Performance leeway percentages in BP (ex. [500, 450, 400])
    function setPerformanceLeewayData(
        uint256 curveId,
        uint256[] calldata keyPivots,
        uint256[] calldata performanceLeeways
    ) external;

    /// @notice Get performance leeway parameters by the curveId.
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

    /// @notice Set priority queue limit for the curveId.
    /// @dev The first `limit` keys for the Node Operator with the given `curveId` will be placed in the priority queue.
    /// @param curveId Curve Id to associate priority queue limit with
    /// @param limit Priority queue limit
    function setPriorityQueueLimit(uint256 curveId, uint256 limit) external;

    /// @notice Get priority queue limit by the curveId.
    /// @dev Default value is returned if the value is not set for the given curveId.
    /// @dev The first `limit` keys for the Node Operator with the given `curveId` will be placed in the priority queue.
    /// @param curveId Curve Id to get priority queue limit for
    /// @return limit Priority queue limit
    function getPriorityQueueLimit(
        uint256 curveId
    ) external view returns (uint256 limit);
}
