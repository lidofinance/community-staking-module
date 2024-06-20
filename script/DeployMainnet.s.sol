// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployMainnet is DeployBase {
    constructor() DeployBase("mainnet", 1) {
        // Lido addresses
        config.lidoLocatorAddress = 0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;
        config.votingAddress = 0x2e59A20f205bB85a89C53f1936454680651E618e;
        config
            .easyTrackEVMScriptExecutor = 0xFE5986E06210aC1eCC1aDCafc0cc7f8D63B3F977;
        config.proxyAdmin = 0x2e59A20f205bB85a89C53f1936454680651E618e;

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1606824023;
        config.oracleReportEpochsPerFrame = 225 * 28; // 28 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        config.oracleMembers = new address[](9);
        config.oracleMembers[0] = 0x140Bd8FbDc884f48dA7cb1c09bE8A2fAdfea776E;
        config.oracleMembers[1] = 0xA7410857ABbf75043d61ea54e07D57A6EB6EF186;
        config.oracleMembers[2] = 0x404335BcE530400a5814375E7Ec1FB55fAff3eA2;
        config.oracleMembers[3] = 0x946D3b081ed19173dC83Cd974fC69e1e760B7d78;
        config.oracleMembers[4] = 0x007DE4a5F7bc37E2F26c0cb2E8A95006EE9B89b5;
        config.oracleMembers[5] = 0xEC4BfbAF681eb505B94E4a7849877DC6c600Ca3A;
        config.oracleMembers[6] = 0x61c91ECd902EB56e314bB2D5c5C07785444Ea1c8;
        config.oracleMembers[7] = 0x1Ca0fEC59b86F549e1F1184d97cb47794C8Af58d;
        config.oracleMembers[8] = 0xc79F702202E3A6B0B6310B537E786B9ACAA19BAf;
        config.hashConsensusQuorum = 5;
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

        config.verifierSupportedEpoch = 269568;
        // Accounting
        // TODO: Reconsider before the mainnet launch
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
        config.setResetBondCurveAddress = address(0); // TODO: set
        config.chargeRecipient = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c; // locator.treasury()
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;
        config.elRewardsStealingReporter = address(0); // TODO: set
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
        config.gateSealFactory = 0x6C82877cAC5a7A739f16Ca0A89c0A328B8764A24;
        // TODO: Reconsider before the mainnet launch
        config.sealingCommittee = address(0);
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        _setUp();
    }

    function run() external pure override {
        revert IsNotReadyForDeployment();
    }
}
