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

contract ContractsStateTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_moduleState() public {
        assertFalse(csm.isPaused());
        assertFalse(csm.publicRelease());
    }

    function test_moduleRoles() public {
        assertTrue(
            csm.hasRole(csm.DEFAULT_ADMIN_ROLE(), deployParams.aragonAgent)
        );
        assertTrue(
            csm.getRoleMemberCount(csm.DEFAULT_ADMIN_ROLE()) == adminsCount
        );
        assertTrue(csm.hasRole(csm.PAUSE_ROLE(), address(gateSeal)));
        assertEq(csm.getRoleMemberCount(csm.PAUSE_ROLE()), 1);
        assertEq(csm.getRoleMemberCount(csm.RESUME_ROLE()), 0);
        assertTrue(
            csm.hasRole(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
                address(deployParams.elRewardsStealingReporter)
            )
        );
        assertEq(
            csm.getRoleMemberCount(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE()
            ),
            1
        );
        assertTrue(
            csm.hasRole(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
                address(deployParams.easyTrackEVMScriptExecutor)
            )
        );
        assertEq(
            csm.getRoleMemberCount(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE()
            ),
            1
        );
        assertTrue(csm.hasRole(csm.VERIFIER_ROLE(), address(verifier)));
        assertEq(csm.getRoleMemberCount(csm.VERIFIER_ROLE()), 1);
        assertEq(csm.getRoleMemberCount(csm.RECOVERER_ROLE()), 0);
    }

    function test_accountingState() public {
        assertFalse(accounting.isPaused());
        assertEq(
            accounting.getCurveInfo(earlyAdoption.curveId()).points,
            deployParams.earlyAdoptionBondCurve
        );
    }

    function test_accountingRoles() public {
        assertTrue(
            accounting.hasRole(
                accounting.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );

        assertTrue(
            accounting.hasRole(accounting.PAUSE_ROLE(), address(gateSeal))
        );
        assertEq(accounting.getRoleMemberCount(accounting.PAUSE_ROLE()), 1);

        assertTrue(
            accounting.hasRole(
                accounting.SET_BOND_CURVE_ROLE(),
                deployParams.setResetBondCurveAddress
            )
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.SET_BOND_CURVE_ROLE()),
            2
        );
        assertTrue(
            accounting.hasRole(
                accounting.RESET_BOND_CURVE_ROLE(),
                deployParams.setResetBondCurveAddress
            )
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.RESET_BOND_CURVE_ROLE()),
            2
        );
        assertEq(accounting.getRoleMemberCount(accounting.RESUME_ROLE()), 0);
        assertEq(
            accounting.getRoleMemberCount(accounting.MANAGE_BOND_CURVES_ROLE()),
            0
        );
        assertEq(accounting.getRoleMemberCount(accounting.RECOVERER_ROLE()), 0);
    }

    function test_feeDistributorState() public {
        // The conditions below are true just after the vote, but can be broken afterward.
        vm.skip(true);

        assertEq(feeDistributor.totalClaimableShares(), 0);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(
            keccak256(abi.encodePacked(feeDistributor.treeCid())),
            keccak256("")
        );
    }

    function test_feeDistributor_roles() public {
        assertTrue(
            feeDistributor.hasRole(
                feeDistributor.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertTrue(
            feeDistributor.getRoleMemberCount(
                feeDistributor.DEFAULT_ADMIN_ROLE()
            ) == adminsCount
        );
        assertEq(
            feeDistributor.getRoleMemberCount(feeDistributor.RECOVERER_ROLE()),
            0
        );
    }

    function test_feeOracle_state() public {
        // NOTE: It assumes the first report has been settled.
        assertFalse(oracle.isPaused());
        (
            bytes32 hash,
            uint256 refSlot,
            uint256 processingDeadlineTime,
            bool processingStarted
        ) = oracle.getConsensusReport();
        assertFalse(hash == bytes32(0), "expected report hash to be non-zero");
        assertGt(refSlot, 0);
        assertGt(processingDeadlineTime, 0);
    }

    function test_feeOracle_roles() public {
        assertTrue(
            oracle.hasRole(
                oracle.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );
        assertTrue(oracle.hasRole(oracle.PAUSE_ROLE(), address(gateSeal)));
        assertEq(oracle.getRoleMemberCount(oracle.PAUSE_ROLE()), 1);
        assertEq(oracle.getRoleMemberCount(oracle.RESUME_ROLE()), 0);
        assertEq(oracle.getRoleMemberCount(oracle.SUBMIT_DATA_ROLE()), 0);
        assertEq(oracle.getRoleMemberCount(oracle.RECOVERER_ROLE()), 0);
        assertEq(
            oracle.getRoleMemberCount(oracle.MANAGE_CONSENSUS_CONTRACT_ROLE()),
            0
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.MANAGE_CONSENSUS_VERSION_ROLE()),
            0
        );
    }

    function test_hashConsensus_state() public {
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

    function test_hashConsensus_roles() public {
        assertTrue(
            hashConsensus.hasRole(
                hashConsensus.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.DEFAULT_ADMIN_ROLE()
            ),
            adminsCount
        );

        assertTrue(
            hashConsensus.hasRole(
                hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE(),
                deployParams.aragonAgent
            )
        );

        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE()
            ),
            1
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.DISABLE_CONSENSUS_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_FRAME_CONFIG_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_FAST_LANE_CONFIG_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_REPORT_PROCESSOR_ROLE()
            ),
            0
        );
    }
}
