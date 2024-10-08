// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { DeployParams } from "../../../script/DeployBase.s.sol";
import { OssifiableProxy } from "../../../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../../../src/CSModule.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { HashConsensus } from "../../../src/lib/base-oracle/HashConsensus.sol";
import { CSBondCurve } from "../../../src/abstract/CSBondCurve.sol";
import { CSFeeDistributor } from "../../../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../../../src/CSFeeOracle.sol";
import { IWithdrawalQueue } from "../../../src/interfaces/IWithdrawalQueue.sol";
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
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public {
        assertEq(csm.getType(), deployParams.moduleType);
        assertEq(
            csm.INITIAL_SLASHING_PENALTY(),
            32 ether / deployParams.minSlashingPenaltyQuotient
        );
        assertEq(
            csm.EL_REWARDS_STEALING_FINE(),
            deployParams.elRewardsStealingFine
        );
        assertEq(
            csm.MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE(),
            deployParams.maxKeysPerOperatorEA
        );
        assertEq(
            csm.MAX_KEY_REMOVAL_CHARGE(),
            deployParams.maxKeyRemovalCharge
        );
        assertEq(address(csm.LIDO_LOCATOR()), deployParams.lidoLocatorAddress);
    }

    function test_initializer() public {
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(csm.earlyAdoption()), address(earlyAdoption));
        assertEq(csm.keyRemovalCharge(), deployParams.keyRemovalCharge);
        assertTrue(
            csm.hasRole(csm.STAKING_ROUTER_ROLE(), locator.stakingRouter())
        );
        assertTrue(csm.getRoleMemberCount(csm.STAKING_ROUTER_ROLE()) == 1);
    }

    function test_roles() public {
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
        assertEq(csm.getRoleMemberCount(csm.MODULE_MANAGER_ROLE()), 0);
        assertEq(csm.getRoleMemberCount(csm.RECOVERER_ROLE()), 0);
    }

    function test_initialState() public {
        assertTrue(csm.isPaused());
        assertFalse(csm.publicRelease());
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(payable(address(csm)));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.proxyAdmin));
        assertFalse(proxy.proxy__getIsOssified());

        CSModule csmImpl = CSModule(proxy.proxy__getImplementation());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        csmImpl.initialize({
            _accounting: address(accounting),
            _earlyAdoption: address(earlyAdoption),
            _keyRemovalCharge: deployParams.keyRemovalCharge,
            admin: deployParams.aragonAgent
        });
    }
}

contract CSAccountingDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public {
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
            accounting.MIN_BOND_LOCK_RETENTION_PERIOD(),
            deployParams.minBondLockRetentionPeriod
        );
        assertEq(
            accounting.MAX_BOND_LOCK_RETENTION_PERIOD(),
            deployParams.maxBondLockRetentionPeriod
        );
        assertEq(accounting.MAX_CURVE_LENGTH(), deployParams.maxCurveLength);
    }

    function test_initializer() public {
        assertEq(
            accounting.getCurveInfo(accounting.DEFAULT_BOND_CURVE_ID()).points,
            deployParams.bondCurve
        );
        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
        assertEq(
            accounting.getBondLockRetentionPeriod(),
            deployParams.bondLockRetentionPeriod
        );
        assertEq(
            accounting.chargePenaltyRecipient(),
            deployParams.chargePenaltyRecipient
        );
        assertTrue(
            accounting.hasRole(accounting.SET_BOND_CURVE_ROLE(), address(csm))
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

    function test_roles() public {
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
                deployParams.setResetBondCurveAddress
            )
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.SET_BOND_CURVE_ROLE()),
            2
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
            accounting.getRoleMemberCount(accounting.ACCOUNTING_MANAGER_ROLE()),
            0
        );
        assertEq(
            accounting.getRoleMemberCount(accounting.MANAGE_BOND_CURVES_ROLE()),
            0
        );
        assertEq(accounting.getRoleMemberCount(accounting.RECOVERER_ROLE()), 0);
    }

    function test_initialState() public {
        assertFalse(accounting.isPaused());
        assertEq(accounting.totalBondShares(), 0);
        assertEq(
            accounting.getCurveInfo(earlyAdoption.CURVE_ID()).points,
            deployParams.earlyAdoptionBondCurve
        );
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
            bondLockRetentionPeriod: deployParams.bondLockRetentionPeriod,
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
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public {
        assertEq(address(feeDistributor.STETH()), address(lido));
        assertEq(feeDistributor.ACCOUNTING(), address(accounting));
        assertEq(feeDistributor.ORACLE(), address(oracle));
    }

    function test_roles() public {
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

    function test_initialState() public {
        assertEq(feeDistributor.totalClaimableShares(), 0);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(
            keccak256(abi.encodePacked(feeDistributor.treeCid())),
            keccak256("")
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

contract CSFeeOracleDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public {
        assertEq(oracle.SECONDS_PER_SLOT(), deployParams.secondsPerSlot);
        assertEq(oracle.GENESIS_TIME(), deployParams.clGenesisTime);
    }

    function test_initializer() public {
        assertEq(address(oracle.feeDistributor()), address(feeDistributor));
        assertEq(oracle.getContractVersion(), 1);
        assertEq(oracle.getConsensusContract(), address(hashConsensus));
        assertEq(oracle.getConsensusVersion(), deployParams.consensusVersion);
        assertEq(oracle.getLastProcessingRefSlot(), 0);
        assertEq(oracle.avgPerfLeewayBP(), deployParams.avgPerfLeewayBP);
    }

    function test_roles() public {
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
        assertEq(oracle.getRoleMemberCount(oracle.CONTRACT_MANAGER_ROLE()), 0);
        assertEq(oracle.getRoleMemberCount(oracle.SUBMIT_DATA_ROLE()), 0);
        assertEq(oracle.getRoleMemberCount(oracle.RECOVERER_ROLE()), 0);
    }

    function test_initialState() public {
        assertFalse(oracle.isPaused());

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
            consensusContract: address(hashConsensus),
            consensusVersion: deployParams.consensusVersion,
            _avgPerfLeewayBP: deployParams.avgPerfLeewayBP
        });
    }
}

contract HashConsensusDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;
    uint256 adminsCount;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_constructor() public {
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

    function test_roles() public {
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

    function test_initialState() public {
        vm.skip(block.chainid != 1);
        assertEq(hashConsensus.getQuorum(), deployParams.hashConsensusQuorum);
        (address[] memory members, ) = hashConsensus.getMembers();
        assertEq(
            keccak256(abi.encode(members)),
            keccak256(abi.encode(deployParams.oracleMembers))
        );

        (members, ) = HashConsensus(
            BaseOracle(locator.accountingOracle()).getConsensusContract()
        ).getMembers();
        assertEq(
            keccak256(abi.encode(members)),
            keccak256(abi.encode(deployParams.oracleMembers))
        );
    }
}

contract CSEarlyAdoptionDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_constructor() public {
        assertEq(earlyAdoption.TREE_ROOT(), deployParams.earlyAdoptionTreeRoot);
        assertEq(
            accounting.getCurveInfo(earlyAdoption.CURVE_ID()).points,
            deployParams.earlyAdoptionBondCurve
        );
        assertEq(earlyAdoption.MODULE(), address(csm));
    }
}

contract CSVerifierDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_constructor() public {
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
}
