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
import "./helpers/Utilities.sol";

contract CSMCommon is Test, Fixtures, Utilities, CommunityStakingModuleBase {
    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    Stub public burner;
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal stranger;
    address internal alice;
    address internal nodeOperator;

    function setUp() public {
        alice = address(1);
        nodeOperator = address(2);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        (locator, wstETH, stETH, burner) = initLido();

        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        stETH.submit{ value: 2 ether }(address(0));

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

    function createNodeOperator() internal returns (uint256) {
        return createNodeOperator("test");
    }

    function createNodeOperator(string memory name) internal returns (uint256) {
        uint256 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 2 ether }(
            name,
            nodeOperator,
            keysCount,
            keys,
            signatures
        );
        return csm.getNodeOperatorsCount() - 1;
    }
}

contract CSMAddNodeOperator is CSMCommon {
    function test_AddNodeOperatorWstETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.startPrank(nodeOperator);
        wstETH.wrap(2 ether);

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, "test", nodeOperator);
        }

        csm.addNodeOperatorWstETH("test", nodeOperator, 1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysWstETH() public {
        uint256 noId = createNodeOperator();

        vm.deal(nodeOperator, 2 ether);
        stETH.submit{ value: 2 ether }(address(0));
        wstETH.wrap(2 ether);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysWstETH(noId, 1, keys, signatures);
    }

    function test_AddNodeOperatorStETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, "test", nodeOperator);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH("test", nodeOperator, 1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysStETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, 2 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 2 ether }(address(0));
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysStETH(noId, 1, keys, signatures);
    }

    function test_AddNodeOperatorETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, 2 ether);

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, "test", nodeOperator);
        }

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
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysETH{ value: 2 ether }(noId, 1, keys, signatures);
    }
}

contract CSMObtainDepositData is CSMCommon {
    function test_obtainDepositData_RevertWhenNoMoreKeys() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
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

        vm.expectRevert(bytes("NOT_ENOUGH_KEYS"));
        csm.obtainDepositData(1, "");
    }
}

contract CSMEditNodeOperatorInfo is CSMCommon {
    function test_setNodeOperatorName() public {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        vm.expectEmit(true, true, false, true, address(csm));
        emit NodeOperatorNameSet(noId, "newName");
        csm.setNodeOperatorName(noId, "newName");

        string memory name;
        (, name, , , , , , ) = csm.getNodeOperator(noId, true);
        assertEq(name, "newName");
    }

    function test_setNodeOperatorName_revertIfNotManager() public {
        uint256 noId = createNodeOperator();
        vm.prank(stranger);
        vm.expectRevert("sender is not eligible to manage node operator");
        csm.setNodeOperatorName(noId, "newName");
    }

    function test_setNodeOperatorName_revertIfInvalidLength() public {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        vm.expectRevert("WRONG_NAME_LENGTH");
        csm.setNodeOperatorName(noId, "");

        string memory tooLongName = new string(
            csm.MAX_NODE_OPERATOR_NAME_LENGTH() + 1
        );
        vm.prank(nodeOperator);
        vm.expectRevert("WRONG_NAME_LENGTH");
        csm.setNodeOperatorName(noId, tooLongName);
    }

    function test_setNodeOperatorName_revertIfSameName() public {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        vm.expectRevert("SAME_NAME");
        csm.setNodeOperatorName(noId, "test");
    }

    function test_setNodeOperatorName_revertIfNonUniqueName() public {
        uint256 noId = createNodeOperator("test");
        createNodeOperator("test2");

        vm.prank(nodeOperator);
        vm.expectRevert("NAME_ALREADY_EXISTS");
        csm.setNodeOperatorName(noId, "test2");
    }

    function test_setNodeOperatorName_revertIfNotExists() public {
        vm.prank(nodeOperator);
        vm.expectRevert("node operator does not exist");
        csm.setNodeOperatorName(0, "test");
    }
}
