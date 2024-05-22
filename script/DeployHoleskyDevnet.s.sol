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
        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1695902400;
        config.oracleReportEpochsPerFrame = 225; // 1 day
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.performanceThresholdBP = 9500;
        // Verifier
        // NOTE: Deneb fork gIndexes. Should be updated according to `config.verifierSupportedEpoch` fork epoch if needed
        config.gIHistoricalSummaries = pack(0x3b, 5);
        config.gIFirstWithdrawal = pack(0xe1c0, 4);
        config.gIFirstValidator = pack(0x560000000000, 40);

        config.verifierSupportedEpoch = 29696;
        // Accounting
        config.bondCurve = new uint256[](2);
        config.bondCurve[0] = 2 ether;
        config.bondCurve[1] = 4 ether;
        config.bondLockRetentionPeriod = 8 weeks;
        // Module
        config.moduleType = "community-onchain-v1";
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;

        _setUp();
    }
}
