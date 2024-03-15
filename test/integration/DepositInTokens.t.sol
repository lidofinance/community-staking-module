// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSModule } from "../../src/CSModule.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { Utilities } from "../helpers/Utilities.sol";
import { PermitHelper } from "../helpers/Permit.sol";
import { IntegrationFixtures } from "../helpers/Fixtures.sol";
import { CommunityStakingModuleMock } from "../helpers/mocks/CommunityStakingModuleMock.sol";

contract DepositIntegrationTest is
    Test,
    Utilities,
    PermitHelper,
    IntegrationFixtures
{
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

    function setUp() public {
        Env memory env = envVars();

        networkFork = vm.createFork(env.RPC_URL);
        vm.selectFork(networkFork);
        checkChainId(1);

        locator = ILidoLocator(LOCATOR_ADDRESS);
        csm = new CommunityStakingModuleMock();

        wstETH = IWstETH(WSTETH_ADDRESS);

        userPrivateKey = 0xa11ce;
        user = vm.addr(userPrivateKey);
        strangerPrivateKey = 0x517a4637;
        stranger = vm.addr(strangerPrivateKey);

        uint256[] memory curve = new uint256[](2);
        curve[0] = 2 ether;
        curve[1] = 4 ether;
        accounting = new CSAccounting(
            curve,
            user,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks
        );

        csm.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
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

        vm.prank(user);
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
}
