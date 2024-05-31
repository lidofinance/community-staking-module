// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { pack } from "../src/lib/GIndex.sol";

contract DeployHoleskyDevnet is DeployBase {
    constructor() DeployBase("devnet", 17000) {
        // Lido addresses
        config.lidoLocatorAddress = 0x5bF85BadDac33F91B38617c18a3F829f912Ca060;
        config.votingAddress = 0xd8B7F4EFd16e913648C6E9B74772BC3C38203301;
        config.easyTrackEVMScriptExecutor = address(0);

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1695902400;
        config.oracleReportEpochsPerFrame = 225; // 1 day
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
        config.bondCurve = new uint256[](3);
        config.bondCurve[0] = 2 ether; // Validator 1 -> 2 ETH
        config.bondCurve[1] = 3.75 ether; // Validator 2 -> 1.75 ETH
        config.bondCurve[2] = 5.25 ether; // Validator 3, 4, 5, ... -> 1.5 ETH

        config.minBondLockRetentionPeriod = 4 weeks;
        config.maxBondLockRetentionPeriod = 365 days;
        config.bondLockRetentionPeriod = 8 weeks;
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;
        // EarlyAdoption
        config.earlyAdoptionTreeRoot = 0x0;
        config.earlyAdoptionBondCurve = new uint256[](3);
        config.earlyAdoptionBondCurve[0] = 1.5 ether; // Validator 1 -> 1.5 ETH
        config.earlyAdoptionBondCurve[1] = 2.75 ether; // Validator 2 -> 1.25 ETH
        config.earlyAdoptionBondCurve[2] = 3.75 ether; // Validator 3, 4, 5, ... -> 1 ETH
        // GateSeal
        config.gateSealFactory = 0x1134F7077055b0B3559BE52AfeF9aA22A0E1eEC2;
        config.sealingCommittee = address(0);
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        _setUp();
    }
}
