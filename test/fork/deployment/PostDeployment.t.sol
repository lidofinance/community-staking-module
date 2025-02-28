// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { DeployParams } from "../../../script/DeployBase.s.sol";
import { OssifiableProxy } from "../../../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../../../src/CSModule.sol";
import { CSParametersRegistry } from "../../../src/CSParametersRegistry.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { HashConsensus } from "../../../src/lib/base-oracle/HashConsensus.sol";
import { CSBondCurve } from "../../../src/abstract/CSBondCurve.sol";
import { CSFeeDistributor } from "../../../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../../../src/CSFeeOracle.sol";
import { IWithdrawalQueue } from "../../../src/interfaces/IWithdrawalQueue.sol";
import { ICSParametersRegistry } from "../../../src/interfaces/ICSParametersRegistry.sol";
import { BaseOracle } from "../../../src/lib/base-oracle/BaseOracle.sol";
import { GIndex } from "../../../src/lib/GIndex.sol";
import { Slot } from "../../../src/lib/Types.sol";
import { Versioned } from "../../../src/lib/utils/Versioned.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CSModuleDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public view {
        assertEq(csm.getType(), deployParams.moduleType);
        assertEq(address(csm.LIDO_LOCATOR()), deployParams.lidoLocatorAddress);
    }

    function test_initializer() public view {
        assertEq(address(csm.accounting()), address(accounting));
        assertTrue(
            csm.hasRole(csm.STAKING_ROUTER_ROLE(), locator.stakingRouter())
        );
        assertTrue(csm.getRoleMemberCount(csm.STAKING_ROUTER_ROLE()) == 1);
    }

    function test_roles() public view {
        assertTrue(
            csm.hasRole(csm.DEFAULT_ADMIN_ROLE(), deployParams.aragonAgent)
        );
        assertTrue(
            csm.getRoleMemberCount(csm.DEFAULT_ADMIN_ROLE()) == adminsCount
        );
        assertTrue(csm.hasRole(csm.PAUSE_ROLE(), address(gateSeal)));
        assertEq(csm.getRoleMemberCount(csm.PAUSE_ROLE()), 1);
        assertEq(csm.getRoleMemberCount(csm.RESUME_ROLE()), 0);
        assertTrue(
            csm.hasRole(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
                address(deployParams.elRewardsStealingReporter)
            )
        );
        assertEq(
            csm.getRoleMemberCount(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE()
            ),
            1
        );
        assertTrue(
            csm.hasRole(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
                address(deployParams.easyTrackEVMScriptExecutor)
            )
        );
        assertEq(
            csm.getRoleMemberCount(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE()
            ),
            1
        );
        assertTrue(csm.hasRole(csm.VERIFIER_ROLE(), address(verifier)));
        assertEq(csm.getRoleMemberCount(csm.VERIFIER_ROLE()), 1);
        assertEq(csm.getRoleMemberCount(csm.RECOVERER_ROLE()), 0);
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(payable(address(csm)));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSModule csmImpl = CSModule(proxy.proxy__getImplementation());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        csmImpl.initialize({
            _accounting: address(accounting),
            admin: deployParams.aragonAgent
        });
    }
}

contract CSParametersRegistryDeploymentTest is
    Test,
    Utilities,
    DeploymentFixtures
{
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_initializer() public view {
        assertEq(
            parametersRegistry.defaultKeyRemovalCharge(),
            deployParams.keyRemovalCharge
        );
        assertEq(
            parametersRegistry.defaultElRewardsStealingAdditionalFine(),
            deployParams.elRewardsStealingAdditionalFine
        );
        assertEq(
            parametersRegistry.defaultRewardShare(),
            deployParams.rewardShareBP
        );
        assertEq(
            parametersRegistry.defaultPerformanceLeeway(),
            deployParams.avgPerfLeewayBP
        );
        (uint256 strikesLifetime, uint256 strikesThreshold) = parametersRegistry
            .defaultStrikesParams();
        assertEq(strikesLifetime, deployParams.strikesLifetimeFrames);
        assertEq(strikesThreshold, deployParams.strikesThreshold);

        (uint256 priority, uint256 maxDeposits) = parametersRegistry
            .defaultQueueConfig();
        assertEq(priority, deployParams.defaultQueuePriority);
        assertEq(maxDeposits, deployParams.defaultQueueMaxDeposits);

        assertEq(
            parametersRegistry.defaultBadPerformancePenalty(),
            deployParams.badPerformancePenalty
        );

        (
            uint256 attestationsWeight,
            uint256 blocksWeight,
            uint256 syncWeight
        ) = parametersRegistry.defaultPerformanceCoefficients();
        assertEq(attestationsWeight, deployParams.attestationsWeight);
        assertEq(blocksWeight, deployParams.blocksWeight);
        assertEq(syncWeight, deployParams.syncWeight);
    }

    function test_roles() public view {
        assertTrue(
            parametersRegistry.hasRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            parametersRegistry.getRoleMemberCount(
                parametersRegistry.DEFAULT_ADMIN_ROLE()
            ),
            1
        );
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(
            payable(address(parametersRegistry))
        );
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSParametersRegistry parametersRegistryImpl = CSParametersRegistry(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        parametersRegistryImpl.initialize({
            admin: deployParams.aragonAgent,
            data: ICSParametersRegistry.InitializationData({
                keyRemovalCharge: deployParams.keyRemovalCharge,
                elRewardsStealingAdditionalFine: deployParams
                    .elRewardsStealingAdditionalFine,
                rewardShare: deployParams.rewardShareBP,
                performanceLeeway: deployParams.avgPerfLeewayBP,
                strikesLifetime: deployParams.strikesLifetimeFrames,
                strikesThreshold: deployParams.strikesThreshold,
                defaultQueuePriority: deployParams.defaultQueuePriority,
                defaultQueueMaxDeposits: deployParams.defaultQueueMaxDeposits,
                badPerformancePenalty: deployParams.badPerformancePenalty,
                attestationsWeight: deployParams.attestationsWeight,
                blocksWeight: deployParams.blocksWeight,
                syncWeight: deployParams.syncWeight
            })
        });
    }
}

contract CSAccountingDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public view {
        assertEq(address(accounting.CSM()), address(csm));
        assertEq(address(accounting.LIDO_LOCATOR()), address(locator));
        assertEq(address(accounting.LIDO()), locator.lido());
        assertEq(
            address(accounting.WITHDRAWAL_QUEUE()),
            locator.withdrawalQueue()
        );
        assertEq(
            address(accounting.WSTETH()),
            IWithdrawalQueue(locator.withdrawalQueue()).WSTETH()
        );

        assertEq(
            accounting.MIN_BOND_LOCK_PERIOD(),
            deployParams.minBondLockPeriod
        );
        assertEq(
            accounting.MAX_BOND_LOCK_PERIOD(),
            deployParams.maxBondLockPeriod
        );
        assertEq(accounting.MAX_CURVE_LENGTH(), deployParams.maxCurveLength);
    }

    function test_initializer() public view {
        assertEq(
            accounting.getCurveInfo(accounting.DEFAULT_BOND_CURVE_ID()).points,
            deployParams.bondCurve
        );
        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
        assertEq(accounting.getBondLockPeriod(), deployParams.bondLockPeriod);
        assertEq(
            accounting.chargePenaltyRecipient(),
            deployParams.chargePenaltyRecipient
        );
        assertTrue(
            accounting.hasRole(accounting.RESET_BOND_CURVE_ROLE(), address(csm))
        );

        IWithdrawalQueue wq = IWithdrawalQueue(locator.withdrawalQueue());
        assertEq(
            lido.allowance(address(accounting), wq.WSTETH()),
            type(uint256).max
        );
        assertEq(
            lido.allowance(address(accounting), address(wq)),
            type(uint256).max
        );
        assertEq(
            lido.allowance(address(accounting), locator.burner()),
            type(uint256).max
        );
    }

    function test_roles() public view {
        assertTrue(
            accounting.hasRole(
                accounting.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );

        assertTrue(
            accounting.hasRole(accounting.PAUSE_ROLE(), address(gateSeal))
        );
        assertEq(accounting.getRoleMemberCount(accounting.PAUSE_ROLE()), 1);

        assertTrue(
            accounting.hasRole(
                accounting.SET_BOND_CURVE_ROLE(),
                address(vettedGate)
            )
        );
        assertTrue(
            accounting.hasRole(
                accounting.SET_BOND_CURVE_ROLE(),
                deployParams.setResetBondCurveAddress
            )
        );
        assertFalse(
            accounting.hasRole(accounting.SET_BOND_CURVE_ROLE(), address(csm))
        );

        assertTrue(
            accounting.hasRole(
                accounting.RESET_BOND_CURVE_ROLE(),
                deployParams.setResetBondCurveAddress
            )
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.RESET_BOND_CURVE_ROLE()),
            2
        );
        assertEq(accounting.getRoleMemberCount(accounting.RESUME_ROLE()), 0);
        assertEq(
            accounting.getRoleMemberCount(accounting.MANAGE_BOND_CURVES_ROLE()),
            0
        );
        assertEq(accounting.getRoleMemberCount(accounting.RECOVERER_ROLE()), 0);
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(payable(address(accounting)));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSAccounting accountingImpl = CSAccounting(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        accountingImpl.initialize({
            bondCurve: deployParams.bondCurve,
            admin: address(deployParams.aragonAgent),
            _feeDistributor: address(feeDistributor),
            bondLockPeriod: deployParams.bondLockPeriod,
            _chargePenaltyRecipient: address(0)
        });
    }
}

contract CSFeeDistributorDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public view {
        assertEq(address(feeDistributor.STETH()), address(lido));
        assertEq(feeDistributor.ACCOUNTING(), address(accounting));
        assertEq(feeDistributor.ORACLE(), address(oracle));
    }

    function test_roles() public view {
        assertTrue(
            feeDistributor.hasRole(
                feeDistributor.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertTrue(
            feeDistributor.getRoleMemberCount(
                feeDistributor.DEFAULT_ADMIN_ROLE()
            ) == adminsCount
        );
        assertEq(
            feeDistributor.getRoleMemberCount(feeDistributor.RECOVERER_ROLE()),
            0
        );
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(
            payable(address(feeDistributor))
        );
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSFeeDistributor distributorImpl = CSFeeDistributor(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        distributorImpl.initialize({ admin: deployParams.aragonAgent });
    }
}

contract CSStrikesDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public view {
        assertEq(address(strikes.ORACLE()), address(oracle));
        assertEq(address(strikes.EJECTOR()), address(ejector));
    }
}

contract CSFeeOracleDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public view {
        assertEq(oracle.SECONDS_PER_SLOT(), deployParams.secondsPerSlot);
        assertEq(oracle.GENESIS_TIME(), deployParams.clGenesisTime);
    }

    function test_initializer() public view {
        assertEq(address(oracle.feeDistributor()), address(feeDistributor));
        assertEq(address(oracle.strikes()), address(strikes));
        assertEq(oracle.getContractVersion(), 2);
        assertEq(oracle.getConsensusContract(), address(hashConsensus));
        assertEq(oracle.getConsensusVersion(), deployParams.consensusVersion);
        assertEq(oracle.getLastProcessingRefSlot(), 0);
    }

    function test_roles() public view {
        assertTrue(
            oracle.hasRole(
                oracle.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );
        assertTrue(oracle.hasRole(oracle.PAUSE_ROLE(), address(gateSeal)));
        assertEq(oracle.getRoleMemberCount(oracle.PAUSE_ROLE()), 1);
        assertEq(oracle.getRoleMemberCount(oracle.RESUME_ROLE()), 0);
        assertEq(oracle.getRoleMemberCount(oracle.SUBMIT_DATA_ROLE()), 0);
        assertEq(oracle.getRoleMemberCount(oracle.RECOVERER_ROLE()), 0);
        assertEq(
            oracle.getRoleMemberCount(oracle.MANAGE_CONSENSUS_CONTRACT_ROLE()),
            0
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.MANAGE_CONSENSUS_VERSION_ROLE()),
            0
        );
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(payable(address(oracle)));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSFeeOracle oracleImpl = CSFeeOracle(proxy.proxy__getImplementation());
        vm.expectRevert(Versioned.NonZeroContractVersionOnInit.selector);
        oracleImpl.initialize({
            admin: address(deployParams.aragonAgent),
            feeDistributorContract: address(feeDistributor),
            strikesContract: address(strikes),
            consensusContract: address(hashConsensus),
            consensusVersion: deployParams.consensusVersion
        });
    }
}

contract HashConsensusDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public view {
        (
            uint256 slotsPerEpoch,
            uint256 secondsPerSlot,
            uint256 genesisTime
        ) = hashConsensus.getChainConfig();
        assertEq(slotsPerEpoch, deployParams.slotsPerEpoch);
        assertEq(secondsPerSlot, deployParams.secondsPerSlot);
        assertEq(genesisTime, deployParams.clGenesisTime);

        (, uint256 epochsPerFrame, uint256 fastLaneLengthSlots) = hashConsensus
            .getFrameConfig();
        assertEq(epochsPerFrame, deployParams.oracleReportEpochsPerFrame);
        assertEq(fastLaneLengthSlots, deployParams.fastLaneLengthSlots);
        assertEq(hashConsensus.getReportProcessor(), address(oracle));
    }

    function test_roles() public view {
        assertTrue(
            hashConsensus.hasRole(
                hashConsensus.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.DEFAULT_ADMIN_ROLE()
            ),
            adminsCount
        );

        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.DISABLE_CONSENSUS_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_FRAME_CONFIG_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_FAST_LANE_CONFIG_ROLE()
            ),
            0
        );
        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_REPORT_PROCESSOR_ROLE()
            ),
            0
        );
    }
}

contract VettedGateDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_constructor() public view {
        assertTrue(
            vettedGate.hasRole(
                vettedGate.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(vettedGate.treeRoot(), deployParams.vettedGateTreeRoot);
        assertEq(
            accounting.getCurveInfo(vettedGate.curveId()).points,
            deployParams.vettedGateBondCurve
        );
        assertEq(address(vettedGate.CSM()), address(csm));
        assertEq(address(vettedGate.ACCOUNTING()), address(accounting));
        assertTrue(
            vettedGate.hasRole(vettedGate.PAUSE_ROLE(), address(gateSeal))
        );
        assertEq(vettedGate.getRoleMemberCount(vettedGate.PAUSE_ROLE()), 1);
        assertEq(vettedGate.getRoleMemberCount(vettedGate.RESUME_ROLE()), 0);
    }
}

contract CSVerifierDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_constructor() public view {
        assertEq(verifier.WITHDRAWAL_ADDRESS(), locator.withdrawalVault());
        assertEq(address(verifier.MODULE()), address(csm));
        assertEq(verifier.SLOTS_PER_EPOCH(), deployParams.slotsPerEpoch);
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES_PREV()),
            GIndex.unwrap(deployParams.gIHistoricalSummaries)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES_CURR()),
            GIndex.unwrap(deployParams.gIHistoricalSummaries)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL_PREV()),
            GIndex.unwrap(deployParams.gIFirstWithdrawal)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL_CURR()),
            GIndex.unwrap(deployParams.gIFirstWithdrawal)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR_PREV()),
            GIndex.unwrap(deployParams.gIFirstValidator)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR_CURR()),
            GIndex.unwrap(deployParams.gIFirstValidator)
        );
        assertEq(
            Slot.unwrap(verifier.FIRST_SUPPORTED_SLOT()),
            deployParams.verifierSupportedEpoch * deployParams.slotsPerEpoch
        );
        assertEq(
            Slot.unwrap(verifier.PIVOT_SLOT()),
            deployParams.verifierSupportedEpoch * deployParams.slotsPerEpoch
        );
    }

    function test_roles() public view {
        assertTrue(verifier.hasRole(verifier.PAUSE_ROLE(), address(gateSeal)));
        assertEq(verifier.getRoleMemberCount(verifier.PAUSE_ROLE()), 1);
        assertEq(verifier.getRoleMemberCount(verifier.RESUME_ROLE()), 0);
    }
}

contract CSEjectorDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_constructor() public view {
        assertEq(address(ejector.MODULE()), address(csm));
        assertEq(address(ejector.ACCOUNTING()), address(accounting));
    }

    function test_roles() public view {
        assertTrue(ejector.hasRole(ejector.PAUSE_ROLE(), address(gateSeal)));
        assertEq(ejector.getRoleMemberCount(verifier.PAUSE_ROLE()), 1);
        assertEq(ejector.getRoleMemberCount(verifier.RESUME_ROLE()), 0);
        assertTrue(
            ejector.hasRole(
                ejector.BAD_PERFORMER_EJECTOR_ROLE(),
                address(strikes)
            )
        );
        assertEq(
            ejector.getRoleMemberCount(ejector.BAD_PERFORMER_EJECTOR_ROLE()),
            1
        );
    }

    function test_proxy() public view {
        OssifiableProxy proxy = OssifiableProxy(payable(address(ejector)));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());
    }
}
