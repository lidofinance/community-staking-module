// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { pack } from "../src/lib/GIndex.sol";

contract DeployHolesky is DeployBase {
    constructor() DeployBase("holesky", 17000) {
        // Lido addresses
        config.lidoLocatorAddress = 0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8;
        config.votingAddress = 0xdA7d2573Df555002503F29aA4003e398d28cc00f;
        config
            .easyTrackEVMScriptExecutor = 0x2819B65021E13CEEB9AC33E77DB32c7e64e7520D;

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1695902400;
        config.oracleReportEpochsPerFrame = 225 * 28; // 28 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        // Verifier
        // NOTE: Deneb fork gIndexes. Should be updated according to `config.verifierSupportedEpoch` fork epoch if needed
        config.gIHistoricalSummaries = pack(0x3b, 5);
        config.gIFirstWithdrawal = pack(0xe1c0, 4);
        config.gIFirstValidator = pack(0x560000000000, 40);

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
            .setResetBondCurveAddress = 0x226954CD8a6Dd241d5A13Dd525Bd7B89067b11e5; // Known EOA
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;
        config
            .elRewardsStealingReporter = 0x226954CD8a6Dd241d5A13Dd525Bd7B89067b11e5; // Known EOA
        // EarlyAdoption
        // TODO: Set earlyAdoptionTreeRoot
        config.earlyAdoptionTreeRoot = keccak256(abi.encode(0));
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
        config.sealingCommittee = 0x226954CD8a6Dd241d5A13Dd525Bd7B89067b11e5; // Known EOA
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        _setUp();
    }

    function run() external override {
        revert IsNotReadyForDeployment();
    }
}
