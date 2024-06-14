// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/CSEarlyAdoption.sol";
import { Utilities } from "./helpers/Utilities.sol";
import "./helpers/MerkleTree.sol";

contract CSEarlyAdoptionConstructorTest is Test, Utilities {
    CSEarlyAdoption internal earlyAdoption;
    address internal csm;
    address internal nodeOperator;
    address internal stranger;
    uint256 internal curveId;
    MerkleTree internal merkleTree;
    bytes32 internal root;

    function setUp() public {
        csm = nextAddress("CSM");
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));

        curveId = 1;
        root = merkleTree.root();
    }

    function test_constructor() public {
        earlyAdoption = new CSEarlyAdoption(root, curveId, csm);
        assertEq(earlyAdoption.TREE_ROOT(), root);
        assertEq(earlyAdoption.CURVE_ID(), curveId);
        assertEq(earlyAdoption.MODULE(), csm);
    }

    function test_constructor_RevertWhen_InvalidTreeRoot() public {
        vm.expectRevert(CSEarlyAdoption.InvalidTreeRoot.selector);
        new CSEarlyAdoption(bytes32(0), curveId, csm);
    }

    function test_constructor_RevertWhen_InvalidCurveId() public {
        vm.expectRevert(CSEarlyAdoption.InvalidCurveId.selector);
        new CSEarlyAdoption(root, 0, csm);
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(CSEarlyAdoption.ZeroModuleAddress.selector);
        new CSEarlyAdoption(root, curveId, address(0));
    }
}

contract CSEarlyAdoptionTest is Test, Utilities {
    CSEarlyAdoption internal earlyAdoption;
    address internal csm;
    address internal nodeOperator;
    address internal stranger;
    uint256 internal curveId;
    MerkleTree internal merkleTree;

    function setUp() public {
        csm = nextAddress("CSM");
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));

        curveId = 1;
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
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
        emit CSEarlyAdoption.Consumed(nodeOperator);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_onlyModule() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(stranger);
        vm.expectRevert(CSEarlyAdoption.SenderIsNotModule.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_alreadyConsumed() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.startPrank(csm);
        earlyAdoption.consume(nodeOperator, proof);

        vm.expectRevert(CSEarlyAdoption.AlreadyConsumed.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_invalidAddress() public {
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        vm.expectRevert(CSEarlyAdoption.InvalidProof.selector);
        earlyAdoption.consume(stranger, proof);
    }

    function test_consume_revert_invalidProof() public {
        bytes32[] memory proof = merkleTree.getProof(0);
        proof[0] = bytes32(randomBytes(32));

        vm.prank(csm);
        vm.expectRevert(CSEarlyAdoption.InvalidProof.selector);
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
}
