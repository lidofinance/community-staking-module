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
        assertEq(csm.getNonce(), 0);
    }

    function test_accounting_initialState() public view {
        assertFalse(accounting.isPaused());
        assertEq(accounting.totalBondShares(), 0);
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

    function test_vettedGate_initialState() public view {
        assertFalse(vettedGate.isPaused());
        assertFalse(vettedGate.isReferralProgramSeasonActive());
        assertEq(vettedGate.referralProgramSeasonNumber(), 0);
        assertEq(vettedGate.referralCurveId(), 0);
        assertEq(vettedGate.referralsThreshold(), 0);
    }
}
