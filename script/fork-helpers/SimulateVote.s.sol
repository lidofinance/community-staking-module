// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import { DeploymentFixtures } from "test/helpers/Fixtures.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { OssifiableProxy } from "../../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { CSFeeOracle } from "../../src/CSFeeOracle.sol";
import { CSFeeDistributor } from "../../src/CSFeeDistributor.sol";
import { CSEjector } from "../../src/CSEjector.sol";
import { CSParametersRegistry } from "../../src/CSParametersRegistry.sol";
import { IBurner } from "../../src/interfaces/IBurner.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
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

        // 1. Add CommunityStaking module
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
        // 2. burner role
        burner.grantRole(
            burner.REQUEST_BURN_MY_STETH_ROLE(),
            address(accounting)
        );
        // 3. Grant resume to agent
        csm.grantRole(csm.RESUME_ROLE(), agent);
        // 4. Resume CSM
        csm.resume();
        // 5. Revoke resume
        csm.revokeRole(csm.RESUME_ROLE(), agent);
        // 6. Update initial epoch
        hashConsensus.updateInitialEpoch(47480);
    }

    uint256[2][] defaultBondCurve = [
        [uint256(1), 2.4 ether],
        [uint256(2), 1.3 ether]
    ];
    uint256[2][] vettedBondCurve = [
        [uint256(1), 1.5 ether],
        [uint256(2), 1.3 ether]
    ];

    uint256 vettedGateKeyRemovalCharge = 0.01 ether;
    uint256 vettedGateELRewardsStealingAdditionalFine = 0.5 ether;
    uint256 vettedGateKeysLimit = type(uint248).max;
    uint256[2][] vettedGateAvgPerfLeewayData = [[uint256(0), uint256(500)]];

    uint256[2][] vettedGateRewardShareData = [[uint256(0), uint256(10000)]];
    uint256 vettedGateStrikesLifetimeFrames = 6;
    uint256 vettedGateStrikesThreshold = 3;
    uint256 vettedGateQueuePriority = 0;
    uint256 vettedGateQueueMaxDeposits = 10;
    uint256 vettedGateBadPerformancePenalty = 0.1 ether;
    uint256 vettedGateAttestationsWeight = 54;
    uint256 vettedGateBlocksWeight = 8;
    uint256 vettedGateSyncWeight = 2;
    uint256 vettedGateAllowedExitDelay = 4 days;
    uint256 vettedGateExitDelayPenalty = 0.1 ether;
    uint256 vettedGateMaxWithdrawalRequestFee = 0.1 ether;

    function upgrade() external {
        Env memory env = envVars();
        string memory deploymentConfigContent = vm.readFile(env.DEPLOY_CONFIG);
        DeploymentConfig memory deploymentConfig = parseDeploymentConfig(
            deploymentConfigContent
        );

        address admin = _prepareAdmin(deploymentConfig.csm);

        OssifiableProxy csmProxy = OssifiableProxy(
            payable(deploymentConfig.csm)
        );
        vm.startBroadcast(_prepareProxyAdmin(address(csmProxy)));
        {
            csmProxy.proxy__upgradeTo(deploymentConfig.csmImpl);
            CSModule(deploymentConfig.csm).finalizeUpgradeV2(
                deploymentConfig.exitPenalties
            );
        }
        vm.stopBroadcast();

        OssifiableProxy accountingProxy = OssifiableProxy(
            payable(deploymentConfig.accounting)
        );
        vm.startBroadcast(_prepareProxyAdmin(address(accountingProxy)));
        {
            accountingProxy.proxy__upgradeTo(deploymentConfig.accountingImpl);
            CSAccounting(deploymentConfig.accounting).finalizeUpgradeV2(
                defaultBondCurve,
                vettedBondCurve
            );
        }
        vm.stopBroadcast();

        OssifiableProxy oracleProxy = OssifiableProxy(
            payable(deploymentConfig.oracle)
        );
        vm.startBroadcast(_prepareProxyAdmin(address(oracleProxy)));
        {
            oracleProxy.proxy__upgradeTo(deploymentConfig.oracleImpl);
            CSFeeOracle(deploymentConfig.oracle).finalizeUpgradeV2({
                consensusVersion: 3,
                strikesContract: deploymentConfig.strikes
            });
        }
        vm.stopBroadcast();

        OssifiableProxy feeDistributorProxy = OssifiableProxy(
            payable(deploymentConfig.feeDistributor)
        );
        vm.startBroadcast(_prepareProxyAdmin(address(feeDistributorProxy)));
        {
            feeDistributorProxy.proxy__upgradeTo(
                deploymentConfig.feeDistributorImpl
            );
            CSFeeDistributor(deploymentConfig.feeDistributor).finalizeUpgradeV2(
                admin
            );
        }
        vm.stopBroadcast();

        locator = ILidoLocator(deploymentConfig.lidoLocator);
        csm = CSModule(deploymentConfig.csm);
        accounting = CSAccounting(deploymentConfig.accounting);
        oracle = CSFeeOracle(deploymentConfig.oracle);
        IBurner burner = IBurner(locator.burner());
        CSParametersRegistry parametersRegistry = CSParametersRegistry(
            upgradeConfig.parametersRegistry
        );

        vm.startBroadcast(admin);

        uint256 identifiedSolosCurve = 1;
        parametersRegistry.setKeyRemovalCharge(
            identifiedSolosCurve,
            vettedGateKeyRemovalCharge
        );
        parametersRegistry.setElRewardsStealingAdditionalFine(
            identifiedSolosCurve,
            vettedGateELRewardsStealingAdditionalFine
        );
        parametersRegistry.setKeysLimit(
            identifiedSolosCurve,
            vettedGateKeysLimit
        );
        parametersRegistry.setPerformanceLeewayData(
            identifiedSolosCurve,
            vettedGateAvgPerfLeewayData
        );
        parametersRegistry.setRewardShareData(
            identifiedSolosCurve,
            vettedGateRewardShareData
        );
        parametersRegistry.setStrikesParams(
            identifiedSolosCurve,
            vettedGateStrikesLifetimeFrames,
            vettedGateStrikesThreshold
        );
        parametersRegistry.setQueueConfig(
            identifiedSolosCurve,
            uint32(vettedGateQueuePriority),
            uint32(vettedGateQueueMaxDeposits)
        );
        parametersRegistry.setBadPerformancePenalty(
            identifiedSolosCurve,
            vettedGateBadPerformancePenalty
        );
        parametersRegistry.setPerformanceCoefficients(
            identifiedSolosCurve,
            vettedGateAttestationsWeight,
            vettedGateBlocksWeight,
            vettedGateSyncWeight
        );
        parametersRegistry.setAllowedExitDelay(
            identifiedSolosCurve,
            vettedGateAllowedExitDelay
        );
        parametersRegistry.setExitDelayPenalty(
            identifiedSolosCurve,
            vettedGateExitDelayPenalty
        );
        parametersRegistry.setMaxWithdrawalRequestFee(
            identifiedSolosCurve,
            vettedGateMaxWithdrawalRequestFee
        );

        accounting.revokeRole(keccak256("SET_BOND_CURVE_ROLE"), address(csm));
        csm.grantRole(
            csm.CREATE_NODE_OPERATOR_ROLE(),
            deploymentConfig.permissionlessGate
        );
        csm.grantRole(
            csm.CREATE_NODE_OPERATOR_ROLE(),
            deploymentConfig.vettedGate
        );
        accounting.grantRole(
            accounting.SET_BOND_CURVE_ROLE(),
            deploymentConfig.vettedGate
        );

        csm.revokeRole(csm.VERIFIER_ROLE(), address(deploymentConfig.verifier));
        csm.grantRole(
            csm.VERIFIER_ROLE(),
            address(deploymentConfig.verifierV2)
        );

        csm.revokeRole(csm.PAUSE_ROLE(), address(deploymentConfig.gateSeal));
        accounting.revokeRole(
            accounting.PAUSE_ROLE(),
            address(deploymentConfig.gateSeal)
        );
        oracle.revokeRole(
            oracle.PAUSE_ROLE(),
            address(deploymentConfig.gateSeal)
        );

        csm.grantRole(csm.PAUSE_ROLE(), address(deploymentConfig.gateSealV2));
        accounting.grantRole(
            accounting.PAUSE_ROLE(),
            address(deploymentConfig.gateSealV2)
        );
        oracle.grantRole(
            oracle.PAUSE_ROLE(),
            address(deploymentConfig.gateSealV2)
        );
        burner.revokeRole(
            burner.REQUEST_BURN_SHARES_ROLE(),
            address(accounting)
        );
        burner.grantRole(
            burner.REQUEST_BURN_MY_STETH_ROLE(),
            address(accounting)
        );

        accounting.revokeRole(keccak256("RESET_BOND_CURVE_ROLE"), address(csm));
        address csmCommittee = accounting.getRoleMember(
            keccak256("RESET_BOND_CURVE_ROLE"),
            0
        );
        accounting.revokeRole(
            keccak256("RESET_BOND_CURVE_ROLE"),
            address(csmCommittee)
        );

        vm.stopBroadcast();
    }
}
