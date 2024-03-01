// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import { DeployMainnetish } from "../../script/DeployMainnetish.s.sol";
import "../../src/CSModule.sol";
import { Vm } from "forge-std/Vm.sol";
import "../helpers/Fixtures.sol";

contract TestDeployMainnet is Test, IntegrationFixtures {
    DeployMainnetish public script;
    uint256 public networkFork;

    function setUp() public {
        Env memory env = envVars();

        networkFork = vm.createFork(env.RPC_URL);
        vm.selectFork(networkFork);

        script = new DeployMainnetish();
        vm.chainId(1);
        Vm.Wallet memory wallet = vm.createWallet("deployer");
        vm.setEnv("DEPLOYER_PRIVATE_KEY", vm.toString(wallet.privateKey));
    }

    function test_run() public {
        script.run();
        CSModule csm = CSModule(script.csm());
        assertEq(address(csm.accounting()), address(script.accounting()));
    }
}
