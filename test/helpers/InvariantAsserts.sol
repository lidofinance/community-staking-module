// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { IStETH } from "../../src/interfaces/IStETH.sol";
import { IBurner } from "../../src/interfaces/IBurner.sol";
import { CSFeeDistributor } from "../../src/CSFeeDistributor.sol";
import { CSModule } from "../../src/CSModule.sol";
import { NodeOperator } from "../../src/interfaces/ICSModule.sol";
import { Batch } from "../../src/lib/QueueLib.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { CSStrikes } from "../../src/CSStrikes.sol";
import { console } from "forge-std/console.sol";
import { CSFeeOracle } from "../../src/CSFeeOracle.sol";

contract InvariantAsserts is Test {
    bool internal _skipped;

    function skipInvariants() public returns (bool skip) {
        if (_skipped) {
            return true;
        }
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        bool isCIProfile = keccak256(abi.encodePacked(profile)) ==
            keccak256(abi.encodePacked("ci"));
        bool forkIsActive;
        try vm.activeFork() returns (uint256) {
            forkIsActive = true;
        } catch {}
        skip = !isCIProfile && forkIsActive;
        if (skip) {
            console.log(
                "WARN: Skipping invariants. It only runs with FOUNDRY_PROFILE=ci and active fork"
            );
            _skipped = true;
        }
    }

    function assertCSMKeys(CSModule csm) public {
        if (skipInvariants()) {
            return;
        }
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

    function assertCSMEnqueuedCount(CSModule csm) public {
        if (skipInvariants()) {
            return;
        }
        uint256 noCount = csm.getNodeOperatorsCount();
        NodeOperator memory no;

        for (uint256 p = 0; p <= csm.QUEUE_LOWEST_PRIORITY(); ++p) {
            (uint128 head, uint128 tail) = csm.depositQueuePointers(p);

            for (uint128 i = head; i < tail; ) {
                Batch item = csm.depositQueueItem(p, i);
                batchKeys[item.noId()] += item.keys();
                i = item.next();
            }
        }

        for (uint256 noId = 0; noId < noCount; noId++) {
            no = csm.getNodeOperator(noId);
            assertEq(
                no.enqueuedCount,
                batchKeys[noId],
                "assert enqueued == batch keys"
            );
            assertGe(
                no.enqueuedCount,
                no.depositableValidatorsCount,
                "assert enqueued >= depositable"
            );
        }
    }

    function assertCSMUnusedStorageSlots(CSModule csm) public {
        if (skipInvariants()) {
            return;
        }
        bytes32 value;
        // _accountingOld
        value = vm.load(address(csm), bytes32(uint256(2)));
        assertEq(value, bytes32(0), "assert _accountingOld is empty");

        // _earlyAdoption
        value = vm.load(address(csm), bytes32(uint256(3)));
        assertEq(value, bytes32(0), "assert _earlyAdoption is empty");
    }

    function assertAccountingTotalBondShares(
        uint256 nodeOperatorsCount,
        IStETH steth,
        CSAccounting accounting
    ) public {
        if (skipInvariants()) {
            return;
        }
        uint256 totalNodeOperatorsShares;

        for (uint256 noId = 0; noId < nodeOperatorsCount; noId++) {
            totalNodeOperatorsShares += accounting.getBondShares(noId);
        }
        assertEq(
            totalNodeOperatorsShares,
            accounting.totalBondShares(),
            "total shares mismatch"
        );
        assertGe(
            steth.sharesOf(address(accounting)),
            accounting.totalBondShares(),
            "assert balance >= total shares"
        );
    }

    function assertAccountingBurnerApproval(
        IStETH steth,
        address accounting,
        address burner
    ) public {
        if (skipInvariants()) {
            return;
        }
        assertGe(
            steth.allowance(accounting, burner),
            type(uint128).max,
            "assert allowance"
        );
    }

    function assertAccountingUnusedStorageSlots(
        CSAccounting accounting
    ) public {
        if (skipInvariants()) {
            return;
        }
        // _feeDistributorOld
        bytes32 value = vm.load(address(accounting), bytes32(uint256(0)));
        assertEq(value, bytes32(0), "assert _feeDistributorOld is empty");
    }

    function assertFeeDistributorClaimableShares(
        IStETH lido,
        CSFeeDistributor feeDistributor
    ) public {
        if (skipInvariants()) {
            return;
        }
        assertGe(
            lido.sharesOf(address(feeDistributor)),
            feeDistributor.totalClaimableShares(),
            "assert balance >= claimable"
        );
    }

    function assertFeeDistributorTree(CSFeeDistributor feeDistributor) public {
        if (skipInvariants()) {
            return;
        }
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

    function assertFeeOracleUnusedStorageSlots(CSFeeOracle feeOracle) public {
        if (skipInvariants()) {
            return;
        }
        bytes32 value;
        // _feeDistributor
        value = vm.load(address(feeOracle), bytes32(uint256(0)));
        assertEq(value, bytes32(0), "assert _feeDistributor is empty");

        // _avgPerfLeewayBP
        value = vm.load(address(feeOracle), bytes32(uint256(1)));
        assertEq(value, bytes32(0), "assert _avgPerfLeewayBP is empty");
    }

    function assertStrikesTree(CSStrikes strikes) public {
        if (skipInvariants()) {
            return;
        }
        if (strikes.treeRoot() == bytes32(0)) {
            assertEq(strikes.treeCid(), "", "tree doesn't exist, but has CID");
        } else {
            assertNotEq(strikes.treeCid(), "", "tree exists, but has no CID");
        }
    }
}
