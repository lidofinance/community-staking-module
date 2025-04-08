// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { ICuratedExtension, NodeOperatorProperties } from "./interfaces/ICuratedExtension.sol";

contract CuratedExtension is
    ICuratedExtension,
    AccessControlEnumerableUpgradeable
{
    bytes32 public constant MANAGE_NODE_OPERATORS_ROLE =
        keccak256("MANAGE_NODE_OPERATORS_ROLE");

    uint256 public constant MAX_NODE_OPERATOR_NAME_LENGTH = 255;

    /// @dev Address of the Community Staking Module
    ICSModule public immutable CSM;

    mapping(uint256 => NodeOperatorProperties) private _nodeOperators;

    constructor(address csm) {
        if (csm == address(0)) {
            revert ZeroModuleAddress();
        }

        CSM = ICSModule(csm);

        _disableInitializers();
    }

    function initialize(address admin) external initializer {
        __AccessControlEnumerable_init();

        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICuratedExtension
    function addNodeOperator(
        address managerAddress,
        address rewardAddress,
        string calldata name
    )
        external
        onlyRole(MANAGE_NODE_OPERATORS_ROLE)
        returns (uint256 nodeOperatorId)
    {
        _onlyValidNodeOperatorName(name);
        if (managerAddress == address(0)) {
            revert ZeroManagerAddress();
        }
        if (rewardAddress == address(0)) {
            revert ZeroRewardAddress();
        }
        nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            NodeOperatorManagementProperties({
                managerAddress: managerAddress,
                rewardAddress: rewardAddress,
                extendedManagerPermissions: false
            }),
            address(0)
        );
        _nodeOperators[nodeOperatorId] = NodeOperatorProperties({ name: name });
    }

    /// @inheritdoc ICuratedExtension
    function changeNodeOperatorName(
        uint256 nodeOperatorId,
        string calldata newName
    ) external onlyRole(MANAGE_NODE_OPERATORS_ROLE) {
        _onlyValidNodeOperatorName(newName);

        string memory oldName = _nodeOperators[nodeOperatorId].name;
        if (keccak256(bytes(newName)) == keccak256(bytes(oldName))) {
            revert SameName();
        }

        _nodeOperators[nodeOperatorId].name = newName;

        emit NodeOperatorNameChanged(nodeOperatorId, oldName, newName);
    }

    function getNodeOperatorProperties(
        uint256 nodeOperatorId
    ) external view returns (NodeOperatorProperties memory no) {
        no = _nodeOperators[nodeOperatorId];
    }

    function _onlyValidNodeOperatorName(string calldata name) internal pure {
        if (
            bytes(name).length > 0 ||
            bytes(name).length <= MAX_NODE_OPERATOR_NAME_LENGTH
        ) {
            revert InvalidNameLength();
        }
    }
}
