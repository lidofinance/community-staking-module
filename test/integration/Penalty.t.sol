// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IWithdrawalQueue } from "../../src/interfaces/IWithdrawalQueue.sol";
import { IBurner } from "../../src/interfaces/IBurner.sol";
import { ICSAccounting } from "../../src/interfaces/ICSAccounting.sol";
import { Utilities } from "../helpers/Utilities.sol";
import { PermitHelper } from "../helpers/Permit.sol";
import { DeploymentFixtures } from "../helpers/Fixtures.sol";

contract PenaltyIntegrationTest is
    Test,
    Utilities,
    PermitHelper,
    DeploymentFixtures
{
    address internal user;
    address internal stranger;
    address internal nodeOperator;
    uint256 internal defaultNoId;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(
            csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        csm.grantRole(
            csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
            address(this)
        );
        vm.stopPrank();
        csm.resume();

        user = nextAddress("User");
        stranger = nextAddress("stranger");
        nodeOperator = nextAddress("NodeOperator");

        uint256 keysCount = 5;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount);
        vm.deal(nodeOperator, amount);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: amount }(
            keysCount,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );
        defaultNoId = csm.getNodeOperatorsCount() - 1;

        // grant role if testing against non-connected CSM
        if (env.MODULE_ID == 0) {
            IBurner burner = IBurner(locator.burner());
            vm.startPrank(burner.getRoleMember(burner.DEFAULT_ADMIN_ROLE(), 0));
            burner.grantRole(
                burner.REQUEST_BURN_SHARES_ROLE(),
                address(accounting)
            );
            vm.stopPrank();
        }
    }

    function test_penalty() public {
        uint256 sharesBefore = lido.sharesOf(nodeOperator);

        uint256 amount = 1 ether;

        (uint256 bondBefore, ) = accounting.getBondSummary(defaultNoId);

        csm.reportELRewardsStealingPenalty(
            defaultNoId,
            blockhash(block.number),
            amount - csm.EL_REWARDS_STEALING_FINE()
        );

        uint256[] memory idsToSettle = new uint256[](1);
        idsToSettle[0] = defaultNoId;

        csm.settleELRewardsStealingPenalty(idsToSettle);

        (uint256 bondAfter, ) = accounting.getBondSummary(defaultNoId);

        assertEq(bondAfter, bondBefore - amount);
    }
}