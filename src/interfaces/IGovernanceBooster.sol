// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSModule } from "./ICSModule.sol";
import { ICSAccounting } from "./ICSAccounting.sol";
import { ILDO } from "./ILDO.sol";
import { IDelegation } from "./IDelegation.sol";
import { IVoting } from "./IVoting.sol";

interface IGovernanceBooster {
    struct BoostInfo {
        bool boosted; // Whether the operator is boosted
        uint256 oldCurveId; // The old curve ID before the boost
        uint256 boostDeposit; // The amount of LDO tokens used for the boost
    }

    event NodeOperatorBoosted(
        address indexed sender,
        uint256 indexed nodeOperatorId,
        uint256 indexed curveId,
        uint256 boostDeposit
    );

    event NodeOperatorUnboosted(
        address indexed sender,
        uint256 indexed nodeOperatorId
    );

    event BoostDepositSet(uint256 boostDeposit);

    event CurveIdSet(uint256 curveId);

    event DelegateSet(address indexed delegate);

    event DelegationUpdated(address indexed delegate);

    error ZeroModuleAddress();
    error ZeroLDOAddress();
    error ZeroSnapshotDelegationAddress();
    error ZeroVotingAddress();
    error NotAllowedToRecover();
    error NotBoosted();
    error AlreadyBoosted();
    error NotOwnerOfNodeOperator();
    error InvalidCurveId();
    error InvalidBoostDeposit();
    error ZeroDelegateAddress();
    error ZeroAdminAddress();
    error CurveDoesNotExist();
    error InvalidDelegateAddress();
    error NodeOperatorDoesNotExist();
    error NotAllowedToBoost();

    function PAUSE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function RECOVERER_ROLE() external view returns (bytes32);

    function MODULE() external view returns (ICSModule);

    function ACCOUNTING() external view returns (ICSAccounting);

    function LDO() external view returns (ILDO);

    function SNAPSHOT_DELEGATION() external view returns (IDelegation);

    function VOTING() external view returns (IVoting);

    /// @notice Pause boosts and unboosts in the contract.
    /// @param duration Duration of the pause
    function pauseFor(uint256 duration) external;

    /// @notice Resume the contract
    function resume() external;

    /// @notice Boosts the Node Operator with the given ID. Locks LDO tokens and sets a boosted curve ID.
    /// @param nodeOperatorId The ID of the Node Operator to boost.
    function boostNodeOperator(uint256 nodeOperatorId) external;

    /// @notice Unboosts the Node Operator with the given ID. Unlocks LDO tokens and resets the curve ID.
    /// @param nodeOperatorId The ID of the Node Operator to unboost.
    function unboostNodeOperator(uint256 nodeOperatorId) external;

    /// @notice Returns whether the Node Operator is boosted.
    /// @param nodeOperatorId The ID of the Node Operator to check.
    function isOperatorBoosted(
        uint256 nodeOperatorId
    ) external view returns (bool);

    /// @notice Returns the boost information for the Node Operator.
    /// @param nodeOperatorId The ID of the Node Operator to check.
    function getBoostInfo(
        uint256 nodeOperatorId
    ) external view returns (BoostInfo memory);

    /// @notice Sets the boost deposit amount.
    /// @param _boostDeposit The new boost deposit amount.
    function setBoostDeposit(uint256 _boostDeposit) external;

    /// @notice Sets the curve ID for the boosts.
    /// @param _curveId The new curve ID.
    function setCurveId(uint256 _curveId) external;

    /// @notice Sets the delegate address for the boosts.
    /// @param _delegate The new delegate address.
    function setDelegate(address _delegate) external;
}
