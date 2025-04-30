// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSExitPenalties } from "../src/CSExitPenalties.sol";
import { CSEjector } from "../src/CSEjector.sol";
import { CSStrikes } from "../src/CSStrikes.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { PermissionlessGate } from "../src/PermissionlessGate.sol";
import { VettedGateFactory } from "../src/VettedGateFactory.sol";
import { VettedGate } from "../src/VettedGate.sol";
import { CSParametersRegistry } from "../src/CSParametersRegistry.sol";
import { ICSParametersRegistry } from "../src/interfaces/ICSParametersRegistry.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";
import { OssifiableProxy } from "../src/lib/proxy/OssifiableProxy.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";
import { DeployBase } from "./DeployBase.s.sol";

abstract contract DeployImplementationsBase is DeployBase {
    address public gateSealV2;
    address public verifierV2;
    address public earlyAdoption;

    function _deploy() internal {
        if (chainId != block.chainid) {
            revert ChainIdMismatch({
                actual: block.chainid,
                expected: chainId
            });
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

            CSModule csmImpl = new CSModule({
                moduleType: config.moduleType,
                lidoLocator: config.lidoLocatorAddress,
                parametersRegistry: address(parametersRegistry)
            });

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                module: address(csm),
                maxCurveLength: config.maxCurveLength,
                minBondLockPeriod: config.minBondLockPeriod,
                maxBondLockPeriod: config.maxBondLockPeriod
            });

            permissionlessGate = new PermissionlessGate(address(csm));

            address vettedGateImpl = address(new VettedGate(address(csm)));
            vettedGateFactory = new VettedGateFactory(vettedGateImpl);
            vettedGate = VettedGate(
                vettedGateFactory.create({
                    curveId: ICSEarlyAdoption(earlyAdoption).CURVE_ID(),
                    treeRoot: config.vettedGateTreeRoot,
                    treeCid: config.vettedGateTreeCid,
                    admin: deployer
                })
            );

            OssifiableProxy vettedGateProxy = OssifiableProxy(
                payable(address(vettedGate))
            );
            vettedGateProxy.proxy__changeAdmin(config.proxyAdmin);

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime
            });

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting),
                oracle: address(oracle)
            });

            CSExitPenalties exitPenaltiesImpl = new CSExitPenalties(
                address(csm),
                address(parametersRegistry),
                address(accounting)
            );

            exitPenalties = CSExitPenalties(
                _deployProxy(config.proxyAdmin, address(exitPenaltiesImpl))
            );

            ejector = new CSEjector(address(csm), config.stakingModuleId);

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

            CSVerifier verifierV2 = new CSVerifier({
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

            address[] memory sealables = new address[](6);
            sealables[0] = address(csm);
            sealables[1] = address(accounting);
            sealables[2] = address(oracle);
            sealables[3] = address(verifierV2);
            sealables[4] = address(vettedGate);
            sealables[5] = address(ejector);
            gateSealV2 = _deployGateSeal(sealables);

            if (config.secondAdminAddress != address(0)) {
                if (config.secondAdminAddress == deployer) {
                    revert InvalidSecondAdmin();
                }
                _grantSecondAdminsForNewContracts();
            }

            ejector.grantRole(ejector.PAUSE_ROLE(), gateSealV2);
            ejector.grantRole(ejector.DEFAULT_ADMIN_ROLE(), config.aragonAgent);
            ejector.revokeRole(ejector.DEFAULT_ADMIN_ROLE(), deployer);

            vettedGate.grantRole(vettedGate.PAUSE_ROLE(), gateSealV2);
            vettedGate.grantRole(
                vettedGate.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            vettedGate.grantRole(
                vettedGate.SET_TREE_ROLE(),
                config.vettedGateManager
            );
            vettedGate.grantRole(
                vettedGate.START_REFERRAL_SEASON_ROLE(),
                config.aragonAgent
            );
            vettedGate.grantRole(
                vettedGate.END_REFERRAL_SEASON_ROLE(),
                config.vettedGateManager
            );
            vettedGate.revokeRole(vettedGate.DEFAULT_ADMIN_ROLE(), deployer);

            verifierV2.grantRole(verifierV2.PAUSE_ROLE(), gateSealV2);
            verifierV2.grantRole(
                verifierV2.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            verifierV2.revokeRole(verifierV2.DEFAULT_ADMIN_ROLE(), deployer);

            parametersRegistry.grantRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            parametersRegistry.revokeRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
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
            deployJson.set("CSVerifierV2", address(verifierV2));
            deployJson.set("PermissionlessGate", address(permissionlessGate));
            deployJson.set("VettedGateFactory", address(vettedGateFactory));
            deployJson.set("VettedGate", address(vettedGate));
            deployJson.set("VettedGateImpl", address(vettedGateImpl));
            deployJson.set("LidoLocator", config.lidoLocatorAddress);
            deployJson.set("GateSeal", gateSeal);
            deployJson.set("GateSealV2", gateSealV2);
            deployJson.set("DeployParams", abi.encode(config));
            deployJson.set("git-ref", gitRef);
            vm.writeJson(
                deployJson.str,
                string(
                    abi.encodePacked(
                        artifactDir,
                        "upgrade-",
                        chainName,
                        ".json"
                    )
                )
            );
        }

        vm.stopBroadcast();
    }

    function _grantSecondAdminsForNewContracts() internal {
        if (keccak256(abi.encodePacked(chainName)) == keccak256("mainnet")) {
            revert CannotBeUsedInMainnet();
        }
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

interface ICSEarlyAdoption {
    function CURVE_ID() external view returns (uint256);
}
