// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndicies } from "./constants/GIndicies.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

contract DeployHoodi is DeployBase {
    constructor() DeployBase("hoodi", 560048) {
        // Lido addresses
        config.lidoLocatorAddress = 0xe2EF9536DAAAEBFf5b1c130957AB3E80056b06D8;
        config.aragonAgent = 0x0534aA41907c9631fae990960bCC72d75fA7cfeD;
        config
            .easyTrackEVMScriptExecutor = 0x79a20FD0FA36453B2F45eAbab19bfef43575Ba9E;
        config.proxyAdmin = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1742213400;
        config.oracleReportEpochsPerFrame = 225 * 7; // 7 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 3;
        config.oracleMembers = new address[](2);
        config.oracleMembers[0] = 0xcA80ee7313A315879f326105134F938676Cfd7a9;
        config.oracleMembers[1] = 0xf03B8DC8762B97F13Ac82e6F94bE3Ed002FF7459;
        config.hashConsensusQuorum = 2;
        // Verifier
        config.gIFirstWithdrawal = GIndicies.FIRST_WITHDRAWAL_CAPELLA;
        config.gIFirstValidator = GIndicies.FIRST_VALIDATOR_CAPELLA;
        config.gIHistoricalSummaries = GIndicies.HISTORICAL_SUMMARIES_CAPELLA;

        config.verifierSupportedEpoch = 0;
        // Accounting
        config.maxCurveLength = 10;
        // 2.4 -> 1.3
        config.bondCurve.push([1, 2.4 ether]);
        config.bondCurve.push([2, 1.3 ether]);

        config.minBondLockPeriod = 0;
        config.maxBondLockPeriod = 365 days;
        config.bondLockPeriod = 8 weeks;
        config
            .setResetBondCurveAddress = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        config
            .chargePenaltyRecipient = 0x0534aA41907c9631fae990960bCC72d75fA7cfeD; // locator.treasury()
        // Module
        config.moduleType = "community-onchain-v1"; // Just a unique type name to be used by the off-chain tooling
        config
            .elRewardsStealingReporter = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA

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

        // VettedGate
        config
            .vettedGateTreeRoot = 0x359e02c5c065c682839661c9bdfaf38db472629bf5f7a7e8f0261b31dc9332c2; // See the first value in artifacts/mainnet/early-adoption/merkle-tree.json
        // 1.5 -> 1.3
        config.vettedGateBondCurve.push([1, 1.5 ether]);
        config.vettedGateBondCurve.push([2, 1.3 ether]);

        // GateSeal
        config.gateSealFactory = 0xA402349F560D45310D301E92B1AA4DeCABe147B3;
        config.sealingCommittee = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        config.secondAdminAddress = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        _setUp();
    }
}
