// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/CommunityStakingModule.sol";
import "../src/CommunityStakingBondManager.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";

contract CSMAddNodeOperator is Test {
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;

    LidoMock public lidoStETH;
    WstETHMock public wstETH;
    StETHMock public stETH;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;
    LidoLocatorMock public locator;

    address internal stranger;
    address internal alice;
    address internal burner;
    address internal nodeOperator;

    function setUp() public {
        alice = address(1);
        nodeOperator = address(2);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;
        lidoStETH = new LidoMock(8013386371917025835991984);
        lidoStETH.mintShares(address(lidoStETH), 7059313073779349112833523);
        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        lidoStETH.submit{ value: 2 ether }(address(0));
        locator = new LidoLocatorMock(address(lidoStETH), burner);
        wstETH = new WstETHMock(address(lidoStETH));
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(bondManager)
        );
        csm = new CommunityStakingModule(
            "community-staking-module",
            address(locator)
        );
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(locator),
            address(wstETH),
            address(csm),
            penalizeRoleMembers
        );
        csm.setBondManager(address(bondManager));
    }

    function getKeysSignatures(
        uint256 keysCount
    ) public returns (bytes memory, bytes memory) {
        bytes memory keys;
        bytes memory signatures;
        for (uint16 i = 0; i < keysCount; i++) {
            bytes memory index = abi.encodePacked(i + 1);
            //            bytes memory zeroKey = new bytes(48 - index.length);
            bytes memory key = bytes.concat(
                new bytes(48 - index.length),
                index
            );
            bytes memory sign = bytes.concat(
                new bytes(96 - index.length),
                index
            );
            keys = bytes.concat(keys, key);
            signatures = bytes.concat(signatures, sign);
        }
        return (keys, signatures);
    }

    function test_AddNodeOperatorWstETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
        vm.startPrank(nodeOperator);
        wstETH.wrap(2 ether);
        csm.addNodeOperatorWstETH("test", nodeOperator, 1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysWstETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
        vm.startPrank(nodeOperator);
        wstETH.wrap(2 ether);
        csm.addNodeOperatorWstETH("test", nodeOperator, 1, keys, signatures);
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        vm.deal(nodeOperator, 2 ether);
        lidoStETH.submit{ value: 2 ether }(address(0));
        wstETH.wrap(2 ether);
        csm.addValidatorKeysWstETH(noId, 1, keys, signatures);
    }

    function test_AddNodeOperatorStETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH("test", nodeOperator, 1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysStETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH("test", nodeOperator, 1, keys, signatures);
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        vm.deal(nodeOperator, 2 ether);
        vm.startPrank(nodeOperator);
        lidoStETH.submit{ value: 2 ether }(address(0));
        csm.addValidatorKeysStETH(noId, 1, keys, signatures);
    }

    function test_AddNodeOperatorETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
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
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
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

    function test_obtainDepositData() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = getKeysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 2 ether }(
            "test",
            nodeOperator,
            1,
            keys,
            signatures
        );
        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .obtainDepositData(1, "");
        assertEq(obtainedKeys, keys);
        assertEq(obtainedSignatures, signatures);

        (obtainedKeys, obtainedSignatures) = csm.obtainDepositData(1, "");
        assertEq(obtainedKeys, new bytes(48));
        assertEq(obtainedSignatures, new bytes(96));
    }
}
