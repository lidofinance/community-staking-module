// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";

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
import { DeployBase } from "./DeployBase.s.sol";

abstract contract DeployImplementationsBase is DeployBase {
    address gateSeal;

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
            CSModule csmImpl = new CSModule({
                moduleType: config.moduleType,
                minSlashingPenaltyQuotient: config.minSlashingPenaltyQuotient,
                elRewardsStealingAdditionalFine: config
                    .elRewardsStealingAdditionalFine,
                maxKeysPerOperatorEA: config.maxKeysPerOperatorEA,
                maxKeyRemovalCharge: config.maxKeyRemovalCharge,
                lidoLocator: config.lidoLocatorAddress
            });

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: config.lidoLocatorAddress,
                communityStakingModule: address(csm),
                maxCurveLength: config.maxCurveLength,
                minBondLockPeriod: config.minBondLockPeriod,
                maxBondLockPeriod: config.maxBondLockPeriod
            });

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: config.secondsPerSlot,
                genesisTime: config.clGenesisTime
            });

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting),
                oracle: address(oracle)
            });

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
            deployJson.set("CSFeeOracleImpl", address(oracleImpl));
            deployJson.set("CSFeeDistributorImpl", address(feeDistributorImpl));
            deployJson.set("CSVerifier", address(verifier));
            deployJson.set("CSEarlyAdoption", address(earlyAdoption));
            deployJson.set("HashConsensus", address(hashConsensus));
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
