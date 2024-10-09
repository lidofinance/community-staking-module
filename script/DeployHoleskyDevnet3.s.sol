// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployHoleskyDevnet3 is DeployBase {
    constructor() DeployBase("devnet3", 17000) {
        // Lido addresses
        config.lidoLocatorAddress = 0x658B8B25c8d16Be03b5930Df0e9f42E155C3d45C;
        config.aragonAgent = 0xd5611999e39A1C1621F6FCA85EFAf2C53a8166F8;
        config
            .easyTrackEVMScriptExecutor = 0x8C92472e51EFCf126f5BdbC39d7023B95c746c95; // Dev team EOA
        config.proxyAdmin = 0x8C92472e51EFCf126f5BdbC39d7023B95c746c95; // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1695902400;
        config.oracleReportEpochsPerFrame = 225; // 1 day
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        config.oracleMembers = new address[](2);
        config.oracleMembers[0] = 0xd7232c9AFbA4a765Cb5adE6a35dDCe4289D15911;
        config.oracleMembers[1] = 0xB8d37E23D709Dff30f9112592a55737197690e1b;
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
        config.bondCurve = new uint256[](2);
        // 2.4 -> 1.3
        config.bondCurve[0] = 2.4 ether;
        config.bondCurve[1] = 3.7 ether;

        config.minBondLockRetentionPeriod = 4 weeks;
        config.maxBondLockRetentionPeriod = 365 days;
        config.bondLockRetentionPeriod = 8 weeks;
        config
            .setResetBondCurveAddress = 0x8C92472e51EFCf126f5BdbC39d7023B95c746c95; // Dev team EOA
        config
            .chargePenaltyRecipient = 0xd5611999e39A1C1621F6FCA85EFAf2C53a8166F8; // locator.treasury()
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 12;
        config.maxKeyRemovalCharge = 0.1 ether;
        config.keyRemovalCharge = 0.05 ether;
        config
            .elRewardsStealingReporter = 0x8C92472e51EFCf126f5BdbC39d7023B95c746c95; // Dev team EOA
        // EarlyAdoption
        config
            .earlyAdoptionTreeRoot = 0x359e02c5c065c682839661c9bdfaf38db472629bf5f7a7e8f0261b31dc9332c2;
        config.earlyAdoptionBondCurve = new uint256[](2);
        // 1.5 -> 1.3
        config.earlyAdoptionBondCurve[0] = 1.5 ether;
        config.earlyAdoptionBondCurve[1] = 2.8 ether;
        // GateSeal
        config.gateSealFactory = 0x1134F7077055b0B3559BE52AfeF9aA22A0E1eEC2;
        config.sealingCommittee = 0x8C92472e51EFCf126f5BdbC39d7023B95c746c95; // Dev team EOA
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        config.secondAdminAddress = 0x8C92472e51EFCf126f5BdbC39d7023B95c746c95; // Dev team EOA
        _setUp();
    }
}
