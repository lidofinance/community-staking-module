// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { VettedGate } from "../src/VettedGate.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { IVettedGate } from "../src/interfaces/IVettedGate.sol";
import { ICSModule, NodeOperatorManagementProperties, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { CSMMock } from "./helpers/mocks/CSMMock.sol";

contract VettedGateTest is Test, Utilities {
    VettedGate internal vettedGate;
    address internal csm;
    address internal nodeOperator;
    address internal stranger;
    address internal admin;
    uint256 internal curveId;
    MerkleTree internal merkleTree;
    bytes32 internal root;

    function setUp() public {
        csm = address(new CSMMock());
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));
        merkleTree.pushLeaf(abi.encode(stranger));

        curveId = 1;
        root = merkleTree.root();
        vettedGate = new VettedGate(merkleTree.root(), curveId, csm, admin);
    }

    function test_constructor() public {
        vm.expectEmit();
        emit IVettedGate.TreeRootSet(root);
        vettedGate = new VettedGate(root, curveId, csm, admin);

        assertEq(address(vettedGate.CSM()), csm);
        assertEq(vettedGate.CURVE_ID(), curveId);
        assertEq(vettedGate.treeRoot(), root);
        assertEq(
            vettedGate.getRoleMemberCount(vettedGate.DEFAULT_ADMIN_ROLE()),
            1
        );
        assertEq(
            vettedGate.getRoleMember(vettedGate.DEFAULT_ADMIN_ROLE(), 0),
            admin
        );
    }

    function test_constructor_RevertWhen_InvalidTreeRoot() public {
        vm.expectRevert(IVettedGate.InvalidTreeRoot.selector);
        new VettedGate(bytes32(0), curveId, csm, admin);
    }

    function test_constructor_RevertWhen_InvalidCurveId() public {
        vm.expectRevert(IVettedGate.InvalidCurveId.selector);
        new VettedGate(root, 0, csm, admin);
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(IVettedGate.ZeroModuleAddress.selector);
        new VettedGate(root, curveId, address(0), admin);
    }

    function test_constructor_RevertWhen_ZeroAdminAddress() public {
        vm.expectRevert(IVettedGate.ZeroAdminAddress.selector);
        new VettedGate(root, curveId, csm, address(0));
    }

    function test_pauseFor() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);

        vm.expectEmit(address(vettedGate));
        emit PausableUntil.Paused(100);
        vettedGate.pauseFor(100);

        vm.stopPrank();
        assertTrue(vettedGate.isPaused());
    }

    function test_pauseFor_revertWhen_noRole() public {
        expectRoleRevert(admin, vettedGate.PAUSE_ROLE());
        vm.prank(admin);
        vettedGate.pauseFor(100);
    }

    function test_resume() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.grantRole(vettedGate.RESUME_ROLE(), admin);
        vettedGate.pauseFor(100);

        vm.expectEmit(address(vettedGate));
        emit PausableUntil.Resumed();
        vettedGate.resume();

        vm.stopPrank();
        assertFalse(vettedGate.isPaused());
    }

    function test_resume_revertWhen_noRole() public {
        expectRoleRevert(admin, vettedGate.RESUME_ROLE());
        vm.prank(admin);
        vettedGate.resume();
    }

    function test_verifyProof() public view {
        assertTrue(
            vettedGate.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(vettedGate.verifyProof(stranger, merkleTree.getProof(0)));
    }

    function test_hashLeaf() public view {
        // keccak256(bytes.concat(keccak256(abi.encode(address(154))))) = 0x0f7ac7a58332324fa3de7b7a4a05de303436d846e292fa579646a7496f0c2c1a
        assertEq(
            vettedGate.hashLeaf(address(154)),
            0x0f7ac7a58332324fa3de7b7a4a05de303436d846e292fa579646a7496f0c2c1a
        );
    }

    function testFuzz_hashLeaf(address addr) public view {
        assertEq(
            vettedGate.hashLeaf(addr),
            keccak256(bytes.concat(keccak256(abi.encode(addr))))
        );
    }

    function test_setTreeRoot() public {
        MerkleTree newTree = new MerkleTree();
        newTree.pushLeaf(abi.encode(stranger));
        bytes32 newRoot = newTree.root();

        assertTrue(
            vettedGate.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(vettedGate.verifyProof(stranger, newTree.getProof(0)));

        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROOT_ROLE(), admin);

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.TreeRootSet(newRoot);
        vettedGate.setTreeRoot(newRoot);

        vm.stopPrank();

        assertEq(vettedGate.treeRoot(), newRoot);
        assertFalse(
            vettedGate.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertTrue(vettedGate.verifyProof(stranger, newTree.getProof(0)));
    }

    function test_setTreeRoot_revert_zeroRoot() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROOT_ROLE(), admin);

        vm.expectRevert(IVettedGate.InvalidTreeRoot.selector);
        vettedGate.setTreeRoot(bytes32(0));

        vm.stopPrank();
    }

    function test_setTreeRoot_revert_sameRoot() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROOT_ROLE(), admin);
        bytes32 currRoot = merkleTree.root();

        vm.expectRevert(IVettedGate.InvalidTreeRoot.selector);
        vettedGate.setTreeRoot(currRoot);

        vm.stopPrank();
    }

    function test_setTreeRoot_revert_noRole() public {
        vm.startPrank(admin);
        expectRoleRevert(admin, vettedGate.SET_TREE_ROOT_ROLE());
        vettedGate.setTreeRoot(bytes32(randomBytes(32)));
        vm.stopPrank();
    }

    function test_addNodeOperatorETH() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        assertFalse(vettedGate.isConsumed(nodeOperator));

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );

        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_addNodeOperatorStETH() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        assertFalse(vettedGate.isConsumed(nodeOperator));

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );

        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_addNodeOperatorWstETH() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        assertFalse(vettedGate.isConsumed(nodeOperator));

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );

        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_addNodeOperatorETH_revertWhen_alreadyConsumed() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorETH_revertWhen_invalidProof() public {
        uint256 keysCount = 1;
        bytes32[] memory invalidProof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            invalidProof,
            address(0)
        );
    }

    function test_addNodeOperatorETH_revertWhen_paused() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.pauseFor(type(uint256).max);
        vm.stopPrank();

        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorStETH_revertWhen_alreadyConsumed() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorStETH_revertWhen_invalidProof() public {
        uint256 keysCount = 1;
        bytes32[] memory invalidProof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            invalidProof,
            address(0)
        );
    }

    function test_addNodeOperatorStETH_revertWhen_paused() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.pauseFor(type(uint256).max);
        vm.stopPrank();

        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorWstETH_revertWhen_alreadyConsumed() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorWstETH_revertWhen_invalidProof() public {
        uint256 keysCount = 1;
        bytes32[] memory invalidProof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            invalidProof,
            address(0)
        );
    }

    function test_addNodeOperatorWstETH_revertWhen_paused() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.pauseFor(type(uint256).max);
        vm.stopPrank();

        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_claimBondCurve() public {
        NodeOperator memory no;
        no.managerAddress = nodeOperator;
        no.rewardAddress = nodeOperator;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.claimBondCurve(0, proof);
    }

    function test_claimBondCurve_revertWhen_notRewardAddress() public {
        NodeOperator memory no;
        no.managerAddress = nodeOperator;
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(IVettedGate.NotAllowedToClaim.selector);
        vettedGate.claimBondCurve(0, proof);
    }

    function test_claimBondCurve_revertWhen_notManagerAddress() public {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nodeOperator;
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(IVettedGate.NotAllowedToClaim.selector);
        vettedGate.claimBondCurve(0, proof);
    }
}
