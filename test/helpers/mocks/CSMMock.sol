// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;
import { NodeOperatorManagementProperties, NodeOperator } from "../../../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";

contract CSMMock {
    uint256 public constant DEFAULT_BOND_CURVE_ID = 0;
    NodeOperator internal mockNodeOperator;

    function accounting() external view returns (ICSAccounting) {
        return ICSAccounting(address(this));
    }

    function mock_setNodeOperator(NodeOperator memory no) external {
        mockNodeOperator = no;
    }

    function getNodeOperator(
        uint256 nodeOperatorId
    ) external view returns (NodeOperator memory) {
        return mockNodeOperator;
    }

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

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external {}
}
