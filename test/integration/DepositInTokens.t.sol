// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { ICSAccounting } from "../../src/interfaces/ICSAccounting.sol";
import { Utilities } from "../helpers/Utilities.sol";
import { PermitHelper } from "../helpers/Permit.sol";
import { DeploymentFixtures } from "../helpers/Fixtures.sol";

contract DepositIntegrationTest is
    Test,
    Utilities,
    PermitHelper,
    DeploymentFixtures
{
    address internal user;
    address internal stranger;
    uint256 internal userPrivateKey;
    uint256 internal strangerPrivateKey;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        vm.stopPrank();
        csm.resume();

        userPrivateKey = 0xa11ce;
        user = vm.addr(userPrivateKey);
        strangerPrivateKey = 0x517a4637;
        stranger = vm.addr(strangerPrivateKey);

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
    }

    function test_depositStETH() public {
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        uint256 shares = lido.submit{ value: 32 ether }({
            _referal: address(0)
        });

        uint256 preShares = accounting.getBondShares(0);

        lido.approve(address(accounting), type(uint256).max);
        csm.depositStETH(
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(ILido(locator.lido()).balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preShares);
    }

    function test_depositETH() public {
        vm.startPrank(user);
        vm.deal(user, 32 ether);

        uint256 preShares = accounting.getBondShares(0);

        uint256 shares = lido.getSharesByPooledEth(32 ether);
        csm.depositETH{ value: 32 ether }(0);

        assertEq(user.balance, 0);
        assertEq(accounting.getBondShares(0), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preShares);
    }

    function test_depositWstETH() public {
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        lido.submit{ value: 32 ether }({ _referal: address(0) });
        lido.approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 preShares = accounting.getBondShares(0);

        wstETH.approve(address(accounting), type(uint256).max);
        csm.depositWstETH(
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preShares);
    }

    function test_depositStETHWithPermit() public {
        bytes32 digest = stETHPermitDigest(
            user,
            address(accounting),
            32 ether,
            vm.getNonce(user),
            type(uint256).max,
            address(lido)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 shares = lido.submit{ value: 32 ether }({
            _referal: address(0)
        });

        uint256 preShares = accounting.getBondShares(0);

        csm.depositStETH(
            0,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );

        assertEq(lido.balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preShares);
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
        lido.submit{ value: 32 ether }({ _referal: address(0) });
        lido.approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 preShares = accounting.getBondShares(0);

        csm.depositWstETH(
            0,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(0), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preShares);
    }
}
