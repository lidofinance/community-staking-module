// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../../helpers/Fixtures.sol";
import { NodeOperator } from "../../../../src/interfaces/ICSModule.sol";
import { QueueLib, Batch } from "../../../../src/lib/QueueLib.sol";
import { InvariantAsserts } from "../../../helpers/InvariantAsserts.sol";

contract InvariantsBase is
    Test,
    Utilities,
    DeploymentFixtures,
    InvariantAsserts
{
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        adminsCount = block.chainid == 1 ? 1 : 2;
    }
}

using QueueLib for QueueLib.Queue;

contract CSModuleInvariants is InvariantsBase {
    function test_keys() public noGasMetering {
        assertCSMKeys(csm);
    }

    function test_enqueuedCount() public noGasMetering {
        assertCSMEnqueuedCount(csm);
    }

    function test_roles() public view {
        assertEq(
            csm.getRoleMemberCount(csm.DEFAULT_ADMIN_ROLE()),
            adminsCount,
            "default admin"
        );
        assertEq(csm.getRoleMemberCount(csm.PAUSE_ROLE()), 1, "pause");
        assertEq(
            csm.getRoleMember(csm.PAUSE_ROLE(), 0),
            address(gateSeal),
            "pause address"
        );
        assertEq(csm.getRoleMemberCount(csm.RESUME_ROLE()), 0, "resume");
        assertEq(
            csm.getRoleMemberCount(csm.STAKING_ROUTER_ROLE()),
            1,
            "staking router"
        );
        assertEq(
            csm.getRoleMemberCount(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE()
            ),
            1,
            "report el rewards stealing penalty"
        );
        assertEq(
            csm.getRoleMemberCount(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE()
            ),
            1,
            "settle el rewards stealing penalty"
        );
        assertEq(csm.getRoleMemberCount(csm.VERIFIER_ROLE()), 1, "verifier");
        assertEq(
            csm.getRoleMember(csm.VERIFIER_ROLE(), 0),
            address(verifier),
            "verifier address"
        );
        assertEq(csm.getRoleMemberCount(csm.RECOVERER_ROLE()), 0, "recoverer");
    }
}

contract CSAccountingInvariants is InvariantsBase {
    function test_sharesAccounting() public noGasMetering {
        uint256 noCount = csm.getNodeOperatorsCount();
        assertAccountingTotalBondShares(noCount, lido, accounting);
    }

    function test_burnerApproval() public {
        assertAccountingBurnerApproval(
            lido,
            address(accounting),
            locator.burner()
        );
    }

    function test_roles() public view {
        assertEq(
            accounting.getRoleMemberCount(accounting.DEFAULT_ADMIN_ROLE()),
            adminsCount,
            "default admin"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.PAUSE_ROLE()),
            1,
            "pause"
        );
        assertEq(
            accounting.getRoleMember(accounting.PAUSE_ROLE(), 0),
            address(gateSeal),
            "pause address"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.RESUME_ROLE()),
            0,
            "resume"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.MANAGE_BOND_CURVES_ROLE()),
            0,
            "manage bond curves"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.RECOVERER_ROLE()),
            0,
            "recoverer"
        );
    }
}

contract CSFeeDistributorInvariants is InvariantsBase {
    function test_claimableShares() public {
        assertFeeDistributorClaimableShares(lido, feeDistributor);
    }

    function test_tree() public {
        assertFeeDistributorTree(feeDistributor);
    }

    function test_roles() public view {
        assertEq(
            feeDistributor.getRoleMemberCount(
                feeDistributor.DEFAULT_ADMIN_ROLE()
            ),
            adminsCount,
            "default admin"
        );
        assertEq(
            feeDistributor.getRoleMemberCount(feeDistributor.RECOVERER_ROLE()),
            0,
            "recoverer"
        );
    }
}

contract CSFeeOracleInvariant is InvariantsBase {
    function test_roles() public view {
        assertEq(
            oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE()),
            adminsCount,
            "default admin"
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.SUBMIT_DATA_ROLE()),
            0,
            "submit data"
        );
        assertEq(oracle.getRoleMemberCount(oracle.PAUSE_ROLE()), 1, "pause");
        assertEq(
            oracle.getRoleMember(oracle.PAUSE_ROLE(), 0),
            address(gateSeal),
            "pause address"
        );
        assertEq(oracle.getRoleMemberCount(oracle.RESUME_ROLE()), 0, "resume");
        assertEq(
            oracle.getRoleMemberCount(oracle.RECOVERER_ROLE()),
            0,
            "recoverer"
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.MANAGE_CONSENSUS_CONTRACT_ROLE()),
            0,
            "manage_consensus_contract"
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.MANAGE_CONSENSUS_VERSION_ROLE()),
            0,
            "manage_consensus_version"
        );
    }
}

contract HashConsensusInvariant is InvariantsBase {
    function test_roles() public view {
        assertEq(
            oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE()),
            adminsCount,
            "default admin"
        );
    }
}

contract VerifierInvariant is InvariantsBase {
    function test_roles() public view {
        assertEq(
            verifier.getRoleMemberCount(verifier.PAUSE_ROLE()),
            1,
            "pause"
        );
        assertEq(
            verifier.getRoleMember(verifier.PAUSE_ROLE(), 0),
            address(gateSeal),
            "pause address"
        );
        assertEq(
            verifier.getRoleMemberCount(verifier.RESUME_ROLE()),
            0,
            "resume"
        );
    }
}
