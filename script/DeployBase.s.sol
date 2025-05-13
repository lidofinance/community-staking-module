// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { OssifiableProxy } from "../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSEjector } from "../src/CSEjector.sol";
import { CSStrikes } from "../src/CSStrikes.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { PermissionlessGate } from "../src/PermissionlessGate.sol";
import { VettedGate } from "../src/VettedGate.sol";
import { CSParametersRegistry } from "../src/CSParametersRegistry.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { IGateSealFactory } from "../src/interfaces/IGateSealFactory.sol";
import { BaseOracle } from "../src/lib/base-oracle/BaseOracle.sol";
import { ICSParametersRegistry } from "../src/interfaces/ICSParametersRegistry.sol";
import { ICSBondCurve } from "../src/interfaces/ICSBondCurve.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";
import { VettedGateFactory } from "../src/VettedGateFactory.sol";
import { CSExitPenalties } from "../src/CSExitPenalties.sol";
import { IGateSeal } from "../src/interfaces/IGateSeal.sol";

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
    address[] oracleMembers;
    uint256 hashConsensusQuorum;
    // Verifier
    GIndex gIHistoricalSummaries;
    GIndex gIFirstWithdrawal;
    GIndex gIFirstValidator;
    uint256 verifierSupportedEpoch;
    // Accounting
    uint256 maxCurveLength;
    uint256[2][] bondCurve;
    uint256 minBondLockPeriod;
    uint256 maxBondLockPeriod;
    uint256 bondLockPeriod;
    address setResetBondCurveAddress;
    address chargePenaltyRecipient;
    // Module
    uint256 stakingModuleId;
    bytes32 moduleType;
    address elRewardsStealingReporter;
    // CSParameters
    uint256 keyRemovalCharge;
    uint256 elRewardsStealingAdditionalFine;
    uint256 keysLimit;
    uint256 avgPerfLeewayBP;
    uint256 rewardShareBP;
    uint256 strikesLifetimeFrames;
    uint256 strikesThreshold;
    uint256 queueLowestPriority;
    uint256 defaultQueuePriority;
    uint256 defaultQueueMaxDeposits;
    uint256 badPerformancePenalty;
    uint256 attestationsWeight;
    uint256 blocksWeight;
    uint256 syncWeight;
    // TODO rename other default parameters to be consistent
    uint256 defaultAllowedExitDelay;
    uint256 defaultExitDelayPenalty;
    uint256 defaultMaxWithdrawalRequestFee;
    // VettedGate
    address identifiedSoloOperatorManager;
    bytes32 identifiedSoloOperatorTreeRoot;
    string identifiedSoloOperatorTreeCid;
    uint256[2][] identifiedSoloOperatorBondCurve;
    // Parameters for Identified Solo Operator type
    uint256 identifiedSoloOperatorKeyRemovalCharge;
    uint256 identifiedSoloOperatorELRewardsStealingAdditionalFine;
    uint256 identifiedSoloOperatorKeysLimit;
    uint256[2][] identifiedSoloOperatorAvgPerfLeewayData;
    uint256[2][] identifiedSoloOperatorRewardShareData;
    uint256 identifiedSoloOperatorStrikesLifetimeFrames;
    uint256 identifiedSoloOperatorStrikesThreshold;
    uint256 identifiedSoloOperatorQueuePriority;
    uint256 identifiedSoloOperatorQueueMaxDeposits;
    uint256 identifiedSoloOperatorBadPerformancePenalty;
    uint256 identifiedSoloOperatorAttestationsWeight;
    uint256 identifiedSoloOperatorBlocksWeight;
    uint256 identifiedSoloOperatorSyncWeight;
    uint256 identifiedSoloOperatorAllowedExitDelay;
    uint256 identifiedSoloOperatorExitDelayPenalty;
    uint256 identifiedSoloOperatorMaxWithdrawalRequestFee;
    // GateSeal
    address gateSealFactory;
    address sealingCommittee;
    uint256 sealDuration;
    uint256 sealExpiryTimestamp;
    // Testnet stuff
    address secondAdminAddress;
}

abstract contract DeployBase is Script {
    string internal gitRef;
    DeployParams internal config;
    string internal artifactDir;
    string internal chainName;
    uint256 internal chainId;
    ILidoLocator internal locator;

    address internal deployer;
    CSModule public csm;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;
    CSExitPenalties public exitPenalties;
    CSEjector public ejector;
    CSStrikes public strikes;
    CSVerifier public verifier;
    address public gateSeal;
    PermissionlessGate public permissionlessGate;
    VettedGateFactory public vettedGateFactory;
    VettedGate public vettedGate;
    HashConsensus public hashConsensus;
    CSParametersRegistry public parametersRegistry;

    error ChainIdMismatch(uint256 actual, uint256 expected);
    error HashConsensusMismatch();
    error IsNotReadyForDeployment();
    error CannotBeUsedInMainnet();
    error InvalidSecondAdmin();

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

    function run(string memory _gitRef) external virtual {
        gitRef = _gitRef;
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
        (, deployer, ) = vm.readCallers();
        vm.label(deployer, "DEPLOYER");

        vm.startBroadcast(deployer);
        {
            CSParametersRegistry parametersRegistryImpl = new CSParametersRegistry(
                    config.queueLowestPriority
                );
            parametersRegistry = CSParametersRegistry(
                _deployProxy(config.proxyAdmin, address(parametersRegistryImpl))
            );

            CSModule csmImpl = new CSModule({
                moduleType: config.moduleType,
                lidoLocator: config.lidoLocatorAddress,
                parametersRegistry: address(parametersRegistry)
            });
            csm = CSModule(_deployProxy(config.proxyAdmin, address(csmImpl)));

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                module: address(csm),
                maxCurveLength: config.maxCurveLength,
                minBondLockPeriod: config.minBondLockPeriod,
                maxBondLockPeriod: config.maxBondLockPeriod
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
                gindices: ICSVerifier.GIndices({
                    gIFirstWithdrawalPrev: config.gIFirstWithdrawal,
                    gIFirstWithdrawalCurr: config.gIFirstWithdrawal,
                    gIFirstValidatorPrev: config.gIFirstValidator,
                    gIFirstValidatorCurr: config.gIFirstValidator,
                    gIHistoricalSummariesPrev: config.gIHistoricalSummaries,
                    gIHistoricalSummariesCurr: config.gIHistoricalSummaries
                }),
                firstSupportedSlot: Slot.wrap(
                    uint64(config.verifierSupportedEpoch * config.slotsPerEpoch)
                ),
                pivotSlot: Slot.wrap(
                    uint64(config.verifierSupportedEpoch * config.slotsPerEpoch)
                ),
                admin: deployer
            });

            parametersRegistry.initialize({
                admin: deployer,
                data: ICSParametersRegistry.InitializationData({
                    keyRemovalCharge: config.keyRemovalCharge,
                    elRewardsStealingAdditionalFine: config
                        .elRewardsStealingAdditionalFine,
                    keysLimit: config.keysLimit,
                    rewardShare: config.rewardShareBP,
                    performanceLeeway: config.avgPerfLeewayBP,
                    strikesLifetime: config.strikesLifetimeFrames,
                    strikesThreshold: config.strikesThreshold,
                    defaultQueuePriority: config.defaultQueuePriority,
                    defaultQueueMaxDeposits: config.defaultQueueMaxDeposits,
                    badPerformancePenalty: config.badPerformancePenalty,
                    attestationsWeight: config.attestationsWeight,
                    blocksWeight: config.blocksWeight,
                    syncWeight: config.syncWeight,
                    defaultAllowedExitDelay: config.defaultAllowedExitDelay,
                    defaultExitDelayPenalty: config.defaultExitDelayPenalty,
                    defaultMaxWithdrawalRequestFee: config
                        .defaultMaxWithdrawalRequestFee
                })
            });

            accounting.initialize({
                bondCurve: config.bondCurve,
                admin: deployer,
                _feeDistributor: address(feeDistributor),
                bondLockPeriod: config.bondLockPeriod,
                _chargePenaltyRecipient: config.chargePenaltyRecipient
            });

            accounting.grantRole(
                accounting.MANAGE_BOND_CURVES_ROLE(),
                address(deployer)
            );

            uint256 identifiedSoloOperatorBondCurveId = accounting.addBondCurve(
                config.identifiedSoloOperatorBondCurve
            );
            accounting.revokeRole(
                accounting.MANAGE_BOND_CURVES_ROLE(),
                address(deployer)
            );

            CSExitPenalties exitPenaltiesImpl = new CSExitPenalties(
                address(csm),
                address(parametersRegistry),
                address(accounting)
            );

            exitPenalties = CSExitPenalties(
                _deployProxy(config.proxyAdmin, address(exitPenaltiesImpl))
            );

            ejector = new CSEjector(address(csm), config.stakingModuleId);

            csm.initialize({
                _accounting: address(accounting),
                _exitPenalties: address(exitPenalties),
                admin: deployer
            });

            CSStrikes strikesImpl = new CSStrikes({
                module: address(csm),
                oracle: address(oracle),
                exitPenalties: address(exitPenalties)
            });

            strikes = CSStrikes(
                _deployProxy(config.proxyAdmin, address(strikesImpl))
            );

            exitPenalties.initialize(address(strikes));
            ejector.initialize(deployer, address(strikes));
            strikes.initialize(deployer, address(ejector));

            permissionlessGate = new PermissionlessGate(address(csm));

            address vettedGateImpl = address(new VettedGate(address(csm)));
            vettedGateFactory = new VettedGateFactory(vettedGateImpl);
            vettedGate = VettedGate(
                vettedGateFactory.create({
                    curveId: identifiedSoloOperatorBondCurveId,
                    treeRoot: config.identifiedSoloOperatorTreeRoot,
                    treeCid: config.identifiedSoloOperatorTreeCid,
                    admin: deployer
                })
            );

            OssifiableProxy vettedGateProxy = OssifiableProxy(
                payable(address(vettedGate))
            );
            vettedGateProxy.proxy__changeAdmin(config.proxyAdmin);

            parametersRegistry.setKeyRemovalCharge(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorKeyRemovalCharge
            );
            parametersRegistry.setElRewardsStealingAdditionalFine(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorELRewardsStealingAdditionalFine
            );
            parametersRegistry.setKeysLimit(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorKeysLimit
            );
            parametersRegistry.setPerformanceLeewayData(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorAvgPerfLeewayData
            );
            parametersRegistry.setRewardShareData(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorRewardShareData
            );
            parametersRegistry.setStrikesParams(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorStrikesLifetimeFrames,
                config.identifiedSoloOperatorStrikesThreshold
            );
            parametersRegistry.setQueueConfig(
                identifiedSoloOperatorBondCurveId,
                uint32(config.identifiedSoloOperatorQueuePriority),
                uint32(config.identifiedSoloOperatorQueueMaxDeposits)
            );
            parametersRegistry.setBadPerformancePenalty(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorBadPerformancePenalty
            );
            parametersRegistry.setPerformanceCoefficients(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorAttestationsWeight,
                config.identifiedSoloOperatorBlocksWeight,
                config.identifiedSoloOperatorSyncWeight
            );
            parametersRegistry.setAllowedExitDelay(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorAllowedExitDelay
            );
            parametersRegistry.setExitDelayPenalty(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorExitDelayPenalty
            );
            parametersRegistry.setMaxWithdrawalRequestFee(
                identifiedSoloOperatorBondCurveId,
                config.identifiedSoloOperatorMaxWithdrawalRequestFee
            );

            feeDistributor.initialize({
                admin: address(deployer),
                _rebateRecipient: config.aragonAgent
            });

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
                config.aragonAgent
            );
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
                strikesContract: address(strikes),
                consensusContract: address(hashConsensus),
                consensusVersion: config.consensusVersion
            });

            if (config.gateSealFactory != address(0)) {
                address[] memory sealables = new address[](6);
                sealables[0] = address(csm);
                sealables[1] = address(accounting);
                sealables[2] = address(oracle);
                sealables[3] = address(verifier);
                sealables[4] = address(vettedGate);
                sealables[5] = address(ejector);
                gateSeal = _deployGateSeal(sealables);

                csm.grantRole(csm.PAUSE_ROLE(), gateSeal);
                oracle.grantRole(oracle.PAUSE_ROLE(), gateSeal);
                accounting.grantRole(accounting.PAUSE_ROLE(), gateSeal);
                verifier.grantRole(verifier.PAUSE_ROLE(), gateSeal);
                vettedGate.grantRole(vettedGate.PAUSE_ROLE(), gateSeal);
                ejector.grantRole(ejector.PAUSE_ROLE(), gateSeal);
            }

            accounting.grantRole(
                accounting.SET_BOND_CURVE_ROLE(),
                address(config.setResetBondCurveAddress)
            );
            accounting.grantRole(
                accounting.SET_BOND_CURVE_ROLE(),
                address(vettedGate)
            );

            csm.grantRole(
                csm.CREATE_NODE_OPERATOR_ROLE(),
                address(permissionlessGate)
            );
            csm.grantRole(csm.CREATE_NODE_OPERATOR_ROLE(), address(vettedGate));
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
                if (config.secondAdminAddress == deployer) {
                    revert InvalidSecondAdmin();
                }
                _grantSecondAdmins();
            }

            csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), config.aragonAgent);
            csm.revokeRole(csm.DEFAULT_ADMIN_ROLE(), deployer);

            ejector.grantRole(ejector.DEFAULT_ADMIN_ROLE(), config.aragonAgent);
            ejector.revokeRole(ejector.DEFAULT_ADMIN_ROLE(), deployer);

            parametersRegistry.grantRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            parametersRegistry.revokeRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                deployer
            );

            vettedGate.grantRole(
                vettedGate.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            vettedGate.grantRole(
                vettedGate.SET_TREE_ROLE(),
                config.identifiedSoloOperatorManager
            );
            vettedGate.grantRole(
                vettedGate.START_REFERRAL_SEASON_ROLE(),
                config.aragonAgent
            );
            vettedGate.grantRole(
                vettedGate.END_REFERRAL_SEASON_ROLE(),
                config.identifiedSoloOperatorManager
            );
            vettedGate.revokeRole(vettedGate.DEFAULT_ADMIN_ROLE(), deployer);

            verifier.grantRole(
                verifier.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            verifier.revokeRole(verifier.DEFAULT_ADMIN_ROLE(), deployer);

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

            strikes.grantRole(strikes.DEFAULT_ADMIN_ROLE(), config.aragonAgent);
            strikes.revokeRole(strikes.DEFAULT_ADMIN_ROLE(), deployer);

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("ChainId", chainId);
            deployJson.set("CSModule", address(csm));
            deployJson.set("CSModuleImpl", address(csmImpl));
            deployJson.set("CSParametersRegistry", address(parametersRegistry));
            deployJson.set(
                "CSParametersRegistryImpl",
                address(parametersRegistryImpl)
            );
            deployJson.set("CSAccounting", address(accounting));
            deployJson.set("CSAccountingImpl", address(accountingImpl));
            deployJson.set("CSFeeOracle", address(oracle));
            deployJson.set("CSFeeOracleImpl", address(oracleImpl));
            deployJson.set("CSFeeDistributor", address(feeDistributor));
            deployJson.set("CSFeeDistributorImpl", address(feeDistributorImpl));
            deployJson.set("CSExitPenalties", address(exitPenalties));
            deployJson.set("CSExitPenaltiesImpl", address(exitPenaltiesImpl));
            deployJson.set("CSEjector", address(ejector));
            deployJson.set("CSStrikes", address(strikes));
            deployJson.set("CSStrikesImpl", address(strikesImpl));
            deployJson.set("HashConsensus", address(hashConsensus));
            deployJson.set("CSVerifier", address(verifier));
            deployJson.set("PermissionlessGate", address(permissionlessGate));
            deployJson.set("VettedGateFactory", address(vettedGateFactory));
            deployJson.set("VettedGate", address(vettedGate));
            deployJson.set("VettedGateImpl", address(vettedGateImpl));
            deployJson.set("LidoLocator", config.lidoLocatorAddress);
            deployJson.set("GateSeal", gateSeal);
            deployJson.set("DeployParams", abi.encode(config));
            deployJson.set("git-ref", gitRef);
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

    function _deployGateSeal(
        address[] memory sealables
    ) internal returns (address) {
        IGateSealFactory gateSealFactory = IGateSealFactory(
            config.gateSealFactory
        );

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
        parametersRegistry.grantRole(
            parametersRegistry.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        vettedGate.grantRole(
            vettedGate.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        ejector.grantRole(
            ejector.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        verifier.grantRole(
            verifier.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
        strikes.grantRole(
            strikes.DEFAULT_ADMIN_ROLE(),
            config.secondAdminAddress
        );
    }
}
