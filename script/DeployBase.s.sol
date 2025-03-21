// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { OssifiableProxy } from "../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { CSEarlyAdoption } from "../src/CSEarlyAdoption.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { IGateSealFactory } from "../src/interfaces/IGateSealFactory.sol";
import { BaseOracle } from "../src/lib/base-oracle/BaseOracle.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";

struct DeployParams {
    // Lido addresses
    address lidoLocatorAddress;
    address aragonAgent;
    address easyTrackEVMScriptExecutor;
    address proxyAdmin;
    // Oracle
    uint256 secondsPerSlot;
    uint256 slotsPerEpoch;
    uint256 clGenesisTime;
    uint256 oracleReportEpochsPerFrame;
    uint256 fastLaneLengthSlots;
    uint256 consensusVersion;
    uint256 avgPerfLeewayBP;
    address[] oracleMembers;
    uint256 hashConsensusQuorum;
    // Verifier
    GIndex gIHistoricalSummaries;
    GIndex gIFirstWithdrawal;
    GIndex gIFirstValidator;
    uint256 verifierSupportedEpoch;
    // Accounting
    uint256 maxCurveLength;
    uint256[] bondCurve;
    uint256 minBondLockRetentionPeriod;
    uint256 maxBondLockRetentionPeriod;
    uint256 bondLockRetentionPeriod;
    address setResetBondCurveAddress;
    address chargePenaltyRecipient;
    // Module
    bytes32 moduleType;
    uint256 minSlashingPenaltyQuotient;
    uint256 elRewardsStealingFine;
    uint256 maxKeysPerOperatorEA;
    uint256 maxKeyRemovalCharge;
    uint256 keyRemovalCharge;
    address elRewardsStealingReporter;
    // EarlyAdoption
    bytes32 earlyAdoptionTreeRoot;
    uint256[] earlyAdoptionBondCurve;
    // GateSeal
    address gateSealFactory;
    address sealingCommittee;
    uint256 sealDuration;
    uint256 sealExpiryTimestamp;
    // Testnet stuff
    address secondAdminAddress;
}

abstract contract DeployBase is Script {
    DeployParams internal config;
    string internal artifactDir;
    string internal chainName;
    uint256 internal chainId;
    ILidoLocator internal locator;

    address internal deployer;
    uint256 internal pk;
    CSModule public csm;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;
    CSVerifier public verifier;
    CSEarlyAdoption public earlyAdoption;
    HashConsensus public hashConsensus;

    error ChainIdMismatch(uint256 actual, uint256 expected);
    error HashConsensusMismatch();
    error IsNotReadyForDeployment();
    error CannotBeUsedInMainnet();

    constructor(string memory _chainName, uint256 _chainId) {
        chainName = _chainName;
        chainId = _chainId;
    }

    function _setUp() internal {
        vm.label(config.aragonAgent, "ARAGON_AGENT_ADDRESS");
        vm.label(config.lidoLocatorAddress, "LIDO_LOCATOR");
        vm.label(config.easyTrackEVMScriptExecutor, "EVM_SCRIPT_EXECUTOR");
        locator = ILidoLocator(config.lidoLocatorAddress);
    }

    function run() external virtual {
        if (chainId != block.chainid) {
            revert ChainIdMismatch({
                actual: block.chainid,
                expected: chainId
            });
        }
        HashConsensus accountingConsensus = HashConsensus(
            BaseOracle(locator.accountingOracle()).getConsensusContract()
        );
        (address[] memory members, ) = accountingConsensus.getMembers();
        uint256 quorum = accountingConsensus.getQuorum();
        if (block.chainid == 1) {
            if (
                keccak256(abi.encode(config.oracleMembers)) !=
                keccak256(abi.encode(members)) ||
                config.hashConsensusQuorum != quorum
            ) {
                revert HashConsensusMismatch();
            }
        }
        artifactDir = vm.envOr("ARTIFACTS_DIR", string("./artifacts/local/"));
        pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(pk);
        vm.label(deployer, "DEPLOYER");

        vm.startBroadcast(pk);
        {
            CSModule csmImpl = new CSModule({
                moduleType: config.moduleType,
                minSlashingPenaltyQuotient: config.minSlashingPenaltyQuotient,
                elRewardsStealingFine: config.elRewardsStealingFine,
                maxKeysPerOperatorEA: config.maxKeysPerOperatorEA,
                maxKeyRemovalCharge: config.maxKeyRemovalCharge,
                lidoLocator: config.lidoLocatorAddress
            });
            csm = CSModule(_deployProxy(config.proxyAdmin, address(csmImpl)));

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                communityStakingModule: address(csm),
                maxCurveLength: config.maxCurveLength,
                minBondLockRetentionPeriod: config.minBondLockRetentionPeriod,
                maxBondLockRetentionPeriod: config.maxBondLockRetentionPeriod
            });
            accounting = CSAccounting(
                _deployProxy(config.proxyAdmin, address(accountingImpl))
            );

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime
            });
            oracle = CSFeeOracle(
                _deployProxy(config.proxyAdmin, address(oracleImpl))
            );

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting),
                oracle: address(oracle)
            });
            feeDistributor = CSFeeDistributor(
                _deployProxy(config.proxyAdmin, address(feeDistributorImpl))
            );

            verifier = new CSVerifier({
                withdrawalAddress: locator.withdrawalVault(),
                module: address(csm),
                slotsPerEpoch: uint64(config.slotsPerEpoch),
                gIFirstWithdrawalPrev: config.gIFirstWithdrawal,
                gIFirstWithdrawalCurr: config.gIFirstWithdrawal,
                gIFirstValidatorPrev: config.gIFirstValidator,
                gIFirstValidatorCurr: config.gIFirstValidator,
                gIHistoricalSummariesPrev: config.gIHistoricalSummaries,
                gIHistoricalSummariesCurr: config.gIHistoricalSummaries,
                firstSupportedSlot: Slot.wrap(
                    uint64(config.verifierSupportedEpoch * config.slotsPerEpoch)
                ),
                pivotSlot: Slot.wrap(
                    uint64(config.verifierSupportedEpoch * config.slotsPerEpoch)
                )
            });

            accounting.initialize({
                bondCurve: config.bondCurve,
                admin: deployer,
                _feeDistributor: address(feeDistributor),
                bondLockRetentionPeriod: config.bondLockRetentionPeriod,
                _chargePenaltyRecipient: config.chargePenaltyRecipient
            });

            accounting.grantRole(
                accounting.MANAGE_BOND_CURVES_ROLE(),
                address(deployer)
            );
            uint256 eaCurveId = accounting.addBondCurve(
                config.earlyAdoptionBondCurve
            );
            accounting.revokeRole(
                accounting.MANAGE_BOND_CURVES_ROLE(),
                address(deployer)
            );

            earlyAdoption = new CSEarlyAdoption({
                treeRoot: config.earlyAdoptionTreeRoot,
                curveId: eaCurveId,
                module: address(csm)
            });

            csm.initialize({
                _accounting: address(accounting),
                _earlyAdoption: address(earlyAdoption),
                _keyRemovalCharge: config.keyRemovalCharge,
                admin: deployer
            });

            feeDistributor.initialize({ admin: address(deployer) });

            hashConsensus = new HashConsensus({
                slotsPerEpoch: config.slotsPerEpoch,
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime,
                epochsPerFrame: config.oracleReportEpochsPerFrame,
                fastLaneLengthSlots: config.fastLaneLengthSlots,
                admin: address(deployer),
                reportProcessor: address(oracle)
            });
            hashConsensus.grantRole(
                hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE(),
                address(deployer)
            );
            for (uint256 i = 0; i < config.oracleMembers.length; i++) {
                hashConsensus.addMember(
                    config.oracleMembers[i],
                    config.hashConsensusQuorum
                );
            }
            hashConsensus.revokeRole(
                hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE(),
                address(deployer)
            );

            oracle.initialize({
                admin: address(deployer),
                feeDistributorContract: address(feeDistributor),
                consensusContract: address(hashConsensus),
                consensusVersion: config.consensusVersion,
                _avgPerfLeewayBP: config.avgPerfLeewayBP
            });

            address gateSeal;
            if (config.gateSealFactory != address(0)) {
                gateSeal = _deployGateSeal();
                csm.grantRole(csm.PAUSE_ROLE(), gateSeal);
                oracle.grantRole(oracle.PAUSE_ROLE(), gateSeal);
                accounting.grantRole(accounting.PAUSE_ROLE(), gateSeal);
            }

            accounting.grantRole(
                accounting.SET_BOND_CURVE_ROLE(),
                config.setResetBondCurveAddress
            );
            accounting.grantRole(
                accounting.RESET_BOND_CURVE_ROLE(),
                config.setResetBondCurveAddress
            );

            csm.grantRole(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
                config.elRewardsStealingReporter
            );
            csm.grantRole(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
                config.easyTrackEVMScriptExecutor
            );

            csm.grantRole(csm.VERIFIER_ROLE(), address(verifier));

            if (config.secondAdminAddress != address(0)) {
                _grantSecondAdmins();
            }

            csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), config.aragonAgent);
            csm.revokeRole(csm.DEFAULT_ADMIN_ROLE(), deployer);

            accounting.grantRole(
                accounting.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            accounting.revokeRole(accounting.DEFAULT_ADMIN_ROLE(), deployer);

            hashConsensus.grantRole(
                hashConsensus.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            hashConsensus.revokeRole(
                hashConsensus.DEFAULT_ADMIN_ROLE(),
                deployer
            );

            oracle.grantRole(oracle.DEFAULT_ADMIN_ROLE(), config.aragonAgent);
            oracle.revokeRole(oracle.DEFAULT_ADMIN_ROLE(), deployer);

            feeDistributor.grantRole(
                feeDistributor.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            feeDistributor.revokeRole(
                feeDistributor.DEFAULT_ADMIN_ROLE(),
                deployer
            );

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("ChainId", chainId);
            deployJson.set("CSModule", address(csm));
            deployJson.set("CSEarlyAdoption", address(earlyAdoption));
            deployJson.set("CSAccounting", address(accounting));
            deployJson.set("CSFeeOracle", address(oracle));
            deployJson.set("CSFeeDistributor", address(feeDistributor));
            deployJson.set("HashConsensus", address(hashConsensus));
            deployJson.set("CSVerifier", address(verifier));
            deployJson.set("LidoLocator", config.lidoLocatorAddress);
            deployJson.set("GateSeal", gateSeal);
            deployJson.set("DeployParams", abi.encode(config));
            vm.writeJson(deployJson.str, _deployJsonFilename());
        }

        vm.stopBroadcast();
    }

    function _deployProxy(
        address admin,
        address implementation
    ) internal returns (address) {
        OssifiableProxy proxy = new OssifiableProxy({
            implementation_: implementation,
            data_: new bytes(0),
            admin_: admin
        });

        return address(proxy);
    }

    function _deployGateSeal() internal returns (address) {
        IGateSealFactory gateSealFactory = IGateSealFactory(
            config.gateSealFactory
        );
        address[] memory sealables = new address[](3);
        sealables[0] = address(csm);
        sealables[1] = address(accounting);
        sealables[2] = address(oracle);

        address committee = config.sealingCommittee == address(0)
            ? deployer
            : config.sealingCommittee;

        vm.recordLogs();
        gateSealFactory.create_gate_seal({
            sealingCommittee: committee,
            sealDurationSeconds: config.sealDuration,
            sealables: sealables,
            expiryTimestamp: config.sealExpiryTimestamp
        });
        VmSafe.Log[] memory entries = vm.getRecordedLogs();
        return abi.decode(entries[0].data, (address));
    }

    function _deployJsonFilename() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(artifactDir, "deploy-", chainName, ".json")
            );
    }

    function _grantSecondAdmins() internal {
        if (keccak256(abi.encodePacked(chainName)) == keccak256("mainnet")) {
            revert CannotBeUsedInMainnet();
        }
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), config.secondAdminAddress);
        accounting.grantRole(
            csm.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        oracle.grantRole(
            oracle.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        feeDistributor.grantRole(
            feeDistributor.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        hashConsensus.grantRole(
            hashConsensus.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
    }
}
