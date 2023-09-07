// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { CommunityStakingModule } from "../../src/CommunityStakingModule.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";

contract StakingRouterIntegrationTest is Test {
    uint256 mainnetFork;

    CommunityStakingModule public csm;
    ILidoLocator public locator;
    IStakingRouter public stakingRouter;

    address internal agent;
    address internal locatorAddress =
        0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);

        locator = ILidoLocator(locatorAddress);
        stakingRouter = IStakingRouter(payable(locator.stakingRouter()));
        csm = new CommunityStakingModule("community-staking-module");

        agent = stakingRouter.getRoleMember(
            stakingRouter.DEFAULT_ADMIN_ROLE(),
            0
        );
        vm.startPrank(agent);
        stakingRouter.grantRole(
            stakingRouter.STAKING_MODULE_MANAGE_ROLE(),
            agent
        );
        vm.stopPrank();
    }

    function test_connectCSMToRouter() public {
        vm.prank(agent);
        stakingRouter.addStakingModule({
            _name: "community-staking-v1",
            _stakingModuleAddress: address(csm),
            _targetShare: 10000,
            _stakingModuleFee: 500,
            _treasuryFee: 500
        });
        IStakingRouter.StakingModule[] memory modules = stakingRouter
            .getStakingModules();
        bool contains = false;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i].stakingModuleAddress == address(csm)) {
                contains = true;
                break;
            }
        }
        assertTrue(contains);
    }
}
