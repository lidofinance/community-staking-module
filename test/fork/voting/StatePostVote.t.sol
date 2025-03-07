// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { DeployParams, DeployParamsV1 } from "../../../script/DeployBase.s.sol";
import { HashConsensus } from "../../../src/lib/base-oracle/HashConsensus.sol";
import { BaseOracle } from "../../../src/lib/base-oracle/BaseOracle.sol";
import { Slot } from "../../../src/lib/Types.sol";

contract ContractsStateTest is Test, Utilities, DeploymentFixtures {
    DeployParamsV1 private deployParams;
    DeployParams private upgradeDeployParams;
    uint256 adminsCount;

    error UpdateConfigRequired();

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParamsV1(env.DEPLOY_CONFIG);
        if (_isEmpty(env.UPGRADE_CONFIG)) {
            revert UpdateConfigRequired();
        }
        upgradeDeployParams = parseDeployParams(env.UPGRADE_CONFIG);
        adminsCount = block.chainid == 1 ? 1 : 2;
    }

    function test_moduleState() public view {
        assertFalse(csm.isPaused());
        assertFalse(
            csm.depositQueueItem(csm.QUEUE_LEGACY_PRIORITY(), 0).isNil()
        );
    }

    function test_moduleRoles() public view {
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

    function test_parametersRegistryState() public view {
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

        assertEq(
            parametersRegistry.defaultKeyRemovalCharge(),
            upgradeDeployParams.keyRemovalCharge
        );
        assertEq(
            parametersRegistry.defaultElRewardsStealingAdditionalFine(),
            upgradeDeployParams.elRewardsStealingAdditionalFine
        );
        assertEq(
            parametersRegistry.defaultKeysLimit(),
            upgradeDeployParams.keysLimit
        );
        assertEq(
            parametersRegistry.defaultRewardShare(),
            upgradeDeployParams.rewardShareBP
        );
        assertEq(
            parametersRegistry.defaultPerformanceLeeway(),
            upgradeDeployParams.avgPerfLeewayBP
        );
        (uint256 strikesLifetime, uint256 strikesThreshold) = parametersRegistry
            .defaultStrikesParams();
        assertEq(strikesLifetime, upgradeDeployParams.strikesLifetimeFrames);
        assertEq(strikesThreshold, upgradeDeployParams.strikesThreshold);

        (uint256 priority, uint256 maxDeposits) = parametersRegistry
            .defaultQueueConfig();
        assertEq(priority, upgradeDeployParams.defaultQueuePriority);
        assertEq(maxDeposits, upgradeDeployParams.defaultQueueMaxDeposits);

        assertEq(
            parametersRegistry.defaultBadPerformancePenalty(),
            upgradeDeployParams.badPerformancePenalty
        );

        (
            uint256 attestationsWeight,
            uint256 blocksWeight,
            uint256 syncWeight
        ) = parametersRegistry.defaultPerformanceCoefficients();
        assertEq(attestationsWeight, upgradeDeployParams.attestationsWeight);
        assertEq(blocksWeight, upgradeDeployParams.blocksWeight);
        assertEq(syncWeight, upgradeDeployParams.syncWeight);
    }

    function test_accountingState() public view {
        assertFalse(accounting.isPaused());
        assertEq(
            accounting.getCurveInfo(vettedGate.curveId()).points,
            deployParams.vettedGateBondCurve
        );
        assertTrue(
            burner.hasRole(
                burner.REQUEST_BURN_MY_STETH_ROLE(),
                address(accounting)
            )
        );
    }

    function test_accountingRoles() public view {
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

    function test_feeDistributorState() public {
        // The conditions below are true just after the vote, but can be broken afterward.
        vm.skip(true);

        assertEq(feeDistributor.totalClaimableShares(), 0);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(
            keccak256(abi.encodePacked(feeDistributor.treeCid())),
            keccak256("")
        );
    }

    function test_strikesState() public view {
        assertEq(strikes.treeRoot(), bytes32(0));
        assertEq(keccak256(abi.encodePacked(strikes.treeCid())), keccak256(""));
    }

    function test_feeDistributor_roles() public view {
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

    function test_feeOracle_state() public view {
        // NOTE: It assumes the first report has been settled.
        assertFalse(oracle.isPaused());
        (
            bytes32 hash,
            uint256 refSlot,
            uint256 processingDeadlineTime,

        ) = oracle.getConsensusReport();
        assertFalse(hash == bytes32(0), "expected report hash to be non-zero");
        assertGt(refSlot, 0);
        assertGt(processingDeadlineTime, 0);
        assertEq(oracle.getConsensusVersion(), 3);
        assertEq(oracle.getContractVersion(), 2);
        assertEq(address(oracle.strikes()), address(strikes));
    }

    function test_feeOracle_roles() public view {
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

    function test_hashConsensus_state() public {
        vm.skip(block.chainid != 1);
        assertEq(hashConsensus.getQuorum(), deployParams.hashConsensusQuorum);

        (address[] memory membersAO, ) = HashConsensus(
            BaseOracle(locator.accountingOracle()).getConsensusContract()
        ).getMembers();
        (address[] memory membersCSM, ) = hashConsensus.getMembers();
        assertEq(
            keccak256(abi.encode(membersAO)),
            keccak256(abi.encode(membersCSM))
        );
    }

    function test_hashConsensus_roles() public view {
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

    function test_verifier_roles() public view {
        assertTrue(verifier.hasRole(verifier.PAUSE_ROLE(), address(gateSeal)));
        assertEq(verifier.getRoleMemberCount(verifier.PAUSE_ROLE()), 1);
        assertEq(verifier.getRoleMemberCount(verifier.RESUME_ROLE()), 0);
    }

    function test_ejector_roles() public view {
        assertTrue(ejector.hasRole(ejector.PAUSE_ROLE(), address(gateSeal)));
        assertEq(ejector.getRoleMemberCount(ejector.PAUSE_ROLE()), 1);
        assertEq(ejector.getRoleMemberCount(ejector.RESUME_ROLE()), 0);
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
}
