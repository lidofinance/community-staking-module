// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { NodeOperator } from "../../../src/interfaces/ICSModule.sol";
import { QueueLib, Batch } from "../../../src/lib/QueueLib.sol";

contract InvariantsBase is Test, Utilities, DeploymentFixtures {
    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
    }
}

using QueueLib for QueueLib.Queue;

contract CSModuleInvariants is InvariantsBase {
    function test_keys() public {
        uint256 noCount = csm.getNodeOperatorsCount();
        NodeOperator memory no;

        uint256 totalDepositedValidators;
        uint256 totalExitedValidators;
        uint256 totalDepositableValidators;

        for (uint256 noId = 0; noId < noCount; noId++) {
            no = csm.getNodeOperator(noId);

            assertGe(
                no.totalAddedKeys,
                no.totalDepositedKeys,
                "assert added >= deposited"
            );
            assertGe(
                no.totalDepositedKeys,
                no.totalWithdrawnKeys,
                "assert deposited >= withdrawn"
            );
            assertGe(
                no.totalVettedKeys,
                no.totalDepositedKeys,
                "assert vetted >= deposited"
            );

            assertGe(
                no.totalDepositedKeys - no.totalExitedKeys,
                no.stuckValidatorsCount,
                "assert deposited - exited >= stuck"
            );

            assertGe(
                no.totalAddedKeys,
                no.depositableValidatorsCount + no.totalWithdrawnKeys,
                "assert added >= depositable + withdrawn"
            );
            assertGe(
                no.totalAddedKeys - no.totalDepositedKeys,
                no.depositableValidatorsCount,
                "assert added - deposited >= depositable"
            );

            assertNotEq(
                no.proposedManagerAddress,
                no.managerAddress,
                "assert proposed != manager"
            );
            assertNotEq(
                no.proposedRewardAddress,
                no.rewardAddress,
                "assert proposed != reward"
            );
            assertNotEq(no.managerAddress, address(0), "assert manager != 0");
            assertNotEq(no.rewardAddress, address(0), "assert reward != 0");

            totalExitedValidators += no.totalExitedKeys;
            totalDepositedValidators += no.totalDepositedKeys;
            totalDepositableValidators += no.depositableValidatorsCount;
        }

        (
            uint256 _totalExitedValidators,
            uint256 _totalDepositedValidators,
            uint256 _depositableValidatorsCount
        ) = csm.getStakingModuleSummary();
        assertEq(
            totalExitedValidators,
            _totalExitedValidators,
            "assert total exited"
        );
        assertEq(
            totalDepositedValidators,
            _totalDepositedValidators,
            "assert total deposited"
        );
        assertEq(
            totalDepositableValidators,
            _depositableValidatorsCount,
            "assert depositable"
        );
    }

    mapping(uint256 => uint256) batchKeys;

    function test_enqueuedCount() public {
        uint256 noCount = csm.getNodeOperatorsCount();
        NodeOperator memory no;

        (uint128 head, uint128 tail) = csm.depositQueue();
        for (uint128 i = head; i < tail; ) {
            Batch item = csm.depositQueueItem(i);
            batchKeys[item.noId()] += item.keys();
            i = item.next();
        }

        for (uint256 noId = 0; noId < noCount; noId++) {
            no = csm.getNodeOperator(noId);
            assertEq(
                no.enqueuedCount,
                batchKeys[noId],
                "assert enqueued == batch keys"
            );
        }
    }

    function test_earlyAdoptionMaxKeys() public {
        vm.skip(csm.publicRelease());

        uint256 noCount = csm.getNodeOperatorsCount();
        NodeOperator memory no;
        for (uint256 noId = 0; noId < noCount; noId++) {
            no = csm.getNodeOperator(noId);

            assertGe(
                csm.MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE(),
                no.totalAddedKeys
            );
        }
    }

    function test_roles() public {
        assertEq(
            csm.getRoleMemberCount(csm.DEFAULT_ADMIN_ROLE()),
            1,
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
            csm.getRoleMemberCount(csm.MODULE_MANAGER_ROLE()),
            0,
            "module manager"
        );
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
    function test_sharesAccounting() public {
        uint256 noCount = csm.getNodeOperatorsCount();
        uint256 totalNodeOperatorsShares;

        for (uint256 noId = 0; noId < noCount; noId++) {
            totalNodeOperatorsShares += accounting.getBondShares(noId);
        }
        assertEq(
            totalNodeOperatorsShares,
            accounting.totalBondShares(),
            "total shares mismatch"
        );
        assertGe(
            lido.sharesOf(address(accounting)),
            accounting.totalBondShares(),
            "assert balance >= total shares"
        );
    }

    function test_burnerApproval() public {
        assertGe(
            lido.allowance(address(accounting), address(locator.burner())),
            type(uint128).max,
            "assert allowance"
        );
    }

    function test_roles() public {
        assertEq(
            accounting.getRoleMemberCount(accounting.DEFAULT_ADMIN_ROLE()),
            1,
            "default admin"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.PAUSE_ROLE()),
            1,
            "pause"
        );
        assertEq(
            csm.getRoleMember(accounting.PAUSE_ROLE(), 0),
            address(gateSeal),
            "pause address"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.RESUME_ROLE()),
            0,
            "resume"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.ACCOUNTING_MANAGER_ROLE()),
            0,
            "accounting manager"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.MANAGE_BOND_CURVES_ROLE()),
            0,
            "manage bond curves"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.SET_BOND_CURVE_ROLE()),
            2,
            "set bond curve"
        );
        assertTrue(
            accounting.hasRole(accounting.SET_BOND_CURVE_ROLE(), address(csm)),
            "set bond curve csm"
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.RESET_BOND_CURVE_ROLE()),
            2,
            "reset bond curve"
        );
        assertTrue(
            accounting.hasRole(
                accounting.RESET_BOND_CURVE_ROLE(),
                address(csm)
            ),
            "reset bond curve csm"
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
        assertGe(
            lido.sharesOf(address(feeDistributor)),
            feeDistributor.totalClaimableShares(),
            "assert balance >= claimable"
        );
    }

    function test_tree() public {
        if (feeDistributor.treeRoot() == bytes32(0)) {
            assertEq(
                feeDistributor.treeCid(),
                "",
                "tree doesn't exist, but has CID"
            );
        } else {
            assertNotEq(
                feeDistributor.treeCid(),
                "",
                "tree exists, but has no CID"
            );
        }
    }

    function test_roles() public {
        assertEq(
            feeDistributor.getRoleMemberCount(
                feeDistributor.DEFAULT_ADMIN_ROLE()
            ),
            1
        );
        assertEq(
            feeDistributor.getRoleMemberCount(feeDistributor.RECOVERER_ROLE()),
            0
        );
    }
}

contract CSFeeOracleInvariant is InvariantsBase {
    function test_roles() public {
        assertEq(
            oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE()),
            1,
            "default admin"
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.CONTRACT_MANAGER_ROLE()),
            0,
            "contract manager"
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.SUBMIT_DATA_ROLE()),
            0,
            "submit data"
        );
        assertEq(oracle.getRoleMemberCount(oracle.PAUSE_ROLE()), 1, "pause");
        assertEq(
            csm.getRoleMember(oracle.PAUSE_ROLE(), 0),
            address(gateSeal),
            "pause address"
        );
        assertEq(oracle.getRoleMemberCount(oracle.RESUME_ROLE()), 0, "resume");
        assertEq(
            oracle.getRoleMemberCount(oracle.RECOVERER_ROLE()),
            0,
            "recoverer"
        );
    }
}
