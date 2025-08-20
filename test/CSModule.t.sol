// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { CSModule } from "../src/CSModule.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";
import { CSParametersRegistryMock } from "./helpers/mocks/CSParametersRegistryMock.sol";
import { Batch, QueueLib, IQueueLib } from "../src/lib/QueueLib.sol";
import { SigningKeys } from "../src/lib/SigningKeys.sol";
import { ICSModule, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { TransientUintUintMap, TransientUintUintMapLib } from "../src/lib/TransientUintUintMapLib.sol";
import { ExitPenaltiesMock } from "./helpers/mocks/ExitPenaltiesMock.sol";
import { CSAccountingMock } from "./helpers/mocks/CSAccountingMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import "./ModuleAbstract.t.sol";

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

contract CSMCommon is ModuleFixtures {
    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        strangerNumberTwo = nextAddress("STRANGER_TWO");
        admin = nextAddress("ADMIN");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");
        stakingRouter = nextAddress("STAKING_ROUTER");

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

        module = CSModule(
            new CSModuleTestable({
                moduleType: "community-staking-module",
                lidoLocator: address(locator),
                parametersRegistry: address(parametersRegistry),
                _accounting: address(accounting),
                exitPenalties: address(exitPenalties)
            })
        );

        accounting.setModule(module);

        _enableInitializers(address(module));
        module.initialize({ admin: admin });

        vm.startPrank(admin);
        module.grantRole(module.CREATE_NODE_OPERATOR_ROLE(), address(this));
        module.grantRole(module.PAUSE_ROLE(), address(this));
        module.grantRole(module.RESUME_ROLE(), address(this));
        module.grantRole(module.DEFAULT_ADMIN_ROLE(), address(this));
        module.grantRole(module.STAKING_ROUTER_ROLE(), address(this));
        module.grantRole(module.STAKING_ROUTER_ROLE(), stakingRouter);
        module.grantRole(
            module.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        module.grantRole(
            module.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        module.grantRole(module.VERIFIER_ROLE(), address(this));
        vm.stopPrank();

        module.resume();

        // Just to make sure we configured defaults properly and check things properly.
        assertNotEq(PRIORITY_QUEUE, module.QUEUE_LOWEST_PRIORITY());
        assertNotEq(PRIORITY_QUEUE, module.QUEUE_LEGACY_PRIORITY());
        REGULAR_QUEUE = uint32(module.QUEUE_LOWEST_PRIORITY());
        LEGACY_QUEUE = uint32(module.QUEUE_LEGACY_PRIORITY());
    }
}

contract CSMCommonNoRoles is ModuleFixtures {
    function setUp() public virtual {
        nodeOperator = nextAddress("NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        actor = nextAddress("ACTOR");
        testChargePenaltyRecipient = nextAddress("CHARGERECIPIENT");
        stakingRouter = nextAddress("STAKING_ROUTER");

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

        module = CSModule(
            new CSModuleTestable({
                moduleType: "community-staking-module",
                lidoLocator: address(locator),
                parametersRegistry: address(parametersRegistry),
                _accounting: address(accounting),
                exitPenalties: address(exitPenalties)
            })
        );

        accounting.setModule(module);

        _enableInitializers(address(module));
        module.initialize({ admin: admin });

        vm.startPrank(admin);
        module.grantRole(module.DEFAULT_ADMIN_ROLE(), address(this));
        module.grantRole(module.CREATE_NODE_OPERATOR_ROLE(), admin);
        module.grantRole(module.RESUME_ROLE(), admin);
        module.grantRole(module.VERIFIER_ROLE(), address(this));
        module.resume();
        vm.stopPrank();
    }
}

contract CsmFuzz is ModuleFuzz, CSMCommon {}

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

contract CSMPauseTest is ModulePauseTest, CSMCommon {}

contract CSMPauseAffectingTest is ModulePauseAffectingTest, CSMCommon {}

contract CSMCreateNodeOperator is ModuleCreateNodeOperator, CSMCommon {}

contract CSMAddValidatorKeys is ModuleAddValidatorKeys, CSMCommon {}

contract CSMAddValidatorKeysNegative is
    ModuleAddValidatorKeysNegative,
    CSMCommon
{}

contract CSMObtainDepositData is ModuleObtainDepositData, CSMCommon {}

contract CSMProposeNodeOperatorManagerAddressChange is
    ModuleProposeNodeOperatorManagerAddressChange,
    CSMCommon
{}

contract CSMConfirmNodeOperatorManagerAddressChange is
    ModuleConfirmNodeOperatorManagerAddressChange,
    CSMCommon
{}

contract CSMProposeNodeOperatorRewardAddressChange is
    ModuleProposeNodeOperatorRewardAddressChange,
    CSMCommon
{}

contract CSMConfirmNodeOperatorRewardAddressChange is
    ModuleConfirmNodeOperatorRewardAddressChange,
    CSMCommon
{}

contract CSMResetNodeOperatorManagerAddress is
    ModuleResetNodeOperatorManagerAddress,
    CSMCommon
{}

contract CSMChangeNodeOperatorRewardAddress is
    ModuleChangeNodeOperatorRewardAddress,
    CSMCommon
{}

contract CSMVetKeys is ModuleVetKeys, CSMCommon {}

contract CSMQueueOps is ModuleQueueOps, CSMCommon {
    function test_cleanDepositQueue_revertWhen_QueueLookupNoLimit()
        public
        assertInvariants
    {
        uint256 noId = createNodeOperator({ keysCount: 2 });
        uploadMoreKeys(noId, 1);
        unvetKeys({ noId: noId, to: 2 });

        vm.expectRevert(IQueueLib.QueueLookupNoLimit.selector);
        CSModuleTestable(address(module)).cleanDepositQueueTestable(0);
    }
}

contract CSMPriorityQueue is ModulePriorityQueue, CSMCommon {
    function test_migrateToPriorityQueue_FromLegacyQueue() public {
        uint256 noId = createNodeOperator(0);
        CSModuleTestable(address(module))._enqueueToLegacyQueue(noId, 8);
        uploadMoreKeys(noId, 8);

        BatchInfo[] memory exp = new BatchInfo[](1);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(LEGACY_QUEUE, exp);

        _assertQueueIsEmptyByPriority(REGULAR_QUEUE);
        _assertQueueIsEmptyByPriority(PRIORITY_QUEUE);

        _enablePriorityQueue(PRIORITY_QUEUE, MAX_DEPOSITS);

        {
            vm.expectEmit(address(module));
            emit ICSModule.BatchEnqueued(PRIORITY_QUEUE, noId, 8);

            module.migrateToPriorityQueue(noId);
        }

        assertEq(module.getNodeOperator(noId).enqueuedCount, 8 + 8);

        _assertQueueIsEmptyByPriority(REGULAR_QUEUE);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(PRIORITY_QUEUE, exp);

        exp[0] = BatchInfo({ nodeOperatorId: noId, count: 8 });
        _assertQueueState(LEGACY_QUEUE, exp);
    }
}

contract CSMDecreaseVettedSigningKeysCount is
    ModuleDecreaseVettedSigningKeysCount,
    CSMCommon
{}

contract CSMGetSigningKeys is ModuleGetSigningKeys, CSMCommon {}

contract CSMGetSigningKeysWithSignatures is
    ModuleGetSigningKeysWithSignatures,
    CSMCommon
{}

contract CSMRemoveKeys is ModuleRemoveKeys, CSMCommon {}

contract CSMRemoveKeysChargeFee is ModuleRemoveKeysChargeFee, CSMCommon {}

contract CSMRemoveKeysReverts is ModuleRemoveKeysReverts, CSMCommon {}

contract CSMGetNodeOperatorNonWithdrawnKeys is
    ModuleGetNodeOperatorNonWithdrawnKeys,
    CSMCommon
{}

contract CSMGetNodeOperatorSummary is ModuleGetNodeOperatorSummary, CSMCommon {}

contract CSMGetNodeOperator is ModuleGetNodeOperator, CSMCommon {}

contract CSMUpdateTargetValidatorsLimits is
    ModuleUpdateTargetValidatorsLimits,
    CSMCommon
{}

contract CSMUpdateExitedValidatorsCount is
    ModuleUpdateExitedValidatorsCount,
    CSMCommon
{}

contract CSMUnsafeUpdateValidatorsCount is
    ModuleUnsafeUpdateValidatorsCount,
    CSMCommon
{}

contract CSMReportELRewardsStealingPenalty is
    ModuleReportELRewardsStealingPenalty,
    CSMCommon
{}

contract CSMCancelELRewardsStealingPenalty is
    ModuleCancelELRewardsStealingPenalty,
    CSMCommon
{}

contract CSMSettleELRewardsStealingPenaltyBasic is
    ModuleSettleELRewardsStealingPenaltyBasic,
    CSMCommon
{}

contract CSMSettleELRewardsStealingPenaltyAdvanced is
    ModuleSettleELRewardsStealingPenaltyAdvanced,
    CSMCommon
{}

contract CSMCompensateELRewardsStealingPenalty is
    ModuleCompensateELRewardsStealingPenalty,
    CSMCommon
{}

contract CSMSubmitWithdrawals is ModuleSubmitWithdrawals, CSMCommon {}

contract CSMGetStakingModuleSummary is
    ModuleGetStakingModuleSummary,
    CSMCommon
{}

contract CSMAccessControl is ModuleAccessControl, CSMCommonNoRoles {}

contract CSMStakingRouterAccessControl is
    ModuleStakingRouterAccessControl,
    CSMCommonNoRoles
{}

contract CSMDepositableValidatorsCount is
    ModuleDepositableValidatorsCount,
    CSMCommon
{}

contract CSMNodeOperatorStateAfterUpdateCurve is
    ModuleNodeOperatorStateAfterUpdateCurve,
    CSMCommon
{}

contract CSMOnRewardsMinted is ModuleOnRewardsMinted, CSMCommon {}

contract CSMRecoverERC20 is ModuleRecoverERC20, CSMCommon {}

contract CSMMisc is ModuleMisc, CSMCommon {}

contract CSMExitDeadlineThreshold is ModuleExitDeadlineThreshold, CSMCommon {}

contract CSMIsValidatorExitDelayPenaltyApplicable is
    ModuleIsValidatorExitDelayPenaltyApplicable,
    CSMCommon
{}

contract CSMReportValidatorExitDelay is
    ModuleReportValidatorExitDelay,
    CSMCommon
{}

contract CSMOnValidatorExitTriggered is
    ModuleOnValidatorExitTriggered,
    CSMCommon
{}

contract CSMCreateNodeOperators is ModuleCreateNodeOperators, CSMCommon {}
