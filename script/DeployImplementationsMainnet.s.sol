// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { DeployImplementationsBase } from "./DeployImplementationsBase.s.sol";
import "./DeployMainnet.s.sol";
import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { CSEarlyAdoption } from "../src/CSEarlyAdoption.sol";
import { DeploymentHelpers } from "../test/helpers/Fixtures.sol";

contract DeployImplementationsMainnet is
    DeployImplementationsBase,
    DeployMainnet,
    DeploymentHelpers
{
    function deploy(string memory deploymentConfigPath) external {
        string memory deploymentConfigContent = vm.readFile(
            deploymentConfigPath
        );
        DeploymentConfig memory deploymentConfig = parseDeploymentConfig(
            deploymentConfigContent
        );

        csm = CSModule(deploymentConfig.csm);
        earlyAdoption = CSEarlyAdoption(deploymentConfig.earlyAdoption);
        accounting = CSAccounting(deploymentConfig.accounting);
        oracle = CSFeeOracle(deploymentConfig.oracle);
        feeDistributor = CSFeeDistributor(deploymentConfig.feeDistributor);
        hashConsensus = HashConsensus(deploymentConfig.hashConsensus);
        gateSeal = deploymentConfig.gateSeal;

        _deploy();
    }
}
