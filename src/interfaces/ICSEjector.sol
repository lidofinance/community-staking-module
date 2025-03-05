// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSAccounting } from "./ICSAccounting.sol";
import { IAssetRecovererLib } from "../lib/AssetRecovererLib.sol";
import { ICSParametersRegistry } from "./ICSParametersRegistry.sol";
import { ICSModule } from "./ICSModule.sol";

interface ICSEjector is IAssetRecovererLib {
    error SigningKeysInvalidOffset();
    error AlreadyWithdrawn();
    error AlreadyEjected();
    error ZeroAdminAddress();
    error ZeroModuleAddress();
    error NotEnoughStrikesToEject();
    error NodeOperatorDoesNotExist();

    event EjectionSubmitted(
        uint256 indexed nodeOperatorId,
        uint256 keyIndex,
        bytes pubkey
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

    /// @notice Report Node Operator's key as bad performer and eject it with corresponding penalty
    /// @notice Called by the `CSStrikes` contract.
    ///         See `CSStrikes.processBadPerformanceProof` to use this method permissionless
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex Index of the withdrawn key in the Node Operator's keys storage
    /// @param strikesCount Strikes count of the Node Operator's validator key
    function ejectBadPerformer(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 strikesCount
    ) external;

    /// @notice Check if the given Node Operator's key is reported as ejected
    /// @param nodeOperatorId ID of the Node Operator
    /// @param keyIndex index of the key to check
    function isValidatorEjected(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool);
}
