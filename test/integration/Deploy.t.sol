// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "../../src/CSModule.sol";
import "../../src/CSAccounting.sol";
import "../../src/CSFeeOracle.sol";
import "../../src/CSFeeDistributor.sol";
import "../../src/CSVerifier.sol";
import { HashConsensus } from "../../lib/base-oracle/oracle/HashConsensus.sol";
import { Test } from "forge-std/Test.sol";
import { DeployBase } from "../../script/DeployBase.s.sol";
import { DeployMainnetish } from "../../script/DeployMainnetish.s.sol";
import { DeployHolesky } from "../../script/DeployHolesky.s.sol";
import { DeployHoleskyDevnet } from "../../script/DeployHoleskyDevnet.s.sol";
import { Vm } from "forge-std/Vm.sol";
import "../helpers/Fixtures.sol";

contract TestDeployment is Test, DeploymentFixtures {
    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        vm.stopPrank();
        csm.resume();
    }

    function test_init() public {
        assertEq(csm.getType(), "community-onchain-v1");
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
        assertEq(feeDistributor.ACCOUNTING(), address(accounting));
    }
}
