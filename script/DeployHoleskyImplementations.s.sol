// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { DeployHolesky } from "./DeployHolesky.s.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { CSEarlyAdoption } from "../src/CSEarlyAdoption.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";

contract DeployHoleskyImplementations is DeployHolesky {
    address gateSeal;

    function run() external virtual override {
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
        parseDeploymentConfig();

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

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                communityStakingModule: address(csm),
                maxCurveLength: config.maxCurveLength,
                minBondLockRetentionPeriod: config.minBondLockRetentionPeriod,
                maxBondLockRetentionPeriod: config.maxBondLockRetentionPeriod
            });

            // No changes in these contracts. Uncomment if any
            //            CSFeeOracle oracleImpl = new CSFeeOracle({
            //                secondsPerSlot: config.secondsPerSlot,
            //                genesisTime: config.clGenesisTime
            //            });

            //            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
            //                stETH: locator.lido(),
            //                accounting: address(accounting),
            //                oracle: address(oracle)
            //            });

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

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("CSModuleImpl", address(csmImpl));
            deployJson.set("CSAccountingImpl", address(accountingImpl));
            // deployJson.set("CSFeeOracleImpl", address(oracle));
            // deployJson.set("CSFeeDistributor", address(feeDistributor));
            deployJson.set("CSVerifier", address(verifier));
            vm.writeJson(
                deployJson.str,
                string(
                    abi.encodePacked(artifactDir, "update-", chainName, ".json")
                )
            );
        }

        vm.stopBroadcast();
    }

    function parseDeploymentConfig() internal {
        string memory deployConfig = vm.readFile(
            vm.envOr("DEPLOY_CONFIG", string(""))
        );
        csm = CSModule(vm.parseJsonAddress(deployConfig, ".CSModule"));
        earlyAdoption = CSEarlyAdoption(
            vm.parseJsonAddress(deployConfig, ".CSEarlyAdoption")
        );
        accounting = CSAccounting(
            vm.parseJsonAddress(deployConfig, ".CSAccounting")
        );
        oracle = CSFeeOracle(vm.parseJsonAddress(deployConfig, ".CSFeeOracle"));
        feeDistributor = CSFeeDistributor(
            vm.parseJsonAddress(deployConfig, ".CSFeeDistributor")
        );
        hashConsensus = HashConsensus(
            vm.parseJsonAddress(deployConfig, ".HashConsensus")
        );
        gateSeal = vm.parseJsonAddress(deployConfig, ".GateSeal");
    }
}
