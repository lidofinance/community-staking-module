// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { DeployParams } from "../../../script/DeployBase.s.sol";
import { HashConsensus } from "../../../src/lib/base-oracle/HashConsensus.sol";
import { BaseOracle } from "../../../src/lib/base-oracle/BaseOracle.sol";
import { Slot } from "../../../src/lib/Types.sol";

contract ContractsInitialStateTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_module_initialState() public view {
        assertTrue(csm.isPaused());
        assertFalse(csm.publicRelease());
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_parametersRegistry_initialState() public view {
        assertEq(
            parametersRegistry.defaultKeyRemovalCharge(),
            deployParams.keyRemovalCharge
        );
        assertEq(
            parametersRegistry.defaultElRewardsStealingAdditionalFine(),
            deployParams.elRewardsStealingAdditionalFine
        );
        assertEq(
            parametersRegistry.defaultPriorityQueueLimit(),
            deployParams.priorityQueueLimit
        );
        assertEq(
            parametersRegistry.defaultRewardShare(),
            deployParams.rewardShareBP
        );
        assertEq(
            parametersRegistry.defaultPerformanceLeeway(),
            deployParams.avgPerfLeewayBP
        );
        (uint256 strikesLifetime, uint256 strikesThreshold) = parametersRegistry
            .defaultStrikesParams();
        assertEq(strikesLifetime, deployParams.strikesLifetimeFrames);
        assertEq(strikesThreshold, deployParams.strikesThreshold);
    }

    function test_accounting_initialState() public view {
        assertFalse(accounting.isPaused());
        assertEq(accounting.totalBondShares(), 0);
        assertEq(
            accounting.getCurveInfo(vettedGate.CURVE_ID()).points,
            deployParams.vettedGateBondCurve
        );
    }

    function test_feeDistributor_initialState() public view {
        assertEq(feeDistributor.totalClaimableShares(), 0);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(
            keccak256(abi.encodePacked(feeDistributor.treeCid())),
            keccak256("")
        );
    }

    function test_strikes_initialState() public view {
        assertEq(strikes.treeRoot(), bytes32(0));
        assertEq(keccak256(abi.encodePacked(strikes.treeCid())), keccak256(""));
    }

    function test_feeOracle_initialState() public view {
        assertFalse(oracle.isPaused());
        (
            bytes32 hash,
            uint256 refSlot,
            uint256 processingDeadlineTime,
            bool processingStarted
        ) = oracle.getConsensusReport();
        assertEq(hash, bytes32(0));
        assertEq(refSlot, 0);
        assertEq(processingDeadlineTime, 0);
        assertFalse(processingStarted);
    }

    function test_hashConsensus_initialState() public {
        vm.skip(block.chainid != 1);
        assertEq(hashConsensus.getQuorum(), deployParams.hashConsensusQuorum);
        (address[] memory members, ) = hashConsensus.getMembers();
        assertEq(
            keccak256(abi.encode(members)),
            keccak256(abi.encode(deployParams.oracleMembers))
        );

        (members, ) = HashConsensus(
            BaseOracle(locator.accountingOracle()).getConsensusContract()
        ).getMembers();
        assertEq(
            keccak256(abi.encode(members)),
            keccak256(abi.encode(deployParams.oracleMembers))
        );
    }
}
