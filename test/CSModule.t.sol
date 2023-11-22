// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/CSModule.sol";
import "../src/CSAccounting.sol";
import "../src/lib/Batch.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";
import "./helpers/Utilities.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract CSMCommon is Test, Fixtures, Utilities, CSModuleBase {
    using Strings for uint256;

    struct BatchInfo {
        uint256 nodeOperatorId;
        uint256 start;
        uint256 count;
        uint256 nonce;
    }

    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    Stub public burner;
    CSModule public csm;
    CSAccounting public accounting;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal admin;
    address internal stranger;
    address internal nodeOperator;

    function setUp() public {
        vm.label(address(this), "TEST");

        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

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
            admin,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks,
            1 days
        );
        csm.setAccounting(address(accounting));

        vm.startPrank(admin);
        accounting.grantRole(
            accounting.INSTANT_PENALIZE_BOND_ROLE(),
            address(csm)
        ); // NOTE: required because of `unvetKeys`
        vm.stopPrank();
    }

    function createNodeOperator() internal returns (uint256) {
        return createNodeOperator(nodeOperator, 1);
    }

    function createNodeOperator(uint256 keysCount) internal returns (uint256) {
        return createNodeOperator(nodeOperator, keysCount);
    }

    function createNodeOperator(
        address managerAddress,
        uint256 keysCount
    ) internal returns (uint256) {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(managerAddress, keysCount * 2 ether);
        vm.prank(managerAddress);
        csm.addNodeOperatorETH{ value: keysCount * 2 ether }(
            keysCount,
            keys,
            signatures
        );
        return csm.getNodeOperatorsCount() - 1;
    }

    function _assertQueueState(BatchInfo[] memory exp) internal {
        // (bytes32 pointer,) = csm.queue(); // it works, but how?
        bytes32 pointer = bytes32(0);

        for (uint256 i = 0; i < exp.length; i++) {
            BatchInfo memory b = exp[i];

            assertFalse(
                _isLastElementInQueue(pointer),
                string.concat("unexpected end of queue at index ", i.toString())
            );

            pointer = _nextPointer(pointer);
            (
                uint256 nodeOperatorId,
                uint256 start,
                uint256 count,
                uint256 nonce
            ) = Batch.deserialize(pointer);

            assertEq(
                nodeOperatorId,
                b.nodeOperatorId,
                string.concat(
                    "unexpected `nodeOperatorId` at index ",
                    i.toString()
                )
            );
            assertEq(
                start,
                b.start,
                string.concat("unexpected `start` at index ", i.toString())
            );
            assertEq(
                count,
                b.count,
                string.concat("unexpected `count` at index ", i.toString())
            );
            assertEq(
                nonce,
                b.nonce,
                string.concat("unexpected `nonce` at index ", i.toString())
            );
        }

        assertTrue(_isLastElementInQueue(pointer), "unexpected tail of queue");
    }

    function _isLastElementInQueue(
        bytes32 pointer
    ) internal view returns (bool) {
        bytes32 next = _nextPointer(pointer);
        return next == pointer;
    }

    function _nextPointer(bytes32 pointer) internal view returns (bytes32) {
        (, bytes32 next, ) = csm.depositQueue(1, pointer);
        return next;
    }
}

contract CsmInitialization is CSMCommon {
    function test_initContract() public {
        csm = new CSModule("community-staking-module", address(locator));
        assertEq(csm.getType(), "community-staking-module");
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_setAccounting() public {
        csm = new CSModule("community-staking-module", address(locator));
        csm.setAccounting(address(accounting));
        assertEq(address(csm.accounting()), address(accounting));
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
        emit NodeOperatorManagerAddressChangeProposed(noId, stranger);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorManagerAddressChange(0, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenNotManager()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotManagerAddress.selector);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenAlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectRevert(AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
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
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorManagerAddressChanged(noId, nodeOperator, stranger);
        vm.prank(stranger);
        csm.confirmNodeOperatorManagerAddressChange(noId);

        no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, stranger);
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
        vm.prank(stranger);
        csm.confirmNodeOperatorManagerAddressChange(noId);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhenOtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectRevert(SenderIsNotProposedAddress.selector);
        vm.prank(nextAddress());
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
        emit NodeOperatorRewardAddressChangeProposed(noId, stranger);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorRewardAddressChange(0, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenNotRewardAddress()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SenderIsNotRewardAddress.selector);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenAlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
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
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorRewardAddressChanged(noId, nodeOperator, stranger);
        vm.prank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);

        no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, stranger);
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
        vm.prank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhenOtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(SenderIsNotProposedAddress.selector);
        vm.prank(nextAddress());
        csm.confirmNodeOperatorRewardAddressChange(noId);
    }
}

contract CsmResetNodeOperatorManagerAddress is CSMCommon {
    function test_resetNodeOperatorManagerAddress() public {
        uint256 noId = createNodeOperator();

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
        vm.prank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);

        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorManagerAddressChanged(noId, nodeOperator, stranger);
        vm.prank(stranger);
        csm.resetNodeOperatorManagerAddress(noId);

        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, stranger);
        assertEq(no.rewardAddress, stranger);
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

contract CsmVetKeys is CSMCommon {
    function test_vetKeys() public {
        uint256 noId = createNodeOperator();

        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, 0, 1);
        vm.expectEmit(true, true, false, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 1);
        csm.vetKeys(noId, 1);

        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);

        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({
            nodeOperatorId: noId,
            start: 0,
            count: 1,
            nonce: 0
        });
        _assertQueueState(exp);
    }

    function test_vetKeys_totalVettedKeysIsNotZero() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 1);

        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, 1, 1);
        vm.expectEmit(true, true, false, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 2);
        csm.vetKeys(noId, 2);

        NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 2);

        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({
            nodeOperatorId: noId,
            start: 0,
            count: 1,
            nonce: 0
        });
        exp[1] = BatchInfo({
            nodeOperatorId: noId,
            start: 1,
            count: 1,
            nonce: 0
        });
        _assertQueueState(exp);
    }

    function test_vetKeys_RevertWhenNoNodeOperator() public {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.vetKeys(0, 1);
    }

    function test_vetKeys_RevertWhenPointerLessThanTotalVetted() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);

        vm.expectRevert(InvalidVetKeysPointer.selector);
        csm.vetKeys(noId, 1);
    }

    function test_vetKeys_RevertWhenPointerGreaterThanTotalAdded() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(InvalidVetKeysPointer.selector);
        csm.vetKeys(noId, 2);
    }
}

contract CsmQueueOps is CSMCommon {
    function test_queueIsCleanByDefault() public {
        createNodeOperator({ keysCount: 2 });
        csm.vetKeys(0, 1);

        (bool isDirty /* next */, ) = csm.isQueueDirty(1, bytes32(0));
        assertFalse(isDirty, "queue should be clean");
    }

    function test_queueIsDirty_WhenUnvettedKeys() public {
        createNodeOperator({ keysCount: 2 });
        csm.vetKeys(0, 1);
        csm.unvetKeys(0);

        (bool isDirty /* next */, ) = csm.isQueueDirty(1, bytes32(0));
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsClean_AfterCleanup() public {
        createNodeOperator({ keysCount: 2 });
        csm.vetKeys(0, 1);
        csm.unvetKeys(0);
        csm.cleanDepositQueue(1, bytes32(0));

        (bool isDirty /* next */, ) = csm.isQueueDirty(1, bytes32(0));
        assertFalse(isDirty, "queue should be clean");
    }

    function test_queueIsDirty_WhenDanglingBatch() public {
        createNodeOperator({ keysCount: 2 });

        csm.vetKeys(0, 1);
        csm.vetKeys(0, 2);
        csm.unvetKeys(0);
        csm.vetKeys(0, 2);

        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](3);
        exp[0] = BatchInfo({ nodeOperatorId: 0, start: 0, count: 1, nonce: 0 });
        exp[1] = BatchInfo({ nodeOperatorId: 0, start: 1, count: 1, nonce: 0 });
        exp[2] = BatchInfo({ nodeOperatorId: 0, start: 0, count: 2, nonce: 1 });
        _assertQueueState(exp);

        (bool isDirty /* next */, ) = csm.isQueueDirty(3, bytes32(0));
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsClean_WhenDanglingBatchCleanedUp() public {
        createNodeOperator({ keysCount: 2 });

        csm.vetKeys(0, 1);
        csm.vetKeys(0, 2);
        csm.unvetKeys(0);
        csm.vetKeys(0, 2);

        csm.cleanDepositQueue(3, bytes32(0));
        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: 0, start: 0, count: 2, nonce: 1 });
        _assertQueueState(exp);

        (bool isDirty /* next */, ) = csm.isQueueDirty(3, bytes32(0));
        assertFalse(isDirty, "queue should be clean");
    }
}
