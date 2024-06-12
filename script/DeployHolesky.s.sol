// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

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
        config.oracleMembers = new address[](10);
        config.oracleMembers[0] = 0x12A1D74F8697b9f4F1eEBb0a9d0FB6a751366399;
        config.oracleMembers[1] = 0xD892c09b556b547c80B7d8c8cB8d75bf541B2284;
        config.oracleMembers[2] = 0xf7aE520e99ed3C41180B5E12681d31Aa7302E4e5;
        config.oracleMembers[3] = 0x31fa51343297FFce0CC1E67a50B2D3428057D1b1;
        config.oracleMembers[4] = 0x81E411f1BFDa43493D7994F82fb61A415F6b8Fd4;
        config.oracleMembers[5] = 0x4c75FA734a39f3a21C57e583c1c29942F021C6B7;
        config.oracleMembers[6] = 0xD3b1e36A372Ca250eefF61f90E833Ca070559970;
        config.oracleMembers[7] = 0xF0F23944EfC5A63c53632C571E7377b85d5E6B6f;
        config.oracleMembers[8] = 0xb29dD2f6672C0DFF2d2f173087739A42877A5172;
        config.oracleMembers[9] = 0x3799bDA7B884D33F79CEC926af21160dc47fbe05;
        config.hashConsensusQuorum = 6;
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
            .setResetBondCurveAddress = 0x226954CD8a6Dd241d5A13Dd525Bd7B89067b11e5; // Known EOA
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;
        config
            .elRewardsStealingReporter = 0x226954CD8a6Dd241d5A13Dd525Bd7B89067b11e5; // Known EOA
        config.chargeRecipient = 0xE92329EC7ddB11D25e25b3c21eeBf11f15eB325d; // locator.treasury()
        // EarlyAdoption
        // TODO: Set earlyAdoptionTreeRoot
        config.earlyAdoptionTreeRoot = 0x00;
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

    function run() external pure override {
        revert IsNotReadyForDeployment();
    }
}
