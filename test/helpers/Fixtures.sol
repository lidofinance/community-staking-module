// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { StdCheats } from "forge-std/StdCheats.sol";
import { LidoMock } from "./mocks/LidoMock.sol";
import { WstETHMock } from "./mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./mocks/LidoLocatorMock.sol";
import { WithdrawalQueueMock } from "./mocks/WithdrawalQueueMock.sol";
import { Stub } from "./mocks/Stub.sol";
import "forge-std/Test.sol";

contract Fixtures is StdCheats {
    function initLido()
        public
        returns (
            LidoLocatorMock locator,
            WstETHMock wstETH,
            LidoMock stETH,
            Stub burner
        )
    {
        stETH = new LidoMock({ _totalPooledEther: 8013386371917025835991984 });
        stETH.mintShares({
            _account: address(stETH),
            _sharesAmount: 7059313073779349112833523
        });
        burner = new Stub();
        WithdrawalQueueMock wq = new WithdrawalQueueMock(address(stETH));
        locator = new LidoLocatorMock(
            address(stETH),
            address(burner),
            address(wq)
        );
        wstETH = new WstETHMock(address(stETH));
    }
}

contract IntegrationFixtures is StdCheats, Test {
    struct Env {
        string RPC_URL;
        string LIDO_LOCATOR_ADDRESS;
        string WSTETH_ADDRESS;
    }

    function envVars() public returns (Env memory) {
        Env memory env = Env(
            vm.envOr("RPC_URL", string("")),
            vm.envOr("LIDO_LOCATOR_ADDRESS", string("")),
            vm.envOr("WSTETH_ADDRESS", string(""))
        );
        vm.skip(
            keccak256(abi.encodePacked(env.RPC_URL)) ==
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(env.LIDO_LOCATOR_ADDRESS)) ==
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(env.WSTETH_ADDRESS)) ==
                keccak256(abi.encodePacked(""))
        );
        return env;
    }
}
