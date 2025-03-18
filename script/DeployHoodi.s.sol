// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployHoodi is DeployBase {
    constructor() DeployBase("hoodi", 560048) {
        // Lido addresses
        config.lidoLocatorAddress = 0xe2EF9536DAAAEBFf5b1c130957AB3E80056b06D8;
        config.aragonAgent = 0x0534aA41907c9631fae990960bCC72d75fA7cfeD;
        // TODO update this address after ET deployment
        config
            .easyTrackEVMScriptExecutor = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        config.proxyAdmin = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1742213400;
        config.oracleReportEpochsPerFrame = 225 * 7; // 7 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        config.oracleMembers = new address[](2);
        config.oracleMembers[0] = 0xcA80ee7313A315879f326105134F938676Cfd7a9;
        config.oracleMembers[1] = 0xf03B8DC8762B97F13Ac82e6F94bE3Ed002FF7459;
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

        config.verifierSupportedEpoch = 0;
        // Accounting
        config.maxCurveLength = 10;
        config.bondCurve = new uint256[](2);
        // 2.4 -> 1.3
        config.bondCurve[0] = 2.4 ether;
        config.bondCurve[1] = 3.7 ether;

        config.minBondLockRetentionPeriod = 0;
        config.maxBondLockRetentionPeriod = 365 days;
        config.bondLockRetentionPeriod = 8 weeks;
        config
            .setResetBondCurveAddress = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.maxKeyRemovalCharge = 0.1 ether;
        config.keyRemovalCharge = 0.05 ether;
        config
            .elRewardsStealingReporter = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        config
            .chargePenaltyRecipient = 0x0534aA41907c9631fae990960bCC72d75fA7cfeD; // locator.treasury()
        // EarlyAdoption
        config
            .earlyAdoptionTreeRoot = 0x359e02c5c065c682839661c9bdfaf38db472629bf5f7a7e8f0261b31dc9332c2; // See the first value in artifacts/mainnet/early-adoption/merkle-tree.json
        config.earlyAdoptionBondCurve = new uint256[](2);
        // 1.5 -> 1.3
        config.earlyAdoptionBondCurve[0] = 1.5 ether;
        config.earlyAdoptionBondCurve[1] = 2.8 ether;
        // GateSeal
        config.gateSealFactory = 0xA402349F560D45310D301E92B1AA4DeCABe147B3;
        config.sealingCommittee = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        config.secondAdminAddress = 0x4AF43Ee34a6fcD1fEcA1e1F832124C763561dA53; // Dev team EOA
        _setUp();
    }
}
