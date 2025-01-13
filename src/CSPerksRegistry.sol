// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSPerksRegistry } from "./interfaces/ICSPerksRegistry.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CSPerksRegistry is
    ICSPerksRegistry,
    Initializable,
    AccessControlEnumerableUpgradeable
{
    uint256 internal constant MAX_BP = 10000;

    mapping(uint256 => uint256) internal _priorityQueueLimits;

    mapping(uint256 => uint256[]) internal _rewardSharePivotsData;
    mapping(uint256 => uint256[]) internal _rewardShareValuesData;

    mapping(uint256 => uint256[]) internal _performanceLeewayPivotsData;
    mapping(uint256 => uint256[]) internal _performanceLeewayValuesData;

    constructor() {
        _disableInitializers();
    }

    /// @notice initialize contract
    function initialize(address admin) external initializer {
        if (admin == address(0)) revert ZeroAdminAddress();
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICSPerksRegistry
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

    /// @inheritdoc ICSPerksRegistry
    function getRewardShareData(
        uint256 curveId
    )
        external
        view
        returns (uint256[] memory keyPivots, uint256[] memory rewardShares)
    {
        if (_rewardShareValuesData[curveId].length == 0) revert NoData();
        return (
            _rewardSharePivotsData[curveId],
            _rewardShareValuesData[curveId]
        );
    }

    /// @inheritdoc ICSPerksRegistry
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

    /// @inheritdoc ICSPerksRegistry
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
        if (_performanceLeewayValuesData[curveId].length == 0) revert NoData();
        return (
            _performanceLeewayPivotsData[curveId],
            _performanceLeewayValuesData[curveId]
        );
    }

    /// @inheritdoc ICSPerksRegistry
    function setPriorityQueueLimit(
        uint256 curveId,
        uint256 limit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _priorityQueueLimits[curveId] = limit;
        emit PriorityQueueLimitSet(curveId, limit);
    }

    /// @inheritdoc ICSPerksRegistry
    function getPriorityQueueLimit(
        uint256 curveId
    ) external view returns (uint256 limit) {
        return _priorityQueueLimits[curveId];
    }
}
