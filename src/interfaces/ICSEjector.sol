// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSAccounting } from "./ICSAccounting.sol";
import { IAssetRecovererLib } from "../lib/AssetRecovererLib.sol";
import { ICSParametersRegistry } from "./ICSParametersRegistry.sol";
import { ICSModule } from "./ICSModule.sol";

struct MarkedUint248 {
    uint248 value;
    bool isValue;
}

struct ExitPenaltyInfo {
    MarkedUint248 delayPenalty;
    MarkedUint248 strikesPenalty;
    uint256 withdrawalRequestFee;
}

interface ICSEjector is IAssetRecovererLib {
    error SigningKeysInvalidOffset();
    error AlreadyWithdrawn();
    error ZeroAdminAddress();
    error ZeroModuleAddress();
    error ZeroParametersRegistryAddress();
    error ZeroAccountingAddress();
    error NotEnoughStrikesToEject();
    error NodeOperatorDoesNotExist();
    error SenderIsNotEligible();
    error SenderIsNotModule();
    error ValidatorExitDelayNotApplicable();

    event ValidatorExitDelayProcessed(
        uint256 indexed nodeOperatorId,
        bytes pubkey,
        uint256 delayPenalty
    );
    event TriggeredExitFeeRecorded(
        uint256 indexed nodeOperatorId,
        uint256 indexed exitType,
        bytes pubkey,
        uint256 withdrawalRequestFee
    );
    event BadPerformancePenaltyProcessed(
        uint256 indexed nodeOperatorId,
        bytes pubkey,
        uint256 badPerformancePenalty
    );

    function PAUSE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function BAD_PERFORMER_EJECTOR_ROLE() external view returns (bytes32);

    function MODULE() external view returns (ICSModule);

    function ACCOUNTING() external view returns (ICSAccounting);

    /// @notice Pause ejection methods calls
    /// @param duration Duration of the pause in seconds
    function pauseFor(uint256 duration) external;

    /// @notice Resume ejection methods calls
    function resume() external;

    /// @notice Process the delayed exit report
    /// @param nodeOperatorId ID of the Node Operator
    /// @param publicKey Public key of the validator
    /// @param eligibleToExitInSec The time in seconds when the validator is eligible to exit
    function processExitDelayReport(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 eligibleToExitInSec
    ) external;

    /// @notice Process the triggered exit report
    /// @param nodeOperatorId ID of the Node Operator
    /// @param publicKey Public key of the validator
    /// @param withdrawalRequestPaidFee The fee paid for the withdrawal request
    /// @param exitType The type of the exit (0 - direct exit, 1 - forced exit)
    function processTriggeredExit(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 withdrawalRequestPaidFee,
        uint256 exitType
    ) external;

    /// @notice Withdraw the validator key from the Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the withdrawn key in the Node Operator's keys storage
    function voluntaryEject(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external payable;

    /// @notice Report Node Operator's key as bad performer and eject it with corresponding penalty
    /// @notice Called by the `CSStrikes` contract.
    ///         See `CSStrikes.processBadPerformanceProof` to use this method permissionless
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the withdrawn key in the Node Operator's keys storage
    /// @param strikes Strikes of the Node Operator's validator key
    function ejectBadPerformer(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 strikes
    ) external payable;

    /// @notice Determines whether a validator exit status should be updated and will have affect on Node Operator.
    /// @dev called only by CSM
    /// @param nodeOperatorId The ID of the node operator.
    /// @param publicKey Validator's public key.
    /// @param eligibleToExitInSec The number of seconds the validator was eligible to exit but did not.
    /// @return bool Returns true if contract should receive updated validator's status.
    function isValidatorExitDelayPenaltyApplicable(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 eligibleToExitInSec
    ) external view returns (bool);

    /// @notice get delayed exit penalty info for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @param publicKey Public key of the validator
    /// @return penaltyInfo Delayed exit penalty info
    function getDelayedExitPenaltyInfo(
        uint256 nodeOperatorId,
        bytes calldata publicKey
    ) external view returns (ExitPenaltyInfo memory penaltyInfo);
}
