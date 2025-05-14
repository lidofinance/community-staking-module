// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndicies } from "./constants/GIndicies.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

contract DeployLocalDevNet is DeployBase {
    constructor() DeployBase("local-devnet", vm.envUint("DEVNET_CHAIN_ID")) {
        // Lido addresses
        config.lidoLocatorAddress = vm.envAddress("CSM_LOCATOR_ADDRESS");
        config.aragonAgent = vm.envAddress("CSM_ARAGON_AGENT_ADDRESS");
        config.easyTrackEVMScriptExecutor = vm.envAddress(
            "EVM_SCRIPT_EXECUTOR_ADDRESS"
        );
        config.proxyAdmin = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = vm.envUint("DEVNET_SLOTS_PER_EPOCH");
        config.clGenesisTime = vm.envUint("DEVNET_GENESIS_TIME");
        config.oracleReportEpochsPerFrame = vm.envUint("CSM_EPOCHS_PER_FRAME");
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 3;
        config.oracleMembers = new address[](3);
        config.oracleMembers[0] = vm.envAddress("CSM_ORACLE_1_ADDRESS");
        config.oracleMembers[1] = vm.envAddress("CSM_ORACLE_2_ADDRESS");
        config.oracleMembers[2] = vm.envAddress("CSM_ORACLE_3_ADDRESS");
        config.hashConsensusQuorum = 2;
        // Verifier
        config.gIFirstWithdrawal = GIndicies.FIRST_WITHDRAWAL_CAPELLA;
        config.gIFirstValidator = GIndicies.FIRST_VALIDATOR_CAPELLA;
        config.gIHistoricalSummaries = GIndicies.HISTORICAL_SUMMARIES_CAPELLA;

        config.verifierSupportedEpoch = vm.envUint("DEVNET_ELECTRA_EPOCH");
        // Accounting
        config.maxCurveLength = 10;
        // 2.4 -> 1.3
        config.bondCurve.push([1, 2.4 ether]);
        config.bondCurve.push([2, 1.3 ether]);

        config.minBondLockPeriod = 1 days;
        config.maxBondLockPeriod = 7 days;
        config.bondLockPeriod = 1 days;
        config.setResetBondCurveAddress = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        config.chargePenaltyRecipient = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        // Module
        config.stakingModuleId = vm.envUint("CSM_STAKING_MODULE_ID");
        config.moduleType = "community-onchain-v1"; // Just a unique type name to be used by the off-chain tooling
        config.elRewardsStealingReporter = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA

        // CSParameters
        config.keyRemovalCharge = 0.05 ether;
        config.elRewardsStealingAdditionalFine = 0.1 ether;
        config.keysLimit = type(uint256).max;
        config.avgPerfLeewayBP = 500;
        config.rewardShareBP = 10000;
        config.strikesLifetimeFrames = 6;
        config.strikesThreshold = 3;
        config.queueLowestPriority = 5;
        config.defaultQueuePriority = 5;
        config.defaultQueueMaxDeposits = type(uint32).max;
        config.badPerformancePenalty = 0.1 ether; // TODO: to be reviewed
        config.attestationsWeight = 54; // https://eth2book.info/capella/part2/incentives/rewards/
        config.blocksWeight = 8; // https://eth2book.info/capella/part2/incentives/rewards/
        config.syncWeight = 2; // https://eth2book.info/capella/part2/incentives/rewards/
        config.defaultAllowedExitDelay = 4 days; // TODO: reconsider
        config.defaultExitDelayPenalty = 0.1 ether; // TODO: to be reviewed
        config.defaultMaxWithdrawalRequestFee = 0.1 ether; // TODO: to be reviewed

        // VettedGate
        config
            .identifiedCommunityStakerManager = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        config.identifiedCommunityStakerTreeRoot = vm.envOr(
            "CSM_VETTED_GATE_TREE_ROOT",
            bytes32(uint256(0xdeadbeef))
        );
        config.identifiedCommunityStakerTreeCid = vm.envOr(
            "CSM_VETTED_GATE_TREE_CID",
            string("someCid")
        );
        // 1.5 -> 1.3
        config.identifiedCommunityStakerBondCurve.push([1, 1.5 ether]);
        config.identifiedCommunityStakerBondCurve.push([2, 1.3 ether]);

        // Parameters for Identified Solo Operator type
        // TODO: Set proper values bellow
        config.identifiedCommunityStakerKeyRemovalCharge = 0.01 ether;
        config
            .identifiedCommunityStakerELRewardsStealingAdditionalFine = 0.05 ether;
        config.identifiedCommunityStakerKeysLimit = type(uint248).max;
        config.identifiedCommunityStakerAvgPerfLeewayData.push([0, 500]);
        config.identifiedCommunityStakerAvgPerfLeewayData.push([100, 600]);
        config.identifiedCommunityStakerRewardShareData.push([0, 10000]);
        config.identifiedCommunityStakerRewardShareData.push([100, 9900]);
        config.identifiedCommunityStakerStrikesLifetimeFrames = 8;
        config.identifiedCommunityStakerStrikesThreshold = 4;
        config.identifiedCommunityStakerQueuePriority = 0;
        config.identifiedCommunityStakerQueueMaxDeposits = 10;
        config.identifiedCommunityStakerBadPerformancePenalty = 0.05 ether;
        config.identifiedCommunityStakerAttestationsWeight = 60;
        config.identifiedCommunityStakerBlocksWeight = 4;
        config.identifiedCommunityStakerSyncWeight = 0;
        config.identifiedCommunityStakerAllowedExitDelay = 8 days;
        config.identifiedCommunityStakerExitDelayPenalty = 0.05 ether;
        config.identifiedCommunityStakerMaxWithdrawalRequestFee = 0.05 ether;

        // GateSeal
        config.gateSealFactory = 0x0000000000000000000000000000000000000000;
        config.sealingCommittee = 0x0000000000000000000000000000000000000000;
        config.sealDuration = 0;
        config.sealExpiryTimestamp = 0;

        config.secondAdminAddress = vm.envOr(
            "CSM_SECOND_ADMIN_ADDRESS",
            address(0)
        );

        _setUp();
    }
}
