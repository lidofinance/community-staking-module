// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/CommunityStakingModule.sol";
import "../src/CommunityStakingBondManager.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";

contract CSMAddNodeOperator is Test, Fixtures {
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal stranger;
    address internal alice;
    address internal nodeOperator;

    function setUp() public withLido {
        alice = address(1);
        nodeOperator = address(2);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        lido.stETH.submit{ value: 2 ether }(address(0));

        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(lido.locator),
            address(bondManager)
        );
        csm = new CommunityStakingModule(
            "community-staking-module",
            address(lido.locator)
        );
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(lido.locator),
            address(lido.wstETH),
            address(csm),
            penalizeRoleMembers
        );
        csm.setBondManager(address(bondManager));
    }

    function getKeysSignatures() public returns (bytes memory, bytes memory) {
        return (new bytes(0), new bytes(0));
    }

    function test_AddNodeOperatorWstETH() public {
        (bytes memory keys, bytes memory signatures) = getKeysSignatures();
        vm.startPrank(nodeOperator);
        lido.wstETH.wrap(2 ether);
        csm.addNodeOperatorWstETH("test", nodeOperator, 1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysWstETH() public {
        (bytes memory keys, bytes memory signatures) = getKeysSignatures();
        vm.startPrank(nodeOperator);
        lido.wstETH.wrap(2 ether);
        csm.addNodeOperatorWstETH("test", nodeOperator, 1, keys, signatures);
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        vm.deal(nodeOperator, 2 ether);
        lido.stETH.submit{ value: 2 ether }(address(0));
        lido.wstETH.wrap(2 ether);
        csm.addValidatorKeysWstETH(noId, 1, keys, signatures);
    }

    function test_AddNodeOperatorStETH() public {
        (bytes memory keys, bytes memory signatures) = getKeysSignatures();
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH("test", nodeOperator, 1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysStETH() public {
        (bytes memory keys, bytes memory signatures) = getKeysSignatures();
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH("test", nodeOperator, 1, keys, signatures);
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        vm.deal(nodeOperator, 2 ether);
        vm.startPrank(nodeOperator);
        lido.stETH.submit{ value: 2 ether }(address(0));
        csm.addValidatorKeysStETH(noId, 1, keys, signatures);
    }

    function test_AddNodeOperatorETH() public {
        (bytes memory keys, bytes memory signatures) = getKeysSignatures();
        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 2 ether }(
            "test",
            nodeOperator,
            1,
            keys,
            signatures
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysETH() public {
        (bytes memory keys, bytes memory signatures) = getKeysSignatures();
        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 2 ether }(
            "test",
            nodeOperator,
            1,
            keys,
            signatures
        );
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: 2 ether }(noId, 1, keys, signatures);
    }
}
