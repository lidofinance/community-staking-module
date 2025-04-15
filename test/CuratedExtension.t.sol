// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { CuratedExtension } from "../src/CuratedExtension.sol";
import { ICuratedExtension, NodeOperatorProperties } from "../src/interfaces/ICuratedExtension.sol";
import { ICSModule, NodeOperatorManagementProperties, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { CSMMock } from "./helpers/mocks/CSMMock.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CuratedExtensionTest is Test, Utilities, Fixtures {
    CuratedExtension internal curatedExtension;
    address internal csm;
    address internal stranger;
    address internal admin;
    address internal manager;
    address internal nodeOperator;

    function setUp() public {
        csm = address(new CSMMock());
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        nodeOperator = nextAddress("NODE_OPERATOR");
        manager = nextAddress("MANAGER");

        curatedExtension = new CuratedExtension(csm);
        _enableInitializers(address(curatedExtension));
        curatedExtension.initialize(admin);
        bytes32 managerRole = curatedExtension.MANAGE_NODE_OPERATORS_ROLE();
        vm.prank(admin);
        curatedExtension.grantRole(managerRole, manager);
    }

    function test_constructor() public {
        curatedExtension = new CuratedExtension(csm);
        assertEq(address(curatedExtension.MODULE()), csm);
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICuratedExtension.ZeroModuleAddress.selector);
        new CuratedExtension(address(0));
    }

    function test_initializer() public {
        curatedExtension = new CuratedExtension(csm);
        _enableInitializers(address(curatedExtension));

        curatedExtension.initialize(admin);

        assertEq(
            curatedExtension.getRoleMemberCount(
                curatedExtension.DEFAULT_ADMIN_ROLE()
            ),
            1
        );
        assertEq(
            curatedExtension.getRoleMember(
                curatedExtension.DEFAULT_ADMIN_ROLE(),
                0
            ),
            admin
        );
    }

    function test_initializer_RevertWhen_ZeroAdminAddress() public {
        curatedExtension = new CuratedExtension(csm);
        _enableInitializers(address(curatedExtension));

        vm.expectRevert(ICuratedExtension.ZeroAdminAddress.selector);
        curatedExtension.initialize(address(0));
    }

    function test_addNodeOperator() public {
        uint256 nodeOperatorId = curatedExtension
            .MODULE()
            .getNodeOperatorsCount();
        string memory name = "Awesome Curated NO";

        vm.expectCall(
            address(curatedExtension.MODULE()),
            abi.encodeWithSelector(
                ICSModule.createNodeOperator.selector,
                manager,
                NodeOperatorManagementProperties({
                    managerAddress: nodeOperator,
                    rewardAddress: nodeOperator,
                    extendedManagerPermissions: false
                }),
                address(0)
            )
        );
        vm.expectEmit(address(curatedExtension));
        emit ICuratedExtension.NodeOperatorCreated(nodeOperatorId, name);
        vm.prank(manager);
        curatedExtension.addNodeOperator(nodeOperator, nodeOperator, name);
    }

    function test_addNodeOperator_revertWhen_notManager() public {
        string memory name = "Awesome Curated NO";

        expectRoleRevert(
            stranger,
            curatedExtension.MANAGE_NODE_OPERATORS_ROLE()
        );
        vm.prank(stranger);
        curatedExtension.addNodeOperator(nodeOperator, nodeOperator, name);
    }

    function test_addNodeOperator_revertWhen_InvalidNameLength_zeroName()
        public
    {
        string memory name = "";

        vm.expectRevert(ICuratedExtension.InvalidNameLength.selector);
        vm.prank(manager);
        curatedExtension.addNodeOperator(nodeOperator, nodeOperator, name);
    }

    function test_addNodeOperator_revertWhen_InvalidNameLength_tooLongName()
        public
    {
        bytes memory bytesName = new bytes(257);
        string memory name = string(bytesName);

        vm.expectRevert(ICuratedExtension.InvalidNameLength.selector);
        vm.prank(manager);
        curatedExtension.addNodeOperator(nodeOperator, nodeOperator, name);
    }

    function test_addNodeOperator_revertWhen_ZeroManagerAddress() public {
        string memory name = "Awesome Curated NO";

        vm.expectRevert(ICuratedExtension.ZeroManagerAddress.selector);
        vm.prank(manager);
        curatedExtension.addNodeOperator(address(0), nodeOperator, name);
    }

    function test_addNodeOperator_revertWhen_ZeroRewardAddress() public {
        string memory name = "Awesome Curated NO";

        vm.expectRevert(ICuratedExtension.ZeroRewardAddress.selector);
        vm.prank(manager);
        curatedExtension.addNodeOperator(nodeOperator, address(0), name);
    }

    function test_changeNodeOperatorName() public {
        string memory name = "Awesome Curated NO";

        vm.prank(manager);
        uint256 nodeOperatorId = curatedExtension.addNodeOperator(
            nodeOperator,
            nodeOperator,
            name
        );

        string memory newName = "New Awesome Curated NO";

        vm.expectEmit(address(curatedExtension));
        emit ICuratedExtension.NodeOperatorNameChanged(
            nodeOperatorId,
            name,
            newName
        );
        vm.prank(manager);
        curatedExtension.changeNodeOperatorName(nodeOperatorId, newName);

        NodeOperatorProperties memory properties = curatedExtension
            .getNodeOperatorProperties(nodeOperatorId);
        assertEq(keccak256(bytes(properties.name)), keccak256(bytes(newName)));
    }

    function test_changeNodeOperatorName_revertWhen_notManager() public {
        string memory name = "Awesome Curated NO";

        vm.prank(manager);
        uint256 nodeOperatorId = curatedExtension.addNodeOperator(
            nodeOperator,
            nodeOperator,
            name
        );

        string memory newName = "New Awesome Curated NO";

        expectRoleRevert(
            stranger,
            curatedExtension.MANAGE_NODE_OPERATORS_ROLE()
        );
        vm.prank(stranger);
        curatedExtension.changeNodeOperatorName(nodeOperatorId, newName);
    }

    function test_changeNodeOperatorName_revertWhen_SameName() public {
        string memory name = "Awesome Curated NO";

        vm.prank(manager);
        uint256 nodeOperatorId = curatedExtension.addNodeOperator(
            nodeOperator,
            nodeOperator,
            name
        );

        vm.expectRevert(ICuratedExtension.SameName.selector);
        vm.prank(manager);
        curatedExtension.changeNodeOperatorName(nodeOperatorId, name);
    }

    function test_changeNodeOperatorName_revertWhen_InvalidNameLength_zeroName()
        public
    {
        string memory name = "Awesome Curated NO";

        vm.prank(manager);
        uint256 nodeOperatorId = curatedExtension.addNodeOperator(
            nodeOperator,
            nodeOperator,
            name
        );

        string memory newName = "";

        vm.expectRevert(ICuratedExtension.InvalidNameLength.selector);
        vm.prank(manager);
        curatedExtension.changeNodeOperatorName(nodeOperatorId, newName);
    }

    function test_changeNodeOperatorName_revertWhen_InvalidNameLength_tooLongName()
        public
    {
        string memory name = "Awesome Curated NO";

        vm.prank(manager);
        uint256 nodeOperatorId = curatedExtension.addNodeOperator(
            nodeOperator,
            nodeOperator,
            name
        );

        bytes memory bytesName = new bytes(257);
        string memory newName = string(bytesName);

        vm.expectRevert(ICuratedExtension.InvalidNameLength.selector);
        vm.prank(manager);
        curatedExtension.changeNodeOperatorName(nodeOperatorId, newName);
    }

    function test_getNodeOperatorProperties() public {
        string memory name = "Awesome Curated NO";

        vm.prank(manager);
        uint256 nodeOperatorId = curatedExtension.addNodeOperator(
            nodeOperator,
            nodeOperator,
            name
        );

        NodeOperatorProperties memory properties = curatedExtension
            .getNodeOperatorProperties(nodeOperatorId);
        assertEq(keccak256(bytes(properties.name)), keccak256(bytes(name)));
    }
}
