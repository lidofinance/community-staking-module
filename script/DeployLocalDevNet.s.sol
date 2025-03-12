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
        config.easyTrackEVMScriptExecutor = vm.envAddress(
            "EVM_SCRIPT_EXECUTOR_ADDRESS"
        );
        config.proxyAdmin = vm.envAddress("CSM_FIRST_ADMIN_ADDRESS"); // Dev team EOA

        // Oracle
        config.secondsPerSlot = 12;
        config.slotsPerEpoch = vm.envUint("DEVNET_SLOTS_PER_EPOCH");
        config.clGenesisTime = vm.envUint("DEVNET_GENESIS_TIME");
        config.oracleReportEpochsPerFrame = 225 * 28; // 28 days
        config.fastLaneLengthSlots = 0;
        config.consensusVersion = 3;
        config.oracleMembers = new address[](3);
        config.oracleMembers[0] = vm.envAddress("CSM_ORACLE_1_ADDRESS");
        config.oracleMembers[1] = vm.envAddress("CSM_ORACLE_2_ADDRESS");
        config.oracleMembers[2] = vm.envAddress("CSM_ORACLE_3_ADDRESS");
        config.hashConsensusQuorum = 2;
        // Verifier
        // NOTE: Deneb fork gIndexes. Should be updated according to `config.verifierSupportedEpoch` fork epoch if needed
        // Check using `yarn run gindex`
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

        config.minBondLockPeriod = 4 weeks;
        config.maxBondLockPeriod = 365 days;
        config.bondLockPeriod = 8 weeks;
        config.setResetBondCurveAddress = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        config.chargePenaltyRecipient = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        // Module
        config.moduleType = "community-onchain-v1"; // Just a unique type name to be used by the off-chain tooling
        config.elRewardsStealingReporter = vm.envAddress(
            "CSM_FIRST_ADMIN_ADDRESS"
        ); // Dev team EOA
        // CSParameters
        config.keyRemovalCharge = 0.05 ether;
        config.elRewardsStealingAdditionalFine = 0.1 ether;
        config.keysLimit = type(uint256).max;
        config.avgPerfLeewayBP = 500;
        config.rewardShareBP = 10000;
        config.strikesLifetimeFrames = 6;
        config.strikesThreshold = 3;
        config.queueLowestPriority = 5;
        config.defaultQueuePriority = 5;
        config.defaultQueueMaxDeposits = type(uint32).max;
        config.badPerformancePenalty = 0.1 ether; // TODO: to be reviewed
        config.attestationsWeight = 54; // https://eth2book.info/capella/part2/incentives/rewards/
        config.blocksWeight = 8; // https://eth2book.info/capella/part2/incentives/rewards/
        config.syncWeight = 2; // https://eth2book.info/capella/part2/incentives/rewards/
        // VettedGate
        config
            .vettedGateTreeRoot = 0x359e02c5c065c682839661c9bdfaf38db472629bf5f7a7e8f0261b31dc9332c2; // See the first value in artifacts/mainnet/early-adoption/merkle-tree.json
        config.vettedGateBondCurve = new uint256[](2);
        // 1.5 -> 1.3
        config.vettedGateBondCurve[0] = 1.5 ether;
        config.vettedGateBondCurve[1] = 2.8 ether;

        // GateSeal
        config.gateSealEnabled = false;
        config.gateSealFactory = 0x0000000000000000000000000000000000000000;
        config.sealingCommittee = 0x0000000000000000000000000000000000000000;
        config.sealDuration = 0;
        config.sealExpiryTimestamp = 0;

        _setUp();
    }
}
