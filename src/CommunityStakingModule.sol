// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStakingModule } from "./interfaces/IStakingModule.sol";

contract CommunityStakingModule is IStakingModule {
    uint256 private nodeOperatorsCount;
    bytes32 private moduleType;

    constructor(bytes32 _type) {
        moduleType = _type;
        nodeOperatorsCount = 0;
    }

    function getType() external view returns (bytes32) {
        return moduleType;
    }

    function getStakingModuleSummary()
        external
        view
        returns (
            uint256 /*totalExitedValidators*/,
            uint256 /*totalDepositedValidators*/,
            uint256 /*depositableValidatorsCount*/
        )
    {
        revert("NOT_IMPLEMENTED");
    }

    function getNodeOperatorSummary(
        uint256 /*_nodeOperatorId*/
    )
        external
        view
        returns (
            bool /*isTargetLimitActive*/,
            uint256 /*targetValidatorsCount*/,
            uint256 /*stuckValidatorsCount*/,
            uint256 /*refundedValidatorsCount*/,
            uint256 /*stuckPenaltyEndTimestamp*/,
            uint256 /*totalExitedValidators*/,
            uint256 /*totalDepositedValidators*/,
            uint256 /*depositableValidatorsCount*/
        )
    {
        revert("NOT_IMPLEMENTED");
    }

    function getNonce() external view returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function getNodeOperatorsCount() public view returns (uint256) {
        return nodeOperatorsCount;
    }

    function getActiveNodeOperatorsCount() external view returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function getNodeOperatorIsActive(
        uint256 /*_nodeOperatorId*/
    ) external view returns (bool) {
        revert("NOT_IMPLEMENTED");
    }

    function getNodeOperatorIds(
        uint256 /*_offset*/,
        uint256 /*_limit*/
    ) external view returns (uint256[] memory /*nodeOperatorIds*/) {
        revert("NOT_IMPLEMENTED");
    }

    function onRewardsMinted(uint256 /*_totalShares*/) external {
        revert("NOT_IMPLEMENTED");
    }

    function updateStuckValidatorsCount(
        bytes calldata /*_nodeOperatorIds*/,
        bytes calldata /*_stuckValidatorsCounts*/
    ) external {
        revert("NOT_IMPLEMENTED");
    }

    function updateExitedValidatorsCount(
        bytes calldata /*_nodeOperatorIds*/,
        bytes calldata /*_exitedValidatorsCounts*/
    ) external {
        revert("NOT_IMPLEMENTED");
    }

    function updateRefundedValidatorsCount(
        uint256 /*_nodeOperatorId*/,
        uint256 /*_refundedValidatorsCount*/
    ) external {
        revert("NOT_IMPLEMENTED");
    }

    function updateTargetValidatorsLimits(
        uint256 /*_nodeOperatorId*/,
        bool /*_isTargetLimitActive*/,
        uint256 /*_targetLimit*/
    ) external {
        revert("NOT_IMPLEMENTED");
    }

    function onExitedAndStuckValidatorsCountsUpdated() external {
        revert("NOT_IMPLEMENTED");
    }

    function unsafeUpdateValidatorsCount(
        uint256 /*_nodeOperatorId*/,
        uint256 /*_exitedValidatorsKeysCount*/,
        uint256 /*_stuckValidatorsKeysCount*/
    ) external {
        revert("NOT_IMPLEMENTED");
    }

    function onWithdrawalCredentialsChanged() external {
        revert("NOT_IMPLEMENTED");
    }

    function obtainDepositData(
        uint256 /*_depositsCount*/,
        bytes calldata
    )
        external
        returns (bytes memory /*publicKeys*/, bytes memory /*signatures*/)
    {
        revert("NOT_IMPLEMENTED");
    }
}
