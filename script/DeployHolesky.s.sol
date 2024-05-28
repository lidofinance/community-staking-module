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
        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = 1695902400;
        config.oracleReportEpochsPerFrame = 225 * 28; // 28 days
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
        config.bondCurve = new uint256[](3);
        config.bondCurve[0] = 2 ether; // Validator 1 -> 2 ETH
        config.bondCurve[1] = 3.75 ether; // Validator 2 -> 1.75 ETH
        config.bondCurve[2] = 5.25 ether; // Validator 3, 4, 5, ... -> 1.5 ETH

        config.bondLockRetentionPeriod = 8 weeks;
        // Module
        config.moduleType = "community-onchain-v1";
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.keyRemovalCharge = 0.05 ether;

        _setUp();
    }
}
