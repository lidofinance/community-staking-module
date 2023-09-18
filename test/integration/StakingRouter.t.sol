// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { CommunityStakingModule } from "../../src/CommunityStakingModule.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";

contract StakingRouterIntegrationTest is Test {
    uint256 networkFork;

    CommunityStakingModule public csm;
    ILidoLocator public locator;
    IStakingRouter public stakingRouter;

    address internal agent;

    string RPC_URL;
    string LIDO_LOCATOR_ADDRESS;

    function setUp() public {
        RPC_URL = vm.envOr("RPC_URL", string(""));
        LIDO_LOCATOR_ADDRESS = vm.envOr("LIDO_LOCATOR_ADDRESS", string(""));
        vm.skip(
            keccak256(abi.encodePacked(RPC_URL)) ==
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(LIDO_LOCATOR_ADDRESS)) ==
                keccak256(abi.encodePacked(""))
        );

        networkFork = vm.createFork(RPC_URL);
        vm.selectFork(networkFork);

        locator = ILidoLocator(vm.parseAddress(LIDO_LOCATOR_ADDRESS));
        stakingRouter = IStakingRouter(payable(locator.stakingRouter()));
        csm = new CommunityStakingModule(
            "community-staking-module",
            address(locator),
            address(90210) // FIXME
        );

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
        uint256[] memory ids = stakingRouter.getStakingModuleIds();
        IStakingRouter.StakingModule memory module = stakingRouter
            .getStakingModule(ids[ids.length - 1]);
        assertTrue(module.stakingModuleAddress == address(csm));
    }
}
