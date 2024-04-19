// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "../../src/CSModule.sol";
import "../../src/CSAccounting.sol";
import "../../src/CSFeeOracle.sol";
import "../../src/CSFeeDistributor.sol";
import { Test } from "forge-std/Test.sol";
import "../../src/CSVerifier.sol";
import { HashConsensus } from "../../lib/base-oracle/oracle/HashConsensus.sol";
import "../helpers/Fixtures.sol";

contract Deploy is Test, EnvFixtures {
    CSModule public csm;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;
    CSVerifier public verifier;
    HashConsensus public hashConsensus;

    constructor() {
        Env memory env = envVars();
        uint256 networkFork = vm.createFork(env.RPC_URL);
        vm.selectFork(networkFork);

        string memory root = vm.projectRoot();
        string memory config = vm.readFile(
            string.concat(root, env.POST_DEPLOY_CONFIG)
        );

        csm = CSModule(vm.parseJsonAddress(config, ".CSModule"));
        vm.label(address(csm), "csm");

        accounting = CSAccounting(vm.parseJsonAddress(config, ".CSAccounting"));
        vm.label(address(accounting), "accounting");

        oracle = CSFeeOracle(vm.parseJsonAddress(config, ".CSFeeOracle"));
        vm.label(address(oracle), "oracle");

        feeDistributor = CSFeeDistributor(
            vm.parseJsonAddress(config, ".CSFeeDistributor")
        );
        vm.label(address(feeDistributor), "feeDistributor");

        verifier = CSVerifier(vm.parseJsonAddress(config, ".CSVerifier"));
        vm.label(address(verifier), "verifier");

        hashConsensus = HashConsensus(
            vm.parseJsonAddress(config, ".HashConsensus")
        );
        vm.label(address(hashConsensus), "hashConsensus");
    }

    function test_init() public {
        assertEq(csm.getType(), "community-staking-module");
        assertEq(address(csm.accounting()), address(accounting));
        assertEq(address(accounting.feeDistributor()), address(feeDistributor));
        assertEq(feeDistributor.ACCOUNTING(), address(accounting));
    }
}
