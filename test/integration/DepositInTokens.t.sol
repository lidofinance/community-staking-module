// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { CommunityStakingModule } from "../../src/CommunityStakingModule.sol";
import { IWstETH, ILido, CommunityStakingBondManager } from "../../src/CommunityStakingBondManager.sol";
import { CommunityStakingModuleMock } from "../../src/test_helpers/CommunityStakingModuleMock.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";

contract StakingRouterIntegrationTest is Test {
    uint256 networkFork;

    CommunityStakingModuleMock public csm;
    CommunityStakingBondManager public bondManager;
    ILidoLocator public locator;
    IWstETH public wstETH;

    address internal agent;
    address internal alice;

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
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(WSTETH_ADDRESS)) ==
                keccak256(abi.encodePacked(""))
        );

        networkFork = vm.createFork(RPC_URL);
        vm.selectFork(networkFork);

        locator = ILidoLocator(vm.parseAddress(LIDO_LOCATOR_ADDRESS));
        csm = new CommunityStakingModuleMock();

        wstETH = IWstETH(vm.parseAddress(WSTETH_ADDRESS));

        alice = address(1);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(locator),
            address(wstETH),
            address(csm),
            penalizeRoleMembers
        );
    }

    function test_depositStETH() public {
        vm.deal(alice, 32 ether);
        vm.prank(alice);
        uint256 shares = ILido(locator.lido()).submit{ value: 32 ether }({
            _referal: address(0)
        });

        csm.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Alice",
            _rewardAddress: alice,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(alice);
        ILido(locator.lido()).approve(address(bondManager), ~uint256(0));
        bondManager.depositStETH(0, 32 ether);

        assertEq(bondManager.getBondShares(0), shares);
    }

    function test_depositETH() public {
        vm.deal(alice, 32 ether);

        csm.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Alice",
            _rewardAddress: alice,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.prank(alice);
        uint256 shares = bondManager.depositETH{ value: 32 ether }(0);

        assertEq(bondManager.getBondShares(0), shares);
    }

    function test_depositWstETH() public {
        vm.deal(alice, 32 ether);
        vm.startPrank(alice);
        ILido(locator.lido()).submit{ value: 32 ether }({
            _referal: address(0)
        });
        ILido(locator.lido()).approve(address(wstETH), ~uint256(0));
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        vm.stopPrank();

        csm.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "Alice",
            _rewardAddress: alice,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });

        vm.startPrank(alice);
        wstETH.approve(address(bondManager), ~uint256(0));
        uint256 shares = bondManager.depositWstETH(0, wstETHAmount);

        assertEq(bondManager.getBondShares(0), shares);
    }
}
