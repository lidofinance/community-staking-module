// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;
import { NodeOperatorManagementProperties, NodeOperator } from "../../../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";
import { ICSParametersRegistry } from "../../../src/interfaces/ICSParametersRegistry.sol";
import { CSParametersRegistryMock } from "./CSParametersRegistryMock.sol";
import { Utilities } from "../Utilities.sol";

contract AccountingMock {
    uint256 public constant DEFAULT_BOND_CURVE_ID = 0;

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external {}

    function penalize(uint256 nodeOperatorId, uint256 amount) external {}

    function getBondCurveId(uint256 nodeOperatorId) external returns (uint256) {
        return DEFAULT_BOND_CURVE_ID;
    }
}

contract CSMMock is Utilities {
    NodeOperator internal mockNodeOperator;
    uint256 internal nodeOperatorsCount;
    bool internal isValidatorWithdrawnMock;
    ICSAccounting public immutable ACCOUNTING;
    ICSParametersRegistry public immutable PARAMETERS_REGISTRY;

    constructor() {
        ACCOUNTING = ICSAccounting(address(new AccountingMock()));
        PARAMETERS_REGISTRY = ICSParametersRegistry(
            address(new CSParametersRegistryMock())
        );
    }

    function accounting() external view returns (ICSAccounting) {
        return ACCOUNTING;
    }

    function mock_setNodeOperator(NodeOperator memory no) external {
        mockNodeOperator = no;
    }

    function getNodeOperator(
        uint256 /* nodeOperatorId */
    ) external view returns (NodeOperator memory) {
        return mockNodeOperator;
    }

    function mock_setIsValidatorWithdrawn(bool value) external {
        isValidatorWithdrawnMock = value;
    }

    function isValidatorWithdrawn(
        uint256,
        uint256
    ) external view returns (bool) {
        return isValidatorWithdrawnMock;
    }

    function mock_setNodeOperatorsCount(uint256 count) external {
        nodeOperatorsCount = count;
    }

    function getNodeOperatorsCount() external view returns (uint256) {
        return nodeOperatorsCount;
    }

    function createNodeOperator(
        address /* from */,
        NodeOperatorManagementProperties memory /* managementProperties */,
        address /* referrer */
    ) external pure returns (uint256) {
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

    function getSigningKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external returns (bytes memory pubkeys) {
        (pubkeys, ) = keysSignatures(keysCount);
    }
}
