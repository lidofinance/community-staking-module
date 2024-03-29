// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { StdCheats } from "forge-std/StdCheats.sol";
import { LidoMock } from "./mocks/LidoMock.sol";
import { WstETHMock } from "./mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./mocks/LidoLocatorMock.sol";
import { BurnerMock } from "./mocks/BurnerMock.sol";
import { WithdrawalQueueMock } from "./mocks/WithdrawalQueueMock.sol";
import { Stub } from "./mocks/Stub.sol";
import "forge-std/Test.sol";

contract Fixtures is StdCheats, Test {
    function initLido()
        public
        returns (
            LidoLocatorMock locator,
            WstETHMock wstETH,
            LidoMock stETH,
            BurnerMock burner
        )
    {
        stETH = new LidoMock({ _totalPooledEther: 8013386371917025835991984 });
        stETH.mintShares({
            _account: address(stETH),
            _sharesAmount: 7059313073779349112833523
        });
        burner = new BurnerMock();
        Stub elVault = new Stub();
        WithdrawalQueueMock wq = new WithdrawalQueueMock();
        Stub treasury = new Stub();
        locator = new LidoLocatorMock(
            address(stETH),
            address(burner),
            address(wq),
            address(elVault),
            address(treasury)
        );
        wstETH = new WstETHMock(address(stETH));
        vm.label(address(stETH), "lido");
        vm.label(address(wstETH), "wstETH");
        vm.label(address(locator), "locator");
        vm.label(address(burner), "burner");
        vm.label(address(wq), "wq");
        vm.label(address(elVault), "elVault");
        vm.label(address(treasury), "treasury");
    }
}

contract IntegrationFixtures is StdCheats, Test {
    struct Env {
        string RPC_URL;
    }

    address internal immutable LOCATOR_ADDRESS =
        0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;
    address internal immutable WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal immutable ARAGON_VOTING_ADDRESS =
        0x2e59A20f205bB85a89C53f1936454680651E618e;

    function envVars() public returns (Env memory) {
        Env memory env = Env(vm.envOr("RPC_URL", string("")));
        vm.skip(_isEmpty(env.RPC_URL));
        return env;
    }

    function _isEmpty(string memory s) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(s)) == keccak256(abi.encodePacked(""));
    }
}
