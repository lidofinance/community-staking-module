// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import { DeploymentFixtures } from "test/helpers/Fixtures.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { OssifiableProxy } from "../../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../../src/CSModule.sol";
import { IBurner } from "../../src/interfaces/IBurner.sol";
import { ForkHelpersCommon } from "./Common.sol";

contract SimulateVote is Script, DeploymentFixtures, ForkHelpersCommon {
    function addModule() external {
        _setUp();

        IStakingRouter stakingRouter = IStakingRouter(locator.stakingRouter());
        IBurner burner = IBurner(locator.burner());

        address agent = stakingRouter.getRoleMember(
            stakingRouter.STAKING_MODULE_MANAGE_ROLE(),
            0
        );
        vm.label(agent, "agent");

        address csmAdmin = _prepareAdmin(address(csm));
        address burnerAdmin = _prepareAdmin(address(burner));

        vm.startBroadcast(csmAdmin);
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), agent);
        hashConsensus.grantRole(hashConsensus.DEFAULT_ADMIN_ROLE(), agent);
        vm.stopBroadcast();

        vm.startBroadcast(burnerAdmin);
        burner.grantRole(burner.DEFAULT_ADMIN_ROLE(), agent);
        vm.stopBroadcast();

        vm.startBroadcast(agent);
        // 1. Grant manager role
        csm.grantRole(csm.MODULE_MANAGER_ROLE(), agent);

        // 2. Add CommunityStaking module
        stakingRouter.addStakingModule({
            _name: "community-staking-v1",
            _stakingModuleAddress: address(csm),
            _stakeShareLimit: 2000, // 20%
            _priorityExitShareThreshold: 2500, // 25%
            _stakingModuleFee: 800, // 8%
            _treasuryFee: 200, // 2%
            _maxDepositsPerBlock: 30,
            _minDepositBlockDistance: 25
        });
        // 3. burner role
        burner.grantRole(
            burner.REQUEST_BURN_SHARES_ROLE(),
            address(accounting)
        );
        // 4. Grant resume to agent
        csm.grantRole(csm.RESUME_ROLE(), agent);
        // 5. Resume CSM
        csm.resume();
        // 6. Revoke resume
        csm.revokeRole(csm.RESUME_ROLE(), agent);
        // 7. Update initial epoch
        hashConsensus.updateInitialEpoch(47480);
    }

    function upgrade() external {
        Env memory env = envVars();
        string memory deploymentConfigContent = vm.readFile(env.DEPLOY_CONFIG);
        DeploymentConfig memory deploymentConfig = parseDeploymentConfig(
            deploymentConfigContent
        );
        string memory upgradeConfigContent = vm.readFile(env.UPGRADE_CONFIG);
        UpgradeConfig memory upgradeConfig = parseUpgradeConfig(
            upgradeConfigContent
        );
        OssifiableProxy csmProxy = OssifiableProxy(
            payable(deploymentConfig.csm)
        );
        vm.broadcast(csmProxy.proxy__getAdmin());
        csmProxy.proxy__upgradeTo(upgradeConfig.csmImpl);

        OssifiableProxy accountingProxy = OssifiableProxy(
            payable(deploymentConfig.accounting)
        );
        vm.broadcast(accountingProxy.proxy__getAdmin());
        accountingProxy.proxy__upgradeTo(upgradeConfig.accountingImpl);

        OssifiableProxy oracleProxy = OssifiableProxy(
            payable(deploymentConfig.oracle)
        );
        vm.broadcast(oracleProxy.proxy__getAdmin());
        oracleProxy.proxy__upgradeTo(upgradeConfig.oracleImpl);

        OssifiableProxy feeDistributorProxy = OssifiableProxy(
            payable(deploymentConfig.feeDistributor)
        );
        vm.broadcast(feeDistributorProxy.proxy__getAdmin());
        feeDistributorProxy.proxy__upgradeTo(upgradeConfig.feeDistributorImpl);

        address admin = _prepareAdmin(deploymentConfig.csm);
        csm = CSModule(deploymentConfig.csm);

        vm.startBroadcast(admin);
        csm.revokeRole(csm.VERIFIER_ROLE(), address(deploymentConfig.verifier));
        csm.grantRole(csm.VERIFIER_ROLE(), address(upgradeConfig.verifier));
        vm.stopBroadcast();
    }
}
