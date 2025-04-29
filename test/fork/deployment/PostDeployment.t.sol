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
import { CSStrikes } from "../../../src/CSStrikes.sol";
import { VettedGate } from "../../../src/VettedGate.sol";
import { CSExitPenalties } from "../../../src/CSExitPenalties.sol";
import { IWithdrawalQueue } from "../../../src/interfaces/IWithdrawalQueue.sol";
import { ICSParametersRegistry } from "../../../src/interfaces/ICSParametersRegistry.sol";
import { ICSBondCurve } from "../../../src/interfaces/ICSBondCurve.sol";
import { BaseOracle } from "../../../src/lib/base-oracle/BaseOracle.sol";
import { GIndex } from "../../../src/lib/GIndex.sol";
import { Slot } from "../../../src/lib/Types.sol";
import { Versioned } from "../../../src/lib/utils/Versioned.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DeploymentBaseTest is Test, Utilities, DeploymentFixtures {
    DeployParams internal deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }
}

contract CSModuleDeploymentTest is DeploymentBaseTest {
    function test_state_scratch_onlyFull() public view {
        assertTrue(csm.isPaused());
        assertEq(csm.getNodeOperatorsCount(), 0);
        assertEq(csm.getNonce(), 0);
    }

    function test_state_afterVote() public view {
        assertFalse(csm.isPaused());
    }

    function test_state_onlyFull() public view {
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(csm.exitPenalties()), address(exitPenalties));
        assertEq(csm.getInitializedVersion(), 2);
    }

    function test_immutables() public view {
        assertEq(csmImpl.getType(), deployParams.moduleType);
        assertEq(
            address(csmImpl.LIDO_LOCATOR()),
            deployParams.lidoLocatorAddress
        );
        assertEq(
            address(csmImpl.PARAMETERS_REGISTRY()),
            address(parametersRegistry)
        );
        assertEq(address(csmImpl.STETH()), address(lido));
        assertEq(
            csmImpl.QUEUE_LOWEST_PRIORITY(),
            deployParams.queueLowestPriority
        );
        assertEq(
            csmImpl.QUEUE_LEGACY_PRIORITY(),
            deployParams.queueLowestPriority - 1
        );
    }

    function test_roles_onlyFull() public view {
        assertTrue(
            csm.hasRole(csm.DEFAULT_ADMIN_ROLE(), deployParams.aragonAgent)
        );
        assertTrue(
            csm.getRoleMemberCount(csm.DEFAULT_ADMIN_ROLE()) == adminsCount
        );

        assertTrue(
            csm.hasRole(csm.STAKING_ROUTER_ROLE(), locator.stakingRouter())
        );
        assertEq(csm.getRoleMemberCount(csm.STAKING_ROUTER_ROLE()), 1);

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

        assertEq(csm.getRoleMemberCount(csm.CREATE_NODE_OPERATOR_ROLE()), 2);
        assertTrue(
            csm.hasRole(csm.CREATE_NODE_OPERATOR_ROLE(), address(vettedGate))
        );
        assertTrue(
            csm.hasRole(
                csm.CREATE_NODE_OPERATOR_ROLE(),
                address(permissionlessGate)
            )
        );
    }

    function test_proxy_onlyFull() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        csm.initialize({
            _accounting: address(accounting),
            _exitPenalties: address(exitPenalties),
            admin: deployParams.aragonAgent
        });

        OssifiableProxy proxy = OssifiableProxy(payable(address(csm)));

        assertEq(proxy.proxy__getImplementation(), address(csmImpl));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSModule csmImpl = CSModule(proxy.proxy__getImplementation());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        csmImpl.initialize({
            _accounting: address(accounting),
            _exitPenalties: address(exitPenalties),
            admin: deployParams.aragonAgent
        });
    }
}

contract CSAccountingDeploymentTest is DeploymentBaseTest {
    function test_state_scratch_onlyFull() public view {
        assertEq(accounting.totalBondShares(), 0);
    }

    function test_state_onlyFull() public view {
        uint256 defaultCurveId = accounting.DEFAULT_BOND_CURVE_ID();
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[0].minKeysCount,
            deployParams.bondCurve[0][0]
        );
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[0].trend,
            deployParams.bondCurve[0][1]
        );
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[1].minKeysCount,
            deployParams.bondCurve[1][0]
        );
        assertEq(
            accounting.getCurveInfo(defaultCurveId)[1].trend,
            deployParams.bondCurve[1][1]
        );

        uint256 vettedCurveId = vettedGate.curveId();
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[0].minKeysCount,
            deployParams.vettedGateBondCurve[0][0]
        );
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[0].trend,
            deployParams.vettedGateBondCurve[0][1]
        );
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[1].minKeysCount,
            deployParams.vettedGateBondCurve[1][0]
        );
        assertEq(
            accounting.getCurveInfo(vettedCurveId)[1].trend,
            deployParams.vettedGateBondCurve[1][1]
        );
        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
        assertEq(accounting.getBondLockPeriod(), deployParams.bondLockPeriod);

        assertEq(
            accounting.chargePenaltyRecipient(),
            deployParams.chargePenaltyRecipient
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
        assertEq(accounting.getInitializedVersion(), 2);
    }

    function test_state() public view {
        assertFalse(accounting.isPaused());
    }

    function test_immutables() public view {
        assertEq(address(accountingImpl.MODULE()), address(csm));
        assertEq(address(accountingImpl.LIDO_LOCATOR()), address(locator));
        assertEq(address(accountingImpl.LIDO()), locator.lido());
        assertEq(
            address(accountingImpl.WITHDRAWAL_QUEUE()),
            locator.withdrawalQueue()
        );
        assertEq(
            address(accountingImpl.WSTETH()),
            IWithdrawalQueue(locator.withdrawalQueue()).WSTETH()
        );

        assertEq(
            accountingImpl.MIN_BOND_LOCK_PERIOD(),
            deployParams.minBondLockPeriod
        );
        assertEq(
            accountingImpl.MAX_BOND_LOCK_PERIOD(),
            deployParams.maxBondLockPeriod
        );
        assertEq(
            accountingImpl.MAX_CURVE_LENGTH(),
            deployParams.maxCurveLength
        );
    }

    function test_roles_onlyFull() public view {
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

        assertEq(accounting.getRoleMemberCount(accounting.RESUME_ROLE()), 0);

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
        assertEq(
            accounting.getRoleMemberCount(accounting.SET_BOND_CURVE_ROLE()),
            2
        );

        assertEq(
            accounting.getRoleMemberCount(keccak256("RESET_BOND_CURVE_ROLE")),
            0
        );

        assertEq(
            accounting.getRoleMemberCount(accounting.MANAGE_BOND_CURVES_ROLE()),
            0
        );

        assertEq(accounting.getRoleMemberCount(accounting.RECOVERER_ROLE()), 0);
    }

    function test_proxy_onlyFull() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        accounting.initialize({
            bondCurve: deployParams.bondCurve,
            admin: address(deployParams.aragonAgent),
            _feeDistributor: address(feeDistributor),
            bondLockPeriod: deployParams.bondLockPeriod,
            _chargePenaltyRecipient: address(0)
        });

        OssifiableProxy proxy = OssifiableProxy(payable(address(accounting)));

        assertEq(proxy.proxy__getImplementation(), address(accountingImpl));
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

contract CSFeeDistributorDeploymentTest is DeploymentBaseTest {
    function test_state_scratch_onlyFull() public view {
        assertEq(feeDistributor.totalClaimableShares(), 0);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(
            keccak256(abi.encodePacked(feeDistributor.treeCid())),
            keccak256("")
        );
    }

    function test_state_onlyFull() public view {
        assertEq(feeDistributor.getInitializedVersion(), 2);
        assertEq(feeDistributor.rebateRecipient(), deployParams.aragonAgent);
    }

    function test_immutables() public view {
        assertEq(address(feeDistributorImpl.STETH()), address(lido));
        assertEq(feeDistributorImpl.ACCOUNTING(), address(accounting));
        assertEq(feeDistributorImpl.ORACLE(), address(oracle));
    }

    function test_roles_onlyFull() public view {
        assertTrue(
            feeDistributor.hasRole(
                feeDistributor.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            feeDistributor.getRoleMemberCount(
                feeDistributor.DEFAULT_ADMIN_ROLE()
            ),
            adminsCount
        );

        assertEq(
            feeDistributor.getRoleMemberCount(feeDistributor.RECOVERER_ROLE()),
            0
        );
    }

    function test_proxy_onlyFull() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        feeDistributor.initialize({
            admin: deployParams.aragonAgent,
            _rebateRecipient: deployParams.aragonAgent
        });

        OssifiableProxy proxy = OssifiableProxy(
            payable(address(feeDistributor))
        );

        assertEq(proxy.proxy__getImplementation(), address(feeDistributorImpl));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSFeeDistributor distributorImpl = CSFeeDistributor(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        distributorImpl.initialize({
            admin: deployParams.aragonAgent,
            _rebateRecipient: deployParams.aragonAgent
        });
    }
}

contract CSFeeOracleDeploymentTest is DeploymentBaseTest {
    function test_state_scratch_onlyFull() public view {
        (
            bytes32 hash,
            uint256 refSlot,
            uint256 processingDeadlineTime,
            bool processingStarted
        ) = oracle.getConsensusReport();
        assertEq(hash, bytes32(0));
        assertEq(refSlot, 0);
        assertEq(processingDeadlineTime, 0);
        assertFalse(processingStarted);
        assertEq(oracle.getLastProcessingRefSlot(), 0);
    }

    function test_state_onlyFull() public view {
        assertFalse(oracle.isPaused());
        assertEq(address(oracle.feeDistributor()), address(feeDistributor));
        assertEq(address(oracle.strikes()), address(strikes));
        assertEq(oracle.getContractVersion(), 2);
        assertEq(oracle.getConsensusContract(), address(hashConsensus));
        assertEq(oracle.getConsensusVersion(), deployParams.consensusVersion);
    }

    function test_immutables() public view {
        assertEq(oracleImpl.SECONDS_PER_SLOT(), deployParams.secondsPerSlot);
        assertEq(oracleImpl.GENESIS_TIME(), deployParams.clGenesisTime);
    }

    function test_roles_onlyFull() public view {
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

    function test_proxy_onlyFull() public {
        vm.expectRevert(Versioned.NonZeroContractVersionOnInit.selector);
        oracle.initialize({
            admin: address(deployParams.aragonAgent),
            feeDistributorContract: address(feeDistributor),
            strikesContract: address(strikes),
            consensusContract: address(hashConsensus),
            consensusVersion: deployParams.consensusVersion
        });

        OssifiableProxy proxy = OssifiableProxy(payable(address(oracle)));

        assertEq(proxy.proxy__getImplementation(), address(oracleImpl));
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

contract HashConsensusDeploymentTest is DeploymentBaseTest {
    function test_state() public view {
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
        assertEq(hashConsensus.getQuorum(), deployParams.hashConsensusQuorum);
        (address[] memory members, ) = hashConsensus.getMembers();
        assertEq(
            keccak256(abi.encode(members)),
            keccak256(abi.encode(deployParams.oracleMembers))
        );

        // For test purposes AO and CSM Oracle members might be different on Hoodi testnet (cainId = 560048)
        if (block.chainid != 560048) {
            (address[] memory membersAo, ) = HashConsensus(
                BaseOracle(locator.accountingOracle()).getConsensusContract()
            ).getMembers();
            assertEq(
                keccak256(abi.encode(membersAo)),
                keccak256(abi.encode(members))
            );
        }
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
                hashConsensus.DISABLE_CONSENSUS_ROLE()
            ),
            0
        );

        assertEq(
            hashConsensus.getRoleMemberCount(
                hashConsensus.MANAGE_REPORT_PROCESSOR_ROLE()
            ),
            0
        );

        // Roles on Hoodi are custom
        if (block.chainid != 560048) {
            assertTrue(
                hashConsensus.hasRole(
                    hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE(),
                    deployParams.aragonAgent
                )
            );
            assertEq(
                hashConsensus.getRoleMemberCount(
                    hashConsensus.MANAGE_MEMBERS_AND_QUORUM_ROLE()
                ),
                1
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
        }
    }
}

contract CSVerifierDeploymentTest is DeploymentBaseTest {
    function test_state() public view {
        assertFalse(verifier.isPaused());
    }

    function test_immutables() public view {
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
        assertTrue(
            verifier.hasRole(
                verifier.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            verifier.getRoleMemberCount(verifier.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );

        assertTrue(verifier.hasRole(verifier.PAUSE_ROLE(), address(gateSeal)));
        assertEq(verifier.getRoleMemberCount(verifier.PAUSE_ROLE()), 1);

        assertEq(verifier.getRoleMemberCount(verifier.RESUME_ROLE()), 0);
    }
}

contract CSParametersRegistryDeploymentTest is DeploymentBaseTest {
    function test_immutables() public view {
        assertEq(
            parametersRegistryImpl.QUEUE_LOWEST_PRIORITY(),
            deployParams.queueLowestPriority
        );
        assertEq(
            parametersRegistryImpl.QUEUE_LEGACY_PRIORITY(),
            deployParams.queueLowestPriority - 1
        );
    }

    function test_state() public view {
        assertEq(
            parametersRegistry.defaultKeyRemovalCharge(),
            deployParams.keyRemovalCharge
        );
        assertEq(
            parametersRegistry.defaultElRewardsStealingAdditionalFine(),
            deployParams.elRewardsStealingAdditionalFine
        );
        assertEq(parametersRegistry.defaultKeysLimit(), deployParams.keysLimit);
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
        assertEq(
            parametersRegistry.defaultAllowedExitDelay(),
            deployParams.defaultAllowedExitDelay
        );
        assertEq(
            parametersRegistry.defaultExitDelayPenalty(),
            deployParams.defaultExitDelayPenalty
        );
        assertEq(
            parametersRegistry.defaultMaxWithdrawalRequestFee(),
            deployParams.defaultMaxWithdrawalRequestFee
        );
        assertEq(parametersRegistry.getInitializedVersion(), 1);
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
            adminsCount
        );
    }

    function test_proxy() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        parametersRegistry.initialize({
            admin: deployParams.aragonAgent,
            data: ICSParametersRegistry.InitializationData({
                keyRemovalCharge: deployParams.keyRemovalCharge,
                elRewardsStealingAdditionalFine: deployParams
                    .elRewardsStealingAdditionalFine,
                keysLimit: deployParams.keysLimit,
                rewardShare: deployParams.rewardShareBP,
                performanceLeeway: deployParams.avgPerfLeewayBP,
                strikesLifetime: deployParams.strikesLifetimeFrames,
                strikesThreshold: deployParams.strikesThreshold,
                defaultQueuePriority: deployParams.defaultQueuePriority,
                defaultQueueMaxDeposits: deployParams.defaultQueueMaxDeposits,
                badPerformancePenalty: deployParams.badPerformancePenalty,
                attestationsWeight: deployParams.attestationsWeight,
                blocksWeight: deployParams.blocksWeight,
                syncWeight: deployParams.syncWeight,
                defaultAllowedExitDelay: deployParams.defaultAllowedExitDelay,
                defaultExitDelayPenalty: deployParams.defaultExitDelayPenalty,
                defaultMaxWithdrawalRequestFee: deployParams
                    .defaultMaxWithdrawalRequestFee
            })
        });

        OssifiableProxy proxy = OssifiableProxy(
            payable(address(parametersRegistry))
        );

        assertEq(
            proxy.proxy__getImplementation(),
            address(parametersRegistryImpl)
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
                keysLimit: deployParams.keysLimit,
                rewardShare: deployParams.rewardShareBP,
                performanceLeeway: deployParams.avgPerfLeewayBP,
                strikesLifetime: deployParams.strikesLifetimeFrames,
                strikesThreshold: deployParams.strikesThreshold,
                defaultQueuePriority: deployParams.defaultQueuePriority,
                defaultQueueMaxDeposits: deployParams.defaultQueueMaxDeposits,
                badPerformancePenalty: deployParams.badPerformancePenalty,
                attestationsWeight: deployParams.attestationsWeight,
                blocksWeight: deployParams.blocksWeight,
                syncWeight: deployParams.syncWeight,
                defaultAllowedExitDelay: deployParams.defaultAllowedExitDelay,
                defaultExitDelayPenalty: deployParams.defaultExitDelayPenalty,
                defaultMaxWithdrawalRequestFee: deployParams
                    .defaultMaxWithdrawalRequestFee
            })
        });
    }
}

contract CSStrikesDeploymentTest is DeploymentBaseTest {
    function test_state_scratch() public view {
        assertEq(strikes.treeRoot(), bytes32(0));
        assertEq(keccak256(abi.encodePacked(strikes.treeCid())), keccak256(""));
    }

    function test_state() public view {
        assertEq(address(strikes.ejector()), address(ejector));
        assertEq(strikes.getInitializedVersion(), 1);
    }

    function test_immutables() public view {
        assertEq(address(strikesImpl.MODULE()), address(csm));
        assertEq(address(strikesImpl.ACCOUNTING()), address(accounting));
        assertEq(address(strikesImpl.ORACLE()), address(oracle));
        assertEq(address(strikesImpl.EXIT_PENALTIES()), address(exitPenalties));
    }

    function test_roles() public view {
        assertTrue(
            strikes.hasRole(
                strikes.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            strikes.getRoleMemberCount(strikes.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );
    }

    function test_proxy() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        strikes.initialize({
            admin: deployParams.aragonAgent,
            _ejector: address(ejector)
        });

        OssifiableProxy proxy = OssifiableProxy(payable(address(strikes)));

        assertEq(proxy.proxy__getImplementation(), address(strikesImpl));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSStrikes strikesImpl = CSStrikes(proxy.proxy__getImplementation());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        strikesImpl.initialize({
            admin: deployParams.aragonAgent,
            _ejector: address(ejector)
        });
    }
}

contract VettedGateDeploymentTest is DeploymentBaseTest {
    function test_state_scratch() public view {
        assertFalse(vettedGate.isReferralProgramSeasonActive());
        assertEq(vettedGate.referralProgramSeasonNumber(), 0);
        assertEq(vettedGate.referralCurveId(), 0);
        assertEq(vettedGate.referralsThreshold(), 0);
    }

    function test_state() public view {
        assertFalse(vettedGate.isPaused());
        assertEq(vettedGate.treeRoot(), deployParams.vettedGateTreeRoot);
        assertEq(vettedGate.treeCid(), deployParams.vettedGateTreeCid);
        uint256 curveId = vettedGate.curveId();
        // Check that the curve is set
        assertTrue(vettedGate.curveId() != 0);
        assertEq(vettedGate.getInitializedVersion(), 1);
    }

    function test_immutables() public view {
        assertEq(address(vettedGateImpl.MODULE()), address(csm));
        assertEq(address(vettedGateImpl.ACCOUNTING()), address(accounting));
    }

    function test_roles() public view {
        assertTrue(
            vettedGate.hasRole(
                vettedGate.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );

        assertTrue(
            vettedGate.hasRole(vettedGate.PAUSE_ROLE(), address(gateSeal))
        );
        assertEq(vettedGate.getRoleMemberCount(vettedGate.PAUSE_ROLE()), 1);

        assertEq(vettedGate.getRoleMemberCount(vettedGate.RESUME_ROLE()), 0);

        assertTrue(
            vettedGate.hasRole(
                vettedGate.SET_TREE_ROLE(),
                deployParams.vettedGateManager
            )
        );
        assertEq(vettedGate.getRoleMemberCount(vettedGate.SET_TREE_ROLE()), 1);

        assertTrue(
            vettedGate.hasRole(
                vettedGate.START_REFERRAL_SEASON_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            vettedGate.getRoleMemberCount(
                vettedGate.START_REFERRAL_SEASON_ROLE()
            ),
            1
        );

        assertTrue(
            vettedGate.hasRole(
                vettedGate.END_REFERRAL_SEASON_ROLE(),
                deployParams.vettedGateManager
            )
        );
        assertEq(
            vettedGate.getRoleMemberCount(
                vettedGate.END_REFERRAL_SEASON_ROLE()
            ),
            1
        );
    }

    function test_proxy() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vettedGate.initialize({
            _curveId: 1,
            _treeRoot: deployParams.vettedGateTreeRoot,
            _treeCid: deployParams.vettedGateTreeCid,
            admin: deployParams.aragonAgent
        });

        OssifiableProxy proxy = OssifiableProxy(payable(address(vettedGate)));

        assertEq(proxy.proxy__getImplementation(), address(vettedGateImpl));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        VettedGate vettedGateImpl = VettedGate(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vettedGateImpl.initialize({
            _curveId: 1,
            _treeRoot: deployParams.vettedGateTreeRoot,
            _treeCid: deployParams.vettedGateTreeCid,
            admin: deployParams.aragonAgent
        });
    }
}

contract CSEjectorDeploymentTest is DeploymentBaseTest {
    function test_state() public view {
        assertFalse(ejector.isPaused());
        assertEq(address(ejector.strikes()), address(strikes));
    }

    function test_immutables() public view {
        assertEq(address(ejector.MODULE()), address(csm));
        assertEq(address(ejector.VEB()), locator.validatorsExitBusOracle());
        assertEq(ejector.STAKING_MODULE_ID(), deployParams.stakingModuleId);
    }

    function test_roles() public view {
        assertTrue(
            ejector.hasRole(
                ejector.DEFAULT_ADMIN_ROLE(),
                deployParams.aragonAgent
            )
        );
        assertEq(
            ejector.getRoleMemberCount(ejector.DEFAULT_ADMIN_ROLE()),
            adminsCount
        );
        assertTrue(ejector.hasRole(ejector.PAUSE_ROLE(), address(gateSeal)));
        assertEq(ejector.getRoleMemberCount(verifier.PAUSE_ROLE()), 1);
        assertEq(ejector.getRoleMemberCount(verifier.RESUME_ROLE()), 0);
    }
}

contract CSExitPenaltiesDeploymentTest is DeploymentBaseTest {
    function test_state() public view {
        assertEq(address(exitPenalties.strikes()), address(strikes));
        assertEq(exitPenalties.getInitializedVersion(), 1);
    }

    function test_immutables() public view {
        assertEq(address(exitPenaltiesImpl.MODULE()), address(csm));
        assertEq(
            address(exitPenaltiesImpl.PARAMETERS_REGISTRY()),
            address(parametersRegistry)
        );
        assertEq(address(exitPenaltiesImpl.ACCOUNTING()), address(accounting));
    }

    function test_proxy() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        exitPenalties.initialize({ _strikes: address(strikes) });

        OssifiableProxy proxy = OssifiableProxy(
            payable(address(exitPenalties))
        );

        assertEq(proxy.proxy__getImplementation(), address(exitPenaltiesImpl));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSExitPenalties exitPenaltiesImpl = CSExitPenalties(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        exitPenaltiesImpl.initialize({ _strikes: address(strikes) });
    }
}

contract PermissionlessGateDeploymentTest is DeploymentBaseTest {
    function test_immutables() public view {
        assertEq(address(permissionlessGate.MODULE()), address(csm));
        assertEq(
            permissionlessGate.CURVE_ID(),
            accounting.DEFAULT_BOND_CURVE_ID()
        );
    }
}
