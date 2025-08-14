// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { NodeOperatorManagementProperties, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { INOAddresses } from "../src/lib/NOAddresses.sol";

import { CuratedModule } from "../src/CuratedModule.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

import { CSParametersRegistryMock } from "./helpers/mocks/CSParametersRegistryMock.sol";
import { ExitPenaltiesMock } from "./helpers/mocks/ExitPenaltiesMock.sol";
import { CSAccountingMock } from "./helpers/mocks/CSAccountingMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

contract CuratedModuleTest is Fixtures, Utilities {
    uint256 public constant BOND_SIZE = 2 ether;

    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    CuratedModule public cm;
    CSAccountingMock public accounting;
    Stub public feeDistributor;
    CSParametersRegistryMock public parametersRegistry;
    ExitPenaltiesMock public exitPenalties;

    address internal admin;
    address internal stranger;
    address internal nodeOperator;

    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        (locator, wstETH, stETH, , ) = initLido();

        feeDistributor = new Stub();
        parametersRegistry = new CSParametersRegistryMock();
        exitPenalties = new ExitPenaltiesMock();

        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: BOND_SIZE
        });
        accounting = new CSAccountingMock(
            BOND_SIZE,
            address(wstETH),
            address(stETH)
        );
        accounting.setFeeDistributor(address(feeDistributor));

        cm = new CuratedModule({
            moduleType: "curated-module-v2",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            accounting_: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        accounting.setModule(cm);

        _enableInitializers(address(cm));
        cm.initialize({ admin: admin });

        vm.startPrank(admin);
        cm.grantRole(cm.CREATE_NODE_OPERATOR_ROLE(), address(this));
        cm.grantRole(cm.RESUME_ROLE(), address(this));
        cm.grantRole(cm.DEFAULT_ADMIN_ROLE(), address(this));
        cm.grantRole(cm.STAKING_ROUTER_ROLE(), address(this));
        vm.stopPrank();

        cm.resume();
    }

    function test_changeNodeOperatorAddresses_NoExtendedManagerPermissions_SingleOwner()
        public
    {
        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorManagerAddressChanged(
            noId,
            nodeOperator,
            manager
        );

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorRewardAddressChanged(
            noId,
            nodeOperator,
            rewards
        );

        cm.changeNodeOperatorAddresses(noId, manager, rewards);

        NodeOperator memory no = cm.getNodeOperator(noId);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, rewards);
    }

    function test_changeNodeOperatorAddresses_NoExtendedManagerPermissions_SeparateManagerReward()
        public
    {
        address managerToChange = nextAddress();
        address rewardsToChange = nextAddress();

        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: managerToChange,
                rewardAddress: rewardsToChange,
                extendedManagerPermissions: false
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorManagerAddressChanged(
            noId,
            managerToChange,
            manager
        );

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorRewardAddressChanged(
            noId,
            rewardsToChange,
            rewards
        );

        cm.changeNodeOperatorAddresses(noId, manager, rewards);

        NodeOperator memory no = cm.getNodeOperator(noId);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, rewards);
    }

    function test_changeNodeOperatorAddresses_ExtendedManagerPermissions_SingleOwner()
        public
    {
        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: true
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorManagerAddressChanged(
            noId,
            nodeOperator,
            manager
        );

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorRewardAddressChanged(
            noId,
            nodeOperator,
            rewards
        );

        cm.changeNodeOperatorAddresses(noId, manager, rewards);

        NodeOperator memory no = cm.getNodeOperator(noId);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, rewards);
    }

    function test_changeNodeOperatorAddresses_ExtendedManagerPermissions_SeparateManagerReward()
        public
    {
        address managerToChange = nextAddress();
        address rewardsToChange = nextAddress();

        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: managerToChange,
                rewardAddress: rewardsToChange,
                extendedManagerPermissions: true
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorManagerAddressChanged(
            noId,
            managerToChange,
            manager
        );

        vm.expectEmit(true, true, true, true, address(cm));
        emit INOAddresses.NodeOperatorRewardAddressChanged(
            noId,
            rewardsToChange,
            rewards
        );

        cm.changeNodeOperatorAddresses(noId, manager, rewards);

        NodeOperator memory no = cm.getNodeOperator(noId);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, rewards);
    }

    function test_changeNodeOperatorAddresses_ChangesOnlyGivenAddress() public {
        address managerToChange = nextAddress();
        address rewardsToChange = nextAddress();

        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: managerToChange,
                rewardAddress: rewardsToChange,
                extendedManagerPermissions: false
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        uint256 snapshot = vm.snapshotState();

        {
            vm.expectEmit(true, true, true, true, address(cm));
            emit INOAddresses.NodeOperatorRewardAddressChanged(
                noId,
                rewardsToChange,
                rewards
            );

            vm.recordLogs();
            cm.changeNodeOperatorAddresses(noId, managerToChange, rewards);
            assertEq(vm.getRecordedLogs().length, 1);
        }
        vm.revertToState(snapshot);

        {
            vm.expectEmit(true, true, true, true, address(cm));
            emit INOAddresses.NodeOperatorManagerAddressChanged(
                noId,
                managerToChange,
                manager
            );

            vm.recordLogs();
            cm.changeNodeOperatorAddresses(noId, manager, rewardsToChange);
            assertEq(vm.getRecordedLogs().length, 1);
        }
        vm.revertToState(snapshot);
    }

    function test_changeNodeOperatorAddresses_RevertsIfOperatorDoesNotExist()
        public
    {
        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        cm.changeNodeOperatorAddresses(0, manager, rewards);
    }

    function test_changeNodeOperatorAddresses_RevertsIfHasNoRole() public {
        assertFalse(cm.hasRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this)));

        address manager = nextAddress();
        address rewards = nextAddress();

        expectRoleRevert(address(this), cm.NODE_OWNER_ADMIN_ROLE());
        cm.changeNodeOperatorAddresses(0, manager, rewards);
    }

    function test_changeNodeOperatorAddresses_RevertsIfTheSameAddresses()
        public
    {
        address manager = nextAddress();
        address rewards = nextAddress();

        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: rewards,
                extendedManagerPermissions: false
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        vm.expectRevert(INOAddresses.SameAddress.selector);
        cm.changeNodeOperatorAddresses(noId, manager, rewards);
    }

    function test_changeNodeOperatorAddresses_RevertsIfZeroAddressProvided()
        public
    {
        uint256 noId = cm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: nextAddress(),
                rewardAddress: nextAddress(),
                extendedManagerPermissions: false
            }),
            address(0)
        );

        vm.startPrank(admin);
        cm.grantRole(cm.NODE_OWNER_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        address manager = nextAddress();
        address rewards = nextAddress();

        vm.expectRevert(INOAddresses.ZeroManagerAddress.selector);
        cm.changeNodeOperatorAddresses(noId, address(0), rewards);

        vm.expectRevert(INOAddresses.ZeroRewardAddress.selector);
        cm.changeNodeOperatorAddresses(noId, manager, address(0));
    }
}
