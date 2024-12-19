// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployLocalDevNet is DeployBase {
    constructor() DeployBase("local-devnet", 32382) {
        // Lido addresses
        config.lidoLocatorAddress = vm.envAddress("CSM_LOCATOR_ADDRESS");
        config.aragonAgent = vm.envAddress("CSM_ARAGON_AGENT_ADDRESS");
        config
            .easyTrackEVMScriptExecutor = vm.envAddress("EVM_SCRIPT_EXECUTOR_ADDRESS");
        config.proxyAdmin = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = 32;
        config.clGenesisTime = vm.envUint("DEVNET_GENESIS_TIME");
        config.oracleReportEpochsPerFrame = 225 * 7; // 7 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        config.oracleMembers = new address[](2);
        config.oracleMembers[0] = vm.envAddress("CSM_ORACLE_1_ADDRESS");
        config.oracleMembers[1] = vm.envAddress("CSM_ORACLE_2_ADDRESS");
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

        config
            .setResetBondCurveAddress = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.maxKeysPerOperatorEA = 10;
        config.maxKeyRemovalCharge = 0.1 ether;
        config.keyRemovalCharge = 0.05 ether;
        config
            .elRewardsStealingReporter = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA
        config
            .chargePenaltyRecipient = vm.envAddress("CSM_LOCATOR_TREASURY_ADDRESS"); // locator.treasury()
        // EarlyAdoption
        config
            .earlyAdoptionTreeRoot = 0xc9a9c1576cf4f3213ad9075b72a1f1b147914a252ad927fa4ca3460ff0723ca9;
        config.earlyAdoptionBondCurve = new uint256[](6);
        // 1.5 -> 1.9 -> 1.8 -> 1.7 -> 1.6 -> 1.5
        config.earlyAdoptionBondCurve[0] = 1.5 ether;
        config.earlyAdoptionBondCurve[1] = 3.4 ether;
        config.earlyAdoptionBondCurve[2] = 5.2 ether;
        config.earlyAdoptionBondCurve[3] = 6.9 ether;
        config.earlyAdoptionBondCurve[4] = 8.5 ether;
        config.earlyAdoptionBondCurve[5] = 10 ether;
        // GateSeal
        config.gateSealEnabled = false;

        config.gateSealFactory = 0x1134F7077055b0B3559BE52AfeF9aA22A0E1eEC2;
        config.sealingCommittee = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        config.secondAdminAddress = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA
        _setUp();
    }
}
