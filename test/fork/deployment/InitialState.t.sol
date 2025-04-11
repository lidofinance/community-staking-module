// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { ICSBondCurve } from "../../../src/interfaces/ICSBondCurve.sol";

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

        (uint256 priority, uint256 maxDeposits) = parametersRegistry
            .defaultQueueConfig();

        assertEq(priority, deployParams.defaultQueuePriority);
        assertEq(maxDeposits, deployParams.defaultQueueMaxDeposits);

        assertEq(
            parametersRegistry.defaultBadPerformancePenalty(),
            deployParams.badPerformancePenalty
        );

        (
            uint256 attestationsWeight,
            uint256 blocksWeight,
            uint256 syncWeight
        ) = parametersRegistry.defaultPerformanceCoefficients();
        assertEq(attestationsWeight, deployParams.attestationsWeight);
        assertEq(blocksWeight, deployParams.blocksWeight);
        assertEq(syncWeight, deployParams.syncWeight);
    }

    function test_accounting_initialState() public view {
        assertFalse(accounting.isPaused());
        assertEq(accounting.totalBondShares(), 0);
        uint256 defaultCurveId = accounting.DEFAULT_BOND_CURVE_ID();
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[0].fromKeysCount,
            deployParams.bondCurve[0][0]
        );
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[0].trend,
            deployParams.bondCurve[0][1]
        );

        assertEq(
            accounting.getCurveInfo(defaultCurveId)[1].fromKeysCount,
            deployParams.bondCurve[1][0]
        );
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[1].trend,
            deployParams.bondCurve[1][1]
        );
        uint256 vettedCurveId = vettedGate.curveId();
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[0].fromKeysCount,
            deployParams.vettedGateBondCurve[0][0]
        );
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[0].trend,
            deployParams.vettedGateBondCurve[0][1]
        );
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[1].fromKeysCount,
            deployParams.vettedGateBondCurve[1][0]
        );
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[1].trend,
            deployParams.vettedGateBondCurve[1][1]
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
