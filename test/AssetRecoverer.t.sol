// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { AssetRecoverer } from "../src/AssetRecoverer.sol";
import { AssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ERC20Testable, ERC721Testable, ERC1155Testable } from "./helpers/ERCTestable.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";

contract AssetRecovererTestable is AssetRecoverer, ERC1155Holder {
    address public recoverer;
    error OnlyRecoverer();

    constructor(address _recoverer) {
        recoverer = _recoverer;
    }

    function checkRecovererRole() internal override {
        if (msg.sender != recoverer) {
            revert OnlyRecoverer();
        }
    }
}

contract AssetRecovererTest is Test, Utilities {
    AssetRecovererTestable internal recoverer;
    address internal actor;
    address internal stranger;

    function setUp() public {
        actor = nextAddress("Actor");
        stranger = nextAddress("Stranger");
        recoverer = new AssetRecovererTestable(actor);
    }

    function test_recoverETH() public {
        vm.deal(address(recoverer), 1 ether);

        vm.prank(actor);
        vm.expectEmit(true, true, true, true, address(recoverer));
        emit AssetRecovererLib.EtherRecovered(actor, 1 ether);
        recoverer.recoverEther();

        assertEq(address(recoverer).balance, 0);
        assertEq(actor.balance, 1 ether);
    }

    function test_recoverETH_revertIfNoRole() public {
        vm.prank(stranger);
        vm.expectRevert(AssetRecovererTestable.OnlyRecoverer.selector);
        recoverer.recoverEther();
    }

    function test_recoverERC20() public {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(recoverer), 1000);

        vm.prank(actor);
        vm.expectEmit(true, true, true, true, address(recoverer));
        emit AssetRecovererLib.ERC20Recovered(address(token), actor, 1000);
        recoverer.recoverERC20(address(token), 1000);

        assertEq(token.balanceOf(address(recoverer)), 0);
        assertEq(token.balanceOf(actor), 1000);
    }

    function test_recoverERC20_revertIfNoRole() public {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(recoverer), 1000);

        vm.prank(stranger);
        vm.expectRevert(AssetRecovererTestable.OnlyRecoverer.selector);
        recoverer.recoverERC20(address(token), 1000);
    }

    function test_recoverERC721() public {
        ERC721Testable token = new ERC721Testable();
        token.mint(address(recoverer), 0);

        vm.prank(actor);
        vm.expectEmit(true, true, true, true, address(recoverer));
        emit AssetRecovererLib.ERC721Recovered(address(token), 0, actor);
        recoverer.recoverERC721(address(token), 0);

        assertEq(token.ownerOf(0), actor);
    }

    function test_recoverERC721_revertIfNoRole() public {
        ERC721Testable token = new ERC721Testable();
        token.mint(address(recoverer), 0);

        vm.prank(stranger);
        vm.expectRevert(AssetRecovererTestable.OnlyRecoverer.selector);
        recoverer.recoverERC721(address(token), 0);
    }

    function test_recoverERC1155() public {
        ERC1155Testable token = new ERC1155Testable();
        token.mint(address(recoverer), 0, 10, "");

        vm.prank(actor);
        vm.expectEmit(true, true, true, true, address(recoverer));
        emit AssetRecovererLib.ERC1155Recovered(address(token), 0, actor, 10);
        recoverer.recoverERC1155(address(token), 0);

        assertEq(token.balanceOf(actor, 0), 10);
        assertEq(token.balanceOf(address(recoverer), 0), 0);
    }

    function test_recoverERC1155_revertIfNoRole() public {
        ERC1155Testable token = new ERC1155Testable();
        token.mint(address(recoverer), 0, 10, "");

        vm.prank(stranger);
        vm.expectRevert(AssetRecovererTestable.OnlyRecoverer.selector);
        recoverer.recoverERC1155(address(token), 0);
    }
}