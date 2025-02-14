// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployMainnet is DeployBase {
    constructor() DeployBase("mainnet", 1) {
        // Lido addresses
        config.lidoLocatorAddress = 0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;
        config.aragonAgent = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
        config
            .easyTrackEVMScriptExecutor = 0xFE5986E06210aC1eCC1aDCafc0cc7f8D63B3F977;
        config.proxyAdmin = config.aragonAgent;

        // Oracle
        config.secondsPerSlot = 12; // https://github.com/eth-clients/mainnet/blob/f6b7882618a5ad2c1d2731ae35e5d16a660d5bb7/metadata/config.yaml#L58
        config.slotsPerEpoch = 32; // https://github.com/ethereum/consensus-specs/blob/7df1ce30384b13d01617f8ddf930f4035da0f689/specs/phase0/beacon-chain.md?plain=1#L246
        config.clGenesisTime = 1606824023; // https://github.com/eth-clients/mainnet/blob/f6b7882618a5ad2c1d2731ae35e5d16a660d5bb7/README.md?plain=1#L10
        config.oracleReportEpochsPerFrame = 225 * 28; // 28 days
        config.fastLaneLengthSlots = 1800;
        config.consensusVersion = 2;
        config.oracleMembers = new address[](9);
        config.oracleMembers[0] = 0x140Bd8FbDc884f48dA7cb1c09bE8A2fAdfea776E; // Chorus One
        config.oracleMembers[1] = 0xA7410857ABbf75043d61ea54e07D57A6EB6EF186; // Kyber Network
        config.oracleMembers[2] = 0x404335BcE530400a5814375E7Ec1FB55fAff3eA2; // Staking Facilities
        config.oracleMembers[3] = 0x946D3b081ed19173dC83Cd974fC69e1e760B7d78; // Stakefish
        config.oracleMembers[4] = 0x007DE4a5F7bc37E2F26c0cb2E8A95006EE9B89b5; // P2P
        config.oracleMembers[5] = 0xc79F702202E3A6B0B6310B537E786B9ACAA19BAf; // Chainlayer
        config.oracleMembers[6] = 0x61c91ECd902EB56e314bB2D5c5C07785444Ea1c8; // bloXroute
        config.oracleMembers[7] = 0xe57B3792aDCc5da47EF4fF588883F0ee0c9835C9; // MatrixedLink
        config.oracleMembers[8] = 0x73181107c8D9ED4ce0bbeF7A0b4ccf3320C41d12; // Instadapp
        config.hashConsensusQuorum = 5;
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

        config.verifierSupportedEpoch = 269568;
        // Accounting
        config.maxCurveLength = 10;
        config.bondCurve = new uint256[](2);
        // 2.4 -> 1.3
        config.bondCurve[0] = 2.4 ether;
        config.bondCurve[1] = 3.7 ether;

        config.minBondLockPeriod = 4 weeks;
        config.maxBondLockPeriod = 365 days;
        config.bondLockPeriod = 8 weeks;
        config
            .setResetBondCurveAddress = 0xC52fC3081123073078698F1EAc2f1Dc7Bd71880f; // CSM Committee MS
        config
            .chargePenaltyRecipient = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c; // locator.treasury()
        // Module
        config.moduleType = "community-onchain-v1"; // Just a unique type name to be used by the off-chain tooling
        config.minSlashingPenaltyQuotient = 32;
        config.maxKeysPerOperatorEA = 12; // 12 EA vals will result in approx 16 ETH worth of bond
        config
            .elRewardsStealingReporter = 0xC52fC3081123073078698F1EAc2f1Dc7Bd71880f; // CSM Committee MS
        // CSParameters
        config.keyRemovalCharge = 0.05 ether;
        config.elRewardsStealingAdditionalFine = 0.1 ether;
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
        config.gateSealFactory = 0x6C82877cAC5a7A739f16Ca0A89c0A328B8764A24;
        config.sealingCommittee = 0xC52fC3081123073078698F1EAc2f1Dc7Bd71880f; // CSM Committee MS
        config.sealDuration = 6 days;
        config.sealExpiryTimestamp = block.timestamp + 365 days;

        _setUp();
    }
}
