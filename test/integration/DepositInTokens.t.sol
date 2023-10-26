// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { PermitHelper } from "../helpers/Permit.sol";
import { CommunityStakingModuleMock } from "../helpers/mocks/CommunityStakingModuleMock.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";

contract DepositIntegrationTest is Test, PermitHelper {
    uint256 networkFork;

    CommunityStakingModuleMock public csm;
    CSAccounting public accounting;
    ILidoLocator public locator;
    IWstETH public wstETH;

    address internal agent;
    address internal user;
    address internal stranger;
    uint256 internal userPrivateKey;
    uint256 internal strangerPrivateKey;

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

        userPrivateKey = 0xa11ce;
        user = vm.addr(userPrivateKey);
        strangerPrivateKey = 0x517a4637;
        stranger = vm.addr(strangerPrivateKey);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = user;

        accounting = new CSAccounting(
            2 ether,
            user,
            address(locator),
            address(wstETH),
            address(csm),
            penalizeRoleMembers
        );

        csm.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _name: "User",
            _rewardAddress: user,
            _totalVettedValidators: 16,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: 1,
            _totalAddedValidators: 16,
            _totalDepositedValidators: 16
        });
    }

    function test_depositStETH() public {
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        uint256 shares = ILido(locator.lido()).submit{ value: 32 ether }({
            _referal: address(0)
        });

        ILido(locator.lido()).approve(address(accounting), type(uint256).max);
        accounting.depositStETH(user, 0, 32 ether);

        assertEq(ILido(locator.lido()).balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares);
        assertEq(accounting.totalBondShares(), shares);
    }

    function test_depositETH() public {
        vm.prank(user);
        vm.deal(user, 32 ether);
        uint256 shares = accounting.depositETH{ value: 32 ether }(user, 0);

        assertEq(user.balance, 0);
        assertEq(accounting.getBondShares(0), shares);
        assertEq(accounting.totalBondShares(), shares);
    }

    function test_depositWstETH() public {
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        ILido(locator.lido()).submit{ value: 32 ether }({
            _referal: address(0)
        });
        ILido(locator.lido()).approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        vm.startPrank(user);
        wstETH.approve(address(accounting), type(uint256).max);
        uint256 shares = accounting.depositWstETH(user, 0, wstETHAmount);

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares);
        assertEq(accounting.totalBondShares(), shares);
    }

    function test_depositStETHWithPermit() public {
        bytes32 digest = stETHPermitDigest(
            user,
            address(accounting),
            32 ether,
            vm.getNonce(user),
            type(uint256).max,
            address(locator.lido())
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 shares = ILido(locator.lido()).submit{ value: 32 ether }({
            _referal: address(0)
        });
        vm.stopPrank();

        vm.prank(stranger);
        accounting.depositStETHWithPermit(
            user,
            0,
            32 ether,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );

        assertEq(ILido(locator.lido()).balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares);
        assertEq(accounting.totalBondShares(), shares);
    }

    function test_depositWstETHWithPermit() public {
        bytes32 digest = wstETHPermitDigest(
            user,
            address(accounting),
            32 ether,
            vm.getNonce(user),
            type(uint256).max,
            address(wstETH)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        ILido(locator.lido()).submit{ value: 32 ether }({
            _referal: address(0)
        });
        ILido(locator.lido()).approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        vm.stopPrank();

        vm.prank(stranger);
        uint256 shares = accounting.depositWstETHWithPermit(
            user,
            0,
            wstETHAmount,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares);
        assertEq(accounting.totalBondShares(), shares);
    }
}
