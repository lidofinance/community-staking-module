// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule, NodeOperator } from "../../src/CSModule.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { Utilities } from "../helpers/Utilities.sol";
import { DeploymentFixtures } from "../helpers/Fixtures.sol";
import { IKernel } from "../../src/interfaces/IKernel.sol";
import { IACL } from "../../src/interfaces/IACL.sol";

contract StakingRouterIntegrationTest is Test, Utilities, DeploymentFixtures {
    address internal agent;
    uint256 internal moduleId;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        vm.stopPrank();
        csm.resume();

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

        if (env.MODULE_ID == 0) {
            moduleId = addCsmModule();
        } else {
            moduleId = env.MODULE_ID;
        }
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
        IStakingRouter.StakingModule memory module = stakingRouter
            .getStakingModule(moduleId);
        assertTrue(module.stakingModuleAddress == address(csm));
    }

    function test_RouterDeposit() public {
        (bytes memory keys, bytes memory signatures) = keysSignatures(2);
        address nodeOperator = address(2);
        vm.deal(nodeOperator, 4 ether);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: 4 ether }(
            2,
            keys,
            signatures,
            address(0),
            address(0),
            new bytes32[](0),
            address(0)
        );

        IACL acl = IACL(IKernel(lido.kernel()).acl());
        bytes32 role = lido.STAKING_CONTROL_ROLE();
        vm.prank(acl.getPermissionManager(address(lido), role));
        acl.grantPermission(agent, address(lido), role);

        vm.prank(agent);
        lido.removeStakingLimit();
        // It's impossible to process deposits if withdrawal requests amount is more than the buffered ether,
        // so we need to make sure that the buffered ether is enough by submitting this tremendous amount.
        address whale = nextAddress();
        vm.prank(whale);
        vm.deal(whale, 1e7 ether);
        lido.submit{ value: 1e7 ether }(address(0));

        vm.prank(locator.depositSecurityModule());
        lido.deposit(1, moduleId, "");
        (, , , , , , uint256 totalDepositedValidators, ) = csm
            .getNodeOperatorSummary(0);
        assertEq(totalDepositedValidators, 1);
    }

    function test_routerReportRewardsMinted() public {
        uint256[] memory moduleIds = new uint256[](1);
        uint256[] memory rewards = new uint256[](1);

        moduleIds[0] = moduleId;
        rewards[0] = 100;
        vm.prank(agent);
        vm.expectCall(address(csm), abi.encodeCall(csm.onRewardsMinted, (100)));
        stakingRouter.reportRewardsMinted(moduleIds, rewards);
    }
}
