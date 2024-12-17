// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { CSEarlyAdoption } from "../src/CSEarlyAdoption.sol";
import { ICSEarlyAdoption } from "../src/interfaces/ICSEarlyAdoption.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";
import { Utilities } from "./helpers/Utilities.sol";
import "./helpers/MerkleTree.sol";

contract CSMMock {
    uint256 public constant latestCurveId = 2;

    function accounting() external view returns (address) {
        return address(this);
    }

    function curveExists(uint256 curveId) external view returns (bool) {
        return curveId <= latestCurveId;
    }
}

contract CSEarlyAdoptionConstructorTest is Test, Utilities {
    CSEarlyAdoption internal earlyAdoption;
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

        curveId = 1;
        root = merkleTree.root();
        earlyAdoption = new CSEarlyAdoption(
            merkleTree.root(),
            curveId,
            csm,
            admin
        );
    }

    function test_constructor() public {
        vm.expectEmit(true, true, true, true);
        emit ICSEarlyAdoption.TreeRootSet(root);
        earlyAdoption = new CSEarlyAdoption(root, curveId, csm, admin);

        assertEq(earlyAdoption.MODULE(), csm);
        assertEq(earlyAdoption.CURVE_ID(), curveId);
        assertEq(earlyAdoption.treeRoot(), root);
        assertEq(
            earlyAdoption.getRoleMemberCount(
                earlyAdoption.DEFAULT_ADMIN_ROLE()
            ),
            1
        );
        assertEq(
            earlyAdoption.getRoleMember(earlyAdoption.DEFAULT_ADMIN_ROLE(), 0),
            admin
        );
    }

    function test_constructor_RevertWhen_InvalidTreeRoot() public {
        vm.expectRevert(ICSEarlyAdoption.InvalidTreeRoot.selector);
        new CSEarlyAdoption(bytes32(0), curveId, csm, admin);
    }

    function test_constructor_RevertWhen_InvalidCurveId() public {
        vm.expectRevert(ICSEarlyAdoption.InvalidCurveId.selector);
        new CSEarlyAdoption(root, 0, csm, admin);
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSEarlyAdoption.ZeroModuleAddress.selector);
        new CSEarlyAdoption(root, curveId, address(0), admin);
    }

    function test_constructor_RevertWhen_ZeroAdminAddress() public {
        vm.expectRevert(ICSEarlyAdoption.ZeroAdminAddress.selector);
        new CSEarlyAdoption(root, curveId, csm, address(0));
    }

    function test_verifyProof() public {
        assertTrue(
            earlyAdoption.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(
            earlyAdoption.verifyProof(stranger, merkleTree.getProof(0))
        );
    }

    function test_consume() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        vm.expectEmit(true, true, true, true, address(earlyAdoption));
        emit ICSEarlyAdoption.Consumed(nodeOperator);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_onlyModule() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(stranger);
        vm.expectRevert(ICSEarlyAdoption.SenderIsNotModule.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_alreadyConsumed() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.startPrank(csm);
        earlyAdoption.consume(nodeOperator, proof);

        vm.expectRevert(ICSEarlyAdoption.AlreadyConsumed.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_invalidAddress() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        vm.expectRevert(ICSEarlyAdoption.InvalidProof.selector);
        earlyAdoption.consume(stranger, proof);
    }

    function test_consume_revert_invalidProof() public {
        bytes32[] memory proof = merkleTree.getProof(0);
        proof[0] = bytes32(randomBytes(32));

        vm.prank(csm);
        vm.expectRevert(ICSEarlyAdoption.InvalidProof.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_isConsumed() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        earlyAdoption.consume(nodeOperator, proof);
        assertTrue(earlyAdoption.isConsumed(nodeOperator));
    }

    function test_hashLeaf() public {
        // keccak256(bytes.concat(keccak256(abi.encode(address(154))))) = 0x0f7ac7a58332324fa3de7b7a4a05de303436d846e292fa579646a7496f0c2c1a
        assertEq(
            earlyAdoption.hashLeaf(address(154)),
            0x0f7ac7a58332324fa3de7b7a4a05de303436d846e292fa579646a7496f0c2c1a
        );
    }

    function testFuzz_hashLeaf(address addr) public {
        assertEq(
            earlyAdoption.hashLeaf(addr),
            keccak256(bytes.concat(keccak256(abi.encode(addr))))
        );
    }

    function test_setTreeRoot() public {
        MerkleTree newTree = new MerkleTree();
        newTree.pushLeaf(abi.encode(stranger));
        bytes32 newRoot = newTree.root();

        assertTrue(
            earlyAdoption.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(earlyAdoption.verifyProof(stranger, newTree.getProof(0)));

        vm.startPrank(admin);
        earlyAdoption.grantRole(earlyAdoption.SET_TREE_ROOT_ROLE(), admin);

        vm.expectEmit(true, true, true, true);
        emit ICSEarlyAdoption.TreeRootSet(newRoot);
        earlyAdoption.setTreeRoot(newRoot);

        vm.stopPrank();

        assertEq(earlyAdoption.treeRoot(), newRoot);
        assertFalse(
            earlyAdoption.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertTrue(earlyAdoption.verifyProof(stranger, newTree.getProof(0)));
    }

    function test_setTreeRoot_revert_zeroRoot() public {
        vm.startPrank(admin);
        earlyAdoption.grantRole(earlyAdoption.SET_TREE_ROOT_ROLE(), admin);

        vm.expectRevert(ICSEarlyAdoption.InvalidTreeRoot.selector);
        earlyAdoption.setTreeRoot(bytes32(0));

        vm.stopPrank();
    }

    function test_setTreeRoot_revert_sameRoot() public {
        vm.startPrank(admin);
        earlyAdoption.grantRole(earlyAdoption.SET_TREE_ROOT_ROLE(), admin);
        bytes32 currRoot = merkleTree.root();

        vm.expectRevert(ICSEarlyAdoption.InvalidTreeRoot.selector);
        earlyAdoption.setTreeRoot(currRoot);

        vm.stopPrank();
    }

    function test_setTreeRoot_revert_noRole() public {
        vm.startPrank(admin);
        expectRoleRevert(admin, earlyAdoption.SET_TREE_ROOT_ROLE());
        earlyAdoption.setTreeRoot(bytes32(randomBytes(32)));
        vm.stopPrank();
    }
}
