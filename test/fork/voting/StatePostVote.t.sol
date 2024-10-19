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
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_module_initialState() public {
        assertFalse(csm.isPaused());
        assertFalse(csm.publicRelease());
    }

    function test_acounting_initialState() public {
        assertFalse(accounting.isPaused());
        assertEq(
            accounting.getCurveInfo(earlyAdoption.CURVE_ID()).points,
            deployParams.earlyAdoptionBondCurve
        );
    }

    function test_feedistirbutor_initialState() public {
        assertEq(feeDistributor.totalClaimableShares(), 0);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(
            keccak256(abi.encodePacked(feeDistributor.treeCid())),
            keccak256("")
        );
    }

    function test_feeoracle_initialState() public {
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

    function test_hashconsensus_initialState() public {
        vm.skip(block.chainid != 1);
        assertEq(hashConsensus.getQuorum(), deployParams.hashConsensusQuorum);

        (address[] memory membersAO, ) = HashConsensus(
            BaseOracle(locator.accountingOracle()).getConsensusContract()
        ).getMembers();
        (address[] memory membersCSM, ) = hashConsensus.getMembers();
        assertEq(
            keccak256(abi.encode(membersAO)),
            keccak256(abi.encode(membersCSM))
        );
    }
}
