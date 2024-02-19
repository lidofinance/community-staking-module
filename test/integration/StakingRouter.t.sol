// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSModule, NodeOperator } from "../../src/CSModule.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { Utilities } from "../helpers/Utilities.sol";
import { IntegrationFixtures } from "../helpers/Fixtures.sol";

contract StakingRouterIntegrationTest is Test, Utilities, IntegrationFixtures {
    uint256 networkFork;

    CSModule public csm;
    ILidoLocator public locator;
    IStakingRouter public stakingRouter;
    ILido public lido;
    IWstETH public wstETH;

    address internal agent;

    function setUp() public {
        Env memory env = envVars();

        networkFork = vm.createFork(env.RPC_URL);
        vm.selectFork(networkFork);
        checkChainId(1);

        locator = ILidoLocator(LOCATOR_ADDRESS);
        stakingRouter = IStakingRouter(payable(locator.stakingRouter()));
        lido = ILido(locator.lido());
        wstETH = IWstETH(WSTETH_ADDRESS);
        vm.label(address(lido), "lido");
        vm.label(address(stakingRouter), "stakingRouter");

        csm = new CSModule(
            "community-staking-module",
            address(locator),
            address(0),
            address(this)
        );
        uint256[] memory curve = new uint256[](2);
        curve[0] = 2 ether;
        curve[1] = 4 ether;
        CSAccounting accounting = new CSAccounting(
            curve,
            address(csm),
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks
        );
        csm.grantRole(csm.SET_ACCOUNTING_ROLE(), address(this));
        csm.grantRole(csm.KEY_VALIDATOR_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(stakingRouter));

        csm.setAccounting(address(accounting));

        agent = stakingRouter.getRoleMember(
            stakingRouter.DEFAULT_ADMIN_ROLE(),
            0
        );
        vm.startPrank(agent);
        stakingRouter.grantRole(
            stakingRouter.STAKING_MODULE_MANAGE_ROLE(),
            agent
        );
        stakingRouter.grantRole(
            stakingRouter.REPORT_REWARDS_MINTED_ROLE(),
            agent
        );
        vm.stopPrank();
    }

    function addCsmModule() public returns (uint256) {
        vm.prank(agent);
        stakingRouter.addStakingModule({
            _name: "community-staking-v1",
            _stakingModuleAddress: address(csm),
            _targetShare: 10000,
            _stakingModuleFee: 500,
            _treasuryFee: 500
        });
        uint256[] memory ids = stakingRouter.getStakingModuleIds();
        return ids[ids.length - 1];
    }

    function test_connectCSMToRouter() public {
        uint256 moduleId = addCsmModule();
        IStakingRouter.StakingModule memory module = stakingRouter
            .getStakingModule(moduleId);
        assertTrue(module.stakingModuleAddress == address(csm));
    }

    function test_RouterDeposit() public {
        uint256 moduleId = addCsmModule();
        (bytes memory keys, bytes memory signatures) = keysSignatures(2);
        address nodeOperator = address(2);
        vm.deal(nodeOperator, 4 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 4 ether }(2, keys, signatures);

        {
            // Pretend to be a key validation oracle
            csm.vetKeys(0, 2);
        }

        // It's impossible to process deposits if withdrawal requests amount is more than the buffered ether,
        // so we need to make sure that the buffered ether is enough by submitting this tremendous amount.
        address whale = nextAddress();
        vm.prank(whale);
        vm.deal(whale, 1e5 ether);
        lido.submit{ value: 1e5 ether }(address(0));

        vm.prank(locator.depositSecurityModule());
        lido.deposit(1, moduleId, "");
        (, , , , , , uint256 totalDepositedValidators, ) = csm
            .getNodeOperatorSummary(0);
        assertEq(totalDepositedValidators, 1);
    }

    function test_routerReportRewardsMinted() public {
        uint256 moduleId = addCsmModule();
        uint256[] memory moduleIds = new uint256[](1);
        uint256[] memory rewards = new uint256[](1);

        moduleIds[0] = moduleId;
        rewards[0] = 100;
        vm.prank(agent);
        vm.expectCall(address(csm), abi.encodeCall(csm.onRewardsMinted, (100)));
        stakingRouter.reportRewardsMinted(moduleIds, rewards);
    }
}
