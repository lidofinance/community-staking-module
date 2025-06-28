// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { NodeOperatorManagementProperties } from "../../../src/interfaces/ICSModule.sol";
import { CSModule } from "../../../src/CSModule.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { IWstETH } from "../../../src/interfaces/IWstETH.sol";
import { ILido } from "../../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../../src/interfaces/ILidoLocator.sol";
import { IWithdrawalQueue } from "../../../src/interfaces/IWithdrawalQueue.sol";
import { IBurner } from "../../../src/interfaces/IBurner.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";
import { Utilities } from "../../helpers/Utilities.sol";
import { PermitHelper } from "../../helpers/Permit.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { InvariantAsserts } from "../../helpers/InvariantAsserts.sol";

contract PenaltyIntegrationTest is
    Test,
    Utilities,
    PermitHelper,
    DeploymentFixtures,
    InvariantAsserts
{
    address internal user;
    address internal stranger;
    address internal nodeOperator;
    uint256 internal defaultNoId;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertCSMKeys(csm);
        assertCSMEnqueuedCount(csm);
        assertCSMUnusedStorageSlots(csm);
        assertAccountingTotalBondShares(noCount, lido, accounting);
        assertAccountingBurnerApproval(
            lido,
            address(accounting),
            locator.burner()
        );
        assertAccountingUnusedStorageSlots(accounting);
        assertFeeDistributorClaimableShares(lido, feeDistributor);
        assertFeeDistributorTree(feeDistributor);
        assertFeeOracleUnusedStorageSlots(oracle);
        vm.resumeGasMetering();
    }

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
        csm.grantRole(
            csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        csm.grantRole(
            csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        vm.stopPrank();

        handleStakingLimit();
        handleBunkerMode();

        user = nextAddress("User");
        stranger = nextAddress("stranger");
        nodeOperator = nextAddress("NodeOperator");

        uint256 keysCount = 5;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
        vm.deal(nodeOperator, amount);

        vm.prank(nodeOperator);
        defaultNoId = permissionlessGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });
    }

    function test_elRewardsStealingPenalty() public assertInvariants {
        uint256 amount = 1 ether;

        uint256 amountShares = lido.getSharesByPooledEth(amount);

        (uint256 bondBefore, ) = accounting.getBondSummaryShares(defaultNoId);

        csm.reportELRewardsStealingPenalty(
            defaultNoId,
            blockhash(block.number),
            amount -
                csm.PARAMETERS_REGISTRY().getElRewardsStealingAdditionalFine(
                    accounting.getBondCurveId(defaultNoId)
                )
        );

        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = defaultNoId;

        csm.settleELRewardsStealingPenalty(idsToSettle);

        (uint256 bondAfter, ) = accounting.getBondSummaryShares(defaultNoId);

        assertEq(bondAfter, bondBefore - amountShares);
    }
}
