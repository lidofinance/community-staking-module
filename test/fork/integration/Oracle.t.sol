// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import "../../helpers/Fixtures.sol";
import "../../helpers/MerkleTree.sol";

import { ICSStrikes } from "../../../src/interfaces/ICSStrikes.sol";
import { ICSFeeOracle } from "../../../src/interfaces/ICSFeeOracle.sol";
import { ICSExitPenalties } from "../../../src/interfaces/ICSExitPenalties.sol";
import { NodeOperatorManagementProperties } from "../../../src/interfaces/ICSModule.sol";
import { InvariantAsserts } from "../../helpers/InvariantAsserts.sol";
import { Utilities } from "../../helpers/Utilities.sol";
import { Batch } from "../../../src/lib/QueueLib.sol";

contract OracleTest is Test, Utilities, DeploymentFixtures, InvariantAsserts {
    uint256 private nodeOperatorId;
    MerkleTree private feesTree;
    MerkleTree private strikesTree;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        feesTree = new MerkleTree();
        strikesTree = new MerkleTree();

        if (csm.isPaused()) {
            csm.resume();
        }

        hugeDeposit();

        uint256 keysCount;
        uint256 moduleId = findCSModule();
        (nodeOperatorId, keysCount) = getDepositableNodeOperator(nextAddress());
        vm.prank(locator.depositSecurityModule());
        lido.deposit(keysCount, moduleId, "");
    }

    function reachConsensus(uint256 refSlot, bytes32 hash) public {
        (address[] memory addresses, ) = hashConsensus.getFastLaneMembers();
        uint256 consensusVersion = oracle.getConsensusVersion();
        for (uint256 i = 0; i < addresses.length; i++) {
            vm.prank(addresses[i]);
            hashConsensus.submitReport(refSlot, hash, consensusVersion);
        }
    }

    function waitForNextRefSlot() public {
        (
            uint256 SLOTS_PER_EPOCH,
            uint256 SECONDS_PER_SLOT,
            uint256 GENESIS_TIME
        ) = hashConsensus.getChainConfig();
        (uint256 initialEpoch, , ) = hashConsensus.getFrameConfig();
        uint256 epoch = (block.timestamp - GENESIS_TIME) /
            SECONDS_PER_SLOT /
            SLOTS_PER_EPOCH;
        if (epoch < initialEpoch) {
            uint256 targetTime = GENESIS_TIME +
                1 +
                initialEpoch *
                SLOTS_PER_EPOCH *
                SECONDS_PER_SLOT;
            uint256 currentTime = block.timestamp;
            if (targetTime > currentTime) {
                uint256 sleepTime = targetTime - currentTime;
                vm.warp(block.timestamp + sleepTime);
            }
        }
        (uint256 refSlot, ) = hashConsensus.getCurrentFrame();

        (, uint256 EPOCHS_PER_FRAME, ) = hashConsensus.getFrameConfig();
        uint256 frameStartWithOffset = GENESIS_TIME +
            (refSlot + SLOTS_PER_EPOCH * EPOCHS_PER_FRAME + 1) *
            SECONDS_PER_SLOT;
        if (frameStartWithOffset > block.timestamp) {
            vm.warp(block.timestamp + frameStartWithOffset - block.timestamp);
        }
    }

    function prepareReport(
        bytes32 feesTreeRoot,
        uint256 distributedShares,
        bytes32 strikesTreeRoot
    ) public returns (ICSFeeOracle.ReportData memory data) {
        uint256 consensusVersion = oracle.getConsensusVersion();
        waitForNextRefSlot();
        (uint256 refSlot, ) = hashConsensus.getCurrentFrame();

        data = ICSFeeOracle.ReportData({
            consensusVersion: consensusVersion,
            refSlot: refSlot,
            treeRoot: feesTreeRoot,
            treeCid: someCIDv0(),
            logCid: someCIDv0(),
            distributed: distributedShares,
            rebate: 0,
            strikesTreeRoot: strikesTreeRoot,
            strikesTreeCid: someCIDv0()
        });
        reachConsensus(refSlot, keccak256(abi.encode(data)));
    }

    function test_reportDistributedFees() public {
        vm.deal(address(feeDistributor), 1 ether);
        vm.prank(address(feeDistributor));
        lido.submit{ value: 1 ether }(address(0));
        uint256 distributed = feeDistributor.pendingSharesToDistribute();
        feesTree.pushLeaf(abi.encode(nodeOperatorId, distributed));
        feesTree.pushLeaf(abi.encode(type(uint64).max, 0));

        uint256[] memory strikesData = new uint256[](1);
        strikesData[0] = 0;
        strikesTree.pushLeaf(
            abi.encode(nodeOperatorId, randomBytes(48), strikesData)
        );
        strikesTree.pushLeaf(
            abi.encode(nodeOperatorId + 1, randomBytes(48), strikesData)
        );

        ICSFeeOracle.ReportData memory data = prepareReport(
            feesTree.root(),
            distributed,
            strikesTree.root()
        );
        uint256 contractVersion = oracle.getContractVersion();
        (address[] memory addresses, ) = hashConsensus.getMembers();
        vm.startPrank(addresses[0]);
        vm.startSnapshotGas("CSFeeOracle.submitReportData_fees");
        oracle.submitReportData(data, contractVersion);
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(
            feeDistributor.getFeesToDistribute(
                nodeOperatorId,
                distributed,
                feesTree.getProof(0)
            ),
            distributed - feeDistributor.distributedShares(nodeOperatorId)
        );
    }

    function test_reportStrikes() public {
        vm.skip(
            true,
            "requires a core protocol upgrade. consider removing this check later"
        );
        uint256 distributed = 0;
        feesTree.pushLeaf(abi.encode(type(uint64).max, 0));
        uint256 keyIndex = csm.getNodeOperatorTotalDepositedKeys(
            nodeOperatorId
        ) - 1;
        bytes memory key = csm.getSigningKeys(nodeOperatorId, keyIndex, 1);

        (, uint256 threshold) = parametersRegistry.getStrikesParams(
            accounting.getBondCurveId(nodeOperatorId)
        );
        uint256[] memory strikesData = new uint256[](threshold);
        for (uint256 i = 0; i < threshold; i++) {
            strikesData[i] = 1;
        }
        strikesTree.pushLeaf(abi.encode(nodeOperatorId, key, strikesData));
        strikesTree.pushLeaf(
            abi.encode(nodeOperatorId + 1, randomBytes(48), strikesData)
        );

        ICSFeeOracle.ReportData memory data = prepareReport(
            feesTree.root(),
            distributed,
            strikesTree.root()
        );
        uint256 contractVersion = oracle.getContractVersion();
        (address[] memory addresses, ) = hashConsensus.getMembers();
        vm.startPrank(addresses[0]);
        vm.startSnapshotGas("CSFeeOracle.submitReportData_strikes");
        oracle.submitReportData(data, contractVersion);
        vm.stopSnapshotGas();
        vm.stopPrank();

        bytes32[] memory proof = strikesTree.getProof(0);
        uint256 penalty = parametersRegistry.getBadPerformancePenalty(
            accounting.getBondCurveId(nodeOperatorId)
        );
        ICSStrikes.KeyStrikes[]
            memory keyStrikesList = new ICSStrikes.KeyStrikes[](1);
        keyStrikesList[0] = ICSStrikes.KeyStrikes({
            nodeOperatorId: nodeOperatorId,
            keyIndex: keyIndex,
            data: strikesData
        });
        bool[] memory proofFlags = new bool[](proof.length);

        vm.expectEmit(address(exitPenalties));
        emit ICSExitPenalties.StrikesPenaltyProcessed(
            nodeOperatorId,
            key,
            penalty
        );
        vm.startSnapshotGas("CSStrikes.processBadPerformanceProof");
        this.processBadPerformanceProof(
            keyStrikesList,
            proof,
            proofFlags,
            address(0)
        );
        vm.stopSnapshotGas();
    }

    function processBadPerformanceProof(
        ICSStrikes.KeyStrikes[] calldata keyStrikes,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        address refundRecipient
    ) external {
        strikes.processBadPerformanceProof(
            keyStrikes,
            proof,
            proofFlags,
            refundRecipient
        );
    }
}
