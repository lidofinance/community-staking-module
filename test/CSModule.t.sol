// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/CSModule.sol";
import "../src/CSAccounting.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";
import "./helpers/Utilities.sol";
import "../src/CSEarlyAdoption.sol";
import "./helpers/MerkleTree.sol";

abstract contract CSMFixtures is Test, Fixtures, Utilities, CSModuleBase {
    using Strings for uint256;

    struct BatchInfo {
        uint256 nodeOperatorId;
        uint256 count;
    }

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
    address internal testChargeRecipient;

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

    struct StakingModuleSummary {
        uint256 totalExitedValidators;
        uint256 totalDepositedValidators;
        uint256 depositableValidatorsCount;
    }

    function setUp() public virtual {}

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
            signatures,
            new bytes32[](0)
        );
        return csm.getNodeOperatorsCount() - 1;
    }

    function uploadMoreKeys(uint256 noId, uint256 keysCount) internal {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getRequiredBondForNextKeys(noId, keysCount);
        vm.deal(nodeOperator, amount);
        // NOTE: There's no check for the sender address to be a manager of the operator at the moment.
        csm.addValidatorKeysETH{ value: amount }(
            noId,
            keysCount,
            keys,
            signatures
        );
    }

    function unvetKeys(uint256 noId, uint256 to) internal {
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(to));
    }

    function setExited(uint256 noId, uint256 to) internal {
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(to)))
        );
    }

    function setStuck(uint256 noId, uint256 to) internal {
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(to)))
        );
    }

    // Checks that the queue is in the expected state starting from its head.
    function _assertQueueState(BatchInfo[] memory exp) internal {
        (uint128 curr, ) = csm.queue(); // queue.head

        for (uint256 i = 0; i < exp.length; ++i) {
            BatchInfo memory b = exp[i];
            Batch item = csm.depositQueueItem(curr);

            assertFalse(
                item.isNil(),
                string.concat("unexpected end of queue at index ", i.toString())
            );

            curr = item.next();
            uint256 noId = item.noId();
            uint256 keysInBatch = item.keys();

            assertEq(
                noId,
                b.nodeOperatorId,
                string.concat(
                    "unexpected `nodeOperatorId` at index ",
                    i.toString()
                )
            );
            assertEq(
                keysInBatch,
                b.count,
                string.concat("unexpected `count` at index ", i.toString())
            );
        }

        assertTrue(
            csm.depositQueueItem(curr).isNil(),
            "unexpected tail of queue"
        );
    }

    function _assertQueueIsEmpty() internal {
        (uint128 curr, ) = csm.queue(); // queue.head
        assertTrue(csm.depositQueueItem(curr).isNil(), "queue should be empty");
    }

    function _isLastElementInQueue(uint128 index) internal view returns (bool) {
        Batch item = csm.depositQueueItem(index);
        (, uint128 length) = csm.queue();
        return item.next() == length;
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

    function getStakingModuleSummary()
        public
        view
        returns (StakingModuleSummary memory)
    {
        (
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        ) = csm.getStakingModuleSummary();
        return
            StakingModuleSummary({
                totalExitedValidators: totalExitedValidators,
                totalDepositedValidators: totalDepositedValidators,
                depositableValidatorsCount: depositableValidatorsCount
            });
    }
}

contract CSMCommon is CSMFixtures {
    function setUp() public override {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        communityStakingFeeDistributor = new Stub();

        csm = new CSModule("community-staking-module", 0, admin);
        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE;
        accounting = new CSAccounting(
            curve,
            admin,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks,
            testChargeRecipient
        );

        vm.startPrank(admin);
        csm.grantRole(csm.PAUSE_ROLE(), address(this));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.SET_ACCOUNTING_ROLE(), address(this));
        csm.grantRole(csm.SET_EARLY_ADOPTION_ROLE(), address(this));
        csm.grantRole(csm.SET_PUBLIC_RELEASE_TIMESTAMP_ROLE(), address(this));
        csm.grantRole(csm.SET_REMOVAL_CHARGE_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(this));
        csm.grantRole(
            csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        csm.grantRole(
            csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        csm.grantRole(csm.PENALIZE_ROLE(), address(this));
        csm.grantRole(csm.WITHDRAWAL_SUBMITTER_ROLE(), address(this));
        csm.grantRole(csm.SLASHING_SUBMITTER_ROLE(), address(this));
        accounting.grantRole(accounting.ADD_BOND_CURVE_ROLE(), address(this));
        accounting.grantRole(
            accounting.RELEASE_BOND_LOCK_ROLE(),
            address(this)
        );
        vm.stopPrank();

        csm.setAccounting(address(accounting));
        csm.setRemovalCharge(0.05 ether);
    }
}

contract CSMCommonNoRoles is CSMFixtures {
    address internal actor;

    function setUp() public override {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        actor = nextAddress("ACTOR");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        communityStakingFeeDistributor = new Stub();
        csm = new CSModule("community-staking-module", 0, admin);

        vm.startPrank(admin);
        csm.grantRole(csm.SET_ACCOUNTING_ROLE(), admin);

        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE;
        accounting = new CSAccounting(
            curve,
            admin,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks,
            testChargeRecipient
        );

        csm.setAccounting(address(accounting));
        vm.stopPrank();
    }
}

contract CsmInitialization is CSMCommon {
    function test_initContract() public {
        csm = new CSModule("community-staking-module", 0, admin);
        assertEq(csm.getType(), "community-staking-module");
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_setAccounting() public {
        csm = new CSModule("community-staking-module", 0, admin);
        vm.startPrank(admin);
        csm.grantRole(csm.SET_ACCOUNTING_ROLE(), address(admin));
        csm.setAccounting(address(accounting));
        vm.stopPrank();
        assertEq(address(csm.accounting()), address(accounting));
    }
}

contract CSMPauseTest is CSMCommon {
    function test_notPausedByDefault() public {
        assertFalse(csm.isPaused());
    }

    function test_pauseFor() public {
        csm.pauseFor(1 days);
        assertTrue(csm.isPaused());
    }

    function test_resume() public {
        csm.pauseFor(1 days);
        csm.resume();
        assertFalse(csm.isPaused());
    }

    function test_auto_resume() public {
        csm.pauseFor(1 days);
        assertTrue(csm.isPaused());
        vm.warp(block.timestamp + 1 days + 1 seconds);
        assertFalse(csm.isPaused());
    }

    function test_pause_RevertWhen_notAdmin() public {
        expectRoleRevert(stranger, csm.PAUSE_ROLE());
        vm.prank(stranger);
        csm.pauseFor(1 days);
    }

    function test_resume_RevertWhen_notAdmin() public {
        csm.pauseFor(1 days);

        expectRoleRevert(stranger, csm.RESUME_ROLE());
        vm.prank(stranger);
        csm.resume();
    }
}

contract CSMPauseAffectingTest is CSMCommon, PermitTokenBase {
    function test_addNodeOperatorETH_RevertWhen_Paused() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addNodeOperatorETH(keysCount, keys, signatures, new bytes32[](0));
    }

    function test_addNodeOperatorStETH_RevertWhen_Paused() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addNodeOperatorStETH(keysCount, keys, signatures, new bytes32[](0));
    }

    function test_addNodeOperatorWstETH_RevertWhen_Paused() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addNodeOperatorWstETH(
            keysCount,
            keys,
            signatures,
            new bytes32[](0)
        );
    }

    function test_addNodeOperatorStETHWithPermit_RevertWhen_Paused() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addNodeOperatorStETHWithPermit(
            keysCount,
            keys,
            signatures,
            new bytes32[](0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_addNodeOperatorWstETHWithPermit_RevertWhen_Paused() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addNodeOperatorWstETHWithPermit(
            keysCount,
            keys,
            signatures,
            new bytes32[](0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_addValidatorKeysETH_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysETH(noId, keysCount, keys, signatures);
    }

    function test_addValidatorKeysStETH_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysStETH(noId, keysCount, keys, signatures);
    }

    function test_addValidatorKeysWstETH_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysWstETH(noId, keysCount, keys, signatures);
    }

    function test_addValidatorKeysStETHWithPermit_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysStETHWithPermit(
            noId,
            keysCount,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_addValidatorKeysWstETHWithPermit_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysWstETHWithPermit(
            noId,
            keysCount,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }
}

contract CSMAddNodeOperator is CSMCommon, PermitTokenBase {
    function test_AddNodeOperatorWstETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        wstETH.wrap(BOND_SIZE + 1 wei);
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
        }

        csm.addNodeOperatorWstETH(1, keys, signatures, new bytes32[](0));
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorWstETHWithPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        uint256 wstETHAmount = wstETH.wrap(BOND_SIZE);
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, true, true, address(wstETH));
            emit Approval(nodeOperator, address(accounting), wstETHAmount);
        }

        csm.addNodeOperatorWstETHWithPermit(
            1,
            keys,
            signatures,
            new bytes32[](0),
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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysWstETH() public {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        stETH.submit{ value: toWrap }(address(0));
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 nonce = csm.getNonce();
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysWstETH(noId, 1, keys, signatures);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysWstETHWithPermit() public {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        uint256 wstETHAmount = wstETH.wrap(toWrap);
        uint256 nonce = csm.getNonce();
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
            vm.expectEmit(true, true, true, true, address(wstETH));
            emit Approval(nodeOperator, address(accounting), wstETHAmount);
        }
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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorStETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(1, keys, signatures, new bytes32[](0));
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorStETHWithPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
            vm.expectEmit(true, true, true, true, address(stETH));
            emit Approval(nodeOperator, address(accounting), BOND_SIZE);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETHWithPermit(
            1,
            keys,
            signatures,
            new bytes32[](0),
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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysStETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysStETH(noId, 1, keys, signatures);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysStETHWithPermit() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        vm.prank(nodeOperator);
        stETH.submit{ value: required }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
            vm.expectEmit(true, true, true, true, address(stETH));
            emit Approval(nodeOperator, address(accounting), required);
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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE);
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit NodeOperatorAdded(0, nodeOperator);
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 1);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            1,
            keys,
            signatures,
            new bytes32[](0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        uint256 nonce = csm.getNonce();

        vm.prank(nodeOperator);
        {
            vm.expectEmit(true, true, false, true, address(csm));
            emit TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysETH{ value: required }(noId, 1, keys, signatures);
        assertEq(csm.getNonce(), nonce + 1);
    }
}

contract CSMObtainDepositData is CSMCommon {
    function test_obtainDepositData() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            1,
            keys,
            signatures,
            new bytes32[](0)
        );

        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .obtainDepositData(1, "");
        assertEq(obtainedKeys, keys);
        assertEq(obtainedSignatures, signatures);
    }

    function test_obtainDepositData_counters() public {
        uint256 noId = createNodeOperator();

        vm.expectEmit(true, true, true, true, address(csm));
        emit DepositedSigningKeysCountChanged(noId, 1);
        csm.obtainDepositData(1, "");

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(no.enqueuedCount, 0);
        assertEq(no.totalDepositedValidators, 1);
        assertEq(summary.depositableValidatorsCount, 0);
    }

    function test_obtainDepositData_counters_WhenLessThanLastBatch() public {
        uint256 noId = createNodeOperator(7);

        vm.expectEmit(true, true, true, true, address(csm));
        emit DepositedSigningKeysCountChanged(noId, 3);
        csm.obtainDepositData(3, "");

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(no.enqueuedCount, 4);
        assertEq(no.totalDepositedValidators, 3);
        assertEq(summary.depositableValidatorsCount, 4);
    }

    function test_obtainDepositData_RevertWhenNoMoreKeys() public {
        vm.expectRevert(NotEnoughKeys.selector);
        csm.obtainDepositData(1, "");
    }

    function test_obtainDepositData_nonceChanged() public {
        createNodeOperator();
        uint256 nonce = csm.getNonce();

        csm.obtainDepositData(1, "");
        assertEq(csm.getNonce(), nonce + 1);
    }
}

contract CsmProposeNodeOperatorManagerAddressChange is CSMCommon {
    function test_proposeNodeOperatorManagerAddressChange() public {
        uint256 noId = createNodeOperator();
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.expectEmit(true, true, false, true, address(csm));
        emit NOAddresses.NodeOperatorManagerAddressChangeProposed(
            noId,
            stranger
        );
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

        vm.expectRevert(NOAddresses.AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenSameAddressProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(NOAddresses.SameAddress.selector);
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
        emit NOAddresses.NodeOperatorManagerAddressChanged(
            noId,
            nodeOperator,
            stranger
        );
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
        vm.expectRevert(NOAddresses.SenderIsNotProposedAddress.selector);
        vm.prank(stranger);
        csm.confirmNodeOperatorManagerAddressChange(noId);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhenOtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectRevert(NOAddresses.SenderIsNotProposedAddress.selector);
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
        emit NOAddresses.NodeOperatorRewardAddressChangeProposed(
            noId,
            stranger
        );
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
        vm.expectRevert(NOAddresses.SenderIsNotRewardAddress.selector);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenAlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(NOAddresses.AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhenSameAddressProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(NOAddresses.SameAddress.selector);
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
        emit NOAddresses.NodeOperatorRewardAddressChanged(
            noId,
            nodeOperator,
            stranger
        );
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
        vm.expectRevert(NOAddresses.SenderIsNotProposedAddress.selector);
        vm.prank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhenOtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(NOAddresses.SenderIsNotProposedAddress.selector);
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
        emit NOAddresses.NodeOperatorManagerAddressChanged(
            noId,
            nodeOperator,
            stranger
        );
        vm.prank(stranger);
        csm.resetNodeOperatorManagerAddress(noId);

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, stranger);
        assertEq(no.rewardAddress, stranger);
    }

    function test_resetNodeOperatorManagerAddress_proposedManagerAddressIsReset()
        public
    {
        uint256 noId = createNodeOperator();
        address manager = nextAddress("MANAGER");

        vm.startPrank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, manager);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
        vm.stopPrank();

        vm.startPrank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);
        csm.resetNodeOperatorManagerAddress(noId);
        vm.stopPrank();

        vm.expectRevert(NOAddresses.SenderIsNotProposedAddress.selector);
        vm.prank(manager);
        csm.confirmNodeOperatorManagerAddressChange(noId);
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
        vm.expectRevert(NOAddresses.SenderIsNotRewardAddress.selector);
        vm.prank(stranger);
        csm.resetNodeOperatorManagerAddress(noId);
    }

    function test_resetNodeOperatorManagerAddress_RevertIfSameAddress() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(NOAddresses.SameAddress.selector);
        vm.prank(nodeOperator);
        csm.resetNodeOperatorManagerAddress(noId);
    }
}

contract CsmVetKeys is CSMCommon {
    function test_vetKeys_OnCreateOperator() public {
        uint256 noId = 0;
        uint256 keys = 7;

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, keys);
        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, keys);
        createNodeOperator(keys);

        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: keys });
        _assertQueueState(exp);
    }

    function test_vetKeys_OnUploadKeys() public {
        uint256 noId = createNodeOperator(2);

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 3);
        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, 1);
        uploadMoreKeys(noId, 1);

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 3);

        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 1 });
        _assertQueueState(exp);
    }

    function test_vetKeys_Counters() public {
        uint256 nonce = csm.getNonce();
        uint256 noId = createNodeOperator(1);

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(no.totalVettedValidators, 1);
        assertEq(summary.depositableValidatorsCount, 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_vetKeys_VettedBackViaRemoveKey() public {
        uint256 noId = createNodeOperator(7);
        unvetKeys({ noId: noId, to: 4 });

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 5); // 7 - 2 removed at the next step.

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 4, 2); // Remove keys 4 and 5.

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 5);
    }
}

contract CsmQueueOps is CSMCommon {
    uint256 internal constant LOOKUP_DEPTH = 150; // derived from maxDepositsPerBlock

    function _isQueueDirty(uint256 maxItems) internal returns (bool) {
        // XXX: Mimic a **eth_call** to avoid state changes.
        uint256 snapshot = vm.snapshot();
        uint256 toRemove = csm.cleanDepositQueue(maxItems);
        vm.revertTo(snapshot);
        return toRemove > 0;
    }

    function test_emptyQueueIsClean() public {
        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertFalse(isDirty, "queue should be clean");
    }

    function test_queueIsDirty_WhenHasBatchOfNonDepositableOperator() public {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        unvetKeys({ noId: noId, to: 0 }); // One of the ways to set `depositableValidatorsCount` to 0.

        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsDirty_WhenHasBatchWithNoDepositableKeys() public {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        uploadMoreKeys(noId, 1);
        unvetKeys({ noId: noId, to: 2 });
        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsClean_AfterCleanup() public {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        uploadMoreKeys(noId, 1);
        unvetKeys({ noId: noId, to: 2 });

        uint256 toRemove = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 1, "should remove 1 batch");

        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanup_emptyQueue() public {
        _assertQueueIsEmpty();

        uint256 toRemove = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 0, "queue should be clean");
    }

    function test_cleanup_WhenMultipleInvalidBatchesInRow() public {
        createNodeOperator({ keysCount: 3 });
        createNodeOperator({ keysCount: 5 });
        createNodeOperator({ keysCount: 1 });

        uploadMoreKeys(1, 2);

        unvetKeys({ noId: 1, to: 2 });
        unvetKeys({ noId: 2, to: 0 });

        uint256 toRemove;

        // Operator noId=1 has 1 dangling batch after unvetting.
        // Operator noId=2 is unvetted.
        toRemove = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 2, "should remove 2 batch");

        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({ nodeOperatorId: 0, count: 3 });
        exp[1] = BatchInfo({ nodeOperatorId: 1, count: 5 });
        _assertQueueState(exp);

        toRemove = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 0, "queue should be clean");
    }

    function test_cleanup_WhenAllBatchesInvalid() public {
        createNodeOperator({ keysCount: 2 });
        createNodeOperator({ keysCount: 2 });
        unvetKeys({ noId: 0, to: 0 });
        unvetKeys({ noId: 1, to: 0 });

        uint256 toRemove = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 2, "should remove all batches");

        _assertQueueIsEmpty();
    }

    function test_normalizeQueue_NothingToDo() public {
        // `normalizeQueue` will be called on creating a node operator and uploading a key.
        uint256 noId = createNodeOperator();

        vm.recordLogs();
        vm.prank(nodeOperator);
        csm.normalizeQueue(noId);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }

    function test_normalizeQueue_OnSkippedKeys_WhenStuckKeys() public {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(3, "");
        setStuck(noId, 1);
        csm.cleanDepositQueue(1);
        setStuck(noId, 0);

        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, 4);

        vm.prank(nodeOperator);
        csm.normalizeQueue(noId);
    }

    function test_queueNormalized_WhenSkippedKeysAndTargetValidatorsLimitRaised()
        public
    {
        uint256 noId = createNodeOperator(7);
        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            isTargetLimitActive: true,
            targetLimit: 0
        });
        csm.cleanDepositQueue(1);

        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, 7);

        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            isTargetLimitActive: true,
            targetLimit: 7
        });
    }

    function test_queueNormalized_WhenWithdrawalChangesDepositable() public {
        uint256 noId = createNodeOperator(7);
        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            isTargetLimitActive: true,
            targetLimit: 2
        });
        csm.obtainDepositData(2, "");
        csm.cleanDepositQueue(1);

        vm.expectEmit(true, true, true, true, address(csm));
        emit BatchEnqueued(noId, 1);
        csm.submitWithdrawal(noId, 0, csm.DEPOSIT_SIZE());
    }
}

contract CsmUnvetKeys is CSMCommon {
    function test_unvetKeys_counters() public {
        uint256 noId = createNodeOperator(3);
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noId, 1);
        unvetKeys({ noId: noId, to: 1 });

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(csm.getNonce(), nonce + 1);
        assertEq(no.totalVettedValidators, 1);
        assertEq(summary.depositableValidatorsCount, 1);
    }

    function test_unvetKeys_MultipleOperators() public {
        uint256 noIdOne = createNodeOperator(3);
        uint256 noIdTwo = createNodeOperator(7);
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit VettedSigningKeysCountChanged(noIdOne, 2);
        emit VettedSigningKeysCountChanged(noIdTwo, 3);
        csm.decreaseOperatorVettedKeys(
            UintArr(noIdOne, noIdTwo),
            UintArr(2, 3)
        );

        assertEq(csm.getNonce(), nonce + 1);
        CSModule.NodeOperatorInfo memory no;
        no = csm.getNodeOperator(noIdOne);
        assertEq(no.totalVettedValidators, 2);
        no = csm.getNodeOperator(noIdTwo);
        assertEq(no.totalVettedValidators, 3);
    }

    function test_unvetKeys_RevertIfNodeOperatorDoesntExist() public {
        createNodeOperator(); // Make sure there is at least one node operator.
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.decreaseOperatorVettedKeys(UintArr(1), UintArr(0));
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

    function test_viewNonExistingKeys() public {
        bytes memory keys = randomBytes(48);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1,
            keys: keys,
            signatures: randomBytes(96)
        });

        vm.expectRevert(SigningKeysInvalidOffset.selector);
        csm.getNodeOperatorSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
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

    function test_removeKeys_nonceChanged() public {
        bytes memory keys = bytes.concat(key0);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1,
            keys: keys,
            signatures: randomBytes(96)
        });

        uint256 nonce = csm.getNonce();
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
        assertEq(csm.getNonce(), nonce + 1);
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

    function testRemoveKeys_Charge() public {
        uint256 noId = createNodeOperator(3);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                csm.removalCharge() * 2
            ),
            1
        );
        vm.prank(nodeOperator);
        csm.removeKeys(noId, 1, 2);
    }
}

contract CsmGetNodeOperatorSummary is CSMCommon {
    // TODO add more tests here. There might be fuzz tests

    function test_getNodeOperatorSummary_defaultValues() public {
        uint256 noId = createNodeOperator(1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.isTargetLimitActive, false);
        assertEq(summary.targetValidatorsCount, 0); // ?
        assertEq(summary.stuckValidatorsCount, 0);
        assertEq(summary.refundedValidatorsCount, 0);
        assertEq(summary.stuckPenaltyEndTimestamp, 0);
        assertEq(summary.totalExitedValidators, 0);
        assertEq(summary.totalDepositedValidators, 0);
        assertEq(summary.depositableValidatorsCount, 1);
    }

    function test_getNodeOperatorSummary_depositedKey() public {
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(1, "");

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.depositableValidatorsCount, 1);
        assertEq(summary.totalDepositedValidators, 1);
    }

    function test_getNodeOperatorSummary_targetLimit() public {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, true, 1);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);

        summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetValidatorsCount, 1);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.depositableValidatorsCount, 1);
    }

    function test_getNodeOperatorSummary_targetLimitEqualToDepositedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);
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

        csm.updateTargetValidatorsLimits(noId, true, 2);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.targetValidatorsCount, 2);
        assertEq(summary.depositableValidatorsCount, 2);
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 3); // Should NOT be unvetted.
    }

    function test_getNodeOperatorSummary_targetLimitHigherThanVettedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);
        csm.updateTargetValidatorsLimits(noId, true, 9);
        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertTrue(summary.isTargetLimitActive);
        assertEq(summary.targetValidatorsCount, 9);
        assertEq(summary.depositableValidatorsCount, 3);
    }
}

contract CsmUpdateTargetValidatorsLimits is CSMCommon {
    function test_updateTargetValidatorsLimits() public {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit TargetValidatorsCountChanged(noId, true, 1);
        csm.updateTargetValidatorsLimits(noId, true, 1);
        assertEq(csm.getNonce(), nonce + 1);
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

    function test_updateTargetValidatorsLimits_NoUnvetKeysWhenLimitDisabled()
        public
    {
        uint256 noId = createNodeOperator(2);
        csm.updateTargetValidatorsLimits(noId, true, 1);
        csm.updateTargetValidatorsLimits(noId, false, 1);
        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 2);
    }

    function test_updateTargetValidatorsLimits_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(NodeOperatorDoesNotExist.selector);
        csm.updateTargetValidatorsLimits(0, true, 1);
    }
}

contract CsmUpdateStuckValidatorsCount is CSMCommon {
    function test_updateStuckValidatorsCount_NonZero() public {
        uint256 noId = createNodeOperator(3);
        csm.obtainDepositData(1, "");
        uint256 nonce = csm.getNonce();

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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_updateStuckValidatorsCount_Unstuck() public {
        uint256 noId = createNodeOperator();
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

    function test_updateStuckValidatorsCount_RevertWhenCountMoreThanDeposited()
        public
    {
        createNodeOperator(3);
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
        createNodeOperator();
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
        csm.obtainDepositData(1, "");
        uint256 nonce = csm.getNonce();

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

        assertEq(csm.getNonce(), nonce + 1);
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
        createNodeOperator(1);

        vm.expectRevert(ExitedKeysHigherThanTotalDeposited.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
    }

    function test_updateExitedValidatorsCount_RevertIfExitedKeysDecrease()
        public
    {
        createNodeOperator(1);
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
        createNodeOperator(1);
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

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        csm.penalize(noId, 1 ether);

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
    }

    function test_penalize_ResetBenefitsIfNoBond() public {
        uint256 noId = createNodeOperator();
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.penalize(noId, BOND_SIZE);
    }

    function test_penalize_RevertWhenExpired() public {
        uint256 noId = createNodeOperator();
        vm.warp(block.timestamp + 60 * 60 * 24 * 365 + 1);
        vm.expectRevert(Expired.selector);
        csm.penalize(noId, 1 ether);
    }
}

contract CsmReportELRewardsStealingPenalty is CSMCommon {
    function test_reportELRewardsStealingPenalty_HappyPath() public {
        uint256 noId = createNodeOperator();

        vm.expectEmit(true, true, true, true, address(csm));
        emit ELRewardsStealingPenaltyReported(noId, 100, BOND_SIZE / 2);
        csm.reportELRewardsStealingPenalty(noId, 100, BOND_SIZE / 2);

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(lockedBond, BOND_SIZE / 2 + csm.EL_REWARDS_STEALING_FINE());

        CSModule.NodeOperatorInfo memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedValidators, 1);
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

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }

    function test_settleELRewardsStealingPenalty_noLocked() public {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;

        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

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

        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
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
        csm.obtainDepositData(1, "");
        uint256 nonce = csm.getNonce();

        csm.submitWithdrawal(noId, keyIndex, 1 ether);
        assertEq(csm.getNonce(), nonce + 1);
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
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.submitInitialSlashing(noId, 0);
    }

    function test_submitInitialSlashing_differentKeys() public {
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(2, "");

        vm.expectEmit(true, true, true, true, address(csm));
        emit InitialSlashingSubmitted(noId, 0);
        csm.submitInitialSlashing(noId, 0);

        vm.expectEmit(true, true, true, true, address(csm));
        emit InitialSlashingSubmitted(noId, 1);
        csm.submitInitialSlashing(noId, 1);
    }

    function test_submitInitialSlashing_outOfBond() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
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
        csm.obtainDepositData(1, "");

        csm.submitInitialSlashing(noId, 0);
        vm.expectRevert(AlreadySubmitted.selector);
        csm.submitInitialSlashing(noId, 0);
    }
}

contract CsmGetStakingModuleSummary is CSMCommon {
    function test_getStakingModuleSummary_depositableValidators() public {
        uint256 first = createNodeOperator(1);
        uint256 second = createNodeOperator(2);
        StakingModuleSummary memory summary = getStakingModuleSummary();
        NodeOperatorSummary memory firstSummary = getNodeOperatorSummary(first);
        NodeOperatorSummary memory secondSummary = getNodeOperatorSummary(
            second
        );
        assertEq(firstSummary.depositableValidatorsCount, 1);
        assertEq(secondSummary.depositableValidatorsCount, 2);
        assertEq(summary.depositableValidatorsCount, 3);
    }

    function test_getStakingModuleSummary_depositedValidators() public {
        uint256 first = createNodeOperator(1);
        uint256 second = createNodeOperator(2);
        StakingModuleSummary memory summary = getStakingModuleSummary();
        assertEq(summary.totalDepositedValidators, 0);

        csm.obtainDepositData(3, "");

        summary = getStakingModuleSummary();
        NodeOperatorSummary memory firstSummary = getNodeOperatorSummary(first);
        NodeOperatorSummary memory secondSummary = getNodeOperatorSummary(
            second
        );
        assertEq(firstSummary.totalDepositedValidators, 1);
        assertEq(secondSummary.totalDepositedValidators, 2);
        assertEq(summary.totalDepositedValidators, 3);
    }

    function test_getStakingModuleSummary_exitedValidators() public {
        uint256 first = createNodeOperator(2);
        uint256 second = createNodeOperator(2);
        csm.obtainDepositData(4, "");
        StakingModuleSummary memory summary = getStakingModuleSummary();
        assertEq(summary.totalExitedValidators, 0);

        csm.updateExitedValidatorsCount(
            bytes.concat(
                bytes8(0x0000000000000000),
                bytes8(0x0000000000000001)
            ),
            bytes.concat(
                bytes16(0x00000000000000000000000000000001),
                bytes16(0x00000000000000000000000000000002)
            )
        );

        summary = getStakingModuleSummary();
        NodeOperatorSummary memory firstSummary = getNodeOperatorSummary(first);
        NodeOperatorSummary memory secondSummary = getNodeOperatorSummary(
            second
        );
        assertEq(firstSummary.totalExitedValidators, 1);
        assertEq(secondSummary.totalExitedValidators, 2);
        assertEq(summary.totalExitedValidators, 3);
    }
}

contract CSMAccessControl is CSMCommonNoRoles {
    function test_adminRole() public {
        CSModule csm = new CSModule("csm", 0, actor);
        bytes32 role = csm.SET_ACCOUNTING_ROLE();
        vm.prank(actor);
        csm.grantRole(role, stranger);
        assertTrue(csm.hasRole(role, stranger));

        vm.prank(actor);
        csm.revokeRole(role, stranger);
        assertFalse(csm.hasRole(role, stranger));
    }

    function test_adminRole_revert() public {
        CSModule csm = new CSModule("csm", 0, actor);
        bytes32 role = csm.SET_ACCOUNTING_ROLE();
        bytes32 adminRole = csm.DEFAULT_ADMIN_ROLE();

        vm.startPrank(stranger);
        expectRoleRevert(stranger, adminRole);
        csm.grantRole(role, stranger);
    }

    function test_setAccountingRole() public {
        CSModule csm = new CSModule("csm", 0, admin);
        bytes32 role = csm.SET_ACCOUNTING_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.setAccounting(nextAddress());
    }

    function test_setAccountingRole_revert() public {
        bytes32 role = csm.SET_ACCOUNTING_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.setAccounting(nextAddress());
    }

    function test_setRemovalChargeRole() public {
        bytes32 role = csm.SET_REMOVAL_CHARGE_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.setRemovalCharge(0.1 ether);
    }

    function test_setRemovalChargeRole_revert() public {
        bytes32 role = csm.SET_REMOVAL_CHARGE_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.setRemovalCharge(0.1 ether);
    }

    function test_stakingRouterRole_onRewardsMinted() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.onRewardsMinted(0);
    }

    function test_stakingRouterRole_onRewardsMinted_revert() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.onRewardsMinted(0);
    }

    function test_stakingRouterRole_updateStuckValidatorsCount() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.updateStuckValidatorsCount("", "");
    }

    function test_stakingRouterRole_updateStuckValidatorsCount_revert() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.updateStuckValidatorsCount("", "");
    }

    function test_stakingRouterRole_updateExitedValidatorsCount() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.updateExitedValidatorsCount("", "");
    }

    function test_stakingRouterRole_updateExitedValidatorsCount_revert()
        public
    {
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.updateExitedValidatorsCount("", "");
    }

    function test_stakingRouterRole_updateRefundedValidatorsCount() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.updateRefundedValidatorsCount(noId, 0);
    }

    function test_stakingRouterRole_updateRefundedValidatorsCount_revert()
        public
    {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.updateRefundedValidatorsCount(noId, 0);
    }

    function test_stakingRouterRole_updateTargetValidatorsLimits() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.updateTargetValidatorsLimits(noId, false, 0);
    }

    function test_stakingRouterRole_updateTargetValidatorsLimits_revert()
        public
    {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.updateTargetValidatorsLimits(noId, false, 0);
    }

    function test_stakingRouterRole_onExitedAndStuckValidatorsCountsUpdated()
        public
    {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.onExitedAndStuckValidatorsCountsUpdated();
    }

    function test_stakingRouterRole_onExitedAndStuckValidatorsCountsUpdated_revert()
        public
    {
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.onExitedAndStuckValidatorsCountsUpdated();
    }

    function test_stakingRouterRole_onWithdrawalCredentialsChanged() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.onWithdrawalCredentialsChanged();
    }

    function test_stakingRouterRole_onWithdrawalCredentialsChanged_revert()
        public
    {
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.onWithdrawalCredentialsChanged();
    }

    function test_stakingRouterRole_obtainDepositData() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.obtainDepositData(0, "");
    }

    function test_stakingRouterRole_obtainDepositData_revert() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.obtainDepositData(0, "");
    }

    function test_stakingRouterRole_unsafeUpdateValidatorsCountRole() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.unsafeUpdateValidatorsCount(noId, 0, 0);
    }

    function test_stakingRouterRole_unsafeUpdateValidatorsCountRole_revert()
        public
    {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.unsafeUpdateValidatorsCount(noId, 0, 0);
    }

    function test_stakingRouterRole_unvetKeys() public {
        createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.decreaseOperatorVettedKeys(UintArr(), UintArr());
    }

    function test_stakingRouterRole_unvetKeys_revert() public {
        createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.decreaseOperatorVettedKeys(UintArr(), UintArr());
    }

    function test_reportELRewardsStealingPenaltyRole() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.reportELRewardsStealingPenalty(noId, 0, 1 ether);
    }

    function test_reportELRewardsStealingPenaltyRole_revert() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.reportELRewardsStealingPenalty(noId, 0, 1 ether);
    }

    function test_settleELRewardsStealingPenaltyRole() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.settleELRewardsStealingPenalty(UintArr(noId));
    }

    function test_settleELRewardsStealingPenaltyRole_revert() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.settleELRewardsStealingPenalty(UintArr(noId));
    }

    function test_penalizeRole() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.PENALIZE_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.penalize(noId, 1 ether);
    }

    function test_penalizeRole_revert() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.PENALIZE_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.penalize(noId, 1 ether);
    }

    function test_withdrawalSubmitterRole() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.WITHDRAWAL_SUBMITTER_ROLE();

        vm.startPrank(admin);
        csm.grantRole(role, actor);
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), admin);
        csm.obtainDepositData(1, "");
        vm.stopPrank();

        vm.prank(actor);
        csm.submitWithdrawal(noId, 0, 1 ether);
    }

    function test_withdrawalSubmitterRole_revert() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.WITHDRAWAL_SUBMITTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.submitWithdrawal(noId, 0, 1 ether);
    }

    function test_setPublicReleaseTimestampRole() public {
        bytes32 role = csm.SET_PUBLIC_RELEASE_TIMESTAMP_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.setPublicReleaseTimestamp(0);
    }

    function test_setPublicReleaseTimestampRole_revert() public {
        bytes32 role = csm.SET_PUBLIC_RELEASE_TIMESTAMP_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.setPublicReleaseTimestamp(0);
    }

    function test_setEarlyAdoptionRole() public {
        bytes32 role = csm.SET_EARLY_ADOPTION_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.setEarlyAdoption(address(0));
    }

    function test_setEarlyAdoptionRole_revert() public {
        bytes32 role = csm.SET_EARLY_ADOPTION_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.setEarlyAdoption(address(0));
    }
}

contract CSMPublicReleaseTimestamp is CSMCommon {
    function test_setPublicReleaseTimestamp() public {
        uint256 timestamp = block.timestamp + 30 days;

        vm.expectEmit(true, true, true, true, address(csm));
        emit PublicReleaseTimestampSet(timestamp);
        csm.setPublicReleaseTimestamp(timestamp);

        assertEq(csm.publicReleaseTimestamp(), timestamp);
    }

    function test_addNodeOperatorETH_RevertWhenNoPublicReleaseYet() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 timestamp = block.timestamp + 30 days;
        csm.setPublicReleaseTimestamp(timestamp);

        vm.expectRevert(NotAllowedToJoinYet.selector);
        csm.addNodeOperatorETH{ value: keysCount * BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            new bytes32[](0)
        );
    }

    function test_addNodeOperatorETH_WhenPublicRelease() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 timestamp = block.timestamp + 30 days;
        csm.setPublicReleaseTimestamp(timestamp);

        vm.warp(timestamp + 1);
        csm.addNodeOperatorETH{ value: keysCount * BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            new bytes32[](0)
        );
    }
}

contract CSMEarlyAdoptionTest is CSMCommon {
    function initEarlyAdoption()
        private
        returns (MerkleTree merkleTree, CSEarlyAdoption earlyAdoption)
    {
        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));

        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE / 2;

        uint256 curveId = accounting.addBondCurve(curve);
        earlyAdoption = new CSEarlyAdoption(
            merkleTree.root(),
            curveId,
            address(csm)
        );
    }

    function test_setEarlyAdoption() public {
        (, CSEarlyAdoption earlyAdoption) = initEarlyAdoption();
        csm.setEarlyAdoption(address(earlyAdoption));
        assertEq(address(csm.earlyAdoption()), address(earlyAdoption));
    }

    function test_setEarlyAdoption_revertIfAlreadySet() public {
        (, CSEarlyAdoption earlyAdoption) = initEarlyAdoption();
        csm.setEarlyAdoption(address(earlyAdoption));
        address newEarlyAdoption = nextAddress();

        vm.expectRevert(AlreadyInitialized.selector);
        csm.setEarlyAdoption(newEarlyAdoption);
    }

    function test_addNodeOperator_earlyAdoptionProof() public {
        (
            MerkleTree merkleTree,
            CSEarlyAdoption earlyAdoption
        ) = initEarlyAdoption();
        csm.setEarlyAdoption(address(earlyAdoption));
        csm.setPublicReleaseTimestamp(block.timestamp + 30 days);
        bytes32[] memory proof = merkleTree.getProof(0);

        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        vm.deal(nodeOperator, BOND_SIZE / 2);
        vm.prank(nodeOperator);
        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorAdded(0, nodeOperator);
        csm.addNodeOperatorETH{ value: (BOND_SIZE / 2) * keysCount }(
            keysCount,
            keys,
            signatures,
            proof
        );
        CSAccounting.BondCurve memory curve = accounting.getBondCurve(0);
        assertEq(curve.points[0], BOND_SIZE / 2);
    }

    function test_addNodeOperator_WhenPublicReleaseWithProof() public {
        (
            MerkleTree merkleTree,
            CSEarlyAdoption earlyAdoption
        ) = initEarlyAdoption();
        csm.setEarlyAdoption(address(earlyAdoption));

        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 timestamp = block.timestamp + 30 days;
        csm.setPublicReleaseTimestamp(timestamp);
        vm.warp(timestamp + 1);

        bytes32[] memory proof = merkleTree.getProof(0);
        vm.deal(nodeOperator, BOND_SIZE / 2);
        vm.prank(nodeOperator);
        vm.expectEmit(true, true, true, true, address(csm));
        emit NodeOperatorAdded(0, nodeOperator);
        csm.addNodeOperatorETH{ value: (BOND_SIZE / 2) * keysCount }(
            keysCount,
            keys,
            signatures,
            proof
        );
        CSAccounting.BondCurve memory curve = accounting.getBondCurve(0);
        assertEq(curve.points[0], BOND_SIZE / 2);
    }

    function test_addNodeOperator_RevertWhenMoreThanMaxSigningKeysLimit()
        public
    {
        (
            MerkleTree merkleTree,
            CSEarlyAdoption earlyAdoption
        ) = initEarlyAdoption();
        csm.setEarlyAdoption(address(earlyAdoption));
        csm.setPublicReleaseTimestamp(block.timestamp + 30 days);
        bytes32[] memory proof = merkleTree.getProof(0);

        uint16 keysCount = csm.MAX_SIGNING_KEYS_BEFORE_PUBLIC_RELEASE() + 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        vm.deal(nodeOperator, (BOND_SIZE / 2) * keysCount);
        vm.prank(nodeOperator);
        vm.expectRevert(MaxSigningKeysCountExceeded.selector);
        csm.addNodeOperatorETH{ value: (BOND_SIZE / 2) * keysCount }(
            keysCount,
            keys,
            signatures,
            proof
        );
    }
}

contract CSMDepositableValidatorsCount is CSMCommon {
    function test_depositableValidatorsCountChanges_OnDeposit() public {
        uint256 noId = createNodeOperator(7);
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 7);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 7);
        csm.obtainDepositData(3, "");
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 4);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 4);
    }

    function test_depositableValidatorsCountChanges_OnStuck() public {
        uint256 noId = createNodeOperator(7);
        createNodeOperator(2);
        csm.obtainDepositData(4, "");
        setStuck(noId, 2);
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 0);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 2);
        setStuck(noId, 0);
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 5);
    }

    function test_depositableValidatorsCountChanges_OnUnsafeUpdateValidators()
        public
    {
        // XXX: Underlying method is not implemented yet.
        vm.skip(true);
    }

    function test_depositableValidatorsCountChanges_OnUnvetKeys() public {
        uint256 noId = createNodeOperator(7);
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 7);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(3));
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 3);
    }

    function test_depositableValidatorsCountChanges_OnInitialSlashing() public {
        // 1 key becomes unbonded till withdrawal.
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(1, "");
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 1);
        csm.submitInitialSlashing(noId, 0); // The first key was slashed.
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 0);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 0);
    }

    function test_depositableValidatorsCountChanges_OnPenalize() public {
        // Even small penalty will make a key unbonded (keep in mind 10 wei leeway).
        uint256 noId = createNodeOperator(7);
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 7);
        csm.penalize(noId, BOND_SIZE * 3); // Penalty to unbond 3 validators.
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 4);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 4);
    }

    function test_depositableValidatorsCountChanges_OnWithdrawal() public {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3);
        csm.penalize(noId, BOND_SIZE * 3); // Penalty to unbond 3 validators.
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 0);
        csm.submitWithdrawal(noId, 0, csm.DEPOSIT_SIZE());
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 1);
        csm.submitWithdrawal(noId, 1, csm.DEPOSIT_SIZE());
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 2);
        csm.submitWithdrawal(noId, 2, csm.DEPOSIT_SIZE() - BOND_SIZE); // Large CL balance drop, that doesn't change the unbonded count.
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 2);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 2);
    }

    function test_depositableValidatorsCountChanges_OnReportStealing() public {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3);
        csm.reportELRewardsStealingPenalty(noId, 0, (BOND_SIZE * 3) / 2); // Lock bond to unbond 2 validators.
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 1);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 1);
    }

    function test_depositableValidatorsCountChanges_OnReleaseStealingPenalty()
        public
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3);
        csm.reportELRewardsStealingPenalty(noId, 0, BOND_SIZE); // Lock bond to unbond 2 validators (there's stealing fine).
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 1);
        accounting.releaseLockedBondETH(
            noId,
            accounting.getLockedBondInfo(noId).amount
        );
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3); // Stealing fine is applied so
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 3);
    }

    function test_depositableValidatorsCountChanges_OnRemoveUnvetted() public {
        uint256 noId = createNodeOperator(7);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(3));
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 3);
        vm.prank(nodeOperator);
        csm.removeKeys(noId, 3, 1); // Removal charge is applied, hence one key is unbonded.
        assertEq(getNodeOperatorSummary(noId).depositableValidatorsCount, 6);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 6);
    }
}
