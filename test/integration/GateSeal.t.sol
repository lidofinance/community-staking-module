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
import { DeploymentFixtures } from "../helpers/Fixtures.sol";

contract GateSealTest is Test, Utilities, DeploymentFixtures {
    address internal nodeOperator;
    uint256 internal defaultNoId;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        vm.stopPrank();
        if (csm.isPaused()) csm.resume();

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
    }

    function test_sealAll() public {
        address[] memory sealables = new address[](2);
        sealables[0] = address(csm);
        sealables[1] = address(accounting);

        vm.prank(gateSeal.get_sealing_committee());
        gateSeal.seal(sealables);

        assertTrue(csm.isPaused());
        assertTrue(accounting.isPaused());
    }

    function test_sealCSM() public {
        address[] memory sealables = new address[](1);
        sealables[0] = address(csm);
        vm.prank(gateSeal.get_sealing_committee());
        gateSeal.seal(sealables);

        assertTrue(csm.isPaused());
        assertFalse(accounting.isPaused());
    }

    function test_sealAccounting() public {
        address[] memory sealables = new address[](1);
        sealables[0] = address(accounting);
        vm.prank(gateSeal.get_sealing_committee());
        gateSeal.seal(sealables);

        assertTrue(accounting.isPaused());
        assertFalse(csm.isPaused());
    }
}
