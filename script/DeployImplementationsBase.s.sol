// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSStrikes } from "../src/CSStrikes.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { PermissionlessGate } from "../src/PermissionlessGate.sol";
import { VettedGateFactory } from "../src/VettedGateFactory.sol";
import { VettedGate } from "../src/VettedGate.sol";
import { CSParametersRegistry } from "../src/CSParametersRegistry.sol";
import { ICSEarlyAdoption } from "../src/interfaces/ICSEarlyAdoption.sol";
import { ICSParametersRegistry } from "../src/interfaces/ICSParametersRegistry.sol";
import { ICSVerifier } from "../src/interfaces/ICSVerifier.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";
import { DeployBase } from "./DeployBase.s.sol";

abstract contract DeployImplementationsBase is DeployBase {
    address gateSeal;
    address earlyAdoption;

    function _deploy() internal {
        if (chainId != block.chainid) {
            revert ChainIdMismatch({
                actual: block.chainid,
                expected: chainId
            });
        }
        artifactDir = vm.envOr("ARTIFACTS_DIR", string("./artifacts/local/"));
        pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(pk);
        vm.label(deployer, "DEPLOYER");

        vm.startBroadcast(pk);
        {
            CSParametersRegistry parametersRegistryImpl = new CSParametersRegistry();
            parametersRegistry = CSParametersRegistry(
                _deployProxy(config.proxyAdmin, address(parametersRegistryImpl))
            );
            parametersRegistry.initialize({
                admin: deployer,
                data: ICSParametersRegistry.InitializationData({
                    keyRemovalCharge: config.keyRemovalCharge,
                    elRewardsStealingAdditionalFine: config
                        .elRewardsStealingAdditionalFine,
                    priorityQueueLimit: config.priorityQueueLimit,
                    rewardShare: config.rewardShareBP,
                    performanceLeeway: config.avgPerfLeewayBP,
                    strikesLifetime: config.strikesLifetimeFrames,
                    strikesThreshold: config.strikesThreshold,
                    badPerformancePenalty: config.badPerformancePenalty,
                    attestationsWeight: config.attestationsWeight,
                    blocksWeight: config.blocksWeight,
                    syncWeight: config.syncWeight
                })
            });

            CSModule csmImpl = new CSModule({
                moduleType: config.moduleType,
                minSlashingPenaltyQuotient: config.minSlashingPenaltyQuotient,
                maxKeysPerOperatorEA: config.maxKeysPerOperatorEA,
                lidoLocator: config.lidoLocatorAddress,
                parametersRegistry: address(parametersRegistry)
            });

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                communityStakingModule: address(csm),
                maxCurveLength: config.maxCurveLength,
                minBondLockPeriod: config.minBondLockPeriod,
                maxBondLockPeriod: config.maxBondLockPeriod
            });

            permissionlessGate = new PermissionlessGate(address(csm));

            vettedGateFactory = new VettedGateFactory();
            vettedGate = VettedGate(
                vettedGateFactory.create({
                    csm: address(csm),
                    curveId: ICSEarlyAdoption(earlyAdoption).CURVE_ID(),
                    treeRoot: config.vettedGateTreeRoot,
                    admin: deployer
                })
            );

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime
            });

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting),
                oracle: address(oracle),
                rebateRecipient: config.aragonAgent
            });

            CSStrikes strikesImpl = new CSStrikes(
                address(csm),
                address(oracle)
            );
            strikes = CSStrikes(
                _deployProxy(config.proxyAdmin, address(strikesImpl))
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

            address[] memory sealables = new address[](5);
            sealables[0] = address(csm);
            sealables[1] = address(accounting);
            sealables[2] = address(oracle);
            sealables[3] = address(verifier);
            sealables[4] = address(vettedGate);
            gateSeal = _deployGateSeal(sealables);

            vettedGate.grantRole(vettedGate.PAUSE_ROLE(), address(gateSeal));
            vettedGate.grantRole(
                vettedGate.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            vettedGate.revokeRole(vettedGate.DEFAULT_ADMIN_ROLE(), deployer);

            verifier.grantRole(verifier.PAUSE_ROLE(), address(gateSeal));
            verifier.grantRole(
                verifier.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            verifier.revokeRole(verifier.DEFAULT_ADMIN_ROLE(), deployer);

            parametersRegistry.grantRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                config.aragonAgent
            );
            parametersRegistry.revokeRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                deployer
            );

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("PermissionlessGate", address(permissionlessGate));
            deployJson.set("VettedGateFactory", address(vettedGateFactory));
            deployJson.set("VettedGate", address(vettedGate));
            deployJson.set(
                "CSParametersRegistryImpl",
                address(parametersRegistryImpl)
            );
            deployJson.set("CSParametersRegistry", address(parametersRegistry));
            deployJson.set("CSModuleImpl", address(csmImpl));
            deployJson.set("CSAccountingImpl", address(accountingImpl));
            deployJson.set("CSFeeOracleImpl", address(oracleImpl));
            deployJson.set("CSFeeDistributorImpl", address(feeDistributorImpl));
            deployJson.set("CSStrikes", address(strikes));
            deployJson.set("CSStrikesImpl", address(strikesImpl));
            deployJson.set("CSVerifier", address(verifier));
            deployJson.set("HashConsensus", address(hashConsensus));
            deployJson.set("GateSeal", address(gateSeal));
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
}
