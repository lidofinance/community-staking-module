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
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { AssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { IWithdrawalQueue } from "../src/interfaces/IWithdrawalQueue.sol";
import { Batch } from "../src/lib/QueueLib.sol";
import { SigningKeys } from "../src/lib/SigningKeys.sol";

abstract contract CSMFixtures is Test, Fixtures, Utilities {
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
    CSEarlyAdoption public earlyAdoption;
    Stub public feeDistributor;

    address internal admin;
    address internal stranger;
    address internal nodeOperator;
    address internal testChargeRecipient;

    MerkleTree internal merkleTree;

    struct NodeOperatorSummary {
        uint8 targetLimitMode;
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
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
        return csm.getNodeOperatorsCount() - 1;
    }

    function uploadMoreKeys(uint256 noId, uint256 keysCount) internal {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getRequiredBondForNextKeys(noId, keysCount);
        vm.deal(nodeOperator, amount);
        vm.prank(nodeOperator);
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
            uint8 targetLimitMode,
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
                targetLimitMode: targetLimitMode,
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

    // amount can not be lower than EL_REWARDS_STEALING_FINE
    function penalize(uint256 noId, uint256 amount) public {
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount - csm.EL_REWARDS_STEALING_FINE()
        );
        csm.settleELRewardsStealingPenalty(UintArr(noId));
    }
}

contract CSMCommonNoPublicRelease is CSMFixtures {
    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        feeDistributor = new Stub();

        csm = new CSModule({
            moduleType: "community-staking-module",
            elStealingFine: 0.1 ether,
            maxKeysPerOperatorEA: 10,
            lidoLocator: address(locator)
        });
        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE;
        accounting = new CSAccounting(address(locator), address(csm));
        accounting.initialize(
            curve,
            admin,
            address(feeDistributor),
            8 weeks,
            testChargeRecipient
        );

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));

        uint256[] memory earlyAdoptionCurve = new uint256[](1);
        earlyAdoptionCurve[0] = BOND_SIZE / 2;

        vm.startPrank(admin);
        accounting.grantRole(accounting.ADD_BOND_CURVE_ROLE(), address(this));
        vm.stopPrank();

        uint256 curveId = accounting.addBondCurve(earlyAdoptionCurve);
        earlyAdoption = new CSEarlyAdoption(
            merkleTree.root(),
            curveId,
            address(csm)
        );

        csm.initialize({
            _accounting: address(accounting),
            _earlyAdoption: address(earlyAdoption),
            verifier: address(this),
            admin: admin
        });

        vm.startPrank(admin);
        csm.grantRole(csm.PAUSE_ROLE(), address(this));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.MODULE_MANAGER_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(this));
        csm.grantRole(
            csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        csm.grantRole(
            csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        csm.grantRole(csm.VERIFIER_ROLE(), address(this));
        accounting.grantRole(accounting.ADD_BOND_CURVE_ROLE(), address(this));
        vm.stopPrank();

        csm.setKeyRemovalCharge(0.05 ether);
        csm.resume();
    }
}

contract CSMCommon is CSMCommonNoPublicRelease {
    function setUp() public virtual override {
        super.setUp();
        csm.activatePublicRelease();
    }
}

contract CSMCommonNoRoles is CSMFixtures {
    address internal actor;

    function setUp() public {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        actor = nextAddress("ACTOR");
        testChargeRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, ) = initLido();

        feeDistributor = new Stub();
        csm = new CSModule({
            moduleType: "community-staking-module",
            elStealingFine: 0.1 ether,
            maxKeysPerOperatorEA: 10,
            lidoLocator: address(locator)
        });

        uint256[] memory curve = new uint256[](1);
        curve[0] = BOND_SIZE;
        accounting = new CSAccounting(address(locator), address(csm));
        accounting.initialize(
            curve,
            admin,
            address(feeDistributor),
            8 weeks,
            testChargeRecipient
        );

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));

        uint256[] memory earlyAdoptionCurve = new uint256[](1);
        earlyAdoptionCurve[0] = BOND_SIZE / 2;

        vm.startPrank(admin);
        accounting.grantRole(accounting.ADD_BOND_CURVE_ROLE(), address(this));
        vm.stopPrank();

        uint256 curveId = accounting.addBondCurve(earlyAdoptionCurve);
        earlyAdoption = new CSEarlyAdoption(
            merkleTree.root(),
            curveId,
            address(csm)
        );

        csm.initialize({
            _accounting: address(accounting),
            _earlyAdoption: address(earlyAdoption),
            verifier: address(this),
            admin: admin
        });

        vm.startPrank(admin);
        csm.grantRole(csm.MODULE_MANAGER_ROLE(), address(this));
        csm.grantRole(csm.RESUME_ROLE(), admin);
        csm.resume();
        vm.stopPrank();
    }
}

contract CsmInitialize is CSMCommon {
    function test_constructor() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            elStealingFine: 0.1 ether,
            maxKeysPerOperatorEA: 10,
            lidoLocator: address(locator)
        });
        assertEq(csm.getType(), "community-staking-module");
        assertEq(csm.EL_REWARDS_STEALING_FINE(), 0.1 ether);
        assertEq(csm.MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE(), 10);
        assertEq(address(csm.LIDO_LOCATOR()), address(locator));
    }

    function test_initialize() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            elStealingFine: 0.1 ether,
            maxKeysPerOperatorEA: 10,
            lidoLocator: address(locator)
        });
        csm.initialize({
            _accounting: address(accounting),
            _earlyAdoption: address(1337),
            verifier: address(this),
            admin: address(this)
        });
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(csm.earlyAdoption()), address(1337));
        assertTrue(csm.isPaused());
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
        csm.addNodeOperatorETH(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
    }

    function test_addNodeOperatorStETH_RevertWhen_Paused() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addNodeOperatorStETH(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );
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
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
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
        csm.addValidatorKeysStETH(
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

    function test_addValidatorKeysWstETH_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysWstETH(
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

contract CSMAddNodeOperatorETH is CSMCommon, PermitTokenBase {
    function test_AddNodeOperatorETH() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE);
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 1);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorETH_withCustomAddresses() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE);

        address manager = address(154);
        address reward = address(42);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.NodeOperatorAdded(0, manager, reward);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            manager,
            reward,
            new bytes32[](0),
            address(0)
        );

        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, reward);
    }

    function test_AddNodeOperatorETH_withReferrer() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE);

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.ReferrerSet(0, address(154));
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorETH_RevertWhen_InvalidAmount() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE - 1);

        vm.expectRevert(CSModule.InvalidAmount.selector);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE - 1 ether }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(154)
        );
    }
}

contract CSMAddNodeOperatorStETH is CSMCommon, PermitTokenBase {
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
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 1);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(
            1,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorStETH_withCustomAddresses() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        address manager = address(154);
        address reward = address(42);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.NodeOperatorAdded(0, manager, reward);
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(
            1,
            keys,
            signatures,
            manager,
            reward,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );

        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, reward);
    }

    function test_AddNodeOperatorStETH_withReferrer() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.ReferrerSet(0, address(154));
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(
            1,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorStETH_withPermit() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(stETH));
            emit Approval(nodeOperator, address(accounting), BOND_SIZE);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 1);
        }

        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(
            1,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }
}

contract CSMAddNodeOperatorWstETH is CSMCommon, PermitTokenBase {
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
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 1);
        }

        csm.addNodeOperatorWstETH(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddNodeOperatorWstETH_withCustomAddresses() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        wstETH.wrap(BOND_SIZE + 1 wei);

        address manager = address(154);
        address reward = address(42);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.NodeOperatorAdded(0, manager, reward);
        csm.addNodeOperatorWstETH(
            keysCount,
            keys,
            signatures,
            manager,
            reward,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );

        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, reward);
    }

    function test_AddNodeOperatorWstETH_withReferrer() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        wstETH.wrap(BOND_SIZE + 1 wei);

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.ReferrerSet(0, address(154));
        }

        csm.addNodeOperatorWstETH(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorWstETH_withPermit() public {
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
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
            vm.expectEmit(true, true, true, true, address(wstETH));
            emit Approval(nodeOperator, address(accounting), wstETHAmount);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 1);
        }

        csm.addNodeOperatorWstETH(
            1,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: wstETHAmount,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
    }
}

contract CSMAddValidatorKeys is CSMCommon, PermitTokenBase {
    function test_AddValidatorKeysWstETH() public {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 nonce = csm.getNonce();
        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysWstETH(
            noId,
            1,
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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysWstETH_withPermit() public {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        uint256 wstETHAmount = wstETH.wrap(toWrap);
        uint256 nonce = csm.getNonce();
        {
            vm.expectEmit(true, true, true, true, address(wstETH));
            emit Approval(nodeOperator, address(accounting), wstETHAmount);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysWstETH(
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

    function test_AddValidatorKeysStETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysStETH(
            noId,
            1,
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
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysStETH_withPermit() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        vm.prank(nodeOperator);
        stETH.submit{ value: required }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(true, true, true, true, address(stETH));
            emit Approval(nodeOperator, address(accounting), required);
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 2);
        }
        vm.prank(nodeOperator);
        csm.addValidatorKeysStETH(
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

    function test_AddValidatorKeysETH() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        uint256 nonce = csm.getNonce();

        vm.prank(nodeOperator);
        {
            vm.expectEmit(true, true, true, true, address(csm));
            emit CSModule.TotalSigningKeysCountChanged(0, 2);
        }
        csm.addValidatorKeysETH{ value: required }(noId, 1, keys, signatures);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysETH_RevertWhen_InvalidAmount() public {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required - 1 ether);

        vm.expectRevert(CSModule.InvalidAmount.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required - 1 ether }(
            noId,
            1,
            keys,
            signatures
        );
    }
}

contract CSMAddNodeOperatorNegative is CSMCommon, PermitTokenBase {
    function test_addNodeOperatorETH_RevertWhen_NoKeys() public {
        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addNodeOperatorETH(
            0,
            new bytes(0),
            new bytes(0),
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
    }

    function test_AddNodeOperatorETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint16 keysCount = 1;
        (bytes memory keys, ) = keysSignatures(keysCount);
        vm.deal(nodeOperator, BOND_SIZE);

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            keysCount,
            keys,
            new bytes(0),
            address(0),
            address(0),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorETH_RevertWhen_ZeroKey() public {
        uint16 keysCount = 1;
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);
        vm.deal(nodeOperator, BOND_SIZE);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_NoKeys() public {
        uint256 noId = createNodeOperator();
        uint256 required = accounting.getRequiredBondForNextKeys(0, 0);
        vm.deal(nodeOperator, required);
        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            noId,
            0,
            new bytes(0),
            new bytes(0)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint16 keysCount = 1;
        uint256 noId = createNodeOperator();
        (bytes memory keys, ) = keysSignatures(keysCount);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            noId,
            keysCount,
            keys,
            new bytes(0)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_ZeroKey() public {
        uint16 keysCount = 1;
        uint256 noId = createNodeOperator();
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            noId,
            keysCount,
            keys,
            signatures
        );
    }

    function test_AddNodeOperatorStETH_RevertWhen_NoKeys() public {
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addNodeOperatorStETH(
            0,
            new bytes(0),
            new bytes(0),
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorStETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint16 keysCount = 1;
        (bytes memory keys, ) = keysSignatures(keysCount);
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(
            keysCount,
            keys,
            new bytes(0),
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorStETH_RevertWhen_ZeroKey() public {
        uint16 keysCount = 1;
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        vm.prank(nodeOperator);
        csm.addNodeOperatorStETH(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddValidatorKeysStETH_RevertWhen_NoKeys() public {
        uint256 noId = createNodeOperator();

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addValidatorKeysStETH(
            noId,
            0,
            new bytes(0),
            new bytes(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysStETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint16 keysCount = 1;
        uint256 noId = createNodeOperator();
        (bytes memory keys, ) = keysSignatures(keysCount);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        csm.addValidatorKeysStETH(
            noId,
            keysCount,
            keys,
            new bytes(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysStETH_RevertWhen_ZeroKey() public {
        uint16 keysCount = 1;
        uint256 noId = createNodeOperator();
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        csm.addValidatorKeysStETH(
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

    function test_AddNodeOperatorWstETH_RevertWhen_NoKeys() public {
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        wstETH.wrap(BOND_SIZE + 1 wei);

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addNodeOperatorWstETH(
            0,
            new bytes(0),
            new bytes(0),
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorWstETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint16 keysCount = 1;
        (bytes memory keys, ) = keysSignatures(keysCount);
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        wstETH.wrap(BOND_SIZE + 1 wei);

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        csm.addNodeOperatorWstETH(
            keysCount,
            keys,
            new bytes(0),
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddNodeOperatorWstETH_RevertWhen_ZeroKey() public {
        uint16 keysCount = 1;
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        wstETH.wrap(BOND_SIZE + 1 wei);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        csm.addNodeOperatorWstETH(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            new bytes32[](0),
            address(154)
        );
    }

    function test_AddValidatorKeysWstETH_RevertWhen_NoKeys() public {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        wstETH.wrap(toWrap);

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addValidatorKeysWstETH(
            noId,
            0,
            new bytes(0),
            new bytes(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysWstETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint16 keysCount = 1;
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        wstETH.wrap(toWrap);
        (bytes memory keys, ) = keysSignatures(keysCount);

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        csm.addValidatorKeysWstETH(
            noId,
            keysCount,
            keys,
            new bytes(0),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysWstETH_RevertWhen_ZeroKey() public {
        uint16 keysCount = 1;
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        wstETH.wrap(toWrap);
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        csm.addValidatorKeysWstETH(
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

contract CSMDeposit is CSMCommon, PermitTokenBase {
    function test_DepositETH() public {
        uint256 noId = createNodeOperator();
        uint256 preShares = accounting.getBondShares(noId);
        vm.deal(nodeOperator, 32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);

        vm.prank(nodeOperator);
        csm.depositETH{ value: 32 ether }(noId);

        assertEq(
            nodeOperator.balance,
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(noId),
            sharesToDeposit + preShares,
            "bond shares should be equal to deposited shares + pre shares"
        );
    }

    function test_DepositETH_NotExistingNodeOperator() public {
        uint256 noId = createNodeOperator();
        vm.deal(nodeOperator, 32 ether);

        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 32 ether }(noId + 1);
    }

    function test_DepositETH_NonceShouldChange() public {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.deal(nodeOperator, 32 ether);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 32 ether }(0);

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_DepositETH_NonceShouldNotChange() public {
        uint256 noId = createNodeOperator();

        uint256 nonce = csm.getNonce();

        vm.deal(nodeOperator, 32 ether);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 32 ether }(noId);

        assertEq(csm.getNonce(), nonce);
    }

    function test_DepositStETH() public {
        uint256 noId = createNodeOperator();
        uint256 preShares = accounting.getBondShares(noId);
        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });
        csm.depositStETH(
            noId,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            stETH.balanceOf(nodeOperator),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(noId),
            sharesToDeposit + preShares,
            "bond shares should be equal to deposited shares + pre shares"
        );
    }

    function test_DepositStETH_NotExistingNodeOperator() public {
        uint256 noId = createNodeOperator();
        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.depositStETH(
            noId + 1,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_DepositStETH_withPermit() public {
        uint256 noId = createNodeOperator();
        uint256 preShares = accounting.getBondShares(noId);
        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.expectEmit(true, true, true, true, address(stETH));
        emit Approval(nodeOperator, address(accounting), 32 ether);

        csm.depositStETH(
            noId,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            stETH.balanceOf(nodeOperator),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(noId),
            sharesToDeposit + preShares,
            "bond shares should be equal to deposited shares + pre shares"
        );
    }

    function test_DepositStETH_NonceShouldChange() public {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        csm.depositStETH(
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_DepositStETH_NonceShouldNotChange() public {
        uint256 noId = createNodeOperator();

        uint256 nonce = csm.getNonce();

        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        csm.depositStETH(
            noId,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(csm.getNonce(), nonce);
    }

    function test_DepositWstETH() public {
        uint256 noId = createNodeOperator();
        uint256 preShares = accounting.getBondShares(noId);
        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        csm.depositWstETH(
            noId,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            wstETH.balanceOf(nodeOperator),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(noId),
            sharesToDeposit + preShares,
            "bond shares should be equal to deposited shares + pre shares"
        );
    }

    function test_DepositWstETH_NotExistingNodeOperator() public {
        uint256 noId = createNodeOperator();
        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.depositWstETH(
            noId + 1,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_DepositWstETH_withPermit() public {
        uint256 noId = createNodeOperator();
        uint256 preShares = accounting.getBondShares(noId);
        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        vm.expectEmit(true, true, true, true, address(wstETH));
        emit Approval(nodeOperator, address(accounting), 32 ether);

        csm.depositWstETH(
            noId,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            wstETH.balanceOf(nodeOperator),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(noId),
            sharesToDeposit + preShares,
            "bond shares should be equal to deposited shares + pre shares"
        );
    }

    function test_DepositWstETH_NonceShouldChange() public {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        csm.depositWstETH(
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_DepositWstETH_NonceShouldNotChange() public {
        uint256 noId = createNodeOperator();

        uint256 nonce = csm.getNonce();

        vm.deal(nodeOperator, 32 ether);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        csm.depositWstETH(
            noId,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(csm.getNonce(), nonce);
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
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );

        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .obtainDepositData(1, "");
        assertEq(obtainedKeys, keys);
        assertEq(obtainedSignatures, signatures);
    }

    function test_obtainDepositData_counters() public {
        uint256 noId = createNodeOperator();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.DepositedSigningKeysCountChanged(noId, 1);
        csm.obtainDepositData(1, "");

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.enqueuedCount, 0);
        assertEq(no.totalDepositedKeys, 1);
        assertEq(no.depositableValidatorsCount, 0);
    }

    function test_obtainDepositData_unvettedKeys() public {
        createNodeOperator(2);
        uint256 secondNoId = createNodeOperator(1);
        createNodeOperator(3);

        csm.decreaseOperatorVettedKeys(UintArr(secondNoId), UintArr(0));

        csm.obtainDepositData(5, "");

        (
            ,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        ) = csm.getStakingModuleSummary();
        assertEq(totalDepositedValidators, 5);
        assertEq(depositableValidatorsCount, 0);
    }

    function test_obtainDepositData_counters_WhenLessThanLastBatch() public {
        uint256 noId = createNodeOperator(7);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.DepositedSigningKeysCountChanged(noId, 3);
        csm.obtainDepositData(3, "");

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.enqueuedCount, 4);
        assertEq(no.totalDepositedKeys, 3);
        assertEq(no.depositableValidatorsCount, 4);
    }

    function test_obtainDepositData_RevertWhenNoMoreKeys() public {
        vm.expectRevert(CSModule.NotEnoughKeys.selector);
        csm.obtainDepositData(1, "");
    }

    function test_obtainDepositData_nonceChanged() public {
        createNodeOperator();
        uint256 nonce = csm.getNonce();

        csm.obtainDepositData(1, "");
        assertEq(csm.getNonce(), nonce + 1);
    }
}

contract CSMClaimRewards is CSMCommon {
    // TODO: Add nonce tests
    function test_claimRewardsStETH() public {
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.claimRewardsStETH.selector,
                noId,
                UINT256_MAX,
                0,
                new bytes32[](0)
            ),
            1
        );
        vm.prank(nodeOperator);
        csm.claimRewardsStETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsStETH_fromRewardAddress() public {
        uint256 noId = createNodeOperator();
        address rewardAddress = nextAddress("rewardAddress");
        csm.obtainDepositData(1, "");

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, rewardAddress);

        vm.startPrank(rewardAddress);
        csm.confirmNodeOperatorRewardAddressChange(noId);
        csm.claimRewardsStETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsStETH_revertWhenNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.claimRewardsStETH(0, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsStETH_revertWhenNotEligible() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(CSModule.SenderIsNotEligible.selector);
        csm.claimRewardsStETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsWstETH() public {
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.claimRewardsWstETH.selector,
                noId,
                UINT256_MAX,
                0,
                new bytes32[](0)
            ),
            1
        );
        vm.prank(nodeOperator);
        csm.claimRewardsWstETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsWstETH_fromRewardAddress() public {
        uint256 noId = createNodeOperator();
        address rewardAddress = nextAddress("rewardAddress");
        csm.obtainDepositData(1, "");

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, rewardAddress);

        vm.startPrank(rewardAddress);
        csm.confirmNodeOperatorRewardAddressChange(noId);
        csm.claimRewardsWstETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsWstETH_revertWhenNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.claimRewardsWstETH(0, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_claimRewardsWstETH_revertWhenNotEligible() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(CSModule.SenderIsNotEligible.selector);
        csm.claimRewardsWstETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_requestRewardsETH() public {
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.requestRewardsETH.selector,
                noId,
                UINT256_MAX,
                0,
                new bytes32[](0)
            ),
            1
        );
        vm.prank(nodeOperator);
        csm.requestRewardsETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_requestRewardsETH_fromRewardAddress() public {
        uint256 noId = createNodeOperator();
        address rewardAddress = nextAddress("rewardAddress");
        csm.obtainDepositData(1, "");

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, rewardAddress);

        vm.startPrank(rewardAddress);
        csm.confirmNodeOperatorRewardAddressChange(noId);
        csm.requestRewardsETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_requestRewardsETH_revertWhenNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.requestRewardsETH(0, UINT256_MAX, 0, new bytes32[](0));
    }

    function test_requestRewardsETH_revertWhenNotEligible() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(CSModule.SenderIsNotEligible.selector);
        csm.requestRewardsETH(noId, UINT256_MAX, 0, new bytes32[](0));
    }
}

contract CsmProposeNodeOperatorManagerAddressChange is CSMCommon {
    function test_proposeNodeOperatorManagerAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.expectEmit(true, true, true, true, address(csm));
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorManagerAddressChange(0, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhenNotManager()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(NOAddresses.SenderIsNotManagerAddress.selector);
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

contract CsmOnWithdrawalCredentialsChanged is CSMCommon {
    function test_onWithdrawalCredentialsChanged() public {
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.KeyRemovalChargeSet(0 ether);
        csm.onWithdrawalCredentialsChanged();

        uint256 removalChargeAfter = csm.keyRemovalCharge();
        assertEq(removalChargeAfter, 0 ether);
    }
}

contract CsmConfirmNodeOperatorManagerAddressChange is CSMCommon {
    function test_confirmNodeOperatorManagerAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperator memory no = csm.getNodeOperator(noId);
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
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
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.expectEmit(true, true, true, true, address(csm));
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
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
        NodeOperator memory no = csm.getNodeOperator(noId);
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
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

        NodeOperator memory no = csm.getNodeOperator(noId);
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
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
        emit CSModule.VettedSigningKeysCountChanged(noId, keys);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.BatchEnqueued(noId, keys);
        createNodeOperator(keys);

        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: keys });
        _assertQueueState(exp);
    }

    function test_vetKeys_OnUploadKeys() public {
        uint256 noId = createNodeOperator(2);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(noId, 3);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.BatchEnqueued(noId, 1);
        uploadMoreKeys(noId, 1);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 3);

        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 1 });
        _assertQueueState(exp);
    }

    function test_vetKeys_Counters() public {
        uint256 nonce = csm.getNonce();
        uint256 noId = createNodeOperator(1);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 1);
        assertEq(no.depositableValidatorsCount, 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_vetKeys_VettedBackViaRemoveKey() public {
        uint256 noId = createNodeOperator(7);
        unvetKeys({ noId: noId, to: 4 });

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(noId, 5); // 7 - 2 removed at the next step.

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 4, 2); // Remove keys 4 and 5.

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 5);
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

    function test_cleanup_RevertWhen_zeroDepth() public {
        vm.expectRevert(CSModule.QueueLookupNoLimit.selector);
        csm.cleanDepositQueue(0);
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
        emit CSModule.BatchEnqueued(noId, 4);

        vm.prank(nodeOperator);
        csm.normalizeQueue(noId);
    }

    function test_queueNormalized_WhenSkippedKeysAndTargetValidatorsLimitRaised()
        public
    {
        uint256 noId = createNodeOperator(7);
        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 0
        });
        csm.cleanDepositQueue(1);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.BatchEnqueued(noId, 7);

        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 7
        });
    }

    function test_queueNormalized_WhenWithdrawalChangesDepositable() public {
        uint256 noId = createNodeOperator(7);
        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 2
        });
        csm.obtainDepositData(2, "");
        csm.cleanDepositQueue(1);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.BatchEnqueued(noId, 1);
        csm.submitWithdrawal(noId, 0, csm.DEPOSIT_SIZE());
    }
}

contract CsmUnvetKeys is CSMCommon {
    function test_unvetKeys_counters() public {
        uint256 noId = createNodeOperator(3);
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(noId, 1);
        unvetKeys({ noId: noId, to: 1 });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(csm.getNonce(), nonce + 1);
        assertEq(no.totalVettedKeys, 1);
        assertEq(no.depositableValidatorsCount, 1);
    }

    function test_unvetKeys_MultipleOperators() public {
        uint256 noIdOne = createNodeOperator(3);
        uint256 noIdTwo = createNodeOperator(7);
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(noIdOne, 2);
        emit CSModule.VettedSigningKeysCountChanged(noIdTwo, 3);
        csm.decreaseOperatorVettedKeys(
            UintArr(noIdOne, noIdTwo),
            UintArr(2, 3)
        );

        assertEq(csm.getNonce(), nonce + 1);
        NodeOperator memory no;
        no = csm.getNodeOperator(noIdOne);
        assertEq(no.totalVettedKeys, 2);
        no = csm.getNodeOperator(noIdTwo);
        assertEq(no.totalVettedKeys, 3);
    }

    function test_unvetKeys_RevertIfNodeOperatorDoesntExist() public {
        createNodeOperator(); // Make sure there is at least one node operator.
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.decreaseOperatorVettedKeys(UintArr(1), UintArr(0));
    }
}

contract CsmGetSigningKeys is CSMCommon {
    function test_getSigningKeys() public {
        bytes memory keys = randomBytes(48 * 3);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 3,
            keys: keys,
            signatures: randomBytes(96 * 3)
        });

        bytes memory obtainedKeys = csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });

        assertEq(obtainedKeys, keys, "unexpected keys");
    }

    function test_getSigningKeys_getNonExistingKeys() public {
        bytes memory keys = randomBytes(48);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1,
            keys: keys,
            signatures: randomBytes(96)
        });

        vm.expectRevert(CSModule.SigningKeysInvalidOffset.selector);
        csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
    }

    function test_getSigningKeys_getKeysFromOffset() public {
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

        bytes memory obtainedKeys = csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 1,
            keysCount: 1
        });

        assertEq(obtainedKeys, wantedKey, "unexpected key at position 1");
    }
}

contract CsmGetSigningKeysWithSignatures is CSMCommon {
    function test_getSigningKeysWithSignatures() public {
        bytes memory keys = randomBytes(48 * 3);
        bytes memory signatures = randomBytes(96 * 3);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 3,
            keys: keys,
            signatures: signatures
        });

        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .getSigningKeysWithSignatures({
                nodeOperatorId: noId,
                startIndex: 0,
                keysCount: 3
            });

        assertEq(obtainedKeys, keys, "unexpected keys");
        assertEq(obtainedSignatures, signatures, "unexpected signatures");
    }

    function test_getSigningKeysWithSignatures_getNonExistingKeys() public {
        bytes memory keys = randomBytes(48);
        bytes memory signatures = randomBytes(96);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1,
            keys: keys,
            signatures: signatures
        });

        vm.expectRevert(CSModule.SigningKeysInvalidOffset.selector);
        csm.getSigningKeysWithSignatures({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
    }

    function test_getSigningKeysWithSignatures_getKeysFromOffset() public {
        bytes memory wantedKey = randomBytes(48);
        bytes memory wantedSignature = randomBytes(96);
        bytes memory keys = bytes.concat(
            randomBytes(48),
            wantedKey,
            randomBytes(48)
        );
        bytes memory signatures = bytes.concat(
            randomBytes(96),
            wantedSignature,
            randomBytes(96)
        );

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 3,
            keys: keys,
            signatures: signatures
        });

        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .getSigningKeysWithSignatures({
                nodeOperatorId: noId,
                startIndex: 1,
                keysCount: 1
            });

        assertEq(obtainedKeys, wantedKey, "unexpected key at position 1");
        assertEq(
            obtainedSignatures,
            wantedSignature,
            "unexpected sitnature at position 1"
        );
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 4);
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 3);
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 2, keysCount: 1 });
        /*
            key4
            key3
        */

        bytes memory obtainedKeys = csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 2
        });
        assertEq(obtainedKeys, bytes.concat(key4, key3), "unexpected keys");

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedKeys, 2);
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 3);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 2 });

        bytes memory obtainedKeys = csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
        assertEq(
            obtainedKeys,
            bytes.concat(key3, key4, key2),
            "unexpected keys"
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedKeys, 3);
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 3);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 1, keysCount: 2 });

        bytes memory obtainedKeys = csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
        assertEq(
            obtainedKeys,
            bytes.concat(key0, key3, key4),
            "unexpected keys"
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedKeys, 3);
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 3);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 3, keysCount: 2 });

        bytes memory obtainedKeys = csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
        assertEq(
            obtainedKeys,
            bytes.concat(key0, key1, key2),
            "unexpected keys"
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedKeys, 3);
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
            emit CSModule.TotalSigningKeysCountChanged(noId, 0);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 5 });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedKeys, 0);
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.removeKeys({ nodeOperatorId: 0, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhenMoreThanAdded() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.expectRevert(CSModule.SigningKeysInvalidOffset.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 2 });
    }

    function test_removeKeys_RevertWhenLessThanDeposited() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 2
        });

        csm.obtainDepositData(1, "");

        vm.expectRevert(CSModule.SigningKeysInvalidOffset.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhenNotEligible() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.prank(stranger);
        vm.expectRevert(CSModule.SenderIsNotEligible.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhen_NoKeys() public {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 0 });
    }

    function test_removeKeys_chargeFee() public {
        uint256 noId = createNodeOperator(3);

        uint256 amountToCharge = csm.keyRemovalCharge() * 2;

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                amountToCharge
            ),
            1
        );

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.KeyRemovalChargeApplied(noId, amountToCharge);

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 1, 2);
    }

    function test_removeKeys_withNoFee() public {
        bytes32 role = csm.MODULE_MANAGER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, admin);
        vm.prank(admin);
        csm.setKeyRemovalCharge(0);

        uint256 noId = createNodeOperator(3);

        vm.recordLogs();

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 1, 2);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            assertNotEq(
                entries[i].topics[0],
                CSModule.KeyRemovalChargeApplied.selector
            );
        }
    }
}

contract CsmGetNodeOperatorNonWithdrawnKeys is CSMCommon {
    function test_getNodeOperatorNonWithdrawnKeys() public {
        uint256 noId = createNodeOperator(3);
        uint256 keys = csm.getNodeOperatorNonWithdrawnKeys(noId);
        assertEq(keys, 3);
    }

    function test_getNodeOperatorNonWithdrawnKeys_WithdrawnKeys() public {
        uint256 noId = createNodeOperator(3);
        csm.obtainDepositData(3, "");
        csm.submitWithdrawal(noId, 0, csm.DEPOSIT_SIZE());
        uint256 keys = csm.getNodeOperatorNonWithdrawnKeys(noId);
        assertEq(keys, 2);
    }

    function test_getNodeOperatorNonWithdrawnKeys_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.getNodeOperatorNonWithdrawnKeys(0);
    }
}

contract CsmGetNodeOperatorRewardAddress is CSMCommon {
    function test_getNodeOperatorRewardAddress() public {
        uint256 noId = createNodeOperator();
        address rewardAddress = csm.getNodeOperatorRewardAddress(noId);
        assertEq(rewardAddress, nodeOperator);
    }

    function test_getNodeOperatorRewardAddress_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.getNodeOperatorRewardAddress(0);
    }
}

contract CsmGetNodeOperatorSummary is CSMCommon {
    // TODO add more tests here. There might be fuzz tests

    function test_getNodeOperatorSummary_defaultValues() public {
        uint256 noId = createNodeOperator(1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 0);
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

    function test_getNodeOperatorSummary_softTargetLimit() public {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, 1, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            1,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitAndDeposited() public {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(1, "");

        csm.updateTargetValidatorsLimits(noId, 1, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitAboveTotalKeys()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, 1, 5);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            5,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimit() public {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, 2, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            1,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitAndDeposited() public {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(1, "");

        csm.updateTargetValidatorsLimits(noId, 2, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitAboveTotalKeys()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, 2, 5);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            5,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitEqualToDepositedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(1, "");

        csm.updateTargetValidatorsLimits(noId, 1, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(
            summary.depositableValidatorsCount,
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitLowerThanDepositedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(2, "");

        csm.updateTargetValidatorsLimits(noId, 1, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(
            summary.depositableValidatorsCount,
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitLowerThanVettedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, 1, 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            2,
            "targetValidatorsCount mismatch"
        );
        assertEq(
            summary.depositableValidatorsCount,
            2,
            "depositableValidatorsCount mismatch"
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 3); // Should NOT be unvetted.
    }

    function test_getNodeOperatorSummary_targetLimitHigherThanVettedKeys()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.updateTargetValidatorsLimits(noId, 1, 9);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            9,
            "targetValidatorsCount mismatch"
        );
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_noTargetLimitDueToLockedBond() public {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(3, "");

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 0, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            0,
            "targetValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitDueToUnbondedDeposited()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(3, "");

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            2,
            "targetValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitDueToUnbondedNonDeposited()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(2, "");

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            2,
            "targetValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitDueToAllUnbonded() public {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(2, "");

        penalize(noId, BOND_SIZE * 3);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            0,
            "targetValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitLowerThanUnbonded()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 2, 1);

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            1,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            1,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitLowerThanUnbonded_deposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(1, "");

        csm.updateTargetValidatorsLimits(noId, 2, 2);

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            2,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            1,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitGreaterThanUnbonded()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 2, 4);

        penalize(noId, BOND_SIZE + 100 wei);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            3,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitEqualUnbonded() public {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 2, 4);

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            4,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            4,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitLowerThanUnbonded()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 1, 1);

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            4,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            1,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitLowerThanUnbonded_deposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(1, "");

        csm.updateTargetValidatorsLimits(noId, 1, 2);

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            4,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            1,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitGreaterThanUnbonded()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 1, 4);

        penalize(noId, BOND_SIZE + 100 wei);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            3,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }
}

contract CsmUpdateTargetValidatorsLimits is CSMCommon {
    function test_updateTargetValidatorsLimits() public {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 1, 1);
        csm.updateTargetValidatorsLimits(noId, 1, 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_updateTargetValidatorsLimits_sameValues() public {
        uint256 noId = createNodeOperator();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 1, 1);
        csm.updateTargetValidatorsLimits(noId, 1, 1);

        // expectNoEmit hack
        Vm.Log[] memory entries = vm.getRecordedLogs();
        csm.updateTargetValidatorsLimits(noId, 1, 1);
        assertEq(entries.length, 0);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 1);
        assertEq(summary.targetValidatorsCount, 1);
    }

    function test_updateTargetValidatorsLimits_limitIsZero() public {
        uint256 noId = createNodeOperator();
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 1, 0);
        csm.updateTargetValidatorsLimits(noId, 1, 0);
    }

    function test_updateTargetValidatorsLimits_enableSoftLimit() public {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 0, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 1, 10);
        csm.updateTargetValidatorsLimits(noId, 1, 10);
    }

    function test_updateTargetValidatorsLimits_enableHardLimit() public {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 0, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 2, 10);
        csm.updateTargetValidatorsLimits(noId, 2, 10);
    }

    function test_updateTargetValidatorsLimits_disableSoftLimit() public {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 1, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 0, 10);
        csm.updateTargetValidatorsLimits(noId, 0, 10);
    }

    function test_updateTargetValidatorsLimits_disableHardLimit() public {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 2, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 0, 10);
        csm.updateTargetValidatorsLimits(noId, 0, 10);
    }

    function test_updateTargetValidatorsLimits_switchFromHardToSoftLimit()
        public
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 2, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 1, 5);
        csm.updateTargetValidatorsLimits(noId, 1, 5);
    }

    function test_updateTargetValidatorsLimits_switchFromSoftToHardLimit()
        public
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 1, 10);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.TargetValidatorsCountChangedByRequest(noId, 2, 5);
        csm.updateTargetValidatorsLimits(noId, 2, 5);
    }

    function test_updateTargetValidatorsLimits_NoUnvetKeysWhenLimitDisabled()
        public
    {
        uint256 noId = createNodeOperator(2);
        csm.updateTargetValidatorsLimits(noId, 1, 1);
        csm.updateTargetValidatorsLimits(noId, 0, 1);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 2);
    }

    function test_updateTargetValidatorsLimits_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.updateTargetValidatorsLimits(0, 1, 1);
    }
}

contract CsmUpdateStuckValidatorsCount is CSMCommon {
    function test_updateStuckValidatorsCount_NonZero() public {
        uint256 noId = createNodeOperator(3);
        csm.obtainDepositData(1, "");
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.StuckSigningKeysCountChanged(noId, 1);
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(
            no.stuckValidatorsCount,
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

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.StuckSigningKeysCountChanged(noId, 0);
        csm.updateStuckValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000000))
        );
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(
            no.stuckValidatorsCount,
            0,
            "stuckValidatorsCount should be zero"
        );
    }

    function test_updateStuckValidatorsCount_RevertWhenNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
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

        vm.expectRevert(CSModule.StuckKeysHigherThanNonWithdrawn.selector);
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

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ExitedSigningKeysCountChanged(noId, 1);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, 1, "totalExitedKeys not increased");

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_updateExitedValidatorsCount_RevertIfNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
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

        vm.expectRevert(CSModule.ExitedKeysHigherThanTotalDeposited.selector);
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

        vm.expectRevert(CSModule.ExitedKeysDecrease.selector);
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

contract CsmUnsafeUpdateValidatorsCount is CSMCommon {
    function test_unsafeUpdateValidatorsCount_NonZero() public {
        uint256 noId = createNodeOperator(5);
        csm.obtainDepositData(5, "");
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.StuckSigningKeysCountChanged(noId, 1);
        emit CSModule.ExitedSigningKeysCountChanged(noId, 1);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1,
            stuckValidatorsKeysCount: 1
        });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, 1, "totalExitedKeys not increased");
        assertEq(
            no.stuckValidatorsCount,
            1,
            "stuckValidatorsCount not increased"
        );

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_unsafeUpdateValidatorsCount_RevertIfNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: 100500,
            exitedValidatorsKeysCount: 1,
            stuckValidatorsKeysCount: 1
        });
    }

    function test_unsafeUpdateValidatorsCount_RevertIfNotStakingRouter()
        public
    {
        expectRoleRevert(stranger, csm.STAKING_ROUTER_ROLE());
        vm.prank(stranger);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: 100500,
            exitedValidatorsKeysCount: 1,
            stuckValidatorsKeysCount: 1
        });
    }

    function test_unsafeUpdateValidatorsCount_RevertIfExitedCountMoreThanDeposited()
        public
    {
        uint256 noId = createNodeOperator(1);

        vm.expectRevert(CSModule.ExitedKeysHigherThanTotalDeposited.selector);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 100500,
            stuckValidatorsKeysCount: 1
        });
    }

    function test_unsafeUpdateValidatorsCount_RevertIfStuckCountMoreThanDeposited()
        public
    {
        uint256 noId = createNodeOperator(1);
        csm.obtainDepositData(1, "");

        vm.expectRevert(CSModule.StuckKeysHigherThanNonWithdrawn.selector);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1,
            stuckValidatorsKeysCount: 100500
        });
    }

    function test_unsafeUpdateValidatorsCount_DecreaseExitedKeys() public {
        uint256 noId = createNodeOperator(1);
        csm.obtainDepositData(1, "");

        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 0,
            stuckValidatorsKeysCount: 0
        });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, 0, "totalExitedKeys should be zero");
    }

    function test_unsafeUpdateValidatorsCount_NoEventIfSameValue() public {
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(2, "");

        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1,
            stuckValidatorsKeysCount: 1
        });

        vm.recordLogs();
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1,
            stuckValidatorsKeysCount: 1
        });
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }
}

contract CsmReportELRewardsStealingPenalty is CSMCommon {
    function test_reportELRewardsStealingPenalty_HappyPath() public {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltyReported(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(lockedBond, BOND_SIZE / 2 + csm.EL_REWARDS_STEALING_FINE());
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_reportELRewardsStealingPenalty_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.reportELRewardsStealingPenalty(0, blockhash(block.number), 1 ether);
    }

    function test_reportELRewardsStealingPenalty_NoNonceChange() public {
        uint256 noId = createNodeOperator();

        vm.deal(nodeOperator, 32 ether);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 32 ether }(0);

        uint256 nonce = csm.getNonce();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        assertEq(csm.getNonce(), nonce);
    }
}

contract CsmCancelELRewardsStealingPenalty is CSMCommon {
    function test_cancelELRewardsStealingPenalty_HappyPath() public {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltyCancelled(
            noId,
            BOND_SIZE / 2 + csm.EL_REWARDS_STEALING_FINE()
        );
        csm.cancelELRewardsStealingPenalty(
            noId,
            BOND_SIZE / 2 + csm.EL_REWARDS_STEALING_FINE()
        );

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(lockedBond, 0);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_cancelELRewardsStealingPenalty_Partial() public {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltyCancelled(noId, BOND_SIZE / 2);
        csm.cancelELRewardsStealingPenalty(noId, BOND_SIZE / 2);

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(lockedBond, csm.EL_REWARDS_STEALING_FINE());
        // nonce should not change due to no changes in the depositable validators
        assertEq(csm.getNonce(), nonce);
    }

    function test_cancelELRewardsStealingPenalty_RevertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.cancelELRewardsStealingPenalty(0, 1 ether);
    }
}

contract CsmSettleELRewardsStealingPenalty is CSMCommon {
    function test_settleELRewardsStealingPenalty() public {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(
            noId,
            amount + csm.EL_REWARDS_STEALING_FINE()
        );
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }

    function test_settleELRewardsStealingPenalty_NoLock() public {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(noId, 0);
        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.retentionUntil, 0);
    }

    function test_settleELRewardsStealingPenalty_NoLock_MultipleOperators()
        public
    {
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(firstNoId, 0);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(secondNoId, 0);
        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.resetBondCurve.selector,
                firstNoId
            )
        );
        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.resetBondCurve.selector,
                secondNoId
            )
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory firstLock = accounting.getLockedBondInfo(
            firstNoId
        );
        assertEq(firstLock.amount, 0 ether);
        assertEq(firstLock.retentionUntil, 0);
        CSBondLock.BondLock memory secondLock = accounting.getLockedBondInfo(
            secondNoId
        );
        assertEq(secondLock.amount, 0 ether);
        assertEq(secondLock.retentionUntil, 0);
    }

    function test_settleELRewardsStealingPenalty_RevertWhen_NoExistingNodeOperator()
        public
    {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId + 1;

        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.settleELRewardsStealingPenalty(idsToSettle);
    }

    function test_settleELRewardsStealingPenalty_noLocked() public {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(noId, 0);
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
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;
        csm.reportELRewardsStealingPenalty(
            firstNoId,
            blockhash(block.number),
            1 ether
        );
        csm.reportELRewardsStealingPenalty(
            secondNoId,
            blockhash(block.number),
            BOND_SIZE
        );

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(
            firstNoId,
            1 ether + csm.EL_REWARDS_STEALING_FINE()
        );
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(
            secondNoId,
            BOND_SIZE + csm.EL_REWARDS_STEALING_FINE()
        );
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.resetBondCurve.selector,
                secondNoId
            ),
            1
        );
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.resetBondCurve.selector,
                firstNoId
            ),
            1
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

    function test_settleELRewardsStealingPenalty_multipleNOs_oneExpired()
        public
    {
        uint256 retentionPeriod = accounting.getBondLockRetentionPeriod();
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;
        csm.reportELRewardsStealingPenalty(
            firstNoId,
            blockhash(block.number),
            1 ether
        );
        vm.warp(block.timestamp + retentionPeriod + 1 seconds);
        csm.reportELRewardsStealingPenalty(
            secondNoId,
            blockhash(block.number),
            BOND_SIZE
        );

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(firstNoId, 0);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.ELRewardsStealingPenaltySettled(
            secondNoId,
            BOND_SIZE + csm.EL_REWARDS_STEALING_FINE()
        );
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

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

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

    function test_settleELRewardsStealingPenalty_CurveReset_NoNewUnbonded()
        public
    {
        uint256 noId = createNodeOperator();

        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 2 ether;
        curvePoints[1] = 3 ether;

        uint256 curveId = accounting.addBondCurve(curvePoints);

        vm.prank(address(csm));
        accounting.setBondCurve(0, curveId);

        uploadMoreKeys(0, 1);

        vm.deal(nodeOperator, 3 ether);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 3 ether }(0);

        uint256 amount = 1 ether;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 nonce = csm.getNonce();
        uint256 unbonded = accounting.getUnbondedKeysCount(noId);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        assertEq(accounting.getBondCurve(noId).id, 1);
        assertEq(csm.getNonce(), nonce);
        assertEq(accounting.getUnbondedKeysCount(noId), unbonded);
    }

    function test_settleELRewardsStealingPenalty_CurveReset_NewUnbonded()
        public
    {
        uint256 noId = createNodeOperator();

        uint256[] memory curvePoints = new uint256[](2);
        curvePoints[0] = 2 ether;
        curvePoints[1] = 3 ether;

        uint256 curveId = accounting.addBondCurve(curvePoints);

        vm.prank(address(csm));
        accounting.setBondCurve(0, curveId);

        uploadMoreKeys(0, 1);

        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 2 ether }(0);

        uint256 amount = 1 ether;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 nonce = csm.getNonce();
        uint256 unbonded = accounting.getUnbondedKeysCount(noId);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
        );
        csm.settleELRewardsStealingPenalty(idsToSettle);

        assertEq(accounting.getBondCurve(noId).id, 1);
        assertEq(csm.getNonce(), nonce + 1);
        assertEq(accounting.getUnbondedKeysCount(noId), unbonded + 1);
    }
}

contract CSMCompensateELRewardsStealingPenalty is CSMCommon {
    function test_compensateELRewardsStealingPenalty() public {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256 fine = csm.EL_REWARDS_STEALING_FINE();
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 nonce = csm.getNonce();

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.compensateLockedBondETH.selector,
                noId
            )
        );
        csm.compensateELRewardsStealingPenalty{ value: amount + fine }(noId);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_compensateELRewardsStealingPenalty_Partial() public {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256 fine = csm.EL_REWARDS_STEALING_FINE();
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 nonce = csm.getNonce();

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.compensateLockedBondETH.selector,
                noId
            )
        );
        csm.compensateELRewardsStealingPenalty{ value: amount }(noId);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, fine);
        assertEq(csm.getNonce(), nonce);
    }

    function test_compensateELRewardsStealingPenalty_depositableValidatorsChanged()
        public
    {
        uint256 noId = createNodeOperator(2);
        uint256 amount = 1 ether;
        uint256 fine = csm.EL_REWARDS_STEALING_FINE();
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );
        csm.obtainDepositData(1, "");
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        csm.compensateELRewardsStealingPenalty{ value: amount + fine }(noId);
        uint256 depositableAfter = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;
        assertEq(depositableAfter, depositableBefore + 1);

        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 1 });
        _assertQueueState(exp);
    }

    function test_compensateELRewardsStealingPenalty_revertWhenNoNodeOperator()
        public
    {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.compensateELRewardsStealingPenalty{ value: 1 ether }(0);
    }
}

contract CsmSubmitWithdrawal is CSMCommon {
    function test_submitWithdrawal() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.WithdrawalSubmitted(noId, keyIndex, csm.DEPOSIT_SIZE());
        csm.submitWithdrawal(noId, keyIndex, csm.DEPOSIT_SIZE());

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalWithdrawnKeys, 1);
        bool withdrawn = csm.isValidatorWithdrawn(noId, keyIndex);
        assertTrue(withdrawn);

        // no chages in depositable keys or keys in general
        assertEq(csm.getNonce(), nonce);
    }

    function test_submitWithdrawal_changeNonce() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(1, "");

        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.WithdrawalSubmitted(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - BOND_SIZE - 1 ether
        );
        csm.submitWithdrawal(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - BOND_SIZE - 1 ether
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalWithdrawnKeys, 1);
        // depositable decrease should
        assertEq(csm.getNonce(), nonce + 1);
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
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.resetBondCurve.selector, noId)
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
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.submitWithdrawal(0, 0, 0);
    }

    function test_submitWithdrawal_RevertWhenInvalidKeyIndexOffset() public {
        uint256 noId = createNodeOperator();
        vm.expectRevert(CSModule.SigningKeysInvalidOffset.selector);
        csm.submitWithdrawal(noId, 0, 0);
    }

    function test_submitWithdrawal_RevertWhenAlreadySubmitted() public {
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        uint256 depositSize = csm.DEPOSIT_SIZE();

        csm.submitWithdrawal(noId, 0, depositSize);
        vm.expectRevert(CSModule.AlreadySubmitted.selector);
        csm.submitWithdrawal(noId, 0, depositSize);
    }
}

contract CsmSubmitInitialSlashing is CSMCommon {
    function test_submitInitialSlashing() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(1, "");
        uint256 penaltyAmount = csm.INITIAL_SLASHING_PENALTY();

        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.InitialSlashingSubmitted(noId, keyIndex);
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.penalize.selector,
                noId,
                penaltyAmount
            )
        );
        csm.submitInitialSlashing(noId, keyIndex);

        bool slashed = csm.isValidatorSlashed(noId, keyIndex);
        assertTrue(slashed);

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_submitInitialSlashing_Overbonded() public {
        uint256 noId = createNodeOperator(2);
        vm.deal(nodeOperator, 32 ether);
        vm.prank(nodeOperator);
        csm.depositETH{ value: 32 ether }(0);
        csm.obtainDepositData(1, "");
        uint256 penaltyAmount = csm.INITIAL_SLASHING_PENALTY();

        uint256 nonce = csm.getNonce();

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.InitialSlashingSubmitted(noId, 0);
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.penalize.selector,
                noId,
                penaltyAmount
            )
        );
        csm.submitInitialSlashing(noId, 0);

        assertEq(csm.getNonce(), nonce);
    }

    function test_submitInitialSlashing_differentKeys() public {
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(2, "");

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.InitialSlashingSubmitted(noId, 0);
        csm.submitInitialSlashing(noId, 0);

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.InitialSlashingSubmitted(noId, 1);
        csm.submitInitialSlashing(noId, 1);
    }

    function test_submitInitialSlashing_outOfBond() public {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            csm.DEPOSIT_SIZE() - csm.INITIAL_SLASHING_PENALTY()
        );
        csm.submitInitialSlashing(noId, keyIndex);
    }

    function test_submitInitialSlashing_RevertWhenNoNodeOperator() public {
        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.submitInitialSlashing(0, 0);
    }

    function test_submitInitialSlashing_RevertWhenInvalidKeyIndexOffset()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(CSModule.SigningKeysInvalidOffset.selector);
        csm.submitInitialSlashing(noId, 0);
    }

    function test_submitInitialSlashing_RevertWhenAlreadySubmitted() public {
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        csm.submitInitialSlashing(noId, 0);
        vm.expectRevert(CSModule.AlreadySubmitted.selector);
        csm.submitInitialSlashing(noId, 0);
    }
}

contract CsmGetStakingModuleSummary is CSMCommon {
    function test_getStakingModuleSummary_depositableValidators() public {
        uint256 first = createNodeOperator(1);
        uint256 second = createNodeOperator(2);
        StakingModuleSummary memory summary = getStakingModuleSummary();
        NodeOperator memory firstNo = csm.getNodeOperator(first);
        NodeOperator memory secondNo = csm.getNodeOperator(second);

        assertEq(firstNo.depositableValidatorsCount, 1);
        assertEq(secondNo.depositableValidatorsCount, 2);
        assertEq(summary.depositableValidatorsCount, 3);
    }

    function test_getStakingModuleSummary_depositedValidators() public {
        uint256 first = createNodeOperator(1);
        uint256 second = createNodeOperator(2);
        StakingModuleSummary memory summary = getStakingModuleSummary();
        assertEq(summary.totalDepositedValidators, 0);

        csm.obtainDepositData(3, "");

        summary = getStakingModuleSummary();
        NodeOperator memory firstNo = csm.getNodeOperator(first);
        NodeOperator memory secondNo = csm.getNodeOperator(second);

        assertEq(firstNo.totalDepositedKeys, 1);
        assertEq(secondNo.totalDepositedKeys, 2);
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
        NodeOperator memory firstNo = csm.getNodeOperator(first);
        NodeOperator memory secondNo = csm.getNodeOperator(second);

        assertEq(firstNo.totalExitedKeys, 1);
        assertEq(secondNo.totalExitedKeys, 2);
        assertEq(summary.totalExitedValidators, 3);
    }
}

contract CSMAccessControl is CSMCommonNoRoles {
    function test_adminRole() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            elStealingFine: 0.1 ether,
            maxKeysPerOperatorEA: 10,
            lidoLocator: address(locator)
        });
        csm.initialize(address(0), address(0), address(0), actor);

        bytes32 role = csm.MODULE_MANAGER_ROLE();
        vm.prank(actor);
        csm.grantRole(role, stranger);
        assertTrue(csm.hasRole(role, stranger));

        vm.prank(actor);
        csm.revokeRole(role, stranger);
        assertFalse(csm.hasRole(role, stranger));
    }

    function test_adminRole_revert() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            elStealingFine: 0.1 ether,
            maxKeysPerOperatorEA: 10,
            lidoLocator: address(locator)
        });
        bytes32 role = csm.MODULE_MANAGER_ROLE();
        bytes32 adminRole = csm.DEFAULT_ADMIN_ROLE();

        vm.startPrank(stranger);
        expectRoleRevert(stranger, adminRole);
        csm.grantRole(role, stranger);
    }

    function test_moduleManagerRole_setRemovalCharge() public {
        bytes32 role = csm.MODULE_MANAGER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.setKeyRemovalCharge(0.1 ether);
    }

    function test_moduleManagerRole_setRemovalCharge_revert() public {
        bytes32 role = csm.MODULE_MANAGER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.setKeyRemovalCharge(0.1 ether);
    }

    function test_moduleManagerRole_activatePublicRelease() public {
        bytes32 role = csm.MODULE_MANAGER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.activatePublicRelease();
    }

    function test_moduleManagerRole_activatePublicRelease_revert() public {
        bytes32 role = csm.MODULE_MANAGER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.activatePublicRelease();
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
        csm.activatePublicRelease();
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
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.updateRefundedValidatorsCount(noId, 0);
    }

    function test_stakingRouterRole_updateTargetValidatorsLimits() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.updateTargetValidatorsLimits(noId, 0, 0);
    }

    function test_stakingRouterRole_updateTargetValidatorsLimits_revert()
        public
    {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.updateTargetValidatorsLimits(noId, 0, 0);
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
        csm.activatePublicRelease();
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
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.unsafeUpdateValidatorsCount(noId, 0, 0);
    }

    function test_stakingRouterRole_unvetKeys() public {
        csm.activatePublicRelease();
        createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.decreaseOperatorVettedKeys(UintArr(), UintArr());
    }

    function test_stakingRouterRole_unvetKeys_revert() public {
        csm.activatePublicRelease();
        createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.decreaseOperatorVettedKeys(UintArr(), UintArr());
    }

    function test_reportELRewardsStealingPenaltyRole() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            1 ether
        );
    }

    function test_reportELRewardsStealingPenaltyRole_revert() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            1 ether
        );
    }

    function test_settleELRewardsStealingPenaltyRole() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.settleELRewardsStealingPenalty(UintArr(noId));
    }

    function test_settleELRewardsStealingPenaltyRole_revert() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.settleELRewardsStealingPenalty(UintArr(noId));
    }

    function test_verifierRole_submitWithdrawal() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.VERIFIER_ROLE();

        vm.startPrank(admin);
        csm.grantRole(role, actor);
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), admin);
        csm.obtainDepositData(1, "");
        vm.stopPrank();

        vm.prank(actor);
        csm.submitWithdrawal(noId, 0, 1 ether);
    }

    function test_verifierRole_submitWithdrawal_revert() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.VERIFIER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.submitWithdrawal(noId, 0, 1 ether);
    }

    function test_verifierRole_submitInitialSlashing() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.VERIFIER_ROLE();

        vm.startPrank(admin);
        csm.grantRole(role, actor);
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), admin);
        csm.obtainDepositData(1, "");
        vm.stopPrank();

        vm.prank(actor);
        csm.submitInitialSlashing(noId, 0);
    }

    function test_verifierRole_submitInitialSlashing_revert() public {
        csm.activatePublicRelease();
        uint256 noId = createNodeOperator();
        bytes32 role = csm.VERIFIER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.submitInitialSlashing(noId, 0);
    }

    function test_recovererRole() public {
        bytes32 role = csm.RECOVERER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.recoverEther();
    }

    function test_recovererRole_revert() public {
        bytes32 role = csm.RECOVERER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.recoverEther();
    }
}

contract CSMActivatePublicRelease is CSMCommonNoPublicRelease {
    function test_activatePublicRelease() public {
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.PublicRelease();
        csm.activatePublicRelease();

        assertTrue(csm.publicRelease());
    }

    function test_activatePublicRelease_RevertWhen_AlreadySet() public {
        csm.activatePublicRelease();

        vm.expectRevert(CSModule.AlreadySet.selector);
        csm.activatePublicRelease();
    }

    function test_addNodeOperatorETH_RevertWhenNoPublicReleaseYet() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        vm.expectRevert(CSModule.NotAllowedToJoinYet.selector);
        csm.addNodeOperatorETH{ value: keysCount * BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
    }

    function test_addNodeOperatorETH_WhenPublicRelease() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        csm.activatePublicRelease();

        csm.addNodeOperatorETH{ value: keysCount * BOND_SIZE }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
    }
}

contract CSMEarlyAdoptionTest is CSMCommonNoPublicRelease {
    function test_addNodeOperator_earlyAdoptionProof() public {
        csm.activatePublicRelease();
        bytes32[] memory proof = merkleTree.getProof(0);

        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        vm.deal(nodeOperator, BOND_SIZE / 2);
        vm.prank(nodeOperator);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
        csm.addNodeOperatorETH{ value: (BOND_SIZE / 2) * keysCount }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            proof,
            address(0)
        );
        CSAccounting.BondCurve memory curve = accounting.getBondCurve(0);
        assertEq(curve.points[0], BOND_SIZE / 2);
    }

    function test_addNodeOperator_WhenPublicReleaseWithProof() public {
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        csm.activatePublicRelease();

        bytes32[] memory proof = merkleTree.getProof(0);
        vm.deal(nodeOperator, BOND_SIZE / 2);
        vm.prank(nodeOperator);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator);
        csm.addNodeOperatorETH{ value: (BOND_SIZE / 2) * keysCount }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            proof,
            address(0)
        );
        CSAccounting.BondCurve memory curve = accounting.getBondCurve(0);
        assertEq(curve.points[0], BOND_SIZE / 2);
    }

    function test_addNodeOperator_RevertWhenMoreThanMaxSigningKeysLimit()
        public
    {
        bytes32[] memory proof = merkleTree.getProof(0);

        uint256 keysCount = csm
            .MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE() + 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        vm.deal(nodeOperator, (BOND_SIZE / 2) * keysCount);
        vm.prank(nodeOperator);
        vm.expectRevert(CSModule.MaxSigningKeysCountExceeded.selector);
        csm.addNodeOperatorETH{ value: (BOND_SIZE / 2) * keysCount }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            proof,
            address(0)
        );
    }
}

contract CSMDepositableValidatorsCount is CSMCommon {
    function test_depositableValidatorsCountChanges_OnDeposit() public {
        uint256 noId = createNodeOperator(7);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 7);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 7);
        csm.obtainDepositData(3, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 4);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 4);
    }

    function test_depositableValidatorsCountChanges_OnStuck() public {
        uint256 noId = createNodeOperator(7);
        createNodeOperator(2);
        csm.obtainDepositData(4, "");
        setStuck(noId, 2);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 0);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 2);
        setStuck(noId, 0);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
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
        uint256 nonce = csm.getNonce();
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 7);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(3));
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 3);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_depositableValidatorsCountChanges_OnInitialSlashing() public {
        // 1 key becomes unbonded till withdrawal.
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(1, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 1);
        csm.submitInitialSlashing(noId, 0); // The first key was slashed.
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 0);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 0);
    }

    function test_depositableValidatorsCountChanges_OnWithdrawal() public {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);

        penalize(noId, BOND_SIZE * 3);

        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 0);
        csm.submitWithdrawal(noId, 0, csm.DEPOSIT_SIZE());
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 1);
        csm.submitWithdrawal(noId, 1, csm.DEPOSIT_SIZE());
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 2);
        csm.submitWithdrawal(noId, 2, csm.DEPOSIT_SIZE() - BOND_SIZE); // Large CL balance drop, that doesn't change the unbonded count.
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 2);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 2);
    }

    function test_depositableValidatorsCountChanges_OnReportStealing() public {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            (BOND_SIZE * 3) / 2
        ); // Lock bond to unbond 2 validators.
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 1);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 1);
    }

    function test_depositableValidatorsCountChanges_OnReleaseStealingPenalty()
        public
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE
        ); // Lock bond to unbond 2 validators (there's stealing fine).
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 1);
        csm.cancelELRewardsStealingPenalty(
            noId,
            accounting.getLockedBondInfo(noId).amount
        );
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3); // Stealing fine is applied so
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 3);
    }

    function test_depositableValidatorsCountChanges_OnRemoveUnvetted() public {
        uint256 noId = createNodeOperator(7);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(3));
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        vm.prank(nodeOperator);
        csm.removeKeys(noId, 3, 1); // Removal charge is applied, hence one key is unbonded.
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 6);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 6);
    }
}

contract CSMOnRewardsMinted is CSMCommon {
    address public stakingRouter;

    function setUp() public override {
        super.setUp();
        stakingRouter = nextAddress("STAKING_ROUTER");
        vm.startPrank(admin);
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), stakingRouter);
        vm.stopPrank();
    }

    function test_onRewardsMinted() public {
        uint256 reportShares = 100000;
        uint256 someDustShares = 100;

        stETH.mintShares(address(csm), someDustShares);
        stETH.mintShares(address(csm), reportShares);

        vm.prank(stakingRouter);
        csm.onRewardsMinted(reportShares);

        assertEq(stETH.sharesOf(address(csm)), someDustShares);
        assertEq(stETH.sharesOf(address(feeDistributor)), reportShares);
    }
}

contract CSMRecoverERC20 is CSMCommon {
    function test_recoverERC20() public {
        vm.startPrank(admin);
        csm.grantRole(csm.RECOVERER_ROLE(), stranger);
        vm.stopPrank();

        ERC20Testable token = new ERC20Testable();
        token.mint(address(csm), 1000);

        vm.prank(stranger);
        vm.expectEmit(true, true, true, true, address(csm));
        emit AssetRecovererLib.ERC20Recovered(address(token), stranger, 1000);
        csm.recoverERC20(address(token), 1000);

        assertEq(token.balanceOf(address(csm)), 0);
        assertEq(token.balanceOf(stranger), 1000);
    }

    function test_recoverStETHShares() public {
        vm.startPrank(admin);
        csm.grantRole(csm.RECOVERER_ROLE(), stranger);
        vm.stopPrank();

        uint256 sharesToRecover = stETH.getSharesByPooledEth(1 ether);
        stETH.mintShares(address(csm), sharesToRecover);

        vm.prank(stranger);
        vm.expectEmit(true, true, true, true, address(csm));
        emit AssetRecovererLib.StETHSharesRecovered(stranger, sharesToRecover);
        csm.recoverStETHShares();

        assertEq(stETH.sharesOf(address(csm)), 0);
        assertEq(stETH.sharesOf(stranger), sharesToRecover);
    }
}

contract CSMMisc is CSMCommon {
    function test_updateRefundedValidatorsCount() public {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();
        uint256 refunded = 1;
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.RefundedKeysCountChanged(noId, refunded);
        csm.updateRefundedValidatorsCount(noId, refunded);
        assertEq(csm.getNonce(), nonce + 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.refundedValidatorsCount, refunded);
    }

    function test_getActiveNodeOperatorsCount_OneOperator() public {
        createNodeOperator();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertEq(noCount, 1);
    }

    function test_getActiveNodeOperatorsCount_MultipleOperators() public {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertEq(noCount, 3);
    }

    function test_getNodeOperatorIsActive() public {
        uint256 noId = createNodeOperator();
        bool active = csm.getNodeOperatorIsActive(noId);
        assertTrue(active);
    }

    function test_getNodeOperatorIds() public {
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256 thirdNoId = createNodeOperator();

        uint256[] memory noIds = new uint256[](3);
        noIds[0] = firstNoId;
        noIds[1] = secondNoId;
        noIds[2] = thirdNoId;

        uint256[] memory noIdsActual = new uint256[](5);
        noIdsActual = csm.getNodeOperatorIds(0, 5);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_Offset() public {
        createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256 thirdNoId = createNodeOperator();

        uint256[] memory noIds = new uint256[](2);
        noIds[0] = secondNoId;
        noIds[1] = thirdNoId;

        uint256[] memory noIdsActual = new uint256[](5);
        noIdsActual = csm.getNodeOperatorIds(1, 5);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_OffsetEqualsnNodeOperatorsCount() public {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();

        uint256[] memory noIds = new uint256[](0);

        uint256[] memory noIdsActual = new uint256[](5);
        noIdsActual = csm.getNodeOperatorIds(3, 5);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_OffsetHigherThanNodeOperatorsCount()
        public
    {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();

        uint256[] memory noIds = new uint256[](0);

        uint256[] memory noIdsActual = new uint256[](5);
        noIdsActual = csm.getNodeOperatorIds(4, 5);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_ZeroLimit() public {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();

        uint256[] memory noIds = new uint256[](0);

        uint256[] memory noIdsActual = new uint256[](0);
        noIdsActual = csm.getNodeOperatorIds(0, 0);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_ZeroLimitAndOffsetHigherThanNodeOperatorsCount()
        public
    {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();

        uint256[] memory noIds = new uint256[](0);

        uint256[] memory noIdsActual = new uint256[](0);
        noIdsActual = csm.getNodeOperatorIds(4, 0);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_Limit() public {
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        createNodeOperator();

        uint256[] memory noIds = new uint256[](2);
        noIds[0] = firstNoId;
        noIds[1] = secondNoId;

        uint256[] memory noIdsActual = new uint256[](2);
        noIdsActual = csm.getNodeOperatorIds(0, 2);

        assertEq(noIdsActual, noIds);
    }

    function test_getNodeOperatorIds_LimitAndOffset() public {
        createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256 thirdNoId = createNodeOperator();
        createNodeOperator();

        uint256[] memory noIds = new uint256[](2);
        noIds[0] = secondNoId;
        noIds[1] = thirdNoId;

        uint256[] memory noIdsActual = new uint256[](5);
        noIdsActual = csm.getNodeOperatorIds(1, 2);

        assertEq(noIdsActual, noIds);
    }

    function test_getActiveNodeOperatorsCount_One() public {
        createNodeOperator();

        uint256 activeCount = csm.getActiveNodeOperatorsCount();

        assertEq(activeCount, 1);
    }

    function test_getActiveNodeOperatorsCount_Multiple() public {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();

        uint256 activeCount = csm.getActiveNodeOperatorsCount();

        assertEq(activeCount, 3);
    }

    function test_decreaseOperatorVettedKeys_OneOperator() public {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 5;

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(noId, newVetted);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(newVetted));

        uint256 actualVetted = csm.getNodeOperator(noId).totalVettedKeys;
        assertEq(actualVetted, newVetted);
    }

    function test_decreaseOperatorVettedKeys_MultipleOperators() public {
        uint256 firstNoId = createNodeOperator(10);
        uint256 secondNoId = createNodeOperator(7);
        uint256 thirdNoId = createNodeOperator(15);
        uint256 newVettedFirst = 5;
        uint256 newVettedSecond = 3;

        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(firstNoId, newVettedFirst);
        vm.expectEmit(true, true, true, true, address(csm));
        emit CSModule.VettedSigningKeysCountChanged(
            secondNoId,
            newVettedSecond
        );
        csm.decreaseOperatorVettedKeys(
            UintArr(firstNoId, secondNoId),
            UintArr(newVettedFirst, newVettedSecond)
        );

        uint256 actualVettedFirst = csm
            .getNodeOperator(firstNoId)
            .totalVettedKeys;
        uint256 actualVettedSecond = csm
            .getNodeOperator(secondNoId)
            .totalVettedKeys;
        uint256 actualVettedThird = csm
            .getNodeOperator(thirdNoId)
            .totalVettedKeys;
        assertEq(actualVettedFirst, newVettedFirst);
        assertEq(actualVettedSecond, newVettedSecond);
        assertEq(actualVettedThird, 15);
    }

    function test_decreaseOperatorVettedKeys_RevertWhen_MissingVettedData()
        public
    {
        uint256 firstNoId = createNodeOperator(10);
        uint256 secondNoId = createNodeOperator(7);
        uint256 newVettedFirst = 5;

        vm.expectRevert();
        csm.decreaseOperatorVettedKeys(
            UintArr(firstNoId, secondNoId),
            UintArr(newVettedFirst)
        );
    }

    function test_decreaseOperatorVettedKeys_RevertWhen_NewVettedEqOld()
        public
    {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 10;

        vm.expectRevert(CSModule.InvalidVetKeysPointer.selector);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(newVetted));
    }

    function test_decreaseOperatorVettedKeys_RevertWhen_NewVettedGreaterOld()
        public
    {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 15;

        vm.expectRevert(CSModule.InvalidVetKeysPointer.selector);
        csm.decreaseOperatorVettedKeys(UintArr(noId), UintArr(newVetted));
    }

    function test_decreaseOperatorVettedKeys_RevertWhen_NodeOperatorDoesNotExist()
        public
    {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 15;

        vm.expectRevert(CSModule.NodeOperatorDoesNotExist.selector);
        csm.decreaseOperatorVettedKeys(UintArr(noId + 1), UintArr(newVetted));
    }
}
