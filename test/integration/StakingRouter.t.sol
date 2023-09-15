// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { CommunityStakingModule, NodeOperator } from "../../src/CommunityStakingModule.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { IWstETH } from "../../src/CommunityStakingBondManager.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import "../helpers/Utilities.sol";
import "../../src/CommunityStakingBondManager.sol";

contract StakingRouterIntegrationTest is Test, Utilities {
    uint256 networkFork;

    CommunityStakingModule public csm;
    ILidoLocator public locator;
    IStakingRouter public stakingRouter;
    ILido public lido;
    IWstETH public wstETH;

    address internal agent;

    string RPC_URL;
    string LIDO_LOCATOR_ADDRESS;
    string WSTETH_ADDRESS;

    function setUp() public {
        RPC_URL = vm.envOr("RPC_URL", string(""));
        LIDO_LOCATOR_ADDRESS = vm.envOr("LIDO_LOCATOR_ADDRESS", string(""));
        WSTETH_ADDRESS = vm.envOr("WSTETH_ADDRESS", string(""));
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
        lido = ILido(locator.lido());
        wstETH = IWstETH(vm.parseAddress(WSTETH_ADDRESS));
        vm.label(address(lido), "lido");
        vm.label(address(stakingRouter), "stakingRouter");

        csm = new CommunityStakingModule(
            "community-staking-module",
            address(locator)
        );
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = address(csm);
        CommunityStakingBondManager bondManager = new CommunityStakingBondManager(
                2 ether,
                address(csm),
                address(locator),
                address(wstETH),
                address(csm),
                penalizeRoleMembers
            );
        csm.setBondManager(address(bondManager));

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

    function test_RouterDeposit() public {
        vm.prank(agent);
        stakingRouter.addStakingModule({
            _name: "community-staking-v1",
            _stakingModuleAddress: address(csm),
            _targetShare: 10000,
            _stakingModuleFee: 500,
            _treasuryFee: 500
        });
        uint256[] memory ids = stakingRouter.getStakingModuleIds();
        (bytes memory keys, bytes memory signatures) = keysSignatures(1);
        address nodeOperator = address(2);
        vm.deal(nodeOperator, 2 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 2 ether }(
            "test",
            nodeOperator,
            1,
            keys,
            signatures
        );

        vm.prank(locator.depositSecurityModule());
        lido.deposit(1, ids[ids.length - 1], "");
        (, , , , , , uint256 totalDepositedValidators, ) = csm
            .getNodeOperatorSummary(0);
        assertEq(totalDepositedValidators, 1);
    }
}
