// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../helpers/Utilities.sol";
import { DeploymentFixtures } from "../helpers/Fixtures.sol";
import { DeployParams } from "../../script/DeployBase.s.sol";
import { OssifiableProxy } from "../../src/lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { HashConsensus } from "../../src/lib/base-oracle/HashConsensus.sol";
import { CSBondCurve } from "../../src/abstract/CSBondCurve.sol";
import { CSFeeDistributor } from "../../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../../src/CSFeeOracle.sol";
import { IWithdrawalQueue } from "../../src/interfaces/IWithdrawalQueue.sol";
import { BaseOracle } from "../../src/lib/base-oracle/BaseOracle.sol";
import { GIndex } from "../../src/lib/GIndex.sol";
import { Slot } from "../../src/lib/Types.sol";
import { Versioned } from "../../src/lib/utils/Versioned.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CSModuleDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
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
        assertEq(address(csm.LIDO_LOCATOR()), deployParams.lidoLocatorAddress);
    }

    function test_initializer() public {
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(csm.earlyAdoption()), address(earlyAdoption));
        assertEq(csm.keyRemovalCharge(), deployParams.keyRemovalCharge);
        assertTrue(
            csm.hasRole(csm.STAKING_ROUTER_ROLE(), locator.stakingRouter())
        );
    }

    function test_roles() public {
        assertTrue(
            csm.hasRole(csm.DEFAULT_ADMIN_ROLE(), deployParams.votingAddress)
        );
        assertTrue(csm.hasRole(csm.PAUSE_ROLE(), address(gateSeal)));
        assertTrue(
            csm.hasRole(
                csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
                address(deployParams.elRewardsStealingReporter)
            )
        );
        assertTrue(
            csm.hasRole(
                csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
                address(deployParams.easyTrackEVMScriptExecutor)
            )
        );
        assertTrue(csm.hasRole(csm.VERIFIER_ROLE(), address(verifier)));
    }

    function test_initialState() public {
        assertTrue(csm.isPaused());
        assertFalse(csm.publicRelease());
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_proxy() public {
        OssifiableProxy proxy = OssifiableProxy(payable(address(csm)));
        assertEq(proxy.proxy__getAdmin(), address(deployParams.votingAddress));
        assertFalse(proxy.proxy__getIsOssified());

        CSModule csmImpl = CSModule(proxy.proxy__getImplementation());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        csmImpl.initialize({
            _accounting: address(accounting),
            _earlyAdoption: address(earlyAdoption),
            _keyRemovalCharge: deployParams.keyRemovalCharge,
            admin: deployParams.votingAddress
        });
    }
}

contract CSAccountingDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
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
        assertEq(accounting.chargeRecipient(), deployParams.chargeRecipient);
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
                deployParams.votingAddress
            )
        );
        assertTrue(
            accounting.hasRole(accounting.PAUSE_ROLE(), address(gateSeal))
        );
        assertTrue(
            accounting.hasRole(
                accounting.SET_BOND_CURVE_ROLE(),
                deployParams.setResetBondCurveAddress
            )
        );
        assertTrue(
            accounting.hasRole(
                accounting.RESET_BOND_CURVE_ROLE(),
                deployParams.setResetBondCurveAddress
            )
        );
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
        assertEq(proxy.proxy__getAdmin(), address(deployParams.votingAddress));
        assertFalse(proxy.proxy__getIsOssified());

        CSAccounting accountingImpl = CSAccounting(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        accountingImpl.initialize({
            bondCurve: deployParams.bondCurve,
            admin: address(deployParams.votingAddress),
            _feeDistributor: address(feeDistributor),
            bondLockRetentionPeriod: deployParams.bondLockRetentionPeriod,
            _chargeRecipient: address(0)
        });
    }
}

contract CSFeeDistributorDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
    }

    function test_constructor() public {
        assertEq(address(feeDistributor.STETH()), address(lido));
        assertEq(feeDistributor.ACCOUNTING(), address(accounting));
    }

    function test_initializer() public {
        assertEq(
            feeDistributor.getRoleMember(feeDistributor.ORACLE_ROLE(), 0),
            address(oracle)
        );
    }

    function test_roles() public {
        assertTrue(
            feeDistributor.hasRole(
                feeDistributor.DEFAULT_ADMIN_ROLE(),
                deployParams.votingAddress
            )
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
        assertEq(proxy.proxy__getAdmin(), address(deployParams.votingAddress));
        assertFalse(proxy.proxy__getIsOssified());

        CSFeeDistributor distributorImpl = CSFeeDistributor(
            proxy.proxy__getImplementation()
        );
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        distributorImpl.initialize({
            admin: deployParams.votingAddress,
            oracle: address(oracle)
        });
    }
}

contract CSFeeOracleDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
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
                deployParams.votingAddress
            )
        );
        assertTrue(oracle.hasRole(oracle.PAUSE_ROLE(), address(gateSeal)));
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
        assertEq(proxy.proxy__getAdmin(), address(deployParams.votingAddress));
        assertFalse(proxy.proxy__getIsOssified());

        CSFeeOracle oracleImpl = CSFeeOracle(proxy.proxy__getImplementation());
        vm.expectRevert(Versioned.NonZeroContractVersionOnInit.selector);
        oracleImpl.initialize({
            admin: address(deployParams.votingAddress),
            feeDistributorContract: address(feeDistributor),
            consensusContract: address(hashConsensus),
            consensusVersion: deployParams.consensusVersion,
            _avgPerfLeewayBP: deployParams.avgPerfLeewayBP
        });
    }
}

contract HashConsensusDeploymentTest is Test, Utilities, DeploymentFixtures {
    DeployParams private deployParams;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);
        deployParams = parseDeployParams(env.DEPLOY_CONFIG);
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

        (
            uint256 initialEpoch,
            uint256 epochsPerFrame,
            uint256 fastLaneLengthSlots
        ) = hashConsensus.getFrameConfig();
        assertEq(epochsPerFrame, deployParams.oracleReportEpochsPerFrame);
        assertEq(fastLaneLengthSlots, deployParams.fastLaneLengthSlots);
        assertEq(hashConsensus.getReportProcessor(), address(oracle));
    }

    function test_roles() public {
        assertTrue(
            hashConsensus.hasRole(
                hashConsensus.DEFAULT_ADMIN_ROLE(),
                deployParams.votingAddress
            )
        );
    }

    function test_initialState() public {
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
        assertEq(address(verifier.LOCATOR()), address(locator));
        assertEq(address(verifier.MODULE()), address(csm));
        assertEq(verifier.SLOTS_PER_EPOCH(), deployParams.slotsPerEpoch);
        assertEq(
            GIndex.unwrap(verifier.GI_HISTORICAL_SUMMARIES()),
            GIndex.unwrap(deployParams.gIHistoricalSummaries)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_WITHDRAWAL()),
            GIndex.unwrap(deployParams.gIFirstWithdrawal)
        );
        assertEq(
            GIndex.unwrap(verifier.GI_FIRST_VALIDATOR()),
            GIndex.unwrap(deployParams.gIFirstValidator)
        );
        assertEq(
            Slot.unwrap(verifier.FIRST_SUPPORTED_SLOT()),
            deployParams.verifierSupportedEpoch * deployParams.slotsPerEpoch
        );
    }
}
