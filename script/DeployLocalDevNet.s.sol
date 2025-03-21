// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployLocalDevNet is DeployBase {
    constructor() DeployBase("local-devnet", 32382) {
        // Lido addresses
        config.lidoLocatorAddress = vm.envAddress("CSM_LOCATOR_ADDRESS");
        config.aragonAgent = vm.envAddress("CSM_ARAGON_AGENT_ADDRESS");
        config.easyTrackEVMScriptExecutor = vm.envAddress(
            "EVM_SCRIPT_EXECUTOR_ADDRESS"
        );
        config.proxyAdmin = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = vm.envUint("DEVNET_SLOTS_PER_EPOCH");
        config.clGenesisTime = vm.envUint("DEVNET_GENESIS_TIME");
        config.oracleReportEpochsPerFrame = vm.envUint("CSM_EPOCHS_PER_FRAME");
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 1;
        config.avgPerfLeewayBP = 500;
        config.oracleMembers = new address[](3);
        config.oracleMembers[0] = vm.envAddress("CSM_ORACLE_1_ADDRESS");
        config.oracleMembers[1] = vm.envAddress("CSM_ORACLE_2_ADDRESS");
        config.oracleMembers[2] = vm.envAddress("CSM_ORACLE_3_ADDRESS");
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

        config.verifierSupportedEpoch = vm.envUint("DEVNET_ELECTRA_EPOCH");
        // Accounting
        config.maxCurveLength = 10;
        config.bondCurve = new uint256[](2);
        // 2.4 -> 1.3
        config.bondCurve[0] = 2.4 ether;
        config.bondCurve[1] = 3.7 ether;

        config.minBondLockRetentionPeriod = 1 days;
        config.maxBondLockRetentionPeriod = 7 days;
        config.bondLockRetentionPeriod = 1 days;
        config.setResetBondCurveAddress = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        // Module
        config.moduleType = "community-onchain-v1";
        config.minSlashingPenaltyQuotient = 32;
        config.elRewardsStealingFine = 0.1 ether;
        config.maxKeysPerOperatorEA = 10;
        config.maxKeyRemovalCharge = 0.1 ether;
        config.keyRemovalCharge = 0.05 ether;
        config.elRewardsStealingReporter = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        config.chargePenaltyRecipient = vm.envAddress(
            "CSM_LOCATOR_TREASURY_ADDRESS"
        ); // locator.treasury()
        // EarlyAdoption
        config.earlyAdoptionTreeRoot = vm.envOr(
            "CSM_EARLY_ADOPTION_TREE_ROOT",
            bytes32(uint256(0xdeadbeef))
        );
        config.earlyAdoptionBondCurve = new uint256[](2);
        // 1.5 -> 1.3
        config.earlyAdoptionBondCurve[0] = 1.5 ether;
        config.earlyAdoptionBondCurve[1] = 2.8 ether;

        // GateSeal
        config.gateSealFactory = address(0);
        config.sealingCommittee = address(0);
        config.sealDuration = 0;
        config.sealExpiryTimestamp = 0;

        config.secondAdminAddress = vm.envAddress("CSM_SECOND_ADMIN_ADDRESS"); // Dev team EOA
        _setUp();
    }
}
