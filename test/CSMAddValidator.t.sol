// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/CSModule.sol";
import "../src/CSAccounting.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";
import "./helpers/Utilities.sol";

contract CSMCommon is Test, Fixtures, Utilities, CSModuleBase {
    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    Stub public burner;
    CSModule public csm;
    CSAccounting public accounting;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal stranger;
    address internal alice;
    address internal nodeOperator;

    function setUp() public {
        alice = address(1);
        nodeOperator = address(2);
        stranger = address(3);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        (locator, wstETH, stETH, burner) = initLido();

        vm.deal(nodeOperator, 2 ether + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: 2 ether + 1 wei }(address(0));

        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(accounting)
        );
        csm = new CSModule("community-staking-module", address(locator));
        accounting = new CSAccounting(
            2 ether,
            alice,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks,
            1 days
        );
        csm.setAccounting(address(accounting));
    }

    function createNodeOperator() internal returns (uint256) {
        return createNodeOperator(nodeOperator);
    }

    function createNodeOperator(
        address managerAddress
    ) internal returns (uint256) {
        uint256 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(managerAddress, 2 ether);
        vm.prank(managerAddress);
        csm.addNodeOperatorETH{ value: 2 ether }(keysCount, keys, signatures);
        return csm.getNodeOperatorsCount() - 1;
    }
}

contract CSMAddNodeOperator is CSMCommon, PermitTokenBase {
    function test_AddNodeOperatorWstETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.startPrank(nodeOperator);
        wstETH.wrap(2 ether + 1 wei);

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
        }

        csm.addNodeOperatorWstETH(1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddNodeOperatorWstETHWithPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.prank(nodeOperator);
        uint256 wstETHAmount = wstETH.wrap(2 ether);

        {
            vm.expectEmit(true, true, true, true, address(wstETH));
            emit Approval(nodeOperator, address(accounting), wstETHAmount);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorWstETHWithPermit(
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: wstETHAmount,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysWstETH() public {
        uint256 noId = createNodeOperator();
        uint256 toWrap = 2 ether + 1 wei;
        vm.deal(nodeOperator, toWrap);
        stETH.submit{ value: toWrap }(address(0));
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysWstETH(noId, 1, keys, signatures);
    }

    function test_AddValidatorKeysWstETHWithPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.startPrank(nodeOperator);
        uint256 toWrap = 2 ether + 1 wei;
        wstETH.wrap(toWrap);
        csm.addNodeOperatorWstETH(1, keys, signatures);
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        vm.deal(nodeOperator, toWrap);
        stETH.submit{ value: toWrap }(address(0));
        uint256 wstETHAmount = wstETH.wrap(toWrap);
        vm.stopPrank();
        (keys, signatures) = keysSignatures(keysCount, 1);
        {
            vm.expectEmit(true, true, true, true, address(wstETH));
            emit Approval(nodeOperator, address(accounting), wstETHAmount);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        vm.prank(nodeOperator);
        csm.addValidatorKeysWstETHWithPermit(
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: wstETHAmount,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddNodeOperatorStETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddNodeOperatorStETHWithPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        {
            vm.expectEmit(true, true, true, true, address(stETH));
            emit Approval(nodeOperator, address(accounting), 2 ether);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETHWithPermit(
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: 2 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );
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
            emit TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysStETH(noId, 1, keys, signatures);
    }

    function test_AddValidatorKeysStETHWithPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(1, keys, signatures);
        uint256 noId = csm.getNodeOperatorsCount() - 1;

        uint256 required = accounting.getRequiredBondStETH(0, 1);
        vm.deal(nodeOperator, required);
        vm.prank(nodeOperator);
        stETH.submit{ value: required }(address(0));
        {
            vm.expectEmit(true, true, true, true, address(stETH));
            emit Approval(nodeOperator, address(accounting), required);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        vm.prank(nodeOperator);
        csm.addValidatorKeysStETHWithPermit(
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: required,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddNodeOperatorETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, 2 ether);

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 2 ether }(1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondETH(0, 1);
        vm.deal(nodeOperator, required);
        vm.prank(nodeOperator);
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysETH{ value: required }(noId, 1, keys, signatures);
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
        csm.addNodeOperatorETH{ value: 2 ether }(1, keys, signatures);

        {
            // Pretend to be a key validation oracle
            csm.vetKeys(0, 1);
        }
        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .obtainDepositData(1, "");
        assertEq(obtainedKeys, keys);
        assertEq(obtainedSignatures, signatures);

        vm.expectRevert(bytes("NOT_ENOUGH_KEYS"));
        csm.obtainDepositData(1, "");
    }
}

contract CsmProposeNodeOperatorManagerAddressChange is CSMCommon {
    function test_proposeNodeOperatorManagerAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.expectEmit(true, true, false, true, address(csm));
        emit NodeOperatorManagerAddressChangeProposed(noId, alice);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, alice);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorManagerAddressChange(0, alice);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenNotManager()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotManagerAddress.selector);
        csm.proposeNodeOperatorManagerAddressChange(noId, alice);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenAlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, alice);

        vm.expectRevert(AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, alice);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenSameAddressProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SameAddress.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, nodeOperator);
    }
}

contract CsmConfirmNodeOperatorManagerAddressChange is CSMCommon {
    function test_confirmNodeOperatorManagerAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, alice);

        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorManagerAddressChanged(noId, nodeOperator, alice);
        vm.prank(alice);
        csm.confirmNodeOperatorManagerAddressChange(noId);

        no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, alice);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.confirmNodeOperatorManagerAddressChange(0);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhenNotProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotProposedAddress.selector);
        vm.prank(alice);
        csm.confirmNodeOperatorManagerAddressChange(noId);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhenOtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectRevert(SenderIsNotProposedAddress.selector);
        vm.prank(alice);
        csm.confirmNodeOperatorManagerAddressChange(noId);
    }
}

contract CsmProposeNodeOperatorRewardAddressChange is CSMCommon {
    function test_proposeNodeOperatorRewardAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.expectEmit(true, true, false, true, address(csm));
        emit NodeOperatorRewardAddressChangeProposed(noId, alice);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, alice);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorRewardAddressChange(0, alice);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenNotRewardAddress()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotRewardAddress.selector);
        csm.proposeNodeOperatorRewardAddressChange(noId, alice);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenAlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, alice);

        vm.expectRevert(AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, alice);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenSameAddressProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SameAddress.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, nodeOperator);
    }
}

contract CsmConfirmNodeOperatorRewardAddressChange is CSMCommon {
    function test_confirmNodeOperatorRewardAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, alice);

        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorRewardAddressChanged(noId, nodeOperator, alice);
        vm.prank(alice);
        csm.confirmNodeOperatorRewardAddressChange(noId);

        no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, alice);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.confirmNodeOperatorRewardAddressChange(0);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhenNotProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotProposedAddress.selector);
        vm.prank(alice);
        csm.confirmNodeOperatorRewardAddressChange(noId);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhenOtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(SenderIsNotProposedAddress.selector);
        vm.prank(alice);
        csm.confirmNodeOperatorRewardAddressChange(noId);
    }
}

contract CsmResetNodeOperatorManagerAddress is CSMCommon {
    function test_resetNodeOperatorManagerAddress() public {
        uint256 noId = createNodeOperator();

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, alice);
        vm.prank(alice);
        csm.confirmNodeOperatorRewardAddressChange(noId);

        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorManagerAddressChanged(noId, nodeOperator, alice);
        vm.prank(alice);
        csm.resetNodeOperatorManagerAddress(noId);

        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, alice);
        assertEq(no.rewardAddress, alice);
    }

    function test_resetNodeOperatorManagerAddress_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.resetNodeOperatorManagerAddress(0);
    }

    function test_resetNodeOperatorManagerAddress_RevertWhenNotRewardAddress()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotRewardAddress.selector);
        vm.prank(stranger);
        csm.resetNodeOperatorManagerAddress(noId);
    }

    function test_resetNodeOperatorManagerAddress_RevertIfSameAddress() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SameAddress.selector);
        vm.prank(nodeOperator);
        csm.resetNodeOperatorManagerAddress(noId);
    }
}
