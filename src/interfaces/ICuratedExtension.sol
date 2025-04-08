// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSAccounting } from "./ICSAccounting.sol";
import { ICSModule } from "./ICSModule.sol";

struct NodeOperatorProperties {
    string name;
}

interface ICuratedExtension {
    event NodeOperatorNameChanged(
        uint256 indexed nodeOperatorId,
        string oldName,
        string newName
    );

    error ZeroModuleAddress();
    error ZeroAdminAddress();
    error ZeroManagerAddress();
    error ZeroRewardAddress();
    error InvalidNameLength();
    error SameName();

    function CSM() external view returns (ICSModule);

    /// @notice Add a new Node Operator
    /// @param managerAddress An address to use as a manager address for the Node Operator in the extension
    /// @param rewardAddress An address to use as a reward address for the Node Operator in the module
    /// @param name A name to be set for the Node Operator
    /// @return nodeOperatorId Id of the created Node Operator
    function addNodeOperator(
        address managerAddress,
        address rewardAddress,
        string calldata name
    ) external returns (uint256 nodeOperatorId);

    /// @notice Change Node Operator name stored in the extension
    /// @param nodeOperatorId ID of the Node Operator
    /// @param newName A name to be set for the Node Operator
    function changeNodeOperatorName(
        uint256 nodeOperatorId,
        string calldata newName
    ) external;

    /// @notice Get Node Operator properties stored in the extension
    /// @param nodeOperatorId ID of the Node Operator
    /// @return no Node Operator properties
    function getNodeOperatorProperties(
        uint256 nodeOperatorId
    ) external view returns (NodeOperatorProperties memory no);
}
