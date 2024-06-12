// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployHoleskyDevnet is DeployBase {
    constructor() DeployBase("devnet", 17000) {
        // Lido addresses
        config.lidoLocatorAddress = 0x3F8ae3A6452DC4F7df1E391df39618a9aCF715A6;
        config.votingAddress = 0xcC269aA6688287aA33800fC048A60f418adFcf73;
        config
            .easyTrackEVMScriptExecutor = 0xf992Cc926e7337ECAAaBA8ccECAa6e4a16C9dcC3;

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1695902400;
        config.oracleReportEpochsPerFrame = 225; // 1 day
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        config.oracleMembers = new address[](2);
        config.oracleMembers[0] = 0x1581d0f5272602842d30494A03C8F0024E4fC357;
        config.oracleMembers[1] = 0x955B047c20239f15E40194ee3c19D74B9E8623fB;
        config.hashConsensusQuorum = 2;
        // Verifier
        // NOTE: Deneb fork gIndexes. Should be updated according to `config.verifierSupportedEpoch` fork epoch if needed
        config.gIFirstWithdrawal = GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000000000000e1c004
        );
        config.gIFirstValidator = GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000056000000000028
        );
        config.gIHistoricalSummaries = GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000000000000003b00
        );

        config.verifierSupportedEpoch = 29696;
        // Accounting
        config.maxCurveLength = 10;
        config.bondCurve = new uint256[](6);
        // 2 -> 1.9 -> 1.8 -> 1.7 -> 1.6 -> 1.5
        config.bondCurve[0] = 2 ether;
        config.bondCurve[1] = 3.9 ether;
        config.bondCurve[2] = 5.7 ether;
        config.bondCurve[3] = 7.4 ether;
        config.bondCurve[4] = 9 ether;
        config.bondCurve[5] = 10.5 ether;

        config.minBondLockRetentionPeriod = 4 weeks;
        config.maxBondLockRetentionPeriod = 365 days;
        config.bondLockRetentionPeriod = 8 weeks;
        config
            .setResetBondCurveAddress = 0xC234dBA03943C9238067cDfBC2761844133DD386; // Known EOA
        config.chargeRecipient = 0x636857002fD7975c7B40c0558d4f4834c4390fc6; // locator.treasury()
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;
        config
            .elRewardsStealingReporter = 0xC234dBA03943C9238067cDfBC2761844133DD386; // Known EOA
        // EarlyAdoption
        config
            .earlyAdoptionTreeRoot = 0xa9e0f9295f169913bafcc4bc9debb38acfbd0442ed9fce55d657dd7ad75c9ec4;
        config.earlyAdoptionBondCurve = new uint256[](6);
        // 1.5 -> 1.9 -> 1.8 -> 1.7 -> 1.6 -> 1.5
        config.earlyAdoptionBondCurve[0] = 1.5 ether;
        config.earlyAdoptionBondCurve[1] = 3.4 ether;
        config.earlyAdoptionBondCurve[2] = 5.2 ether;
        config.earlyAdoptionBondCurve[3] = 6.9 ether;
        config.earlyAdoptionBondCurve[4] = 8.5 ether;
        config.earlyAdoptionBondCurve[5] = 10 ether;
        // GateSeal
        config.gateSealFactory = 0x1134F7077055b0B3559BE52AfeF9aA22A0E1eEC2;
        config.sealingCommittee = 0xC234dBA03943C9238067cDfBC2761844133DD386; // Known EOA
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        config.secondAdminAddress = 0xC234dBA03943C9238067cDfBC2761844133DD386; // Known EOA
        _setUp();
    }
}
