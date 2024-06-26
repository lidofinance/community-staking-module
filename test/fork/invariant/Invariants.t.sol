// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { NodeOperator } from "../../../src/interfaces/ICSModule.sol";
import "../../../src/lib/QueueLib.sol";

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

        (uint128 head, uint128 length) = csm.depositQueue();
        for (uint128 i = head; i < length; i++) {
            Batch item = csm.depositQueueItem(i);
            batchKeys[item.noId()] += item.keys();
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

            assertTrue(
                no.totalAddedKeys <=
                    csm.MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE()
            );
        }
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
}
