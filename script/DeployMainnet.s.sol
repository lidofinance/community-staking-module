// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { pack } from "../src/lib/GIndex.sol";

contract DeployMainnet is DeployBase {
    constructor() DeployBase("mainnet", 1) {
        // Lido addresses
        config.lidoLocatorAddress = 0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;
        config.votingAddress = 0x2e59A20f205bB85a89C53f1936454680651E618e;
        config
            .easyTrackEVMScriptExecutor = 0xFE5986E06210aC1eCC1aDCafc0cc7f8D63B3F977;
        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1606824023;
        config.oracleReportEpochsPerFrame = 225 * 28; // 28 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        // Verifier
        // NOTE: Deneb fork gIndexes. Should be updated according to `config.verifierSupportedEpoch` fork epoch if needed
        config.gIHistoricalSummaries = pack(0x3b, 5);
        config.gIFirstWithdrawal = pack(0xe1c0, 4);
        config.gIFirstValidator = pack(0x560000000000, 40);

        config.verifierSupportedEpoch = 269568;
        // Accounting
        // TODO: Reconsider before the mainnet launch
        config.maxCurveLength = 10;
        config.bondCurve = new uint256[](3);
        config.bondCurve[0] = 2 ether; // Validator 1 -> 2 ETH
        config.bondCurve[1] = 3.75 ether; // Validator 2 -> 1.75 ETH
        config.bondCurve[2] = 5.24 ether; // Validator 3, 4, 5, ... -> 1.5 ETH

        config.minBondLockRetentionPeriod = 4 weeks;
        config.maxBondLockRetentionPeriod = 365 days;
        config.bondLockRetentionPeriod = 8 weeks;
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;
        // GateSeal
        config.gateSealFactory = 0x6C82877cAC5a7A739f16Ca0A89c0A328B8764A24;
        // TODO: Reconsider before the mainnet launch
        config.sealingCommittee = address(0);
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        _setUp();
    }
}
