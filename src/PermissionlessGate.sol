// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { IPermissionlessGate } from "./interfaces/IPermissionlessGate.sol";

/// @title PermissionlessGate
/// @notice Contract for adding new Node Operators with no any restrictions
contract PermissionlessGate is IPermissionlessGate {
    /// @dev Curve ID is the default bond curve ID from the accounting contract
    ///      No need to set it explicitly
    uint256 public immutable CURVE_ID;

    ICSModule public immutable CSM;
    ICSAccounting public immutable ACCOUNTING;

    error ZeroModuleAddress();

    constructor(address csm) {
        if (csm == address(0)) revert ZeroModuleAddress();

        CSM = ICSModule(csm);
        ACCOUNTING = ICSAccounting(CSM.accounting());
        CURVE_ID = ACCOUNTING.DEFAULT_BOND_CURVE_ID();
    }

    /// @inheritdoc IPermissionlessGate
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        address referrer
    ) external payable {
        uint256 nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );

        CSM.addValidatorKeysETH{ value: msg.value }({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures
        });
    }

    /// @inheritdoc IPermissionlessGate
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        ICSAccounting.PermitInput calldata permit,
        address referrer
    ) external {
        uint256 nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );

        CSM.addValidatorKeysStETH({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures,
            permit: permit
        });
    }

    /// @inheritdoc IPermissionlessGate
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        ICSAccounting.PermitInput calldata permit,
        address referrer
    ) external {
        uint256 nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );

        CSM.addValidatorKeysWstETH({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures,
            permit: permit
        });
    }
}
