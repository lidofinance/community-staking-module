// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule, NodeOperator, NodeOperatorManagementProperties } from "../../../src/CSModule.sol";
import { ICSModule } from "../../../src/interfaces/ICSModule.sol";
import { ILidoLocator } from "../../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../../src/interfaces/IStakingRouter.sol";
import { IWithdrawalQueue } from "../../../src/interfaces/IWithdrawalQueue.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { ILido } from "../../../src/interfaces/ILido.sol";
import { IWstETH } from "../../../src/interfaces/IWstETH.sol";
import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { IKernel } from "../../../src/interfaces/IKernel.sol";
import { IACL } from "../../../src/interfaces/IACL.sol";
import { InvariantAsserts } from "../../helpers/InvariantAsserts.sol";
import { Batch } from "../../../src/lib/QueueLib.sol";

contract StakingRouterIntegrationTest is
    Test,
    Utilities,
    DeploymentFixtures,
    InvariantAsserts
{
    address internal agent;
    uint256 internal moduleId;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertCSMKeys(csm);
        assertCSMEnqueuedCount(csm);
        assertAccountingTotalBondShares(noCount, lido, accounting);
        assertAccountingBurnerApproval(
            lido,
            address(accounting),
            locator.burner()
        );
        assertFeeDistributorClaimableShares(lido, feeDistributor);
        assertFeeDistributorTree(feeDistributor);
        vm.resumeGasMetering();
    }

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(stakingRouter));
        vm.stopPrank();
        if (csm.isPaused()) csm.resume();

        agent = stakingRouter.getRoleMember(
            stakingRouter.DEFAULT_ADMIN_ROLE(),
            0
        );
        vm.startPrank(agent);
        stakingRouter.grantRole(
            stakingRouter.STAKING_MODULE_MANAGE_ROLE(),
            agent
        );
        stakingRouter.grantRole(
            stakingRouter.REPORT_REWARDS_MINTED_ROLE(),
            agent
        );
        stakingRouter.grantRole(
            stakingRouter.REPORT_EXITED_VALIDATORS_ROLE(),
            agent
        );
        stakingRouter.grantRole(
            stakingRouter.UNSAFE_SET_EXITED_VALIDATORS_ROLE(),
            agent
        );
        vm.stopPrank();

        moduleId = findOrAddCSModule();
    }

    function findOrAddCSModule() internal returns (uint256) {
        uint256[] memory ids = stakingRouter.getStakingModuleIds();
        for (uint256 i = ids.length - 1; i > 0; i--) {
            IStakingRouter.StakingModule memory module = stakingRouter
                .getStakingModule(ids[i]);
            if (module.stakingModuleAddress == address(csm)) {
                return ids[i];
            }
        }
        vm.prank(agent);
        stakingRouter.addStakingModule({
            _name: "community-staking-v1",
            _stakingModuleAddress: address(csm),
            _stakeShareLimit: 10000,
            _priorityExitShareThreshold: 10000,
            _stakingModuleFee: 500,
            _treasuryFee: 500,
            _maxDepositsPerBlock: 30,
            _minDepositBlockDistance: 25
        });
        return ids.length + 1;
    }

    function addNodeOperator(
        address from,
        uint256 keysCount
    ) internal returns (uint256 nodeOperatorId) {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
        vm.deal(from, amount);

        vm.prank(from);
        nodeOperatorId = permissionlessGate.addNodeOperatorETH{
            value: amount
        }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });
    }

    function getDepositableNodeOperator()
        internal
        returns (uint256 noId, uint256 keysCount)
    {
        for (uint256 i = 0; i < csm.QUEUE_LOWEST_PRIORITY(); ++i) {
            (uint128 head, ) = csm.depositQueuePointers(i);
            Batch batch = csm.depositQueueItem(i, head);
            if (!batch.isNil()) {
                return (batch.noId(), batch.keys());
            }
        }
        keysCount = 5;
        noId = addNodeOperator(nextAddress(), keysCount);
    }

    function hugeDeposit() internal {
        // It's impossible to process deposits if withdrawal requests amount is more than the buffered ether,
        // so we need to make sure that the buffered ether is enough by submitting this tremendous amount.
        handleStakingLimit();
        handleBunkerMode();

        address whale = nextAddress();
        vm.prank(whale);
        vm.deal(whale, 1e7 ether);
        lido.submit{ value: 1e7 ether }(address(0));
    }

    function lidoDepositWithNoGasMetering(uint256 keysCount) internal {
        // @dev: depositing keys without gas metering in case of huge queue
        vm.startPrank(locator.depositSecurityModule());
        vm.pauseGasMetering();
        lido.deposit(keysCount, moduleId, "");
        vm.resumeGasMetering();
        vm.stopPrank();
    }

    function test_connectCSMToRouter() public view {
        IStakingRouter.StakingModule memory module = stakingRouter
            .getStakingModule(moduleId);
        assertTrue(module.stakingModuleAddress == address(csm));
    }

    function test_RouterDeposit() public assertInvariants {
        (uint256 noId, uint256 keysCount) = getDepositableNodeOperator();
        uint256 depositedKeysBefore = csm
            .getNodeOperator(noId)
            .totalDepositedKeys;

        hugeDeposit();

        lidoDepositWithNoGasMetering(keysCount);
        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalDepositedKeys, depositedKeysBefore + keysCount);
    }

    function test_routerReportRewardsMinted() public assertInvariants {
        uint256 prevShares = lido.sharesOf(address(feeDistributor));

        uint256 ethToStake = 1 ether;
        address dummy = nextAddress();
        vm.startPrank(dummy);
        vm.deal(dummy, ethToStake);
        uint256 rewardsShares = lido.submit{ value: ethToStake }(address(0));
        lido.transferShares(address(csm), rewardsShares);
        vm.stopPrank();

        uint256[] memory moduleIds = new uint256[](1);
        uint256[] memory rewards = new uint256[](1);
        moduleIds[0] = moduleId;
        rewards[0] = rewardsShares;

        vm.prank(agent);
        vm.expectCall(
            address(csm),
            abi.encodeCall(csm.onRewardsMinted, (rewardsShares))
        );
        stakingRouter.reportRewardsMinted(moduleIds, rewards);

        assertEq(lido.sharesOf(address(csm)), 0);
        assertEq(
            lido.sharesOf(address(feeDistributor)),
            prevShares + rewardsShares
        );
    }

    function test_updateTargetValidatorsLimits() public assertInvariants {
        address nodeOperatorManager = nextAddress();
        uint256 noId = addNodeOperator(nodeOperatorManager, 5);

        vm.prank(agent);
        stakingRouter.updateTargetValidatorsLimits(moduleId, noId, 1, 2);

        (
            uint256 targetLimitMode,
            uint256 targetValidatorsCount,
            ,
            ,
            ,
            ,
            ,

        ) = csm.getNodeOperatorSummary(noId);
        assertEq(targetLimitMode, 1);
        assertEq(targetValidatorsCount, 2);
    }

    function test_updateRefundedValidatorsCount() public assertInvariants {
        address nodeOperatorManager = nextAddress();
        uint256 noId = addNodeOperator(nodeOperatorManager, 5);

        vm.expectRevert(ICSModule.NotSupported.selector);
        vm.prank(agent);
        stakingRouter.updateRefundedValidatorsCount(moduleId, noId, 1);
    }

    function test_reportStakingModuleExitedValidatorsCountByNodeOperator()
        public
        assertInvariants
    {
        (uint256 noId, uint256 keysCount) = getDepositableNodeOperator();
        uint256 exitedKeysBefore = csm.getNodeOperator(noId).totalExitedKeys;

        hugeDeposit();

        lidoDepositWithNoGasMetering(keysCount);

        uint256 exited = 1;
        vm.prank(agent);
        stakingRouter.reportStakingModuleExitedValidatorsCountByNodeOperator(
            moduleId,
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(exited)))
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, exitedKeysBefore + exited);
    }

    function test_getStakingModuleSummary() public assertInvariants {
        IStakingRouter.StakingModuleSummary memory summaryOld = stakingRouter
            .getStakingModuleSummary(moduleId);

        (uint256 noId, uint256 keysCount) = getDepositableNodeOperator();

        hugeDeposit();

        lidoDepositWithNoGasMetering(keysCount);

        uint256 exited = 1;
        vm.prank(agent);
        stakingRouter.reportStakingModuleExitedValidatorsCountByNodeOperator(
            moduleId,
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(exited)))
        );

        IStakingRouter.StakingModuleSummary memory summary = stakingRouter
            .getStakingModuleSummary(moduleId);
        assertEq(
            summary.totalExitedValidators,
            summaryOld.totalExitedValidators + exited
        );
        assertEq(
            summary.totalDepositedValidators,
            summaryOld.totalDepositedValidators + keysCount
        );
        assertEq(
            summary.depositableValidatorsCount,
            summaryOld.depositableValidatorsCount - keysCount
        );
    }

    function test_getNodeOperatorSummary() public assertInvariants {
        (uint256 noId, uint256 keysCount) = getDepositableNodeOperator();
        uint256 depositedValidatorsBefore = csm
            .getNodeOperator(noId)
            .totalDepositedKeys;
        uint256 depositableValidatorsCount = csm
            .getNodeOperator(noId)
            .depositableValidatorsCount;

        hugeDeposit();

        (, , uint256 totalDepositableKeys) = csm.getStakingModuleSummary();
        lidoDepositWithNoGasMetering(keysCount);

        uint256 exited = 1;
        vm.prank(agent);
        stakingRouter.reportStakingModuleExitedValidatorsCountByNodeOperator(
            moduleId,
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(exited)))
        );

        IStakingRouter.NodeOperatorSummary memory summary = stakingRouter
            .getNodeOperatorSummary(moduleId, noId);
        assertEq(summary.targetLimitMode, 0);
        assertEq(summary.targetValidatorsCount, 0);
        assertEq(summary.stuckValidatorsCount, 0);
        assertEq(summary.refundedValidatorsCount, 0);
        assertEq(summary.stuckPenaltyEndTimestamp, 0);
        assertEq(summary.totalExitedValidators, exited);
        assertEq(
            summary.totalDepositedValidators,
            depositedValidatorsBefore + keysCount
        );
        assertEq(
            summary.depositableValidatorsCount,
            depositableValidatorsCount - keysCount
        );
    }

    function test_unsafeSetExitedValidatorsCount() public assertInvariants {
        hugeDeposit();
        uint256 noId;
        uint256 keysCount;

        for (;;) {
            (noId, keysCount) = getDepositableNodeOperator();
            lidoDepositWithNoGasMetering(keysCount);
            /// we need to be sure there are more than 1 keys for further checks
            if (csm.getNodeOperator(noId).totalDepositedKeys > 1) {
                break;
            }
        }

        uint256 exited = 2;
        vm.prank(agent);
        stakingRouter.reportStakingModuleExitedValidatorsCountByNodeOperator(
            moduleId,
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(exited)))
        );

        IStakingRouter.StakingModule memory moduleInfo = stakingRouter
            .getStakingModule(moduleId);

        uint256 unsafeExited = 1;

        IStakingRouter.ValidatorsCountsCorrection
            memory correction = IStakingRouter.ValidatorsCountsCorrection({
                currentModuleExitedValidatorsCount: moduleInfo
                    .exitedValidatorsCount,
                currentNodeOperatorExitedValidatorsCount: exited,
                currentNodeOperatorStuckValidatorsCount: 0,
                // dirty hack since prev call does not update total counts
                newModuleExitedValidatorsCount: moduleInfo
                    .exitedValidatorsCount + unsafeExited,
                newNodeOperatorExitedValidatorsCount: unsafeExited,
                newNodeOperatorStuckValidatorsCount: 0
            });
        vm.prank(agent);
        stakingRouter.unsafeSetExitedValidatorsCount(
            moduleId,
            noId,
            false,
            correction
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalExitedKeys, unsafeExited);
    }

    function test_decreaseVettedSigningKeysCount() public assertInvariants {
        address nodeOperatorManager = nextAddress();
        uint256 totalKeys = 10;
        uint256 newVetted = 2;
        uint256 noId = addNodeOperator(nodeOperatorManager, totalKeys);

        vm.prank(
            stakingRouter.getRoleMember(
                stakingRouter.STAKING_MODULE_UNVETTING_ROLE(),
                0
            )
        );
        stakingRouter.decreaseStakingModuleVettedKeysCountByNodeOperator(
            moduleId,
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(newVetted)))
        );

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.totalVettedKeys, newVetted);
        assertEq(no.depositableValidatorsCount, newVetted);
    }
}
