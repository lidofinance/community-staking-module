// SPDX-FileCopyrightText: 2026 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.33;

import { Test } from "forge-std/Test.sol";

import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { CuratedModule } from "../../../src/CuratedModule.sol";
import { NodeOperator } from "../../../src/interfaces/IBaseModule.sol";
import { OssifiableProxy } from "../../../src/lib/proxy/OssifiableProxy.sol";

contract CuratedV2UpgradeTest is Test, DeploymentFixtures {
    uint256 internal forkIdBeforeUpgrade;
    uint256 internal forkIdAfterUpgrade;
    CuratedModule internal cm;
    CuratedModule internal implementation;

    function setUp() public {
        Env memory env = envVars();
        forkIdBeforeUpgrade = vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        if (moduleType != ModuleType.Curated) vm.skip(true, "Curated deployment required");
        vm.skip(module.getInitializedVersion() != 1, "Migration requires a version 1 deployment");

        forkIdAfterUpgrade = vm.createSelectFork(env.RPC_URL, block.number);
        cm = CuratedModule(address(module));

        // Deployment phase: prepare the implementation linked to the updated allocator.
        implementation = new CuratedModule({
            moduleType: module.getType(),
            lidoLocator: address(module.LIDO_LOCATOR()),
            parametersRegistry: address(module.PARAMETERS_REGISTRY()),
            accounting: address(module.ACCOUNTING()),
            exitPenalties: address(module.EXIT_PENALTIES()),
            metaRegistry: address(cm.META_REGISTRY())
        });

        // Vote phase: atomically upgrade and migrate.
        OssifiableProxy proxy = OssifiableProxy(payable(address(module)));
        address proxyAdmin = proxy.proxy__getAdmin();
        vm.prank(proxyAdmin);
        proxy.proxy__upgradeToAndCall(address(implementation), abi.encodeCall(CuratedModule.finalizeUpgradeV2, ()));
    }

    function test_curatedModuleChanges() public {
        vm.selectFork(forkIdBeforeUpgrade);
        uint256 nonceBefore = module.getNonce();
        address implementationBefore = OssifiableProxy(payable(address(module))).proxy__getImplementation();
        address adminBefore = OssifiableProxy(payable(address(module))).proxy__getAdmin();

        vm.selectFork(forkIdAfterUpgrade);
        assertEq(module.getInitializedVersion(), 2);
        assertEq(module.getNonce(), nonceBefore + 1);
        assertNotEq(implementationBefore, address(implementation));
        assertEq(OssifiableProxy(payable(address(module))).proxy__getImplementation(), address(implementation));
        assertEq(OssifiableProxy(payable(address(module))).proxy__getAdmin(), adminBefore);
    }

    function test_topUpAllocationMigration() public {
        uint256 count = module.getNodeOperatorsCount();
        for (uint256 noId; noId < count; ++noId) {
            vm.selectFork(forkIdBeforeUpgrade);
            NodeOperator memory no = module.getNodeOperator(noId);

            vm.selectFork(forkIdAfterUpgrade);
            assertEq(cm.isTopUpAllocationPaused(noId), no.totalDepositedKeys <= no.totalWithdrawnKeys);
        }
    }

    function test_curatedModuleState() public {
        vm.selectFork(forkIdBeforeUpgrade);
        uint256 countBefore = module.getNodeOperatorsCount();
        uint256 stakeBefore = module.getTotalModuleStake();
        (uint256 exitedBefore, uint256 depositedBefore, uint256 depositableBefore) = module.getStakingModuleSummary();

        vm.selectFork(forkIdAfterUpgrade);
        assertEq(module.getNodeOperatorsCount(), countBefore);
        assertEq(module.getTotalModuleStake(), stakeBefore);
        (uint256 exitedAfter, uint256 depositedAfter, uint256 depositableAfter) = module.getStakingModuleSummary();
        assertEq(exitedAfter, exitedBefore);
        assertEq(depositedAfter, depositedBefore);
        assertEq(depositableAfter, depositableBefore);

        for (uint256 noId; noId < countBefore; ++noId) {
            vm.selectFork(forkIdBeforeUpgrade);
            bytes memory noBefore = abi.encode(module.getNodeOperator(noId));
            uint256 balanceBefore = module.getNodeOperatorBalance(noId);

            vm.selectFork(forkIdAfterUpgrade);
            assertEq(abi.encode(module.getNodeOperator(noId)), noBefore);
            assertEq(module.getNodeOperatorBalance(noId), balanceBefore);
        }
    }
}
