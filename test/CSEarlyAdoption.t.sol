// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/CSEarlyAdoption.sol";
import { Utilities } from "./helpers/Utilities.sol";
import "./helpers/MerkleTree.sol";

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
    }

    function test_initialization() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
        assertEq(earlyAdoption.TREE_ROOT(), merkleTree.root());
        assertEq(earlyAdoption.CURVE_ID(), curveId);
        assertEq(earlyAdoption.MODULE(), csm);
    }

    function test_isEligible() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
        assertTrue(
            earlyAdoption.isEligible(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(earlyAdoption.isEligible(stranger, merkleTree.getProof(0)));
    }

    function test_consume() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);

        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        vm.expectEmit(true, true, true, true, address(earlyAdoption));
        emit CSEarlyAdoption.Consumed(nodeOperator);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consumed() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);

        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        earlyAdoption.consume(nodeOperator, proof);
        assertTrue(earlyAdoption.consumed(nodeOperator));
    }

    function test_consume_revert_onlyModule() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(stranger);
        vm.expectRevert(CSEarlyAdoption.OnlyModule.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_alreadyConsumed() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.startPrank(csm);
        earlyAdoption.consume(nodeOperator, proof);

        vm.expectRevert(CSEarlyAdoption.AlreadyConsumed.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }

    function test_consume_revert_invalidAddress() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(csm);
        vm.expectRevert(CSEarlyAdoption.InvalidProof.selector);
        earlyAdoption.consume(stranger, proof);
    }

    function test_consume_revert_invalidProof() public {
        earlyAdoption = new CSEarlyAdoption(merkleTree.root(), curveId, csm);
        bytes32[] memory proof = merkleTree.getProof(0);
        proof[0] = bytes32(randomBytes(32));

        vm.prank(csm);
        vm.expectRevert(CSEarlyAdoption.InvalidProof.selector);
        earlyAdoption.consume(nodeOperator, proof);
    }
}
