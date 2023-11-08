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
        Stub elVault = new Stub();
        WithdrawalQueueMock wq = new WithdrawalQueueMock(address(stETH));
        locator = new LidoLocatorMock(
            address(stETH),
            address(burner),
            address(wq),
            address(elVault)
        );
        wstETH = new WstETHMock(address(stETH));
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
