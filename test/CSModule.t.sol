// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IStakingModule } from "../src/interfaces/IStakingModule.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSBondLock } from "../src/abstract/CSBondLock.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";
import { Fixtures } from "./helpers/Fixtures.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { CSParametersRegistryMock } from "./helpers/mocks/CSParametersRegistryMock.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { console } from "forge-std/console.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { IAssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { Batch, QueueLib, IQueueLib } from "../src/lib/QueueLib.sol";
import { SigningKeys } from "../src/lib/SigningKeys.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { INOAddresses } from "../src/lib/NOAddresses.sol";
import { InvariantAsserts } from "./helpers/InvariantAsserts.sol";
import { ICSModule, NodeOperator, NodeOperatorManagementProperties, ValidatorWithdrawalInfo } from "../src/interfaces/ICSModule.sol";
import { ICSExitPenalties, ExitPenaltyInfo, MarkedUint248 } from "../src/interfaces/ICSExitPenalties.sol";
import { TransientUintUintMap, TransientUintUintMapLib } from "../src/lib/TransientUintUintMapLib.sol";
import { ExitPenaltiesMock } from "./helpers/mocks/ExitPenaltiesMock.sol";
import { CSAccountingMock } from "./helpers/mocks/CSAccountingMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

contract CSModuleTestable is CSModule {
    using QueueLib for QueueLib.Queue;
    mapping(uint256 => NodeOperator) internal nodeOperators;

    constructor(
        bytes32 moduleType,
        address lidoLocator,
        address parametersRegistry,
        address _accounting,
        address exitPenalties
    )
        CSModule(
            moduleType,
            lidoLocator,
            parametersRegistry,
            _accounting,
            exitPenalties
        )
    {}

    function _enqueueToLegacyQueue(uint256 noId, uint32 count) external {
        _enqueueNodeOperatorKeys(noId, QUEUE_LEGACY_PRIORITY, count);
    }

    function cleanDepositQueueTestable(uint256 maxItems) external {
        TransientUintUintMap queueLookup = TransientUintUintMapLib.create();
        _legacyQueue.clean(nodeOperators, maxItems, queueLookup);
    }
}

abstract contract CSMFixtures is Test, Fixtures, Utilities, InvariantAsserts {
    using Strings for uint256;
    using Strings for uint128;

    struct BatchInfo {
        uint256 nodeOperatorId;
        uint256 count;
    }

    uint256 public constant BOND_SIZE = 2 ether;

    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    CSModuleTestable public csm;
    CSAccountingMock public accounting;
    Stub public feeDistributor;
    CSParametersRegistryMock public parametersRegistry;
    ExitPenaltiesMock public exitPenalties;

    address internal admin;
    address internal stranger;
    address internal strangerNumberTwo;
    address internal nodeOperator;
    address internal testChargePenaltyRecipient;

    struct NodeOperatorSummary {
        uint256 targetLimitMode;
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

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        assertCSMEnqueuedCount(csm);
        assertCSMKeys(csm);
        assertCSMUnusedStorageSlots(csm);
        vm.resumeGasMetering();
    }

    function createNodeOperator() internal returns (uint256) {
        return createNodeOperator(nodeOperator, 1);
    }

    function createNodeOperator(uint256 keysCount) internal returns (uint256) {
        return createNodeOperator(nodeOperator, keysCount);
    }

    function createNodeOperator(
        bool extendedManagerPermissions
    ) internal returns (uint256) {
        return createNodeOperator(nodeOperator, extendedManagerPermissions);
    }

    function createNodeOperator(
        address managerAddress,
        uint256 keysCount
    ) internal returns (uint256 nodeOperatorId) {
        nodeOperatorId = createNodeOperator(managerAddress, false);
        if (keysCount > 0) {
            uploadMoreKeys(nodeOperatorId, keysCount);
        }
    }

    function createNodeOperator(
        address managerAddress,
        uint256 keysCount,
        bytes memory keys,
        bytes memory signatures
    ) internal returns (uint256 nodeOperatorId) {
        nodeOperatorId = createNodeOperator(managerAddress, false);
        uploadMoreKeys(nodeOperatorId, keysCount, keys, signatures);
    }

    function createNodeOperator(
        address managerAddress,
        bool extendedManagerPermissions
    ) internal returns (uint256) {
        vm.prank(csm.getRoleMember(csm.CREATE_NODE_OPERATOR_ROLE(), 0));
        return
            csm.createNodeOperator(
                managerAddress,
                NodeOperatorManagementProperties({
                    managerAddress: address(0),
                    rewardAddress: address(0),
                    extendedManagerPermissions: extendedManagerPermissions
                }),
                address(0)
            );
    }

    function uploadMoreKeys(
        uint256 noId,
        uint256 keysCount,
        bytes memory keys,
        bytes memory signatures
    ) internal {
        uint256 amount = accounting.getRequiredBondForNextKeys(noId, keysCount);
        address managerAddress = csm.getNodeOperator(noId).managerAddress;
        vm.deal(managerAddress, amount);
        vm.prank(managerAddress);
        csm.addValidatorKeysETH{ value: amount }(
            managerAddress,
            noId,
            keysCount,
            keys,
            signatures
        );
    }

    function uploadMoreKeys(uint256 noId, uint256 keysCount) internal {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uploadMoreKeys(noId, keysCount, keys, signatures);
    }

    function unvetKeys(uint256 noId, uint256 to) internal {
        csm.decreaseVettedSigningKeysCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(to)))
        );
    }

    function setExited(uint256 noId, uint256 to) internal {
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(to)))
        );
    }

    function withdrawKey(uint256 noId, uint256 /* keyIndex */) internal {
        ValidatorWithdrawalInfo[]
            memory withdrawalsInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalsInfo[0] = ValidatorWithdrawalInfo(
            noId,
            0,
            csm.DEPOSIT_SIZE()
        );
        csm.submitWithdrawals(withdrawalsInfo);
    }

    // Checks that the queue is in the expected state starting from its head.
    function _assertQueueState(
        uint256 priority,
        BatchInfo[] memory exp
    ) internal view {
        (uint128 curr, ) = csm.depositQueuePointers(priority); // queue.head

        for (uint256 i = 0; i < exp.length; ++i) {
            BatchInfo memory b = exp[i];
            Batch item = csm.depositQueueItem(priority, curr);

            assertFalse(
                item.isNil(),
                string.concat(
                    "unexpected end of queue with priority=",
                    priority.toString(),
                    " at index ",
                    i.toString()
                )
            );

            curr = item.next();
            uint256 noId = item.noId();
            uint256 keysInBatch = item.keys();

            assertEq(
                noId,
                b.nodeOperatorId,
                string.concat(
                    "unexpected `nodeOperatorId` at queue with priority=",
                    priority.toString(),
                    " at index ",
                    i.toString()
                )
            );
            assertEq(
                keysInBatch,
                b.count,
                string.concat(
                    "unexpected `count` at queue with priority=",
                    priority.toString(),
                    " at index ",
                    i.toString()
                )
            );
        }

        assertTrue(
            csm.depositQueueItem(priority, curr).isNil(),
            string.concat(
                "unexpected tail of queue with priority=",
                priority.toString()
            )
        );
    }

    function _assertQueueIsEmpty() internal view {
        for (uint256 p = 0; p <= csm.QUEUE_LOWEST_PRIORITY(); ++p) {
            (uint128 curr, ) = csm.depositQueuePointers(p); // queue.head
            assertTrue(
                csm.depositQueueItem(p, curr).isNil(),
                string.concat(
                    "queue with priority=",
                    p.toString(),
                    " is not empty"
                )
            );
        }
    }

    function _printQueue() internal view {
        for (uint256 p = 0; p <= csm.QUEUE_LOWEST_PRIORITY(); ++p) {
            (uint128 curr, ) = csm.depositQueuePointers(p);

            for (;;) {
                Batch item = csm.depositQueueItem(p, curr);
                if (item.isNil()) {
                    break;
                }

                uint256 noId = item.noId();
                uint256 keysInBatch = item.keys();

                console.log(
                    string.concat(
                        "queue.priority=",
                        p.toString(),
                        "[",
                        curr.toString(),
                        "]={noId:",
                        noId.toString(),
                        ",count:",
                        keysInBatch.toString(),
                        "}"
                    )
                );

                curr = item.next();
            }
        }
    }

    function _isQueueDirty(uint256 maxItems) internal returns (bool) {
        // XXX: Mimic a **eth_call** to avoid state changes.
        uint256 snapshot = vm.snapshotState();
        (uint256 toRemove, ) = csm.cleanDepositQueue(maxItems);
        vm.revertToState(snapshot);
        return toRemove > 0;
    }

    function getNodeOperatorSummary(
        uint256 noId
    ) public view returns (NodeOperatorSummary memory) {
        (
            uint256 targetLimitMode,
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

    // amount can not be lower than EL_REWARDS_STEALING_ADDITIONAL_FINE
    function penalize(uint256 noId, uint256 amount) public {
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount -
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );
        csm.settleELRewardsStealingPenalty(UintArr(noId));
    }
}

contract CSMCommon is CSMFixtures {
    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        strangerNumberTwo = nextAddress("STRANGER_TWO");
        admin = nextAddress("ADMIN");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, , ) = initLido();

        feeDistributor = new Stub();
        parametersRegistry = new CSParametersRegistryMock();
        exitPenalties = new ExitPenaltiesMock();

        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: BOND_SIZE
        });
        accounting = new CSAccountingMock(
            BOND_SIZE,
            address(wstETH),
            address(stETH)
        );
        accounting.setFeeDistributor(address(feeDistributor));

        csm = new CSModuleTestable({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        accounting.setCSM(address(csm));

        _enableInitializers(address(csm));
        csm.initialize({ admin: admin });

        vm.startPrank(admin);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), address(this));
        csm.grantRole(csm.PAUSE_ROLE(), address(this));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
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
        vm.stopPrank();

        csm.resume();
    }
}

contract CSMCommonNoRoles is CSMFixtures {
    address internal actor;

    function setUp() public {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        actor = nextAddress("ACTOR");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");

        (locator, wstETH, stETH, , ) = initLido();

        feeDistributor = new Stub();
        parametersRegistry = new CSParametersRegistryMock();
        exitPenalties = new ExitPenaltiesMock();
        ICSBondCurve.BondCurveIntervalInput[]
            memory curve = new ICSBondCurve.BondCurveIntervalInput[](1);
        curve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: BOND_SIZE
        });
        accounting = new CSAccountingMock(
            BOND_SIZE,
            address(wstETH),
            address(stETH)
        );
        accounting.setFeeDistributor(address(feeDistributor));

        csm = new CSModuleTestable({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        accounting.setCSM(address(csm));

        _enableInitializers(address(csm));
        csm.initialize({ admin: admin });

        vm.startPrank(admin);
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), admin);
        csm.grantRole(csm.RESUME_ROLE(), admin);
        csm.grantRole(csm.VERIFIER_ROLE(), address(this));
        csm.resume();
        vm.stopPrank();
    }
}

contract CsmFuzz is CSMCommon {
    function testFuzz_CreateNodeOperator(
        uint256 keysCount
    ) public assertInvariants {
        keysCount = bound(keysCount, 1, 99);
        createNodeOperator(keysCount);
        assertEq(csm.getNodeOperatorsCount(), 1);
        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.totalAddedKeys, keysCount);
    }

    function testFuzz_CreateMultipleNodeOperators(
        uint256 count
    ) public assertInvariants {
        count = bound(count, 1, 100);
        for (uint256 i = 0; i < count; i++) {
            createNodeOperator(1);
        }
        assertEq(csm.getNodeOperatorsCount(), count);
    }

    function testFuzz_UploadKeys(uint256 keysCount) public assertInvariants {
        keysCount = bound(keysCount, 1, 99);
        createNodeOperator(1);
        uploadMoreKeys(0, keysCount);
        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.totalAddedKeys, keysCount + 1);
    }
}

contract CsmInitialize is CSMCommon {
    using stdStorage for StdStorage;

    function test_constructor() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });
        assertEq(csm.getType(), "community-staking-module");
        assertEq(address(csm.LIDO_LOCATOR()), address(locator));
        assertEq(
            address(csm.PARAMETERS_REGISTRY()),
            address(parametersRegistry)
        );
        assertEq(address(csm.ACCOUNTING()), address(accounting));
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(csm.EXIT_PENALTIES()), address(exitPenalties));
    }

    function test_constructor_RevertWhen_ZeroLocator() public {
        vm.expectRevert(ICSModule.ZeroLocatorAddress.selector);
        new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(0),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });
    }

    function test_constructor_RevertWhen_ZeroParametersRegistryAddress()
        public
    {
        vm.expectRevert(ICSModule.ZeroParametersRegistryAddress.selector);
        new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(0),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });
    }

    function test_constructor_RevertWhen_ZeroAccountingAddress() public {
        vm.expectRevert(ICSModule.ZeroAccountingAddress.selector);
        new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(0),
            exitPenalties: address(exitPenalties)
        });
    }

    function test_constructor_RevertWhen_ZeroExitPenaltiesAddress() public {
        vm.expectRevert(ICSModule.ZeroExitPenaltiesAddress.selector);
        new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(0)
        });
    }

    function test_constructor_RevertWhen_InitOnImpl() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        csm.initialize({ admin: address(this) });
    }

    function test_initialize() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        _enableInitializers(address(csm));
        csm.initialize({ admin: address(this) });
        assertTrue(csm.hasRole(csm.DEFAULT_ADMIN_ROLE(), address(this)));
        assertEq(csm.getRoleMemberCount(csm.DEFAULT_ADMIN_ROLE()), 1);
        assertTrue(csm.isPaused());
        assertEq(csm.getInitializedVersion(), 2);
    }

    function test_initialize_RevertWhen_ZeroAdminAddress() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });

        _enableInitializers(address(csm));
        vm.expectRevert(ICSModule.ZeroAdminAddress.selector);
        csm.initialize({ admin: address(0) });
    }

    function test_finalizeUpgradeV2() public {
        CSModule csm = new CSModule({
            moduleType: "community-staking-module",
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });
        _enableInitializers(address(csm));

        csm.finalizeUpgradeV2();
        assertEq(csm.getInitializedVersion(), 2);
    }
}

contract CSMPauseTest is CSMCommon {
    function test_notPausedByDefault() public view {
        assertFalse(csm.isPaused());
    }

    function test_pauseFor() public {
        csm.pauseFor(1 days);
        assertTrue(csm.isPaused());
        assertEq(csm.getResumeSinceTimestamp(), block.timestamp + 1 days);
    }

    function test_pauseFor_indefinitely() public {
        csm.pauseFor(type(uint256).max);
        assertTrue(csm.isPaused());
        assertEq(csm.getResumeSinceTimestamp(), type(uint256).max);
    }

    function test_pauseFor_RevertWhen_ZeroPauseDuration() public {
        vm.expectRevert(PausableUntil.ZeroPauseDuration.selector);
        csm.pauseFor(0);
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

contract CSMPauseAffectingTest is CSMCommon {
    function test_createNodeOperator_RevertWhen_Paused() public {
        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
    }

    function test_addValidatorKeysETH_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysETH(
            nodeOperator,
            noId,
            keysCount,
            keys,
            signatures
        );
    }

    function test_addValidatorKeysStETH_RevertWhen_Paused() public {
        uint256 noId = createNodeOperator();
        uint16 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        csm.pauseFor(1 days);
        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        csm.addValidatorKeysStETH(
            nodeOperator,
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
            nodeOperator,
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

contract CSMCreateNodeOperator is CSMCommon {
    function test_createNodeOperator() public assertInvariants {
        uint256 nonce = csm.getNonce();
        vm.expectEmit(address(csm));
        emit ICSModule.NodeOperatorAdded(0, nodeOperator, nodeOperator, false);

        uint256 nodeOperatorId = csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
        assertEq(csm.getNodeOperatorsCount(), 1);
        assertEq(csm.getNonce(), nonce + 1);
        assertEq(nodeOperatorId, 0);
    }

    function test_createNodeOperator_withCustomAddresses()
        public
        assertInvariants
    {
        address manager = address(154);
        address reward = address(42);

        vm.expectEmit(address(csm));
        emit ICSModule.NodeOperatorAdded(0, manager, reward, false);
        csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: reward,
                extendedManagerPermissions: false
            }),
            address(0)
        );

        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, reward);
        assertEq(no.extendedManagerPermissions, false);
    }

    function test_createNodeOperator_withExtendedManagerPermissions()
        public
        assertInvariants
    {
        address manager = address(154);
        address reward = address(42);

        vm.expectEmit(address(csm));
        emit ICSModule.NodeOperatorAdded(0, manager, reward, true);
        csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: reward,
                extendedManagerPermissions: true
            }),
            address(0)
        );

        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.managerAddress, manager);
        assertEq(no.rewardAddress, reward);
        assertEq(no.extendedManagerPermissions, true);
    }

    function test_createNodeOperator_withReferrer() public assertInvariants {
        {
            vm.expectEmit(address(csm));
            emit ICSModule.NodeOperatorAdded(
                0,
                nodeOperator,
                nodeOperator,
                false
            );
            vm.expectEmit(address(csm));
            emit ICSModule.ReferrerSet(0, address(154));
        }
        csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(154)
        );
    }

    function test_createNodeOperator_RevertWhen_ZeroSenderAddress() public {
        vm.expectRevert(ICSModule.ZeroSenderAddress.selector);
        csm.createNodeOperator(
            address(0),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
    }

    function test_createNodeOperator_multipleInSameTx() public {
        address manager = nextAddress("MANAGER");
        address referrer = nextAddress("REFERRER");
        NodeOperatorManagementProperties
            memory props = NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: address(0),
                extendedManagerPermissions: false
            });
        uint256 nonceBefore = csm.getNonce();
        uint256 countBefore = csm.getNodeOperatorsCount();

        // Act: create two node operators in the same transaction
        uint256 id1 = csm.createNodeOperator(manager, props, referrer);
        uint256 id2 = csm.createNodeOperator(manager, props, referrer);

        // Assert: both created, ids are sequential, nonce incremented twice
        assertEq(id1, countBefore);
        assertEq(id2, countBefore + 1);
        assertEq(csm.getNodeOperatorsCount(), countBefore + 2);
        assertEq(csm.getNonce(), nonceBefore + 2);
        // Check events and referrer
        NodeOperator memory no1 = csm.getNodeOperator(id1);
        assertEq(no1.managerAddress, manager);
        NodeOperator memory no2 = csm.getNodeOperator(id2);
        assertEq(no2.managerAddress, manager);
    }
}

contract CSMAddValidatorKeys is CSMCommon {
    function test_AddValidatorKeysWstETH()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 nonce = csm.getNonce();
        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 1);
        }
        csm.addValidatorKeysWstETH(
            nodeOperator,
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

    function test_AddValidatorKeysWstETH_keysLimit_withdrawnKeys()
        public
        assertInvariants
        brutalizeMemory
    {
        parametersRegistry.setKeysLimit(0, 1);

        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        withdrawKey(noId, 0);

        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysWstETH(
            nodeOperator,
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
    }

    function test_AddValidatorKeysWstETH_withTargetLimitSet()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();

        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 0
        });

        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysWstETH(
            nodeOperator,
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
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.depositableValidatorsCount, 0);
    }

    function test_AddValidatorKeysWstETH_createNodeOperatorRole()
        public
        assertInvariants
        brutalizeMemory
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        vm.prank(stranger);
        uint256 noId = csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        vm.stopPrank();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 nonce = csm.getNonce();

        vm.prank(stranger);
        csm.addValidatorKeysWstETH(
            nodeOperator,
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

    function test_AddValidatorKeysWstETH_createNodeOperatorRole_MultipleOperators()
        public
        assertInvariants
        brutalizeMemory
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        uint256[] memory ids = new uint256[](3);
        for (uint256 i; i < ids.length; i++) {
            vm.prank(stranger);
            ids[i] = csm.createNodeOperator(
                nodeOperator,
                NodeOperatorManagementProperties({
                    managerAddress: address(0),
                    rewardAddress: address(0),
                    extendedManagerPermissions: false
                }),
                address(0)
            );
        }
        shuffle(ids);

        for (uint256 i; i < ids.length; i++) {
            uint256 toWrap = BOND_SIZE + 2 wei;
            vm.deal(nodeOperator, toWrap);
            vm.startPrank(nodeOperator);
            stETH.submit{ value: toWrap }(address(0));
            stETH.approve(address(wstETH), UINT256_MAX);
            wstETH.wrap(toWrap);
            vm.stopPrank();
            (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
            uint256 nonce = csm.getNonce();

            vm.prank(stranger);
            csm.addValidatorKeysWstETH(
                nodeOperator,
                ids[i],
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
    }

    function test_AddValidatorKeysWstETH_withPermit()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        uint256 wstETHAmount = wstETH.wrap(toWrap);
        uint256 nonce = csm.getNonce();
        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysWstETH(
            nodeOperator,
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

    function test_AddValidatorKeysStETH()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 1);
        }
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysStETH_keysLimit_withdrawnKeys()
        public
        assertInvariants
        brutalizeMemory
    {
        parametersRegistry.setKeysLimit(0, 1);

        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        withdrawKey(noId, 0);

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysStETH_withTargetLimitSet()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();

        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 0
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
        assertEq(csm.getNonce(), nonce + 1);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.depositableValidatorsCount, 0);
    }

    function test_AddValidatorKeysStETH_createNodeOperatorRole()
        public
        assertInvariants
        brutalizeMemory
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        vm.prank(stranger);
        uint256 noId = csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        uint256 nonce = csm.getNonce();

        vm.prank(stranger);
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysStETH_createNodeOperatorRole_MultipleOperators()
        public
        assertInvariants
        brutalizeMemory
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        uint256[] memory ids = new uint256[](3);
        for (uint256 i; i < ids.length; i++) {
            vm.prank(stranger);
            ids[i] = csm.createNodeOperator(
                nodeOperator,
                NodeOperatorManagementProperties({
                    managerAddress: address(0),
                    rewardAddress: address(0),
                    extendedManagerPermissions: false
                }),
                address(0)
            );
        }
        shuffle(ids);

        for (uint256 i; i < ids.length; i++) {
            (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
            vm.deal(nodeOperator, BOND_SIZE + 1 wei);
            vm.prank(nodeOperator);
            stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
            uint256 nonce = csm.getNonce();

            vm.prank(stranger);
            csm.addValidatorKeysStETH(
                nodeOperator,
                ids[i],
                1,
                keys,
                signatures,
                ICSAccounting.PermitInput({
                    value: BOND_SIZE,
                    deadline: 0,
                    v: 0,
                    r: 0,
                    s: 0
                })
            );
            assertEq(csm.getNonce(), nonce + 1);
        }
    }

    function test_AddValidatorKeysStETH_withPermit()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        vm.prank(nodeOperator);
        stETH.submit{ value: required }(address(0));
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        vm.prank(nodeOperator);
        csm.addValidatorKeysStETH(
            nodeOperator,
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

    function test_AddValidatorKeysETH()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        uint256 nonce = csm.getNonce();

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 1);
        }
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysETH_keysLimit_withdrawnKeys()
        public
        assertInvariants
        brutalizeMemory
    {
        parametersRegistry.setKeysLimit(0, 1);

        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");
        withdrawKey(noId, 0);

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);

        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );
    }

    function test_AddValidatorKeysETH_withTargetLimitSet()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();

        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 0
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);
        uint256 nonce = csm.getNonce();

        vm.prank(nodeOperator);
        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );
        assertEq(csm.getNonce(), nonce + 1);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.depositableValidatorsCount, 0);
    }

    function test_AddValidatorKeysETH_createNodeOperatorRole_MultipleOperators()
        public
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        uint256[] memory ids = new uint256[](3);
        for (uint256 i; i < ids.length; i++) {
            vm.prank(stranger);
            ids[i] = csm.createNodeOperator(
                stranger,
                NodeOperatorManagementProperties({
                    managerAddress: address(0),
                    rewardAddress: address(0),
                    extendedManagerPermissions: false
                }),
                address(0)
            );
        }
        shuffle(ids);

        for (uint256 i; i < ids.length; i++) {
            (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
            uint256 required = accounting.getRequiredBondForNextKeys(ids[i], 1);
            vm.deal(stranger, required);
            uint256 nonce = csm.getNonce();

            vm.prank(stranger);
            csm.addValidatorKeysETH{ value: required }(
                nodeOperator,
                ids[i],
                1,
                keys,
                signatures
            );
            assertEq(csm.getNonce(), nonce + 1);
        }
    }

    function test_AddValidatorKeysETH_withMoreEthThanRequired()
        public
        assertInvariants
        brutalizeMemory
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        uint256 deposit = required + 1 ether;
        vm.deal(nodeOperator, deposit);
        uint256 nonce = csm.getNonce();

        vm.prank(nodeOperator);
        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyAdded(noId, keys);
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
        }
        csm.addValidatorKeysETH{ value: deposit }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_AddValidatorKeysETH_RevertWhenCalledFromAnotherExtension()
        public
        assertInvariants
    {
        address extensionOne = nextAddress("EXTENSION_ONE");
        address extensionTwo = nextAddress("EXTENSION_TWO");

        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), extensionOne);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), extensionTwo);

        vm.prank(extensionOne);
        uint256 noId = csm.createNodeOperator({
            from: nodeOperator,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: nodeOperator,
                rewardAddress: nodeOperator,
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 required = accounting.getRequiredBondForNextKeys(noId, 1);
        vm.deal(extensionTwo, required);

        {
            vm.expectRevert(ICSModule.CannotAddKeys.selector);

            vm.prank(extensionTwo);
            csm.addValidatorKeysETH{ value: required }(
                nodeOperator,
                noId,
                1,
                keys,
                signatures
            );
        }
    }

    function test_AddValidatorKeysStETH_RevertWhenCalledFromAnotherExtension()
        public
        assertInvariants
    {
        address extensionOne = nextAddress("EXTENSION_ONE");
        address extensionTwo = nextAddress("EXTENSION_TWO");

        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), extensionOne);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), extensionTwo);

        vm.prank(extensionOne);
        uint256 noId = csm.createNodeOperator({
            from: nodeOperator,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: nodeOperator,
                rewardAddress: nodeOperator,
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        {
            vm.expectRevert(ICSModule.CannotAddKeys.selector);

            vm.prank(extensionTwo);
            csm.addValidatorKeysStETH(
                nodeOperator,
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
        }
    }

    function test_AddValidatorKeysWstETH_RevertWhenCalledFromAnotherExtension()
        public
        assertInvariants
    {
        address extensionOne = nextAddress("EXTENSION_ONE");
        address extensionTwo = nextAddress("EXTENSION_TWO");

        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), extensionOne);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), extensionTwo);

        vm.prank(extensionOne);
        uint256 noId = csm.createNodeOperator({
            from: nodeOperator,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: nodeOperator,
                rewardAddress: nodeOperator,
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        {
            vm.expectRevert(ICSModule.CannotAddKeys.selector);

            vm.prank(extensionTwo);
            csm.addValidatorKeysWstETH(
                nodeOperator,
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
        }
    }

    function test_AddValidatorKeysETH_RevertWhenCalledTwice()
        public
        assertInvariants
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        vm.prank(stranger);
        uint256 noId = csm.createNodeOperator({
            from: nodeOperator,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: nodeOperator,
                rewardAddress: nodeOperator,
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 required = accounting.getRequiredBondForNextKeys(noId, 1);
        vm.deal(stranger, required);

        vm.prank(stranger);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );

        {
            vm.expectRevert(ICSModule.CannotAddKeys.selector);

            vm.prank(stranger);
            csm.addValidatorKeysETH(nodeOperator, noId, 1, keys, signatures);
        }
    }

    function test_AddValidatorKeysStETH_RevertWhenCalledTwice()
        public
        assertInvariants
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        vm.prank(stranger);
        uint256 noId = csm.createNodeOperator({
            from: nodeOperator,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: nodeOperator,
                rewardAddress: nodeOperator,
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 required = accounting.getRequiredBondForNextKeys(noId, 1);
        uint256 toWrap = required + 1 wei;
        vm.deal(stranger, toWrap);

        vm.prank(stranger);
        stETH.submit{ value: toWrap }(address(0));

        vm.prank(stranger);
        csm.addValidatorKeysStETH(
            nodeOperator,
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

        {
            vm.expectRevert(ICSModule.CannotAddKeys.selector);

            vm.prank(stranger);
            csm.addValidatorKeysStETH(
                nodeOperator,
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
        }
    }

    function test_AddValidatorKeysWstETH_RevertWhenCalledTwice()
        public
        assertInvariants
    {
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);

        vm.prank(stranger);
        uint256 noId = csm.createNodeOperator({
            from: nodeOperator,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: nodeOperator,
                rewardAddress: nodeOperator,
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);
        uint256 required = accounting.getRequiredBondForNextKeys(noId, 1);
        uint256 toWrap = required + 1 wei;
        vm.deal(stranger, toWrap);

        vm.startPrank(stranger);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        vm.stopPrank();

        vm.prank(stranger);
        csm.addValidatorKeysWstETH(
            nodeOperator,
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

        {
            vm.expectRevert(ICSModule.CannotAddKeys.selector);

            vm.prank(stranger);
            csm.addValidatorKeysWstETH(
                nodeOperator,
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
        }
    }
}

contract CSMAddValidatorKeysNegative is CSMCommon {
    function beforeTestSetup(
        bytes4 /* testSelector */
    ) public pure returns (bytes[] memory beforeTestCalldata) {
        beforeTestCalldata = new bytes[](1);
        beforeTestCalldata[0] = abi.encodePacked(this.beforeEach.selector);
    }

    function beforeEach() external {
        createNodeOperator();
    }

    function test_AddValidatorKeysETH_RevertWhen_SenderIsNotEligible() public {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(stranger, required);
        vm.expectRevert(ICSModule.SenderIsNotEligible.selector);
        vm.prank(stranger);
        csm.addValidatorKeysETH{ value: required }(
            stranger,
            noId,
            1,
            new bytes(0),
            new bytes(0)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_CannotAddKeys() public {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(stranger, required);
        vm.startPrank(admin);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);
        vm.stopPrank();

        vm.expectRevert(ICSModule.CannotAddKeys.selector);
        vm.prank(stranger);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            1,
            new bytes(0),
            new bytes(0)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_NoKeys()
        public
        assertInvariants
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint256 required = accounting.getRequiredBondForNextKeys(0, 0);
        vm.deal(nodeOperator, required);
        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            0,
            new bytes(0),
            new bytes(0)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_KeysAndSigsLengthMismatch()
        public
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint16 keysCount = 1;
        (bytes memory keys, ) = keysSignatures(keysCount);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            keysCount,
            keys,
            new bytes(0)
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_ZeroKey()
        public
        assertInvariants
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint16 keysCount = 1;
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            keysCount,
            keys,
            signatures
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_KeysLimitExceeded()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required);

        parametersRegistry.setKeysLimit(0, 1);

        vm.expectRevert(ICSModule.KeysLimitExceeded.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );
    }

    function test_AddValidatorKeysStETH_RevertWhen_SenderIsNotEligible()
        public
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(ICSModule.SenderIsNotEligible.selector);
        vm.prank(stranger);
        csm.addValidatorKeysStETH(
            stranger,
            noId,
            1,
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

    function test_AddValidatorKeysStETH_RevertWhen_CannotAddKeys() public {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.prank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));
        vm.startPrank(admin);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);
        vm.stopPrank();

        vm.expectRevert(ICSModule.CannotAddKeys.selector);
        vm.prank(stranger);
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            1,
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

    function test_AddValidatorKeysStETH_RevertWhen_NoKeys()
        public
        assertInvariants
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addValidatorKeysStETH(
            nodeOperator,
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
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint16 keysCount = 1;
        (bytes memory keys, ) = keysSignatures(keysCount);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            keysCount,
            keys,
            new bytes(0),
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysStETH_RevertWhen_ZeroKey()
        public
        assertInvariants
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint16 keysCount = 1;
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            keysCount,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysETH_RevertWhen_InvalidAmount()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        uint256 required = accounting.getRequiredBondForNextKeys(0, 1);
        vm.deal(nodeOperator, required - 1 ether);

        vm.expectRevert(ICSModule.InvalidAmount.selector);
        vm.prank(nodeOperator);
        csm.addValidatorKeysETH{ value: required - 1 ether }(
            nodeOperator,
            noId,
            1,
            keys,
            signatures
        );
    }

    function test_AddValidatorKeysStETH_RevertWhen_KeysLimitExceeded()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        vm.deal(nodeOperator, BOND_SIZE + 1 wei);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: BOND_SIZE + 1 wei }(address(0));

        parametersRegistry.setKeysLimit(0, 1);

        vm.expectRevert(ICSModule.KeysLimitExceeded.selector);
        csm.addValidatorKeysStETH(
            nodeOperator,
            noId,
            1,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: BOND_SIZE,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_AddValidatorKeysWstETH_RevertWhen_SenderIsNotEligible()
        public
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        vm.stopPrank();

        vm.expectRevert(ICSModule.SenderIsNotEligible.selector);
        vm.prank(stranger);
        csm.addValidatorKeysWstETH(
            stranger,
            noId,
            1,
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

    function test_AddValidatorKeysWstETH_RevertWhen_CannotAddKeys() public {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        vm.stopPrank();
        vm.startPrank(admin);
        csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), stranger);
        vm.stopPrank();

        vm.expectRevert(ICSModule.CannotAddKeys.selector);
        vm.prank(stranger);
        csm.addValidatorKeysWstETH(
            nodeOperator,
            noId,
            1,
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

    function test_AddValidatorKeysWstETH_RevertWhen_NoKeys()
        public
        assertInvariants
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.addValidatorKeysWstETH(
            nodeOperator,
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
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint16 keysCount = 1;
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        (bytes memory keys, ) = keysSignatures(keysCount);

        vm.expectRevert(SigningKeys.InvalidLength.selector);
        csm.addValidatorKeysWstETH(
            nodeOperator,
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

    function test_AddValidatorKeysWstETH_RevertWhen_ZeroKey()
        public
        assertInvariants
    {
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        uint16 keysCount = 1;
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        (
            bytes memory keys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, 0);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        csm.addValidatorKeysWstETH(
            nodeOperator,
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

    function test_AddValidatorKeysWstETH_RevertWhen_KeysLimitExceeded()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        uint256 toWrap = BOND_SIZE + 1 wei;
        vm.deal(nodeOperator, toWrap);
        vm.startPrank(nodeOperator);
        stETH.submit{ value: toWrap }(address(0));
        stETH.approve(address(wstETH), UINT256_MAX);
        wstETH.wrap(toWrap);
        (bytes memory keys, bytes memory signatures) = keysSignatures(1, 1);

        parametersRegistry.setKeysLimit(0, 1);

        vm.expectRevert(ICSModule.KeysLimitExceeded.selector);
        csm.addValidatorKeysWstETH(
            nodeOperator,
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
    }
}

contract CSMObtainDepositData is CSMCommon {
    // TODO: test with near to real values

    function test_obtainDepositData() public assertInvariants {
        uint256 nodeOperatorId = createNodeOperator(1);
        (bytes memory keys, bytes memory signatures) = csm
            .getSigningKeysWithSignatures(nodeOperatorId, 0, 1);

        vm.expectEmit(address(csm));
        emit ICSModule.DepositableSigningKeysCountChanged(nodeOperatorId, 0);
        (bytes memory obtainedKeys, bytes memory obtainedSignatures) = csm
            .obtainDepositData(1, "");
        assertEq(obtainedKeys, keys);
        assertEq(obtainedSignatures, signatures);
    }

    function test_obtainDepositData_MultipleOperators()
        public
        assertInvariants
    {
        uint256 firstId = createNodeOperator(2);
        uint256 secondId = createNodeOperator(3);
        uint256 thirdId = createNodeOperator(1);

        vm.expectEmit(address(csm));
        emit ICSModule.DepositableSigningKeysCountChanged(firstId, 0);
        vm.expectEmit(address(csm));
        emit ICSModule.DepositableSigningKeysCountChanged(secondId, 0);
        vm.expectEmit(address(csm));
        emit ICSModule.DepositableSigningKeysCountChanged(thirdId, 0);
        csm.obtainDepositData(6, "");
    }

    function test_obtainDepositData_counters() public assertInvariants {
        uint256 keysCount = 1;
        uint256 noId = createNodeOperator(keysCount);
        (bytes memory keys, bytes memory signatures) = csm
            .getSigningKeysWithSignatures(noId, 0, keysCount);

        vm.expectEmit(address(csm));
        emit ICSModule.DepositedSigningKeysCountChanged(noId, keysCount);
        (bytes memory depositedKeys, bytes memory depositedSignatures) = csm
            .obtainDepositData(keysCount, "");

        assertEq(keys, depositedKeys);
        assertEq(signatures, depositedSignatures);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.enqueuedCount, 0);
        assertEq(no.totalDepositedKeys, 1);
        assertEq(no.depositableValidatorsCount, 0);
    }

    function test_obtainDepositData_zeroDeposits() public assertInvariants {
        uint256 noId = createNodeOperator();

        (bytes memory publicKeys, bytes memory signatures) = csm
            .obtainDepositData(0, "");

        assertEq(publicKeys.length, 0);
        assertEq(signatures.length, 0);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.enqueuedCount, 1);
        assertEq(no.totalDepositedKeys, 0);
        assertEq(no.depositableValidatorsCount, 1);
    }

    function test_obtainDepositData_unvettedKeys() public assertInvariants {
        createNodeOperator(2);
        uint256 secondNoId = createNodeOperator(1);
        createNodeOperator(3);

        unvetKeys(secondNoId, 0);

        csm.obtainDepositData(5, "");

        (
            ,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        ) = csm.getStakingModuleSummary();
        assertEq(totalDepositedValidators, 5);
        assertEq(depositableValidatorsCount, 0);
    }

    function test_obtainDepositData_counters_WhenLessThanLastBatch()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);

        vm.expectEmit(address(csm));
        emit ICSModule.DepositedSigningKeysCountChanged(noId, 3);
        csm.obtainDepositData(3, "");

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.enqueuedCount, 4);
        assertEq(no.totalDepositedKeys, 3);
        assertEq(no.depositableValidatorsCount, 4);
    }

    function test_obtainDepositData_RevertWhen_NoMoreKeys()
        public
        assertInvariants
    {
        vm.expectRevert(ICSModule.NotEnoughKeys.selector);
        csm.obtainDepositData(1, "");
    }

    function test_obtainDepositData_nonceChanged() public assertInvariants {
        createNodeOperator();
        uint256 nonce = csm.getNonce();

        csm.obtainDepositData(1, "");
        assertEq(csm.getNonce(), nonce + 1);
    }

    function testFuzz_obtainDepositData_MultipleOperators(
        uint256 batchCount,
        uint256 random
    ) public assertInvariants {
        batchCount = bound(batchCount, 1, 20);
        random = bound(random, 1, 20);
        vm.assume(batchCount > random);

        uint256 totalKeys;
        for (uint256 i = 1; i < batchCount + 1; ++i) {
            uint256 keys = i / random + 1;
            createNodeOperator(keys);
            totalKeys += keys;
        }

        csm.obtainDepositData(totalKeys - random, "");

        (
            ,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        ) = csm.getStakingModuleSummary();
        assertEq(totalDepositedValidators, totalKeys - random);
        assertEq(depositableValidatorsCount, random);
    }

    function testFuzz_obtainDepositData_OneOperator(
        uint256 batchCount,
        uint256 random
    ) public assertInvariants {
        batchCount = bound(batchCount, 1, 20);
        random = bound(random, 1, 20);
        vm.assume(batchCount > random);

        uint256 totalKeys = 1;
        createNodeOperator(1);
        for (uint256 i = 1; i < batchCount + 1; ++i) {
            uint256 keys = i / random + 1;
            uploadMoreKeys(0, keys);
            totalKeys += keys;
        }

        csm.obtainDepositData(totalKeys - random, "");

        (
            ,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
        ) = csm.getStakingModuleSummary();
        assertEq(totalDepositedValidators, totalKeys - random);
        assertEq(depositableValidatorsCount, random);

        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.enqueuedCount, random);
        assertEq(no.totalDepositedKeys, totalKeys - random);
        assertEq(no.depositableValidatorsCount, random);
    }
}

contract CsmProposeNodeOperatorManagerAddressChange is CSMCommon {
    function test_proposeNodeOperatorManagerAddressChange() public {
        uint256 noId = createNodeOperator();
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorManagerAddressChangeProposed(
            noId,
            address(0),
            stranger
        );
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorManagerAddressChange_proposeNew() public {
        uint256 noId = createNodeOperator();
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorManagerAddressChangeProposed(
            noId,
            stranger,
            strangerNumberTwo
        );
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, strangerNumberTwo);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorManagerAddressChange(0, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhen_NotManager()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SenderIsNotManagerAddress.selector);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhen_AlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectRevert(INOAddresses.AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorManagerAddressChange_RevertWhen_SameAddressProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SameAddress.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, nodeOperator);
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

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorManagerAddressChanged(
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

    function test_confirmNodeOperatorManagerAddressChange_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.confirmNodeOperatorManagerAddressChange(0);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhen_NotProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SenderIsNotProposedAddress.selector);
        vm.prank(stranger);
        csm.confirmNodeOperatorManagerAddressChange(noId);
    }

    function test_confirmNodeOperatorManagerAddressChange_RevertWhen_OtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorManagerAddressChange(noId, stranger);

        vm.expectRevert(INOAddresses.SenderIsNotProposedAddress.selector);
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

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorRewardAddressChangeProposed(
            noId,
            address(0),
            stranger
        );
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorRewardAddressChange_proposeNew() public {
        uint256 noId = createNodeOperator();
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);

        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorRewardAddressChangeProposed(
            noId,
            stranger,
            strangerNumberTwo
        );
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, strangerNumberTwo);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.proposeNodeOperatorRewardAddressChange(0, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhen_NotRewardAddress()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SenderIsNotRewardAddress.selector);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhen_AlreadyProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(INOAddresses.AlreadyProposed.selector);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
    }

    function test_proposeNodeOperatorRewardAddressChange_RevertWhen_SameAddressProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SameAddress.selector);
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

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorRewardAddressChanged(
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

    function test_confirmNodeOperatorRewardAddressChange_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.confirmNodeOperatorRewardAddressChange(0);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhen_NotProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SenderIsNotProposedAddress.selector);
        vm.prank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);
    }

    function test_confirmNodeOperatorRewardAddressChange_RevertWhen_OtherProposed()
        public
    {
        uint256 noId = createNodeOperator();
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);

        vm.expectRevert(INOAddresses.SenderIsNotProposedAddress.selector);
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

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorManagerAddressChanged(
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

        vm.expectRevert(INOAddresses.SenderIsNotProposedAddress.selector);
        vm.prank(manager);
        csm.confirmNodeOperatorManagerAddressChange(noId);
    }

    function test_resetNodeOperatorManagerAddress_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.resetNodeOperatorManagerAddress(0);
    }

    function test_resetNodeOperatorManagerAddress_RevertWhen_NotRewardAddress()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SenderIsNotRewardAddress.selector);
        vm.prank(stranger);
        csm.resetNodeOperatorManagerAddress(noId);
    }

    function test_resetNodeOperatorManagerAddress_RevertWhen_SameAddress()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(INOAddresses.SameAddress.selector);
        vm.prank(nodeOperator);
        csm.resetNodeOperatorManagerAddress(noId);
    }

    function test_resetNodeOperatorManagerAddress_RevertWhen_ExtendedPermissions()
        public
    {
        uint256 noId = createNodeOperator(true);
        vm.expectRevert(INOAddresses.MethodCallIsNotAllowed.selector);
        vm.prank(nodeOperator);
        csm.resetNodeOperatorManagerAddress(noId);
    }
}

contract CsmChangeNodeOperatorRewardAddress is CSMCommon {
    function test_changeNodeOperatorRewardAddress() public {
        uint256 noId = createNodeOperator(true);

        vm.expectEmit(address(csm));
        emit INOAddresses.NodeOperatorRewardAddressChanged(
            noId,
            nodeOperator,
            stranger
        );
        vm.prank(nodeOperator);
        csm.changeNodeOperatorRewardAddress(noId, stranger);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, stranger);
    }

    function test_changeNodeOperatorRewardAddress_proposedRewardAddressReset()
        public
    {
        uint256 noId = createNodeOperator(true);

        vm.startPrank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, nextAddress());
        csm.changeNodeOperatorRewardAddress(noId, stranger);
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, stranger);
        assertEq(no.proposedRewardAddress, address(0));
    }

    function test_changeNodeOperatorRewardAddress_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        vm.prank(nodeOperator);
        csm.changeNodeOperatorRewardAddress(0, stranger);
    }

    function test_changeNodeOperatorRewardAddress_RevertWhen_ZeroRewardAddress()
        public
    {
        uint256 noId = createNodeOperator(true);
        vm.expectRevert(INOAddresses.ZeroRewardAddress.selector);
        vm.prank(nodeOperator);
        csm.changeNodeOperatorRewardAddress(noId, address(0));
    }

    function test_changeNodeOperatorRewardAddress_RevertWhen_NotManagerAddress()
        public
    {
        uint256 noId = createNodeOperator(true);
        vm.expectRevert(INOAddresses.SenderIsNotManagerAddress.selector);
        vm.prank(stranger);
        csm.changeNodeOperatorRewardAddress(noId, stranger);
    }

    function test_changeNodeOperatorRewardAddress_RevertWhen_SenderIsRewardAddress()
        public
    {
        uint256 noId = createNodeOperator(true);
        vm.prank(nodeOperator);
        csm.proposeNodeOperatorRewardAddressChange(noId, stranger);
        vm.prank(stranger);
        csm.confirmNodeOperatorRewardAddressChange(noId);

        vm.expectRevert(INOAddresses.SenderIsNotManagerAddress.selector);
        vm.prank(stranger);
        csm.changeNodeOperatorRewardAddress(0, stranger);
    }

    function test_changeNodeOperatorRewardAddress_RevertWhen_NoExtendedPermissions()
        public
    {
        uint256 noId = createNodeOperator(false);
        vm.expectRevert(INOAddresses.MethodCallIsNotAllowed.selector);
        vm.prank(nodeOperator);
        csm.changeNodeOperatorRewardAddress(noId, stranger);
    }
}

contract CsmVetKeys is CSMCommon {
    function test_vetKeys_OnUploadKeys() public assertInvariants {
        uint256 noId = createNodeOperator(2);

        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountChanged(noId, 3);
        vm.expectEmit(address(csm));
        emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 1);
        uploadMoreKeys(noId, 1);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 3);

        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 1 });
        _assertQueueState(csm.QUEUE_LOWEST_PRIORITY(), exp);
    }

    function test_vetKeys_Counters() public assertInvariants {
        uint256 noId = createNodeOperator(false);
        uint256 nonce = csm.getNonce();
        uploadMoreKeys(noId, 1);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 1);
        assertEq(no.depositableValidatorsCount, 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_vetKeys_VettedBackViaRemoveKey() public assertInvariants {
        uint256 noId = createNodeOperator(7);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 7);
        unvetKeys({ noId: noId, to: 4 });
        no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 4);

        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountChanged(noId, 5); // 7 - 2 removed at the next step.

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 4, 2); // Remove keys 4 and 5.

        no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, 5);
    }
}

contract CsmQueueOps is CSMCommon {
    uint256 internal constant LOOKUP_DEPTH = 150; // derived from maxDepositsPerBlock

    function test_emptyQueueIsClean() public assertInvariants {
        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanDepositQueue_revertWhen_QueueLookupNoLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        uploadMoreKeys(noId, 1);
        unvetKeys({ noId: noId, to: 2 });

        vm.expectRevert(IQueueLib.QueueLookupNoLimit.selector);
        csm.cleanDepositQueueTestable(0);
    }

    function test_queueIsDirty_WhenHasBatchOfNonDepositableOperator()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        unvetKeys({ noId: noId, to: 0 }); // One of the ways to set `depositableValidatorsCount` to 0.

        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsDirty_WhenHasBatchWithNoDepositableKeys()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        uploadMoreKeys(noId, 1);
        unvetKeys({ noId: noId, to: 2 });
        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertTrue(isDirty, "queue should be dirty");
    }

    function test_queueIsClean_AfterCleanup() public assertInvariants {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        uploadMoreKeys(noId, 1);
        unvetKeys({ noId: noId, to: 2 });

        (uint256 toRemove, ) = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 1, "should remove 1 batch");

        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertFalse(isDirty, "queue should be clean");
    }

    function test_cleanup_emptyQueue() public assertInvariants {
        _assertQueueIsEmpty();

        (uint256 toRemove, ) = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 0, "queue should be clean");
    }

    function test_cleanup_zeroMaxItems() public assertInvariants {
        (uint256 removed, uint256 lastRemovedAtDepth) = csm.cleanDepositQueue(
            0
        );
        assertEq(removed, 0, "should not remove any batches");
        assertEq(lastRemovedAtDepth, 0, "lastRemovedAtDepth should be 0");
    }

    function test_cleanup_WhenMultipleInvalidBatchesInRow()
        public
        assertInvariants
    {
        createNodeOperator({ keysCount: 3 });
        createNodeOperator({ keysCount: 5 });
        createNodeOperator({ keysCount: 1 });

        uploadMoreKeys(1, 2);

        unvetKeys({ noId: 1, to: 2 });
        unvetKeys({ noId: 2, to: 0 });

        uint256 toRemove;

        // Operator noId=1 has 1 dangling batch after unvetting.
        // Operator noId=2 is unvetted.
        (toRemove, ) = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 2, "should remove 2 batch");

        // let's check the state of the queue
        BatchInfo[] memory exp = new BatchInfo[](2);
        exp[0] = BatchInfo({ nodeOperatorId: 0, count: 3 });
        exp[1] = BatchInfo({ nodeOperatorId: 1, count: 5 });
        _assertQueueState(csm.QUEUE_LOWEST_PRIORITY(), exp);

        (toRemove, ) = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 0, "queue should be clean");
    }

    function test_cleanup_WhenAllBatchesInvalid() public assertInvariants {
        createNodeOperator({ keysCount: 2 });
        createNodeOperator({ keysCount: 2 });
        unvetKeys({ noId: 0, to: 0 });
        unvetKeys({ noId: 1, to: 0 });

        (uint256 toRemove, ) = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 2, "should remove all batches");

        _assertQueueIsEmpty();
    }

    function test_cleanup_ToVisitCounterIsCorrect() public {
        createNodeOperator({ keysCount: 3 }); // noId: 0
        createNodeOperator({ keysCount: 5 }); // noId: 1
        createNodeOperator({ keysCount: 1 }); // noId: 2
        createNodeOperator({ keysCount: 4 }); // noId: 3
        createNodeOperator({ keysCount: 2 }); // noId: 4

        uploadMoreKeys({ noId: 1, keysCount: 2 });
        uploadMoreKeys({ noId: 3, keysCount: 2 });
        uploadMoreKeys({ noId: 4, keysCount: 2 });

        unvetKeys({ noId: 1, to: 2 });
        unvetKeys({ noId: 2, to: 0 });

        // Items marked with * below are supposed to be removed.
        // (0;3) (1;5) *(2;1) (3;4) (4;2) *(1;2) (3;2) (4;2)

        uint256 snapshot = vm.snapshotState();

        {
            (uint256 toRemove, uint256 toVisit) = csm.cleanDepositQueue({
                maxItems: 10
            });
            assertEq(toRemove, 2, "toRemove != 2");
            assertEq(toVisit, 6, "toVisit != 6");
        }

        vm.revertToState(snapshot);

        {
            (uint256 toRemove, uint256 toVisit) = csm.cleanDepositQueue({
                maxItems: 6
            });
            assertEq(toRemove, 2, "toRemove != 2");
            assertEq(toVisit, 6, "toVisit != 6");
        }
    }

    function test_updateDepositableValidatorsCount_NothingToDo()
        public
        assertInvariants
    {
        // `updateDepositableValidatorsCount` will be called on creating a node operator and uploading a key.
        uint256 noId = createNodeOperator();

        (, , uint256 depositableBefore) = csm.getStakingModuleSummary();
        uint256 nonceBefore = csm.getNonce();

        vm.recordLogs();
        csm.updateDepositableValidatorsCount(noId);

        (, , uint256 depositableAfter) = csm.getStakingModuleSummary();
        uint256 nonceAfter = csm.getNonce();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(depositableBefore, depositableAfter);
        assertEq(nonceBefore, nonceAfter);
        assertEq(logs.length, 0);
    }

    function test_updateDepositableValidatorsCount_NonExistingOperator()
        public
        assertInvariants
    {
        (, , uint256 depositableBefore) = csm.getStakingModuleSummary();
        uint256 nonceBefore = csm.getNonce();

        vm.recordLogs();
        csm.updateDepositableValidatorsCount(100500);

        (, , uint256 depositableAfter) = csm.getStakingModuleSummary();
        uint256 nonceAfter = csm.getNonce();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(depositableBefore, depositableAfter);
        assertEq(nonceBefore, nonceAfter);
        assertEq(logs.length, 0);
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

        vm.expectEmit(address(csm));
        emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 7);

        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 7
        });
    }

    function test_queueNormalized_WhenWithdrawalChangesDepositable()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        csm.updateTargetValidatorsLimits({
            nodeOperatorId: noId,
            targetLimitMode: 1,
            targetLimit: 2
        });
        csm.obtainDepositData(2, "");
        csm.cleanDepositQueue(1);

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            0,
            csm.DEPOSIT_SIZE()
        );

        vm.expectEmit(address(csm));
        emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 1);
        csm.submitWithdrawals(withdrawalInfo);
    }
}

contract CsmPriorityQueue is CSMCommon {
    uint256 constant LOOKUP_DEPTH = 150;

    uint32 constant PRIORITY_QUEUE = 0;
    uint32 constant MAX_DEPOSITS = 10;

    uint32 REGULAR_QUEUE;
    uint32 LEGACY_QUEUE;

    function setUp() public override {
        super.setUp();
        // Just to make sure we configured defaults properly and check things properly.
        assertNotEq(PRIORITY_QUEUE, csm.QUEUE_LOWEST_PRIORITY());
        assertNotEq(PRIORITY_QUEUE, csm.QUEUE_LEGACY_PRIORITY());
        REGULAR_QUEUE = uint32(csm.QUEUE_LOWEST_PRIORITY());
        LEGACY_QUEUE = uint32(csm.QUEUE_LEGACY_PRIORITY());
    }

    function test_enqueueToPriorityQueue_LessThanMaxDeposits() public {
        uint256 noId = createNodeOperator(0);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 8);

            uploadMoreKeys(noId, 8);
        }

        _assertQueueEmpty(REGULAR_QUEUE);

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(PRIORITY_QUEUE, exp);
    }

    function test_enqueueToPriorityQueue_MoreThanMaxDeposits() public {
        uint256 noId = createNodeOperator(0);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 10);

            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(REGULAR_QUEUE, noId, 5);

            uploadMoreKeys(noId, 15);
        }

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 10 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 5 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_enqueueToPriorityQueue_AlreadyEnqueuedLessThanMaxDeposits()
        public
    {
        uint256 noId = createNodeOperator(0);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uploadMoreKeys(noId, 8);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 2);

            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(REGULAR_QUEUE, noId, 10);

            uploadMoreKeys(noId, 12);
        }

        BatchInfo[] memory exp = new BatchInfo[](2);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 10 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_enqueueToPriorityQueue_AlreadyEnqueuedMoreThanMaxDeposits()
        public
    {
        uint256 noId = createNodeOperator(0);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uploadMoreKeys(noId, 12);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(REGULAR_QUEUE, noId, 12);

            uploadMoreKeys(noId, 12);
        }

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 10 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp = new BatchInfo[](2);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 12 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_enqueueToPriorityQueue_EnqueuedWithDepositedLessThanMaxDeposits()
        public
    {
        uint256 noId = createNodeOperator(0);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uploadMoreKeys(noId, 8);
        csm.obtainDepositData(3, ""); // no.enqueuedCount == 5

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 2);

            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(REGULAR_QUEUE, noId, 10);

            uploadMoreKeys(noId, 12);
        }

        BatchInfo[] memory exp = new BatchInfo[](2);

        // The batch was partially consumed by the obtainDepositData call.
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 5 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 10 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_enqueueToPriorityQueue_EnqueuedWithDepositedMoreThanMaxDeposits()
        public
    {
        uint256 noId = createNodeOperator(0);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uploadMoreKeys(noId, 12);
        csm.obtainDepositData(3, ""); // no.enqueuedCount == 9

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(REGULAR_QUEUE, noId, 12);

            uploadMoreKeys(noId, 12);
        }

        BatchInfo[] memory exp = new BatchInfo[](1);

        // The batch was partially consumed by the obtainDepositData call.
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 7 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp = new BatchInfo[](2);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        exp[1] = BatchInfo({ nodeOperatorId: noId, count: 12 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_migrateToPriorityQueue_FromLegacyQueue() public {
        uint256 noId = createNodeOperator(0);
        csm._enqueueToLegacyQueue(noId, 8);
        uploadMoreKeys(noId, 8);

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(LEGACY_QUEUE, exp);

        _assertQueueEmpty(REGULAR_QUEUE);
        _assertQueueEmpty(PRIORITY_QUEUE);

        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 8);

            csm.migrateToPriorityQueue(noId);
        }

        assertEq(csm.getNodeOperator(noId).enqueuedCount, 8 + 8);

        _assertQueueEmpty(REGULAR_QUEUE);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(LEGACY_QUEUE, exp);
    }

    function test_migrateToPriorityQueue_EnqueuedLessThanMaxDeposits() public {
        uint256 noId = createNodeOperator(0);
        uploadMoreKeys(noId, 8);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uint256 initialNonce = csm.getNonce();

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 8);

            csm.migrateToPriorityQueue(noId);
        }

        assertEq(csm.getNodeOperator(noId).enqueuedCount, 8 + 8);

        uint256 updatedNonce = csm.getNonce();
        assertEq(
            updatedNonce,
            initialNonce + 1,
            "Module nonce should increment by 1"
        );

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_migrateToPriorityQueue_EnqueuedMoreThanMaxDeposits() public {
        uint256 noId = createNodeOperator(0);
        uploadMoreKeys(noId, 15);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 10);

            csm.migrateToPriorityQueue(noId);
        }

        assertEq(csm.getNodeOperator(noId).enqueuedCount, 15 + 10);

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 10 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 15 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_migrateToPriorityQueue_DepositedLessThanMaxDeposits() public {
        uint256 noId = createNodeOperator(0);
        uploadMoreKeys(noId, 15);

        csm.obtainDepositData(8, "");

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectEmit(address(csm));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 2);

            csm.migrateToPriorityQueue(noId);
        }

        assertEq(csm.getNodeOperator(noId).enqueuedCount, 15 - 8 + 2);

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 2 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        // The batch was partially consumed by the obtainDepositData call.
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 7 });
        _assertQueueState(REGULAR_QUEUE, exp);
    }

    function test_migrateToPriorityQueue_RevertsIfDepositedMoreThanMaxDeposits()
        public
    {
        uint256 noId = createNodeOperator(0);
        uploadMoreKeys(noId, 15);

        csm.obtainDepositData(12, "");

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectRevert(ICSModule.PriorityQueueMaxDepositsUsed.selector);
            csm.migrateToPriorityQueue(noId);
        }
    }

    function test_migrateToPriorityQueue_RevertsIfPriorityQueueAlreadyUsedViaMigrate()
        public
    {
        uint256 noId = createNodeOperator(0);
        uploadMoreKeys(noId, 15);

        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        csm.migrateToPriorityQueue(noId);

        {
            vm.expectRevert(ICSModule.PriorityQueueAlreadyUsed.selector);
            csm.migrateToPriorityQueue(noId);
        }
    }

    function test_migrateToPriorityQueue_RevertsIfPriorityQueueAlreadyUsedViaAddKeys()
        public
    {
        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uint256 noId = createNodeOperator(0);
        uploadMoreKeys(noId, 15);

        {
            vm.expectRevert(ICSModule.PriorityQueueAlreadyUsed.selector);
            csm.migrateToPriorityQueue(noId);
        }
    }

    function test_migrateToPriorityQueue_RevertsIfNoPriorityQueue() public {
        vm.expectRevert(ICSModule.NotEligibleForPriorityQueue.selector);
        csm.migrateToPriorityQueue(0);
    }

    function test_migrateToPriorityQueue_RevertsIfEmptyNodeOperator() public {
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectRevert(ICSModule.NoQueuedKeysToMigrate.selector);
            csm.migrateToPriorityQueue(0);
        }
    }

    function test_migrateToPriorityQueue_RevertsIfMaxDepositsUsed() public {
        createNodeOperator(MAX_DEPOSITS + 1);
        csm.obtainDepositData(MAX_DEPOSITS, "");

        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectRevert(ICSModule.PriorityQueueMaxDepositsUsed.selector);
            csm.migrateToPriorityQueue(0);
        }
    }

    function test_queueCleanupWorksAcrossQueues() public {
        _assertQueueEmpty(PRIORITY_QUEUE);
        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        uint256 noId = createNodeOperator(0);

        uploadMoreKeys(noId, 2);
        uploadMoreKeys(noId, 10);
        uploadMoreKeys(noId, 10);
        // [2] [8] | ... | [2] [10]

        unvetKeys({ noId: noId, to: 2 });

        (uint256 toRemove, ) = csm.cleanDepositQueue(LOOKUP_DEPTH);
        assertEq(toRemove, 3, "should remove 3 batches");

        bool isDirty = _isQueueDirty(LOOKUP_DEPTH);
        assertFalse(isDirty, "queue should be clean");
    }

    function test_queueCleanupReturnsCorrectDepth() public {
        uint256 noIdOne = createNodeOperator(0);
        uint256 noIdTwo = createNodeOperator(0);

        _enablePriorityQueue(0, 10);
        uploadMoreKeys(noIdOne, 2);
        uploadMoreKeys(noIdOne, 10);
        uploadMoreKeys(noIdOne, 10);

        _enablePriorityQueue(1, 10);
        uploadMoreKeys(noIdTwo, 2);
        uploadMoreKeys(noIdTwo, 8);
        uploadMoreKeys(noIdTwo, 2);

        unvetKeys({ noId: noIdTwo, to: 2 });

        // [0,2] [0,8] | [1,2] [1,8] | ... | [0,2] [0,10] [1,2]
        //     1     2       3     4             5      6     7
        //                         ^                          ^ removed

        uint256 snapshot;

        {
            snapshot = vm.snapshotState();
            (uint256 toRemove, uint256 lastRemovedAtDepth) = csm
                .cleanDepositQueue(3);
            vm.revertToState(snapshot);
            assertEq(toRemove, 0, "should remove 0 batch(es)");
            assertEq(lastRemovedAtDepth, 0, "the depth should be 0");
        }

        {
            snapshot = vm.snapshotState();
            (uint256 toRemove, uint256 lastRemovedAtDepth) = csm
                .cleanDepositQueue(4);
            vm.revertToState(snapshot);
            assertEq(toRemove, 1, "should remove 1 batch(es)");
            assertEq(lastRemovedAtDepth, 4, "the depth should be 4");
        }

        {
            snapshot = vm.snapshotState();
            (uint256 toRemove, uint256 lastRemovedAtDepth) = csm
                .cleanDepositQueue(7);
            vm.revertToState(snapshot);
            assertEq(toRemove, 2, "should remove 2 batch(es)");
            assertEq(lastRemovedAtDepth, 7, "the depth should be 7");
        }

        {
            snapshot = vm.snapshotState();
            (uint256 toRemove, uint256 lastRemovedAtDepth) = csm
                .cleanDepositQueue(100_500);
            vm.revertToState(snapshot);
            assertEq(toRemove, 2, "should remove 2 batch(es)");
            assertEq(lastRemovedAtDepth, 7, "the depth should be 7");
        }
    }

    function test_queueCleanupInvalidBatchesAfterMigrationToPriorityQueue()
        public
    {
        createNodeOperator({ keysCount: 12 });
        _enablePriorityQueue(0, 12);
        csm.migrateToPriorityQueue(0);
        csm.cleanDepositQueue({ maxItems: 2 });
        assertEq(csm.getNodeOperator(0).enqueuedCount, 12);
    }

    function test_obtainDepositDataAfterMigrationSkipsInvalidBatches() public {
        createNodeOperator(10);
        createNodeOperator(10);

        _enablePriorityQueue(0, 8);
        csm.migrateToPriorityQueue(0);

        csm.obtainDepositData(20, "");
        assertEq(csm.getNodeOperator(0).enqueuedCount, 0);
        assertEq(csm.getNodeOperator(1).enqueuedCount, 0);
    }

    function _enablePriorityQueue(
        uint32 priority,
        uint32 maxDeposits
    ) internal {
        parametersRegistry.setQueueConfig({
            curveId: 0,
            priority: priority,
            maxDeposits: maxDeposits
        });
    }

    function _assertQueueEmpty(uint32 priority) private view {
        _assertQueueState(priority, new BatchInfo[](0));
    }
}

contract CsmDecreaseVettedSigningKeysCount is CSMCommon {
    function test_decreaseVettedSigningKeysCount_counters()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(3);
        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountChanged(noId, 1);
        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountDecreased(noId);
        unvetKeys({ noId: noId, to: 1 });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(csm.getNonce(), nonce + 1);
        assertEq(no.totalVettedKeys, 1);
        assertEq(no.depositableValidatorsCount, 1);
    }

    function test_decreaseVettedSigningKeysCount_MultipleOperators()
        public
        assertInvariants
    {
        uint256 firstNoId = createNodeOperator(10);
        uint256 secondNoId = createNodeOperator(7);
        uint256 thirdNoId = createNodeOperator(15);
        uint256 newVettedFirst = 5;
        uint256 newVettedSecond = 3;

        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountChanged(firstNoId, newVettedFirst);
        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountDecreased(firstNoId);

        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountChanged(
            secondNoId,
            newVettedSecond
        );
        vm.expectEmit(address(csm));
        emit ICSModule.VettedSigningKeysCountDecreased(secondNoId);

        csm.decreaseVettedSigningKeysCount(
            bytes.concat(bytes8(uint64(firstNoId)), bytes8(uint64(secondNoId))),
            bytes.concat(
                bytes16(uint128(newVettedFirst)),
                bytes16(uint128(newVettedSecond))
            )
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

    function test_decreaseVettedSigningKeysCount_RevertWhen_MissingVettedData()
        public
    {
        uint256 firstNoId = createNodeOperator(10);
        uint256 secondNoId = createNodeOperator(7);
        uint256 newVettedFirst = 5;

        vm.expectRevert();
        csm.decreaseVettedSigningKeysCount(
            bytes.concat(bytes8(uint64(firstNoId)), bytes8(uint64(secondNoId))),
            bytes.concat(bytes16(uint128(newVettedFirst)))
        );
    }

    function test_decreaseVettedSigningKeysCount_RevertWhen_NewVettedEqOld()
        public
    {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 10;

        vm.expectRevert(ICSModule.InvalidVetKeysPointer.selector);
        unvetKeys(noId, newVetted);
    }

    function test_decreaseVettedSigningKeysCount_RevertWhen_NewVettedGreaterOld()
        public
    {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 15;

        vm.expectRevert(ICSModule.InvalidVetKeysPointer.selector);
        unvetKeys(noId, newVetted);
    }

    function test_decreaseVettedSigningKeysCount_RevertWhen_NewVettedLowerTotalDeposited()
        public
    {
        uint256 noId = createNodeOperator(10);
        csm.obtainDepositData(5, "");
        uint256 newVetted = 4;

        vm.expectRevert(ICSModule.InvalidVetKeysPointer.selector);
        unvetKeys(noId, newVetted);
    }

    function test_decreaseVettedSigningKeysCount_RevertWhen_NodeOperatorDoesNotExist()
        public
    {
        uint256 noId = createNodeOperator(10);
        uint256 newVetted = 15;

        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        unvetKeys(noId + 1, newVetted);
    }
}

contract CsmGetSigningKeys is CSMCommon {
    function test_getSigningKeys() public assertInvariants brutalizeMemory {
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

    function test_getSigningKeys_getNonExistingKeys()
        public
        assertInvariants
        brutalizeMemory
    {
        bytes memory keys = randomBytes(48);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1,
            keys: keys,
            signatures: randomBytes(96)
        });

        vm.expectRevert(ICSModule.SigningKeysInvalidOffset.selector);
        csm.getSigningKeys({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
    }

    function test_getSigningKeys_getKeysFromOffset()
        public
        assertInvariants
        brutalizeMemory
    {
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

    function test_getSigningKeys_WhenNoNodeOperator()
        public
        assertInvariants
        brutalizeMemory
    {
        vm.expectRevert(ICSModule.SigningKeysInvalidOffset.selector);
        csm.getSigningKeys(0, 0, 1);
    }
}

contract CsmGetSigningKeysWithSignatures is CSMCommon {
    function test_getSigningKeysWithSignatures()
        public
        assertInvariants
        brutalizeMemory
    {
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

    function test_getSigningKeysWithSignatures_getNonExistingKeys()
        public
        assertInvariants
        brutalizeMemory
    {
        bytes memory keys = randomBytes(48);
        bytes memory signatures = randomBytes(96);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1,
            keys: keys,
            signatures: signatures
        });

        vm.expectRevert(ICSModule.SigningKeysInvalidOffset.selector);
        csm.getSigningKeysWithSignatures({
            nodeOperatorId: noId,
            startIndex: 0,
            keysCount: 3
        });
    }

    function test_getSigningKeysWithSignatures_getKeysFromOffset()
        public
        assertInvariants
        brutalizeMemory
    {
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

    function test_getSigningKeysWithSignatures_WhenNoNodeOperator()
        public
        assertInvariants
        brutalizeMemory
    {
        vm.expectRevert(ICSModule.SigningKeysInvalidOffset.selector);
        csm.getSigningKeysWithSignatures(0, 0, 1);
    }
}

contract CsmRemoveKeys is CSMCommon {
    bytes key0 = randomBytes(48);
    bytes key1 = randomBytes(48);
    bytes key2 = randomBytes(48);
    bytes key3 = randomBytes(48);
    bytes key4 = randomBytes(48);

    function test_singleKeyRemoval() public assertInvariants brutalizeMemory {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        // at the beginning
        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key0);

            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 4);
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
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key1);

            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 3);
        }
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 1, keysCount: 1 });
        /*
            key4
            key3
            key2
        */

        // at the end
        {
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key2);

            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 2);
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

    function test_multipleKeysRemovalFromStart()
        public
        assertInvariants
        brutalizeMemory
    {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        {
            // NOTE: keys are being removed in reverse order to keep an original order of keys at the end of the list
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key1);
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key0);

            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 3);
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

    function test_multipleKeysRemovalInBetween()
        public
        assertInvariants
        brutalizeMemory
    {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        {
            // NOTE: keys are being removed in reverse order to keep an original order of keys at the end of the list
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key2);
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key1);

            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 3);
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

    function test_multipleKeysRemovalFromEnd()
        public
        assertInvariants
        brutalizeMemory
    {
        bytes memory keys = bytes.concat(key0, key1, key2, key3, key4);

        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: keys,
            signatures: randomBytes(96 * 5)
        });

        {
            // NOTE: keys are being removed in reverse order to keep an original order of keys at the end of the list
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key4);
            vm.expectEmit(address(csm));
            emit IStakingModule.SigningKeyRemoved(noId, key3);

            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 3);
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

    function test_removeAllKeys() public assertInvariants brutalizeMemory {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 5,
            keys: randomBytes(48 * 5),
            signatures: randomBytes(96 * 5)
        });

        {
            vm.expectEmit(address(csm));
            emit ICSModule.TotalSigningKeysCountChanged(noId, 0);
        }

        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 5 });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalAddedKeys, 0);
    }

    function test_removeKeys_nonceChanged() public assertInvariants {
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
}

contract CSMRemoveKeysChargeFee is CSMCommon {
    function test_removeKeys_chargeFee() public assertInvariants {
        uint256 noId = createNodeOperator(3);

        uint256 amountToCharge = csm.PARAMETERS_REGISTRY().getKeyRemovalCharge(
            0
        ) * 2;

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                amountToCharge
            ),
            1
        );

        vm.expectEmit(address(csm));
        emit ICSModule.KeyRemovalChargeApplied(noId);

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 1, 2);
    }

    function test_removeKeys_withNoFee() public assertInvariants {
        vm.prank(admin);
        csm.PARAMETERS_REGISTRY().setKeyRemovalCharge(0, 0);

        uint256 noId = createNodeOperator(3);

        vm.recordLogs();

        vm.prank(nodeOperator);
        csm.removeKeys(noId, 1, 2);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            assertNotEq(
                entries[i].topics[0],
                ICSModule.KeyRemovalChargeApplied.selector
            );
        }
    }
}

contract CSMRemoveKeysReverts is CSMCommon {
    function test_removeKeys_RevertWhen_NoNodeOperator()
        public
        assertInvariants
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.removeKeys({ nodeOperatorId: 0, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhen_MoreThanAdded()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 2 });
    }

    function test_removeKeys_RevertWhen_LessThanDeposited()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 2
        });

        csm.obtainDepositData(1, "");

        vm.expectRevert(ICSModule.SigningKeysInvalidOffset.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhen_NotEligible() public assertInvariants {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.prank(stranger);
        vm.expectRevert(ICSModule.SenderIsNotEligible.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 1 });
    }

    function test_removeKeys_RevertWhen_NoKeys() public assertInvariants {
        uint256 noId = createNodeOperator({
            managerAddress: address(this),
            keysCount: 1
        });

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        csm.removeKeys({ nodeOperatorId: noId, startIndex: 0, keysCount: 0 });
    }
}

contract CsmGetNodeOperatorNonWithdrawnKeys is CSMCommon {
    function test_getNodeOperatorNonWithdrawnKeys() public assertInvariants {
        uint256 noId = createNodeOperator(3);
        uint256 keys = csm.getNodeOperatorNonWithdrawnKeys(noId);
        assertEq(keys, 3);
    }

    function test_getNodeOperatorNonWithdrawnKeys_WithdrawnKeys()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(3);
        csm.obtainDepositData(3, "");

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            0,
            csm.DEPOSIT_SIZE()
        );

        csm.submitWithdrawals(withdrawalInfo);
        uint256 keys = csm.getNodeOperatorNonWithdrawnKeys(noId);
        assertEq(keys, 2);
    }

    function test_getNodeOperatorNonWithdrawnKeys_ZeroWhenNoNodeOperator()
        public
        view
    {
        uint256 keys = csm.getNodeOperatorNonWithdrawnKeys(0);
        assertEq(keys, 0);
    }
}

contract CsmGetNodeOperatorSummary is CSMCommon {
    function test_getNodeOperatorSummary_defaultValues()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_depositedKey()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(2);

        csm.obtainDepositData(1, "");

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.depositableValidatorsCount, 1);
        assertEq(summary.totalDepositedValidators, 1);
    }

    function test_getNodeOperatorSummary_softTargetLimit()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_softTargetLimitAndDeposited()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_hardTargetLimit()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_hardTargetLimitAndDeposited()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_noTargetLimitDueToLockedBond()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_noTargetLimitDueToUnbondedNonDeposited()
        public
    {
        uint256 noId = createNodeOperator(3);

        csm.obtainDepositData(2, "");

        penalize(noId, BOND_SIZE / 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 0, "targetLimitMode mismatch");
        assertEq(
            summary.targetValidatorsCount,
            0,
            "targetValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_targetLimitDueToAllUnbonded()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_hardTargetLimitGreaterThanUnbondedNonDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 2, 4);

        penalize(noId, BOND_SIZE + 100 wei);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            4,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 2, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitGreaterThanUnbondedDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(4, "");

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
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_hardTargetLimitEqualUnbonded()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorSummary_softTargetLimitLowerThanUnbondedNonDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 1, 1);

        penalize(noId, BOND_SIZE / 2);

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

    function test_getNodeOperatorSummary_softTargetLimitLowerThanUnbondedDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(5, "");

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
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitGreaterThanUnbondedNonDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.updateTargetValidatorsLimits(noId, 1, 4);

        penalize(noId, BOND_SIZE + 100 wei);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.targetValidatorsCount,
            4,
            "targetValidatorsCount mismatch"
        );
        assertEq(summary.targetLimitMode, 1, "targetLimitMode mismatch");
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_softTargetLimitGreaterThanUnbondedDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(4, "");

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
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_unbondedGreaterThanTotalMinusDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(3, "");

        penalize(noId, BOND_SIZE * 3);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.depositableValidatorsCount,
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_unbondedEqualToTotalMinusDeposited()
        public
    {
        uint256 noId = createNodeOperator(5);

        csm.obtainDepositData(3, "");

        penalize(noId, BOND_SIZE * 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.depositableValidatorsCount,
            0,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_unbondedGreaterThanTotalMinusVetted()
        public
    {
        uint256 noId = createNodeOperator(5);

        unvetKeys(noId, 4);

        penalize(noId, BOND_SIZE * 2);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_unbondedEqualToTotalMinusVetted()
        public
    {
        uint256 noId = createNodeOperator(5);

        unvetKeys(noId, 4);

        penalize(noId, BOND_SIZE);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.depositableValidatorsCount,
            4,
            "depositableValidatorsCount mismatch"
        );
    }

    function test_getNodeOperatorSummary_unbondedLessThanTotalMinusVetted()
        public
    {
        uint256 noId = createNodeOperator(5);

        unvetKeys(noId, 3);

        penalize(noId, BOND_SIZE);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(
            summary.depositableValidatorsCount,
            3,
            "depositableValidatorsCount mismatch"
        );
    }
}

contract CsmGetNodeOperator is CSMCommon {
    function test_getNodeOperator() public assertInvariants {
        uint256 noId = createNodeOperator();
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.managerAddress, nodeOperator);
        assertEq(no.rewardAddress, nodeOperator);
    }

    function test_getNodeOperator_WhenNoNodeOperator() public assertInvariants {
        NodeOperator memory no = csm.getNodeOperator(0);
        assertEq(no.managerAddress, address(0));
        assertEq(no.rewardAddress, address(0));
    }
}

contract CsmUpdateTargetValidatorsLimits is CSMCommon {
    function test_updateTargetValidatorsLimits() public assertInvariants {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 1, 1);
        csm.updateTargetValidatorsLimits(noId, 1, 1);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_updateTargetValidatorsLimits_sameValues()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 1, 1);
        csm.updateTargetValidatorsLimits(noId, 1, 1);
        csm.updateTargetValidatorsLimits(noId, 1, 1);

        NodeOperatorSummary memory summary = getNodeOperatorSummary(noId);
        assertEq(summary.targetLimitMode, 1);
        assertEq(summary.targetValidatorsCount, 1);
    }

    function test_updateTargetValidatorsLimits_limitIsZero()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 1, 0);
        csm.updateTargetValidatorsLimits(noId, 1, 0);
    }

    function test_updateTargetValidatorsLimits_FromDisabledToDisabled_withNonZeroTargetLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 2, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 0, 0);
        csm.updateTargetValidatorsLimits(noId, 0, 0);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.targetLimit, 0);
    }

    function test_updateTargetValidatorsLimits_enableSoftLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 0, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 1, 10);
        csm.updateTargetValidatorsLimits(noId, 1, 10);
    }

    function test_updateTargetValidatorsLimits_enableHardLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 0, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 2, 10);
        csm.updateTargetValidatorsLimits(noId, 2, 10);
    }

    function test_updateTargetValidatorsLimits_disableSoftLimit_withNonZeroTargetLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 1, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 0, 0);
        csm.updateTargetValidatorsLimits(noId, 0, 10);
    }

    function test_updateTargetValidatorsLimits_disableSoftLimit_withZeroTargetLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 1, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 0, 0);
        csm.updateTargetValidatorsLimits(noId, 0, 0);
    }

    function test_updateTargetValidatorsLimits_disableHardLimit_withNonZeroTargetLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 2, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 0, 0);
        csm.updateTargetValidatorsLimits(noId, 0, 10);
    }

    function test_updateTargetValidatorsLimits_disableHardLimit_withZeroTargetLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 2, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 0, 0);
        csm.updateTargetValidatorsLimits(noId, 0, 0);
    }

    function test_updateTargetValidatorsLimits_switchFromHardToSoftLimit()
        public
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 2, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 1, 5);
        csm.updateTargetValidatorsLimits(noId, 1, 5);
    }

    function test_updateTargetValidatorsLimits_switchFromSoftToHardLimit()
        public
    {
        uint256 noId = createNodeOperator();
        csm.updateTargetValidatorsLimits(noId, 1, 10);

        vm.expectEmit(address(csm));
        emit ICSModule.TargetValidatorsCountChanged(noId, 2, 5);
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

    function test_updateTargetValidatorsLimits_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.updateTargetValidatorsLimits(0, 1, 1);
    }

    function test_updateTargetValidatorsLimits_RevertWhen_TargetLimitExceedsUint32()
        public
    {
        createNodeOperator(1);
        vm.expectRevert(ICSModule.InvalidInput.selector);
        csm.updateTargetValidatorsLimits(0, 1, uint256(type(uint32).max) + 1);
    }

    function test_updateTargetValidatorsLimits_RevertWhen_TargetLimitModeExceedsMax()
        public
    {
        createNodeOperator(1);
        vm.expectRevert(ICSModule.InvalidInput.selector);
        csm.updateTargetValidatorsLimits(0, 3, 1);
    }
}

contract CsmUpdateExitedValidatorsCount is CSMCommon {
    function test_updateExitedValidatorsCount_NonZero()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(1);
        csm.obtainDepositData(1, "");
        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ExitedSigningKeysCountChanged(noId, 1);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, 1, "totalExitedKeys not increased");

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_updateExitedValidatorsCount_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
    }

    function test_updateExitedValidatorsCount_RevertWhen_CountMoreThanDeposited()
        public
    {
        createNodeOperator(1);

        vm.expectRevert(ICSModule.ExitedKeysHigherThanTotalDeposited.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );
    }

    function test_updateExitedValidatorsCount_RevertWhen_ExitedKeysDecrease()
        public
    {
        createNodeOperator(1);
        csm.obtainDepositData(1, "");

        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.expectRevert(ICSModule.ExitedKeysDecrease.selector);
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(0x0000000000000000)),
            bytes.concat(bytes16(0x00000000000000000000000000000000))
        );
    }

    function test_updateExitedValidatorsCount_NoEventIfSameValue()
        public
        assertInvariants
    {
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
        // One event is NonceChanged
        assertEq(logs.length, 1);
    }
}

contract CsmUnsafeUpdateValidatorsCount is CSMCommon {
    function test_unsafeUpdateValidatorsCount_NonZero()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(5);
        csm.obtainDepositData(5, "");
        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ExitedSigningKeysCountChanged(noId, 1);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1
        });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, 1, "totalExitedKeys not increased");
        assertEq(
            no.stuckValidatorsCount,
            0,
            "stuckValidatorsCount not increased"
        );

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_unsafeUpdateValidatorsCount_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: 100500,
            exitedValidatorsKeysCount: 1
        });
    }

    function test_unsafeUpdateValidatorsCount_RevertWhen_NotStakingRouter()
        public
    {
        expectRoleRevert(stranger, csm.STAKING_ROUTER_ROLE());
        vm.prank(stranger);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: 100500,
            exitedValidatorsKeysCount: 1
        });
    }

    function test_unsafeUpdateValidatorsCount_RevertWhen_ExitedCountMoreThanDeposited()
        public
    {
        uint256 noId = createNodeOperator(1);

        vm.expectRevert(ICSModule.ExitedKeysHigherThanTotalDeposited.selector);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 100500
        });
    }

    function test_unsafeUpdateValidatorsCount_DecreaseExitedKeys()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(1);
        csm.obtainDepositData(1, "");

        setExited(0, 1);

        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 0
        });

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, 0, "totalExitedKeys should be zero");
    }

    function test_unsafeUpdateValidatorsCount_NoEventIfSameValue()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(2, "");

        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1
        });

        vm.recordLogs();
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1
        });
        Vm.Log[] memory logs = vm.getRecordedLogs();
        // One event is NonceChanged
        assertEq(logs.length, 1);
    }
}

contract CsmReportELRewardsStealingPenalty is CSMCommon {
    function test_reportELRewardsStealingPenalty_HappyPath()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltyReported(
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
        assertEq(
            lockedBond,
            BOND_SIZE /
                2 +
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );
        assertEq(csm.getNonce(), nonce + 1);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.depositableValidatorsCount, 0);
    }

    function test_reportELRewardsStealingPenalty_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.reportELRewardsStealingPenalty(0, blockhash(block.number), 1 ether);
    }

    function test_reportELRewardsStealingPenalty_RevertWhen_ZeroAmount()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(ICSModule.InvalidAmount.selector);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            0 ether
        );
    }

    function test_reportELRewardsStealingPenalty_NoNonceChange()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();

        vm.deal(nodeOperator, 32 ether);
        vm.prank(nodeOperator);
        accounting.depositETH{ value: 32 ether }(0);

        uint256 nonce = csm.getNonce();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        assertEq(csm.getNonce(), nonce);
    }

    function test_reportELRewardsStealingPenalty_EnqueueAfterUnlock()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        uint256 nonce = csm.getNonce();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(
            lockedBond,
            BOND_SIZE /
                2 +
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );
        assertEq(csm.getNonce(), nonce + 1);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.depositableValidatorsCount, 0);

        createNodeOperator();
        csm.obtainDepositData(1, "");

        vm.warp(accounting.getBondLockPeriod() + 1);

        vm.expectEmit(address(csm));
        emit ICSModule.BatchEnqueued(csm.QUEUE_LOWEST_PRIORITY(), noId, 1);
        csm.updateDepositableValidatorsCount(noId);

        no = csm.getNodeOperator(noId);
        assertEq(no.depositableValidatorsCount, 1);
    }
}

contract CsmCancelELRewardsStealingPenalty is CSMCommon {
    function test_cancelELRewardsStealingPenalty_HappyPath()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltyCancelled(
            noId,
            BOND_SIZE /
                2 +
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );
        csm.cancelELRewardsStealingPenalty(
            noId,
            BOND_SIZE /
                2 +
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(lockedBond, 0);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_cancelELRewardsStealingPenalty_Partial()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            BOND_SIZE / 2
        );

        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltyCancelled(noId, BOND_SIZE / 2);
        csm.cancelELRewardsStealingPenalty(noId, BOND_SIZE / 2);

        uint256 lockedBond = accounting.getActualLockedBond(noId);
        assertEq(
            lockedBond,
            csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );
        // nonce should not change due to no changes in the depositable validators
        assertEq(csm.getNonce(), nonce);
    }

    function test_cancelELRewardsStealingPenalty_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.cancelELRewardsStealingPenalty(0, 1 ether);
    }
}

contract CsmSettleELRewardsStealingPenaltyBasic is CSMCommon {
    function test_settleELRewardsStealingPenalty() public assertInvariants {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(noId);
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.until, 0);
    }

    function test_settleELRewardsStealingPenalty_multipleNOs()
        public
        assertInvariants
    {
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

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(firstNoId);
        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(secondNoId);
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(
            firstNoId
        );
        assertEq(lock.amount, 0 ether);
        assertEq(lock.until, 0);

        lock = accounting.getLockedBondInfo(secondNoId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.until, 0);
    }

    function test_settleELRewardsStealingPenalty_NoLock()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;

        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0 ether);
        assertEq(lock.until, 0);
    }

    function test_settleELRewardsStealingPenalty_multipleNOs_NoLock()
        public
        assertInvariants
    {
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;

        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory firstLock = accounting.getLockedBondInfo(
            firstNoId
        );
        assertEq(firstLock.amount, 0 ether);
        assertEq(firstLock.until, 0);
        CSBondLock.BondLock memory secondLock = accounting.getLockedBondInfo(
            secondNoId
        );
        assertEq(secondLock.amount, 0 ether);
        assertEq(secondLock.until, 0);
    }

    function test_settleELRewardsStealingPenalty_multipleNOs_oneWithNoLock()
        public
    {
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;

        csm.reportELRewardsStealingPenalty(
            secondNoId,
            blockhash(block.number),
            1 ether
        );

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(secondNoId);
        csm.settleELRewardsStealingPenalty(idsToSettle);

        CSBondLock.BondLock memory firstLock = accounting.getLockedBondInfo(
            firstNoId
        );
        assertEq(firstLock.amount, 0 ether);
        assertEq(firstLock.until, 0);
        CSBondLock.BondLock memory secondLock = accounting.getLockedBondInfo(
            secondNoId
        );
        assertEq(secondLock.amount, 0 ether);
        assertEq(secondLock.until, 0);
    }

    function test_settleELRewardsStealingPenalty_withDuplicates() public {
        uint256 firstNoId = createNodeOperator();
        uint256 secondNoId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](3);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;
        idsToSettle[2] = secondNoId;

        uint256 bondBalanceBefore = accounting.getBond(secondNoId);

        uint256 lockAmount = 1 ether;
        csm.reportELRewardsStealingPenalty(
            secondNoId,
            blockhash(block.number),
            lockAmount
        );

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(secondNoId);
        csm.settleELRewardsStealingPenalty(idsToSettle);

        uint256 bondBalanceAfter = accounting.getBond(secondNoId);

        CSBondLock.BondLock memory currentLock = accounting.getLockedBondInfo(
            secondNoId
        );
        assertEq(currentLock.amount, 0 ether);
        assertEq(currentLock.until, 0);
        assertEq(
            bondBalanceAfter,
            bondBalanceBefore -
                lockAmount -
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(0)
        );
    }

    function test_settleELRewardsStealingPenalty_RevertWhen_NoExistingNodeOperator()
        public
    {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId + 1;

        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.settleELRewardsStealingPenalty(idsToSettle);
    }
}

contract CsmSettleELRewardsStealingPenaltyAdvanced is CSMCommon {
    function test_settleELRewardsStealingPenalty_PeriodIsExpired() public {
        uint256 noId = createNodeOperator();
        uint256 period = accounting.getBondLockPeriod();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        uint256 amount = 1 ether;

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        vm.warp(block.timestamp + period + 1 seconds);

        csm.settleELRewardsStealingPenalty(idsToSettle);

        assertEq(accounting.getActualLockedBond(noId), 0);
    }

    function test_settleELRewardsStealingPenalty_multipleNOs_oneExpired()
        public
    {
        uint256 period = accounting.getBondLockPeriod();
        uint256 firstNoId = createNodeOperator(2);
        uint256 secondNoId = createNodeOperator(2);
        uint256[] memory idsToSettle = new uint256[](2);
        idsToSettle[0] = firstNoId;
        idsToSettle[1] = secondNoId;
        csm.reportELRewardsStealingPenalty(
            firstNoId,
            blockhash(block.number),
            1 ether
        );
        vm.warp(block.timestamp + period + 1 seconds);
        csm.reportELRewardsStealingPenalty(
            secondNoId,
            blockhash(block.number),
            BOND_SIZE
        );

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(secondNoId);
        csm.settleELRewardsStealingPenalty(idsToSettle);

        assertEq(accounting.getActualLockedBond(firstNoId), 0);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(
            secondNoId
        );
        assertEq(lock.amount, 0 ether);
        assertEq(lock.until, 0);
    }

    function test_settleELRewardsStealingPenalty_NoBond()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = noId;
        uint256 amount = accounting.getBond(noId) + 1 ether;

        // penalize all current bond to make an edge case when there is no bond but a new lock is applied
        vm.prank(address(csm));
        accounting.penalize(noId, amount);

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );
        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltySettled(noId);
        csm.settleELRewardsStealingPenalty(idsToSettle);
    }
}

contract CSMCompensateELRewardsStealingPenalty is CSMCommon {
    function test_compensateELRewardsStealingPenalty() public assertInvariants {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256 fine = csm
            .PARAMETERS_REGISTRY()
            .getElRewardsStealingAdditionalFine(0);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltyCompensated(noId, amount + fine);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.compensateLockedBondETH.selector,
                noId
            )
        );
        vm.deal(nodeOperator, amount + fine);
        vm.prank(nodeOperator);
        csm.compensateELRewardsStealingPenalty{ value: amount + fine }(noId);

        CSBondLock.BondLock memory lock = accounting.getLockedBondInfo(noId);
        assertEq(lock.amount, 0);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_compensateELRewardsStealingPenalty_Partial()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();
        uint256 amount = 1 ether;
        uint256 fine = csm
            .PARAMETERS_REGISTRY()
            .getElRewardsStealingAdditionalFine(0);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 nonce = csm.getNonce();

        vm.expectEmit(address(csm));
        emit ICSModule.ELRewardsStealingPenaltyCompensated(noId, amount);

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.compensateLockedBondETH.selector,
                noId
            )
        );
        vm.deal(nodeOperator, amount);
        vm.prank(nodeOperator);
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
        uint256 fine = csm
            .PARAMETERS_REGISTRY()
            .getElRewardsStealingAdditionalFine(0);
        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );
        csm.obtainDepositData(1, "");
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        vm.deal(nodeOperator, amount + fine);
        vm.prank(nodeOperator);
        csm.compensateELRewardsStealingPenalty{ value: amount + fine }(noId);
        uint256 depositableAfter = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;
        assertEq(depositableAfter, depositableBefore + 1);

        BatchInfo[] memory exp = new BatchInfo[](1);
        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 1 });
        _assertQueueState(csm.QUEUE_LOWEST_PRIORITY(), exp);
    }

    function test_compensateELRewardsStealingPenalty_RevertWhen_NoNodeOperator()
        public
    {
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.compensateELRewardsStealingPenalty{ value: 1 ether }(0);
    }

    function test_compensateELRewardsStealingPenalty_RevertWhen_NotManager()
        public
    {
        uint256 noId = createNodeOperator();
        vm.expectRevert(ICSModule.SenderIsNotEligible.selector);
        csm.compensateELRewardsStealingPenalty{ value: 1 ether }(noId);
    }
}

contract CsmSubmitWithdrawals is CSMCommon {
    function test_submitWithdrawals() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        (bytes memory pubkey, ) = csm.obtainDepositData(1, "");

        uint256 nonce = csm.getNonce();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectEmit(address(csm));
        emit ICSModule.WithdrawalSubmitted(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE(),
            pubkey
        );
        csm.submitWithdrawals(withdrawalInfo);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalWithdrawnKeys, 1);
        bool withdrawn = csm.isValidatorWithdrawn(noId, keyIndex);
        assertTrue(withdrawn);

        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_submitWithdrawals_changeNonce() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator(2);
        (bytes memory pubkey, ) = csm.obtainDepositData(1, "");

        uint256 nonce = csm.getNonce();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - BOND_SIZE - 1 ether
        );

        vm.expectEmit(address(csm));
        emit ICSModule.WithdrawalSubmitted(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - BOND_SIZE - 1 ether,
            pubkey
        );
        csm.submitWithdrawals(withdrawalInfo);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalWithdrawnKeys, 1);
        // depositable decrease should
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_submitWithdrawals_lowExitBalance() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - 1 ether
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_exitDelayPenalty() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(1 ether, true),
                strikesPenalty: MarkedUint248(0, false),
                withdrawalRequestFee: MarkedUint248(0, false)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_strikesPenalty() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(0, false),
                strikesPenalty: MarkedUint248(1 ether, true),
                withdrawalRequestFee: MarkedUint248(0, false)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_allPenalties() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(1 ether, true),
                strikesPenalty: MarkedUint248(1 ether, true),
                withdrawalRequestFee: MarkedUint248(0, false)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - 1 ether
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 3 ether)
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_chargeWithdrawalFee_DelayPenalty()
        public
        assertInvariants
    {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(1 ether, true),
                strikesPenalty: MarkedUint248(0, false),
                withdrawalRequestFee: MarkedUint248(0.1 ether, true)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                0.1 ether
            )
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_chargeWithdrawalFee_StrikesPenalty()
        public
        assertInvariants
    {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(0, false),
                strikesPenalty: MarkedUint248(1 ether, true),
                withdrawalRequestFee: MarkedUint248(0.1 ether, true)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 1 ether)
        );
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                0.1 ether
            )
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_chargeWithdrawalFee_DelayAndStrikesPenalties()
        public
        assertInvariants
    {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(1 ether, true),
                strikesPenalty: MarkedUint248(1 ether, true),
                withdrawalRequestFee: MarkedUint248(0.1 ether, true)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 2 ether)
        );
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                0.1 ether
            )
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_chargeWithdrawalFee_zeroPenaltyValue()
        public
        assertInvariants
    {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(0, true),
                strikesPenalty: MarkedUint248(0, true),
                withdrawalRequestFee: MarkedUint248(0.1 ether, true)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                0.1 ether
            )
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_dontChargeWithdrawalFee_noPenalties()
        public
        assertInvariants
    {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(0, false),
                strikesPenalty: MarkedUint248(0, false),
                withdrawalRequestFee: MarkedUint248(0.1 ether, true)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE()
        );

        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                0.1 ether
            )
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_dontChargeWithdrawalFee_exitBalancePenalty()
        public
        assertInvariants
    {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        exitPenalties.mock_setDelayedExitPenaltyInfo(
            ExitPenaltyInfo({
                delayPenalty: MarkedUint248(0, false),
                strikesPenalty: MarkedUint248(0, false),
                withdrawalRequestFee: MarkedUint248(0.1 ether, true)
            })
        );

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);

        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            keyIndex,
            csm.DEPOSIT_SIZE() - 1 ether
        );

        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(
                accounting.chargeFee.selector,
                noId,
                0.1 ether
            )
        );
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_unbondedKeys() public assertInvariants {
        uint256 keyIndex = 0;
        uint256 noId = createNodeOperator(2);
        csm.obtainDepositData(1, "");
        uint256 nonce = csm.getNonce();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(noId, keyIndex, 1 ether);

        csm.submitWithdrawals(withdrawalInfo);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_submitWithdrawals_RevertWhen_NoNodeOperator()
        public
        assertInvariants
    {
        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(0, 0, 0);

        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_RevertWhen_InvalidKeyIndexOffset()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(noId, 0, 0);

        vm.expectRevert(ICSModule.SigningKeysInvalidOffset.selector);
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_submitWithdrawals_alreadyWithdrawn() public assertInvariants {
        uint256 noId = createNodeOperator();
        csm.obtainDepositData(1, "");

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            0,
            csm.DEPOSIT_SIZE()
        );

        csm.submitWithdrawals(withdrawalInfo);

        uint256 nonceBefore = csm.getNonce();
        csm.submitWithdrawals(withdrawalInfo);
        assertEq(
            csm.getNonce(),
            nonceBefore,
            "Nonce should not change when trying to withdraw already withdrawn key"
        );
    }

    function test_submitWithdrawals_nonceIncrementsOnceForManyWithdrawals()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(3);
        csm.obtainDepositData(3, "");
        uint256 nonceBefore = csm.getNonce();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](3);
        for (uint256 i = 0; i < 3; ++i) {
            withdrawalInfo[i] = ValidatorWithdrawalInfo(
                noId,
                i,
                csm.DEPOSIT_SIZE()
            );
        }
        csm.submitWithdrawals(withdrawalInfo);
        assertEq(
            csm.getNonce(),
            nonceBefore + 1,
            "Module nonce should increment only once for batch withdrawals"
        );
    }
}

contract CsmGetStakingModuleSummary is CSMCommon {
    function test_getStakingModuleSummary_depositableValidators()
        public
        assertInvariants
    {
        uint256 first = createNodeOperator(1);
        uint256 second = createNodeOperator(2);
        StakingModuleSummary memory summary = getStakingModuleSummary();
        NodeOperator memory firstNo = csm.getNodeOperator(first);
        NodeOperator memory secondNo = csm.getNodeOperator(second);

        assertEq(firstNo.depositableValidatorsCount, 1);
        assertEq(secondNo.depositableValidatorsCount, 2);
        assertEq(summary.depositableValidatorsCount, 3);
    }

    function test_getStakingModuleSummary_depositedValidators()
        public
        assertInvariants
    {
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

    function test_getStakingModuleSummary_exitedValidators()
        public
        assertInvariants
    {
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
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });
        _enableInitializers(address(csm));
        csm.initialize(actor);

        bytes32 role = csm.DEFAULT_ADMIN_ROLE();
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
            lidoLocator: address(locator),
            parametersRegistry: address(parametersRegistry),
            _accounting: address(accounting),
            exitPenalties: address(exitPenalties)
        });
        bytes32 role = csm.DEFAULT_ADMIN_ROLE();
        bytes32 adminRole = csm.DEFAULT_ADMIN_ROLE();

        vm.startPrank(stranger);
        expectRoleRevert(stranger, adminRole);
        csm.grantRole(role, stranger);
    }

    function test_createNodeOperatorRole() public {
        bytes32 role = csm.CREATE_NODE_OPERATOR_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
    }

    function test_createNodeOperatorRole_revert() public {
        bytes32 role = csm.CREATE_NODE_OPERATOR_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.createNodeOperator(
            nodeOperator,
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            address(0)
        );
    }

    function test_reportELRewardsStealingPenaltyRole() public {
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

    function test_verifierRole_submitWithdrawals() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.VERIFIER_ROLE();

        vm.startPrank(admin);
        csm.grantRole(role, actor);
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), admin);
        csm.obtainDepositData(1, "");
        vm.stopPrank();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(noId, 0, 1 ether);

        vm.prank(actor);
        csm.submitWithdrawals(withdrawalInfo);
    }

    function test_verifierRole_submitWithdrawals_revert() public {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.VERIFIER_ROLE();

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](1);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(noId, 0, 1 ether);

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.submitWithdrawals(withdrawalInfo);
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

contract CSMStakingRouterAccessControl is CSMCommonNoRoles {
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

    function test_stakingRouterRole_updateTargetValidatorsLimits() public {
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

    function test_stakingRouterRole_onWithdrawalCredentialsChanged() public {
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        uint256 nonceBefore = csm.getNonce();
        vm.prank(actor);
        csm.onWithdrawalCredentialsChanged();
        assertEq(
            csm.getNonce(),
            nonceBefore + 1,
            "Module nonce should increment by 1"
        );
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
        csm.unsafeUpdateValidatorsCount(noId, 0);
    }

    function test_stakingRouterRole_unsafeUpdateValidatorsCountRole_revert()
        public
    {
        uint256 noId = createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.unsafeUpdateValidatorsCount(noId, 0);
    }

    function test_stakingRouterRole_unvetKeys() public {
        createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();
        vm.prank(admin);
        csm.grantRole(role, actor);

        vm.prank(actor);
        csm.decreaseVettedSigningKeysCount(new bytes(0), new bytes(0));
    }

    function test_stakingRouterRole_unvetKeys_revert() public {
        createNodeOperator();
        bytes32 role = csm.STAKING_ROUTER_ROLE();

        vm.prank(stranger);
        expectRoleRevert(stranger, role);
        csm.decreaseVettedSigningKeysCount(new bytes(0), new bytes(0));
    }
}

contract CSMDepositableValidatorsCount is CSMCommon {
    function test_depositableValidatorsCountChanges_OnDeposit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 7);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 7);
        csm.obtainDepositData(3, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 4);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 4);
    }

    function test_depositableValidatorsCountChanges_OnUnsafeUpdateExitedValidators()
        public
    {
        uint256 noId = createNodeOperator(7);
        createNodeOperator(2);
        csm.obtainDepositData(4, "");

        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 5);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 1
        });
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 5);
    }

    function test_depositableValidatorsCountDoesntChange_OnUnsafeUpdateStuckValidators()
        public
    {
        uint256 noId = createNodeOperator(7);
        createNodeOperator(2);
        csm.obtainDepositData(4, "");

        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 5);
        csm.unsafeUpdateValidatorsCount({
            nodeOperatorId: noId,
            exitedValidatorsKeysCount: 0
        });
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 5);
    }

    function test_depositableValidatorsCountChanges_OnUnvetKeys()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        uint256 nonce = csm.getNonce();
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 7);
        unvetKeys(noId, 3);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 3);
        assertEq(csm.getNonce(), nonce + 1);
    }

    function test_depositableValidatorsCountChanges_OnWithdrawal()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);

        penalize(noId, BOND_SIZE * 3);

        ValidatorWithdrawalInfo[]
            memory withdrawalInfo = new ValidatorWithdrawalInfo[](3);
        withdrawalInfo[0] = ValidatorWithdrawalInfo(
            noId,
            0,
            csm.DEPOSIT_SIZE()
        );
        withdrawalInfo[1] = ValidatorWithdrawalInfo(
            noId,
            1,
            csm.DEPOSIT_SIZE()
        );
        withdrawalInfo[2] = ValidatorWithdrawalInfo(
            noId,
            2,
            csm.DEPOSIT_SIZE() - BOND_SIZE
        ); // Large CL balance drop, that doesn't change the unbonded count.

        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 0);
        csm.submitWithdrawals(withdrawalInfo);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 2);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 2);
    }

    function test_depositableValidatorsCountChanges_OnReportStealing()
        public
        assertInvariants
    {
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

    function test_depositableValidatorsCountChanges_OnRemoveUnvetted()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        unvetKeys(noId, 3);
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 3);
        vm.prank(nodeOperator);
        csm.removeKeys(noId, 3, 1); // Removal charge is applied, hence one key is unbonded.
        assertEq(csm.getNodeOperator(noId).depositableValidatorsCount, 6);
        assertEq(getStakingModuleSummary().depositableValidatorsCount, 6);
    }
}

contract CSMNodeOperatorStateAfterUpdateCurve is CSMCommon {
    function updateToBetterCurve() public {
        accounting.updateBondCurve(0, 1.5 ether);
    }

    function updateToWorseCurve() public {
        accounting.updateBondCurve(0, 2.5 ether);
    }

    function test_depositedOnly_UpdateToBetterCurve() public assertInvariants {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(7, "");

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToBetterCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredBefore,
            requiredAfter,
            "Required bond should decrease"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            0,
            "Should be no unbonded keys"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after normalization"
        );
    }

    function test_depositedOnly_UpdateToWorseCurve() public assertInvariants {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(7, "");

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToWorseCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredAfter,
            requiredBefore,
            "Required bond should increase"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            2,
            "Should be unbonded keys"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after normalization"
        );
    }

    function test_depositableOnly_UpdateToBetterCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToBetterCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredBefore,
            requiredAfter,
            "Required bond should decrease"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            0,
            "Should be no unbonded keys"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore,
            "Depositables should not change after normalization"
        );
    }

    function test_depositableOnly_UpdateToWorseCurve() public assertInvariants {
        uint256 noId = createNodeOperator(7);
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToWorseCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredAfter,
            requiredBefore,
            "Required bond should increase"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            2,
            "Should be unbonded keys"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 2,
            "Depositables should decrease after normalization"
        );
    }

    function test_partiallyUnbondedDepositedOnly_UpdateToBetterCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(7, "");

        penalize(noId, 1 ether);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after penalization"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            1,
            "Should be unbonded keys after penalization"
        );

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToBetterCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredBefore,
            requiredAfter,
            "Required bond should decrease"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after curve update"
        );
        assertEq(accounting.getUnbondedKeysCount(noId), 0);

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after normalization"
        );
    }

    function test_partiallyUnbondedDepositedOnly_UpdateToWorseCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(7, "");

        penalize(noId, 1 ether);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after penalization"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            1,
            "Should be unbonded keys after penalization"
        );

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToWorseCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredAfter,
            requiredBefore,
            "Required bond should increase"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after curve update"
        );
        assertEq(accounting.getUnbondedKeysCount(noId), 2);

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            0,
            "Depositables should not change after normalization"
        );
    }

    function test_partiallyUnbondedDepositableOnly_UpdateToBetterCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        penalize(noId, 1 ether);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should decrease after penalization"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            1,
            "Should be unbonded keys after penalization"
        );

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToBetterCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredBefore,
            requiredAfter,
            "Required bond should decrease"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            0,
            "Should be no unbonded keys after curve update"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore,
            "Depositables should be increased after normalization"
        );
    }

    function test_partiallyUnbondedDepositableOnly_UpdateToWorseCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        penalize(noId, 1 ether);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should decrease after penalization"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            1,
            "Should be unbonded keys after penalization"
        );

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToWorseCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredAfter,
            requiredBefore,
            "Required bond should increase"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            2,
            "Should be unbonded keys after curve update"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 2,
            "Depositables should decrease after normalization"
        );
    }

    function test_partiallyUnbondedPartiallyDeposited_UpdateToBetterCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        penalize(noId, 1 ether);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should decrease after penalization"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            1,
            "Should be unbonded keys after penalization"
        );

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToBetterCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredBefore,
            requiredAfter,
            "Required bond should decrease"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            0,
            "Should be no unbonded keys after curve update"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore,
            "Depositables should be increased after normalization"
        );
    }

    function test_partiallyUnbondedPartiallyDeposited_UpdateToWorseCurve()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator(7);
        csm.obtainDepositData(4, "");
        uint256 depositableBefore = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        penalize(noId, 1 ether);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should decrease after penalization"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            1,
            "Should be unbonded keys after penalization"
        );

        (, uint256 requiredBefore) = accounting.getBondSummary(noId);
        updateToWorseCurve();
        (, uint256 requiredAfter) = accounting.getBondSummary(noId);

        assertGt(
            requiredAfter,
            requiredBefore,
            "Required bond should increase"
        );
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 1,
            "Depositables should not change after curve update"
        );
        assertEq(
            accounting.getUnbondedKeysCount(noId),
            2,
            "Should be unbonded keys after curve update"
        );

        csm.updateDepositableValidatorsCount(noId);
        assertEq(
            csm.getNodeOperator(noId).depositableValidatorsCount,
            depositableBefore - 2,
            "Depositables should decrease after normalization"
        );
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

    function test_onRewardsMinted() public assertInvariants {
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
    function test_recoverERC20() public assertInvariants {
        vm.startPrank(admin);
        csm.grantRole(csm.RECOVERER_ROLE(), stranger);
        vm.stopPrank();

        ERC20Testable token = new ERC20Testable();
        token.mint(address(csm), 1000);

        vm.prank(stranger);
        vm.expectEmit(address(csm));
        emit IAssetRecovererLib.ERC20Recovered(address(token), stranger, 1000);
        csm.recoverERC20(address(token), 1000);

        assertEq(token.balanceOf(address(csm)), 0);
        assertEq(token.balanceOf(stranger), 1000);
    }
}

contract CSMMisc is CSMCommon {
    function test_getInitializedVersion() public view {
        assertEq(csm.getInitializedVersion(), 2);
    }

    function test_getActiveNodeOperatorsCount_OneOperator()
        public
        assertInvariants
    {
        createNodeOperator();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertEq(noCount, 1);
    }

    function test_getActiveNodeOperatorsCount_MultipleOperators()
        public
        assertInvariants
    {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertEq(noCount, 3);
    }

    function test_getNodeOperatorIsActive() public assertInvariants {
        uint256 noId = createNodeOperator();
        bool active = csm.getNodeOperatorIsActive(noId);
        assertTrue(active);
    }

    function test_getNodeOperatorIds() public assertInvariants {
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

    function test_getNodeOperatorIds_Offset() public assertInvariants {
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

    function test_getNodeOperatorIds_OffsetEqualsNodeOperatorsCount()
        public
        assertInvariants
    {
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

    function test_getNodeOperatorIds_ZeroLimit() public assertInvariants {
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

    function test_getNodeOperatorIds_Limit() public assertInvariants {
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

    function test_getNodeOperatorIds_LimitAndOffset() public assertInvariants {
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

    function test_getActiveNodeOperatorsCount_One() public assertInvariants {
        createNodeOperator();

        uint256 activeCount = csm.getActiveNodeOperatorsCount();

        assertEq(activeCount, 1);
    }

    function test_getActiveNodeOperatorsCount_Multiple()
        public
        assertInvariants
    {
        createNodeOperator();
        createNodeOperator();
        createNodeOperator();

        uint256 activeCount = csm.getActiveNodeOperatorsCount();

        assertEq(activeCount, 3);
    }

    function test_getNodeOperatorTotalDepositedKeys() public assertInvariants {
        uint256 noId = createNodeOperator();

        uint256 depositedCount = csm.getNodeOperatorTotalDepositedKeys(noId);
        assertEq(depositedCount, 0);

        csm.obtainDepositData(1, "");

        depositedCount = csm.getNodeOperatorTotalDepositedKeys(noId);
        assertEq(depositedCount, 1);
    }

    function test_getNodeOperatorManagementProperties()
        public
        assertInvariants
    {
        address manager = nextAddress();
        address reward = nextAddress();
        bool extended = true;

        uint256 noId = csm.createNodeOperator(
            manager,
            NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: reward,
                extendedManagerPermissions: extended
            }),
            address(0)
        );

        NodeOperatorManagementProperties memory props = csm
            .getNodeOperatorManagementProperties(noId);
        assertEq(props.managerAddress, manager);
        assertEq(props.rewardAddress, reward);
        assertEq(props.extendedManagerPermissions, extended);
    }

    function test_getNodeOperatorOwner() public assertInvariants {
        address manager = nextAddress();
        address reward = nextAddress();
        bool extended = false;

        uint256 noId = csm.createNodeOperator(
            manager,
            NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: reward,
                extendedManagerPermissions: extended
            }),
            address(0)
        );

        assertEq(csm.getNodeOperatorOwner(noId), reward);
    }

    function test_getNodeOperatorOwner_ExtendedPermissions()
        public
        assertInvariants
    {
        address manager = nextAddress();
        address reward = nextAddress();
        bool extended = true;

        uint256 noId = csm.createNodeOperator(
            manager,
            NodeOperatorManagementProperties({
                managerAddress: manager,
                rewardAddress: reward,
                extendedManagerPermissions: extended
            }),
            address(0)
        );

        assertEq(csm.getNodeOperatorOwner(noId), manager);
    }
}

contract CSMExitDeadlineThreshold is CSMCommon {
    function test_exitDeadlineThreshold() public assertInvariants {
        uint256 noId = createNodeOperator();
        uint256 exitDeadlineThreshold = csm.exitDeadlineThreshold(noId);
        assertEq(exitDeadlineThreshold, parametersRegistry.allowedExitDelay());
    }

    function test_exitDeadlineThreshold_RevertWhenNoNodeOperator()
        public
        assertInvariants
    {
        uint256 noId = 0;
        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.exitDeadlineThreshold(noId);
    }
}

contract CSMIsValidatorExitDelayPenaltyApplicable is CSMCommon {
    function test_isValidatorExitDelayPenaltyApplicable_notApplicable() public {
        uint256 noId = createNodeOperator();
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId);
        bytes memory publicKey = randomBytes(48);

        exitPenalties.mock_isValidatorExitDelayPenaltyApplicable(false);

        vm.expectCall(
            address(exitPenalties),
            abi.encodeWithSelector(
                ICSExitPenalties.isValidatorExitDelayPenaltyApplicable.selector,
                noId,
                publicKey,
                eligibleToExit
            )
        );
        bool applicable = csm.isValidatorExitDelayPenaltyApplicable(
            noId,
            154,
            publicKey,
            eligibleToExit
        );
        assertFalse(applicable);
    }

    function test_isValidatorExitDelayPenaltyApplicable_applicable() public {
        uint256 noId = createNodeOperator();
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId) + 1;
        bytes memory publicKey = randomBytes(48);

        exitPenalties.mock_isValidatorExitDelayPenaltyApplicable(true);

        vm.expectCall(
            address(exitPenalties),
            abi.encodeWithSelector(
                ICSExitPenalties.isValidatorExitDelayPenaltyApplicable.selector,
                noId,
                publicKey,
                eligibleToExit
            )
        );
        bool applicable = csm.isValidatorExitDelayPenaltyApplicable(
            noId,
            154,
            publicKey,
            eligibleToExit
        );
        assertTrue(applicable);
    }
}

contract CSMReportValidatorExitDelay is CSMCommon {
    function test_reportValidatorExitDelay() public {
        uint256 noId = createNodeOperator();
        uint256 exitDeadlineThreshold = csm.exitDeadlineThreshold(noId);
        bytes memory publicKey = randomBytes(48);

        vm.expectCall(
            address(exitPenalties),
            abi.encodeWithSelector(
                ICSExitPenalties.processExitDelayReport.selector,
                noId,
                publicKey,
                exitDeadlineThreshold
            )
        );
        csm.reportValidatorExitDelay(
            noId,
            block.timestamp,
            publicKey,
            exitDeadlineThreshold
        );
    }

    function test_reportValidatorExitDelay_RevertWhen_noNodeOperator() public {
        uint256 noId = 0;
        bytes memory publicKey = randomBytes(48);
        uint256 exitDelay = parametersRegistry.allowedExitDelay();

        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.reportValidatorExitDelay(
            noId,
            block.timestamp,
            publicKey,
            exitDelay
        );
    }
}

contract CSMOnValidatorExitTriggered is CSMCommon {
    function test_onValidatorExitTriggered() public assertInvariants {
        uint256 noId = createNodeOperator();
        bytes memory publicKey = randomBytes(48);
        uint256 paidFee = 0.1 ether;
        uint256 exitType = 1;

        vm.expectCall(
            address(exitPenalties),
            abi.encodeWithSelector(
                ICSExitPenalties.processTriggeredExit.selector,
                noId,
                publicKey,
                paidFee,
                exitType
            )
        );
        csm.onValidatorExitTriggered(noId, publicKey, paidFee, exitType);
    }

    function test_onValidatorExitTriggered_RevertWhen_noNodeOperator() public {
        uint256 noId = 0;
        bytes memory publicKey = randomBytes(48);
        uint256 paidFee = 0.1 ether;
        uint256 exitType = 1;

        vm.expectRevert(ICSModule.NodeOperatorDoesNotExist.selector);
        csm.onValidatorExitTriggered(noId, publicKey, paidFee, exitType);
    }
}

contract CSMCreateNodeOperators is CSMCommon {
    function createMultipleOperatorsWithKeysETH(
        uint256 operators,
        uint256 keysCount,
        address managerAddress
    ) external payable {
        for (uint256 i; i < operators; i++) {
            uint256 noId = csm.createNodeOperator(
                managerAddress,
                NodeOperatorManagementProperties({
                    managerAddress: address(0),
                    rewardAddress: address(0),
                    extendedManagerPermissions: false
                }),
                address(0)
            );
            uint256 amount = csm.accounting().getRequiredBondForNextKeys(
                noId,
                keysCount
            );
            (bytes memory keys, bytes memory signatures) = keysSignatures(
                keysCount
            );
            csm.addValidatorKeysETH{ value: amount }(
                managerAddress,
                noId,
                keysCount,
                keys,
                signatures
            );
        }
    }
}
