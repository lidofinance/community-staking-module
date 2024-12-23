// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;
import "../../../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";

contract CSMMock {
    function createNodeOperator(
        address from,
        NodeOperatorManagementProperties memory managementProperties,
        address referrer
    ) external returns (uint256) {
        return 0;
    }

    function addValidatorKeysETH(
        address from,
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures
    ) external payable {}

    function addValidatorKeysStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        ICSAccounting.PermitInput memory permit
    ) external {}

    function addValidatorKeysWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        ICSAccounting.PermitInput memory permit
    ) external {}

    function claimBeneficialBondCurve(
        uint256 nodeOperatorId,
        uint256 curveId
    ) external {}
}
