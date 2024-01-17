// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/CSModule.sol";
import "../src/CSAccounting.sol";
import "../src/lib/Batch.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";
import "./helpers/Utilities.sol";

contract CSMCommon is Test, Fixtures, Utilities, CSModuleBase {
    using Strings for uint256;

    struct BatchInfo {
        uint256 nodeOperatorId;
        uint256 start;
        uint256 count;
        uint256 nonce;
    }

    bytes32 public constant NULL_POINTER = bytes32(0);
    uint256 public constant BOND_SIZE = 2 ether;

    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    CSModule public csm;
    CSAccounting public accounting;
    Stub public communityStakingFeeDistributor;

    address internal admin;
    address internal stranger;
    address internal nodeOperator;

    struct NodeOperatorSummary {
        bool isTargetLimitActive;
        uint256 targetValidatorsCount;
        uint256 stuckValidatorsCount;
        uint256 refundedValidatorsCount;
        uint256 stuckPenaltyEndTimestamp;
        uint256 totalExitedValidators;
        uint256 totalDepositedValidators;
        uint256 depositableValidatorsCount;
    }

    function setUp() public {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        (locator, wstETH, stETH, ) = initLido();

        // FIXME: move to the corresponding tests
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        communityStakingFeeDistributor = new Stub();
        csm = new CSModule("community-staking-module", address(locator));
        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE;
        accounting = new CSAccounting(
            curve,
            admin,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks
        );
        csm.setAccounting(address(accounting));
        csm.setUnvettingFee(0.05 ether);

        vm.startPrank(admin);
        accounting.grantRole(
            accounting.INSTANT_PENALIZE_BOND_ROLE(),
            address(csm)
        );
        accounting.grantRole(accounting.SET_BOND_LOCK_ROLE(), address(csm));
        accounting.grantRole(accounting.RESET_BOND_CURVE_ROLE(), address(csm));
        accounting.grantRole(accounting.RELEASE_BOND_LOCK_ROLE(), address(csm));
        accounting.grantRole(accounting.SETTLE_BOND_LOCK_ROLE(), address(csm));
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
        return createNodeOperator(managerAddress, keysCount, keys, signatures);
    }

    function createNodeOperator(
        address managerAddress,
        uint256 keysCount,
        bytes memory keys,
        bytes memory signatures
    ) internal returns (uint256) {
        vm.deal(managerAddress, keysCount * BOND_SIZE);
        vm.prank(managerAddress);
        csm.addNodeOperatorETH{ value: keysCount * BOND_SIZE }(
            keysCount,
            keys,
            signatures
        );
        return csm.getNodeOperatorsCount() - 1;
    }

    function _assertQueueState(BatchInfo[] memory exp) internal {
        if (exp.length == 0) {
            revert("NOTE: use _assertQueueIsEmpty");
        }

        (bytes32 pointer, ) = csm.queue(); // queue.front

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

    function _assertQueueIsEmpty() internal {
        (bytes32 front, bytes32 back) = csm.queue();
        assertEq(front, back, "queue is not empty");
    }

    function _isLastElementInQueue(
        bytes32 pointer
    ) internal view returns (bool) {
        bytes32 next = _nextPointer(pointer);
        return next == pointer;
    }

    function _nextPointer(bytes32 pointer) internal view returns (bytes32) {
        (bytes32[] memory items, uint256 count) = csm.depositQueue(1, pointer);
        return count == 0 ? pointer : items[0];
    }

    function getNodeOperatorSummary(
        uint256 noId
    ) public view returns (NodeOperatorSummary memory) {
        (
            bool isTargetLimitActive,
            uint256 targetValidatorsCount,
            uint256 stuckValidatorsCount,
            uint256 refundedValidatorsCount,
            uint256 stuckPenaltyEndTimestamp,
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        ) = csm.getNodeOperatorSummary(noId);
        return
            NodeOperatorSummary({
                isTargetLimitActive: isTargetLimitActive,
                targetValidatorsCount: targetValidatorsCount,
                stuckValidatorsCount: stuckValidatorsCount,
                refundedValidatorsCount: refundedValidatorsCount,
                stuckPenaltyEndTimestamp: stuckPenaltyEndTimestamp,
                totalExitedValidators: totalExitedValidators,
                totalDepositedValidators: totalDepositedValidators,
                depositableValidatorsCount: depositableValidatorsCount
            });
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
        wstETH.wrap(BOND_SIZE + 1 wei);

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
        uint256 wstETHAmount = wstETH.wrap(BOND_SIZE);

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
        uint256 toWrap = BOND_SIZE + 1 wei;
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
        uint256 toWrap = BOND_SIZE + 1 wei;
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
            emit Approval(nodeOperator, address(accounting), BOND_SIZE);
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
                value: BOND_SIZE,
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

        vm.deal(nodeOperator, BOND_SIZE);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE }(address(0));
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

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
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
        vm.deal(nodeOperator, BOND_SIZE);

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(1, keys, signatures);
        assertEq(csm.getNodeOperatorsCount(), 1);
    }

    function test_AddValidatorKeysETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
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
        vm.deal(nodeOperator, BOND_SIZE);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(1, keys, signatures);

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
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
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

    function test_vetKeys_RevertWhenPointerGreaterThanTargetLimit() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 1);
        csm.updateTargetValidatorsLimits(noId, true, 1);

        vm.expectRevert(TargetLimitExceeded.selector);
        csm.vetKeys(noId, 2);
    }

    function test_vetKeys_RevertWhenStuckKeysPresent() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.expectRevert(StuckKeysPresent.selector);
        csm.vetKeys(noId, 2);
    }
}

contract CsmQueueOps is CSMCommon {
    uint256 internal constant LOOKUP_DEPTH = 150; // derived from maxDepositsPerBlock

    function test_emptyQueueIsClean() public {
        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertFalse(isDirty, "queue should be clean");
    }

    function test_queueIsDirty_WhenUnvettedKeys() public {
        createNodeOperator({ keysCount: 2 });
        csm.vetKeys(0, 1);
        csm.unvetKeys(0);

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsClean_AfterCleanup() public {
        createNodeOperator({ keysCount: 2 });
        csm.vetKeys(0, 1);
        csm.unvetKeys(0);
        csm.cleanDepositQueue(LOOKUP_DEPTH, NULL_POINTER);

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertFalse(isDirty, "queue should be clean");
    }

    function test_queueIsDirty_WhenDanglingBatches() public {
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

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsClean_WhenDanglingBatchesCleanedUp() public {
        createNodeOperator({ keysCount: 2 });

        csm.vetKeys(0, 1);
        csm.vetKeys(0, 2);
        csm.unvetKeys(0);
        csm.vetKeys(0, 2);

        csm.cleanDepositQueue(LOOKUP_DEPTH, NULL_POINTER);
        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: 0, start: 0, count: 2, nonce: 1 });
        _assertQueueState(exp);

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanup_emptyQueue() public {
        csm.cleanDepositQueue(LOOKUP_DEPTH, NULL_POINTER);
        _assertQueueIsEmpty();

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanup_WhenOneInvalidBatchInRow() public {
        createNodeOperator({ keysCount: 2 });

        csm.vetKeys(0, 1);
        csm.unvetKeys(0);
        csm.vetKeys(0, 1);

        csm.cleanDepositQueue(LOOKUP_DEPTH, NULL_POINTER);
        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: 0, start: 0, count: 1, nonce: 1 });
        _assertQueueState(exp);

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanup_WhenMultipleInvalidBatchesInRow() public {
        createNodeOperator({ keysCount: 3 });
        createNodeOperator({ keysCount: 2 });

        csm.vetKeys(0, 1); // <-- invalid
        csm.vetKeys(1, 1);
        csm.vetKeys(0, 2); // <-- invalid
        csm.vetKeys(0, 3); // <-- invalid
        csm.unvetKeys(0);
        csm.vetKeys(0, 3);

        csm.cleanDepositQueue(LOOKUP_DEPTH, NULL_POINTER);
        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({ nodeOperatorId: 1, start: 0, count: 1, nonce: 0 });
        exp[1] = BatchInfo({ nodeOperatorId: 0, start: 0, count: 3, nonce: 1 });
        _assertQueueState(exp);

        (bool isDirty /* next */, ) = csm.isQueueDirty(
            LOOKUP_DEPTH,
            NULL_POINTER
        );
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanup_WhenAllBatchesInvalid() public {
        createNodeOperator({ keysCount: 2 });

        csm.vetKeys(0, 1);
        csm.vetKeys(0, 2);
        csm.unvetKeys(0);

        csm.cleanDepositQueue(LOOKUP_DEPTH, NULL_POINTER);
        _assertQueueIsEmpty();
    }

    function test_unvetKeys_feeApplied() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        vm.expectEmit(true, true, true, true, address(csm));
        emit UnvettingFeeApplied(noId);
        csm.unvetKeys(noId);
    }

    function test_unvetKeys_feeEqualsToBond() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.setUnvettingFee(BOND_SIZE);
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.unvetKeys(noId);
    }
}

contract CsmViewKeys is CSMCommon {
    function test_viewAllKeys() public {
        bytes memory keys = randomBytes(48 * 3);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 3,
            keys: keys,
            signatures: randomBytes(96 * 3)
        });

        bytes memory obtainedKeys = csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });

        assertEq(obtainedKeys, keys, "unexpected keys");
    }

    function test_viewKeysFromOffset() public {
        bytes memory wantedKey = randomBytes(48);
        bytes memory keys = bytes.concat(
            randomBytes(48),
            wantedKey,
            randomBytes(48)
        );

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 3,
            keys: keys,
            signatures: randomBytes(96 * 3)
        });

        bytes memory obtainedKeys = csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 1,
            keysCount: 1
        });

        assertEq(obtainedKeys, wantedKey, "unexpected key at position 1");
    }
}

contract CsmRemoveKeys is CSMCommon {
    event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);

    bytes key0 = randomBytes(48);
    bytes key1 = randomBytes(48);
    bytes key2 = randomBytes(48);
    bytes key3 = randomBytes(48);
    bytes key4 = randomBytes(48);

    function test_singleKeyRemoval() public {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        // at the beginning
        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key0);

            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 4);
        }
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
        /*
            key4
            key1
            key2
            key3
        */

        // in between
        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key1);

            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 3);
        }
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 1, keysCount: 1 });
        /*
            key4
            key3
            key2
        */

        // at the end
        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key2);

            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 2);
        }
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 2, keysCount: 1 });
        /*
            key4
            key3
        */

        bytes memory obtainedKeys = csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 2
        });
        assertEq(obtainedKeys, bytes.concat(key4, key3), "unexpected keys");

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedValidators, 2);
    }

    function test_multipleKeysRemovalFromStart() public {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        {
            // NOTE: keys are being removed in reverse order to keep an original order of keys at the end of the list
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key1);
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key0);

            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 3);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 2 });

        bytes memory obtainedKeys = csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
        assertEq(
            obtainedKeys,
            bytes.concat(key3, key4, key2),
            "unexpected keys"
        );

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedValidators, 3);
    }

    function test_multipleKeysRemovalInBetween() public {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        {
            // NOTE: keys are being removed in reverse order to keep an original order of keys at the end of the list
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key2);
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key1);

            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 3);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 1, keysCount: 2 });

        bytes memory obtainedKeys = csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
        assertEq(
            obtainedKeys,
            bytes.concat(key0, key3, key4),
            "unexpected keys"
        );

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedValidators, 3);
    }

    function test_multipleKeysRemovalFromEnd() public {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        {
            // NOTE: keys are being removed in reverse order to keep an original order of keys at the end of the list
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key4);
            vm.expectEmit(true, true, true, true, address(csm));
            emit SigningKeyRemoved(noId, key3);

            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 3);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 3, keysCount: 2 });

        bytes memory obtainedKeys = csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
        assertEq(
            obtainedKeys,
            bytes.concat(key0, key1, key2),
            "unexpected keys"
        );

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedValidators, 3);
    }

    function test_removeAllKeys() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: randomBytes(48 * 5),
            signatures: randomBytes(96 * 5)
        });

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit TotalSigningKeysCountChanged(noId, 0);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 5 });

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedValidators, 0);
    }

    function test_removingVettedKeysUnvetsOperator() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: randomBytes(48 * 5),
            signatures: randomBytes(96 * 5)
        });

        csm.vetKeys(noId, 3);
        csm.obtainDepositData(1, "");

        /*
            no.totalVettedValidators = 3
            no.totalDepositedKeys = 1
            no.totalAddedKeys = 5
        */

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit VettedSigningKeysCountChanged(noId, 1);
            vm.expectEmit(true, true, true, true, address(csm));
            emit UnvettingFeeApplied(noId);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 1, keysCount: 2 });
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
    }

    function test_removingNotVettedKeysDoesntUnvetOperator() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: randomBytes(48 * 5),
            signatures: randomBytes(96 * 5)
        });

        csm.vetKeys(noId, 3);
        csm.obtainDepositData(1, "");

        /*
            no.totalVettedValidators = 3
            no.totalDepositedKeys = 1
            no.totalAddedKeys = 5
        */

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 3, keysCount: 2 });
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(0);
        assertEq(no.totalVettedValidators, 3);
    }

    function test_removeKeys_RevertWhenNoNodeOperator() public {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.removeKeys({ nodeOperatorId: 0, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhenMoreThanAdded() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.expectRevert(SigningKeysInvalidOffset.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 2 });
    }

    function test_removeKeys_RevertWhenLessThanDeposited() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 2
        });

        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        vm.expectRevert(SigningKeysInvalidOffset.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhenNotManager() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.prank(stranger);
        vm.expectRevert(SenderIsNotManagerAddress.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
    }
}

contract CsmGetNodeOperatorSummary is CSMCommon {
    // TODO add more tests here. There might be fuzz tests

    function test_getNodeOperatorSummary_defaultValues() public {
        uint256 noId = createNodeOperator();

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.isTargetLimitActive, false);
        assertEq(summary.targetValidatorsCount, 0);
        assertEq(summary.stuckValidatorsCount, 0);
        assertEq(summary.refundedValidatorsCount, 0);
        assertEq(summary.stuckPenaltyEndTimestamp, 0);
        assertEq(summary.totalExitedValidators, 0);
        assertEq(summary.totalDepositedValidators, 0);
        assertEq(summary.depositableValidatorsCount, 0);
    }

    function test_getNodeOperatorSummary_vetKeys() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.depositableValidatorsCount, 1);
        assertEq(summary.totalDepositedValidators, 0);
    }

    function test_getNodeOperatorSummary_depositedKey() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.depositableValidatorsCount, 0);
        assertEq(summary.totalDepositedValidators, 1);
    }

    function test_getNodeOperatorSummary_targetLimit() public {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, true, 1);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);

        summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetValidatorsCount, 1);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.depositableValidatorsCount, 0);
    }

    function test_getNodeOperatorSummary_targetLimitEqualToDepositedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);
        csm.vetKeys(noId, 2);
        csm.obtainDepositData(1, "");

        csm.updateTargetValidatorsLimits(noId, true, 1);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.targetValidatorsCount, 1);
        assertEq(summary.depositableValidatorsCount, 0);
    }

    function test_getNodeOperatorSummary_targetLimitLowerThanDepositedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);
        csm.vetKeys(noId, 3);
        csm.obtainDepositData(2, "");

        csm.updateTargetValidatorsLimits(noId, true, 1);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.targetValidatorsCount, 1);
        assertEq(summary.depositableValidatorsCount, 0);
    }

    function test_getNodeOperatorSummary_targetLimitLowerThanVettedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);
        csm.vetKeys(noId, 3);

        csm.updateTargetValidatorsLimits(noId, true, 2);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.targetValidatorsCount, 2);
        // should be unvetted
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 0);
    }

    function test_getNodeOperatorSummary_targetLimitHigherThanVettedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);
        csm.updateTargetValidatorsLimits(noId, true, 1);
        csm.vetKeys(noId, 1);

        csm.updateTargetValidatorsLimits(noId, true, 3);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.targetValidatorsCount, 3);
        assertEq(summary.depositableValidatorsCount, 1);
    }
}

contract CsmUpdateTargetValidatorsLimits is CSMCommon {
    function test_updateTargetValidatorsLimits() public {
        uint256 noId = createNodeOperator();

        vm.expectEmit(true, true, true, true, address(csm));
        emit TargetValidatorsCountChanged(noId, true, 1);
        csm.updateTargetValidatorsLimits(noId, true, 1);
    }

    function test_updateTargetValidatorsLimits_limitIsZero() public {
        uint256 noId = createNodeOperator();
        vm.expectEmit(true, true, true, true, address(csm));
        emit TargetValidatorsCountChanged(noId, true, 0);
        csm.updateTargetValidatorsLimits(noId, true, 0);
    }

    function test_updateTargetValidatorsLimits_enableLimit() public {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, false, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit TargetValidatorsCountChanged(noId, true, 10);
        csm.updateTargetValidatorsLimits(noId, true, 10);
    }

    function test_updateTargetValidatorsLimits_disableLimit() public {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, true, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit TargetValidatorsCountChanged(noId, false, 10);
        csm.updateTargetValidatorsLimits(noId, false, 10);
    }

    function test_updateTargetValidatorsLimits_unvetKeys() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);

        csm.updateTargetValidatorsLimits(noId, true, 1);
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 0);
    }

    function test_updateTargetValidatorsLimits_NoUnvetKeysWhenLimitHigher()
        public
    {
        uint256 noId = createNodeOperator(2);
        csm.updateTargetValidatorsLimits(noId, true, 1);

        csm.vetKeys(noId, 1);

        csm.updateTargetValidatorsLimits(noId, true, 2);
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
    }

    function test_updateTargetValidatorsLimits_NoUnvetKeysWhenLimitDisabled()
        public
    {
        uint256 noId = createNodeOperator(2);
        csm.updateTargetValidatorsLimits(noId, true, 1);

        csm.vetKeys(noId, 1);

        csm.updateTargetValidatorsLimits(noId, false, 1);
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
    }

    function test_updateTargetValidatorsLimits_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.updateTargetValidatorsLimits(0, true, 1);
    }

    function test_updateTargetValidatorsLimits_RevertWhenNotStakingRouter()
        public
    {
        // TODO implement
        vm.skip(true);
    }
}

contract CsmUpdateStuckValidatorsCount is CSMCommon {
    function test_updateStuckValidatorsCount_NonZero() public {
        uint256 noId = createNodeOperator(3);
        csm.vetKeys(noId, 3);
        csm.obtainDepositData(1, "");

        vm.expectEmit(true, true, false, true, address(csm));
        emit StuckSigningKeysCountChanged(noId, 1);
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.stuckValidatorsCount,
            1,
            "stuckValidatorsCount not increased"
        );
    }

    function test_updateStuckValidatorsCount_Unstuck() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.expectEmit(true, true, false, true, address(csm));
        emit StuckSigningKeysCountChanged(noId, 0);
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000000))
        );
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.stuckValidatorsCount,
            0,
            "stuckValidatorsCount should be zero"
        );
    }

    function test_updateStuckValidatorsCount_RevertWhenNoNodeOperator() public {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
    }

    function test_updateStuckValidatorsCount_RevertWhenNotStakingRouter()
        public
    {
        // TODO implement
        vm.skip(true);
    }

    function test_updateStuckValidatorsCount_RevertWhenCountMoreThanDeposited()
        public
    {
        uint256 noId = createNodeOperator(3);
        csm.vetKeys(noId, 3);
        csm.obtainDepositData(1, "");

        vm.expectRevert(StuckKeysHigherThanTotalDeposited.selector);
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000002))
        );
    }

    function test_updateStuckValidatorsCount_NoEventWhenStuckKeysCountSame()
        public
    {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.recordLogs();
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }
}

contract CsmUpdateExitedValidatorsCount is CSMCommon {
    function test_updateExitedValidatorsCount_NonZero() public {
        uint256 noId = createNodeOperator(1);
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        vm.expectEmit(true, true, false, true, address(csm));
        emit ExitedSigningKeysCountChanged(noId, 1);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        NodeOperatorSummary memory noSummary = getNodeOperatorSummary(noId);
        assertEq(
            noSummary.totalExitedValidators,
            1,
            "totalExitedValidators not increased"
        );

        (uint256 totalExitedValidators, , ) = csm.getStakingModuleSummary();
        assertEq(
            totalExitedValidators,
            1,
            "totalExitedValidators not increased"
        );
    }

    function test_updateExitedValidatorsCount_RevertIfNoNodeOperator() public {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
    }

    function test_updateExitedValidatorsCount_RevertIfNotStakingRouter()
        public
    {
        // TODO implement
        vm.skip(true);
    }

    function test_updateExitedValidatorsCount_RevertIfCountMoreThanDeposited()
        public
    {
        uint256 noId = createNodeOperator(1);

        vm.expectRevert(ExitedKeysHigherThanTotalDeposited.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
    }

    function test_updateExitedValidatorsCount_RevertIfExitedKeysDecrease()
        public
    {
        uint256 noId = createNodeOperator(1);
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.expectRevert(ExitedKeysDecrease.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000000))
        );
    }

    function test_updateExitedValidatorsCount_NoEventIfSameValue() public {
        uint256 noId = createNodeOperator(1);
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.recordLogs();
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }
}

contract CsmPenalize is CSMCommon {
    function test_penalize_NoUnvet() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        csm.penalize(noId, 1 ether);

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
    }

    function test_penalize_UnvetIfUnbonded() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 2);

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 0);
        csm.penalize(noId, BOND_SIZE);

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 0);
    }

    function test_penalize_ResetBenefitsIfNoBond() public {
        uint256 noId = createNodeOperator();
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.penalize(noId, BOND_SIZE);
    }
}

contract CsmReportELRewardsStealingPenalty is CSMCommon {
    function test_reportELRewardsStealingPenalty_NoUnvet() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);

        vm.expectEmit(true, true, true, true, address(csm));
        emit ELRewardsStealingPenaltyReported(noId, 100, BOND_SIZE / 2);
        csm.reportELRewardsStealingPenalty(noId, 100, BOND_SIZE / 2);

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(lockedBond, BOND_SIZE / 2 + csm.EL_REWARDS_STEALING_FINE());

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
    }

    function test_reportELRewardsStealingPenalty_UnvetIfUnbonded() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 2);

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 0);
        csm.reportELRewardsStealingPenalty(noId, 100, BOND_SIZE);
    }

    function test_reportELRewardsStealingPenalty_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.reportELRewardsStealingPenalty(0, 100, 1 ether);
    }
}

contract CsmSettleELRewardsStealingPenalty is CSMCommon {
    function test_settleELRewardsStealingPenalty() public {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        csm.reportELRewardsStealingPenalty(noId, block.number, amount);

        csm.settleELRewardsStealingPenalty(idsToSettle);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId),
            0 // no called at all
        );
        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }

    function test_settleELRewardsStealingPenalty_multipleNOs() public {
        uint256 retentionPeriod = accounting.getBondLockRetentionPeriod();
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;
        csm.reportELRewardsStealingPenalty(firstNoId, block.number, 1 ether);
        vm.warp(block.timestamp + retentionPeriod + 1 seconds);
        csm.reportELRewardsStealingPenalty(secondNoId, block.number, BOND_SIZE);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.resetBondCurve.selector,
                secondNoId
            ),
            1 // called once for secondNoId
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(
            firstNoId
        );
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);

        lock = accounting.getLockedBondInfo(secondNoId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }

    function test_settleELRewardsStealingPenalty_penalizeEntireBond() public {
        uint256 noId = createNodeOperator();
        uint256 amount = BOND_SIZE;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        csm.reportELRewardsStealingPenalty(noId, block.number, amount);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);
    }

    function test_settleELRewardsStealingPenalty_WhenRetentionPeriodIsExpired()
        public
    {
        uint256 noId = createNodeOperator();
        uint256 retentionPeriod = accounting.getBondLockRetentionPeriod();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        uint256 amount = 1 ether;

        csm.reportELRewardsStealingPenalty(noId, block.number, amount);

        vm.warp(block.timestamp + retentionPeriod + 1 seconds);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId),
            0 // no called at all
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }
}

contract CsmSubmitWithdrawal is CSMCommon {
    function test_submitWithdrawal() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        vm.expectEmit(true, true, true, true, address(csm));
        emit WithdrawalSubmitted(noId, keyIndex, csm.DEPOSIT_SIZE());
        csm.submitWithdrawal(noId, keyIndex, csm.DEPOSIT_SIZE());

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalWithdrawnValidators, 1);
    }

    function test_submitWithdrawal_lowExitBalance() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        uint256 depositSize = csm.DEPOSIT_SIZE();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        csm.submitWithdrawal(noId, keyIndex, depositSize - 1 ether);
    }

    function test_submitWithdrawal_alreadySlashed() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        csm.submitInitialSlashing(noId, 0);

        uint256 exitBalance = csm.DEPOSIT_SIZE() -
            csm.INITIAL_SLASHING_PENALTY();

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.penalize.selector,
                noId,
                0.05 ether
            )
        );
        csm.submitWithdrawal(noId, keyIndex, exitBalance - 0.05 ether);
    }

    function test_submitWithdrawal_unbondedKeys() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 2);
        csm.obtainDepositData(1, "");

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 1);
        csm.submitWithdrawal(noId, keyIndex, 1 ether);
    }

    function test_submitWithdrawal_outOfBond() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.submitWithdrawal(noId, keyIndex, 0 ether);
    }

    function test_submitWithdrawal_RevertWhenNoNodeOperator() public {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.submitWithdrawal(0, 0, 0);
    }

    function test_submitWithdrawal_RevertWhenInvalidKeyIndexOffset() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SigningKeysInvalidOffset.selector);
        csm.submitWithdrawal(noId, 0, 0);
    }

    function test_submitWithdrawal_RevertWhenAlreadySubmitted() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");
        uint256 depositSize = csm.DEPOSIT_SIZE();

        csm.submitWithdrawal(noId, 0, depositSize);
        vm.expectRevert(AlreadySubmitted.selector);
        csm.submitWithdrawal(noId, 0, depositSize);
    }
}

contract CsmSubmitInitialSlashing is CSMCommon {
    function test_submitInitialSlashing() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");
        uint256 penaltyAmount = csm.INITIAL_SLASHING_PENALTY();

        vm.expectEmit(true, true, true, true, address(csm));
        emit InitialSlashingSubmitted(noId, 0);
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.penalize.selector,
                noId,
                penaltyAmount
            )
        );
        csm.submitInitialSlashing(noId, 0);
    }

    function test_submitInitialSlashing_differentKeys() public {
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 2);
        csm.obtainDepositData(2, "");

        vm.expectEmit(true, true, true, true, address(csm));
        emit InitialSlashingSubmitted(noId, 0);
        csm.submitInitialSlashing(noId, 0);

        vm.expectEmit(true, true, true, true, address(csm));
        emit InitialSlashingSubmitted(noId, 1);
        csm.submitInitialSlashing(noId, 1);
    }

    function test_submitInitialSlashing_unbondedKeys() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator(2);
        csm.vetKeys(noId, 2);
        csm.obtainDepositData(1, "");

        uint256 bondThreshold = (accounting.BONDED_KEY_THRESHOLD_PERCENT_BP() *
            csm.DEPOSIT_SIZE()) / accounting.TOTAL_BASIS_POINTS();
        csm.penalize(noId, bondThreshold - 0.1 ether);

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 1);
        csm.submitInitialSlashing(noId, keyIndex);
    }

    function test_submitInitialSlashing_outOfBond() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        csm.penalize(noId, csm.DEPOSIT_SIZE() - csm.INITIAL_SLASHING_PENALTY());
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.submitInitialSlashing(noId, keyIndex);
    }

    function test_submitInitialSlashing_RevertWhenNoNodeOperator() public {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.submitInitialSlashing(0, 0);
    }

    function test_submitInitialSlashing_RevertWhenInvalidKeyIndexOffset()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(SigningKeysInvalidOffset.selector);
        csm.submitInitialSlashing(noId, 0);
    }

    function test_submitInitialSlashing_RevertWhenAlreadySubmitted() public {
        uint256 noId = createNodeOperator();
        csm.vetKeys(noId, 1);
        csm.obtainDepositData(1, "");

        csm.submitInitialSlashing(noId, 0);
        vm.expectRevert(AlreadySubmitted.selector);
        csm.submitInitialSlashing(noId, 0);
    }
}
