// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { StdCheats } from "forge-std/StdCheats.sol";
import { LidoMock } from "./mocks/LidoMock.sol";
import { WstETHMock } from "./mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./mocks/LidoLocatorMock.sol";
import { Stub } from "./mocks/Stub.sol";

contract Fixtures is StdCheats {
    struct LidoContracts {
        LidoLocatorMock locator;
        WstETHMock wstETH;
        LidoMock stETH;
        Stub burner;
    }

    LidoContracts public lido;

    modifier withLido() {
        LidoMock lidoStETH = new LidoMock(8013386371917025835991984);
        lidoStETH.mintShares(address(lidoStETH), 7059313073779349112833523);
        Stub burner = new Stub();
        LidoLocatorMock locator = new LidoLocatorMock(
            address(lidoStETH),
            address(burner)
        );
        WstETHMock wstETH = new WstETHMock(address(lidoStETH));

        lido = LidoContracts({
            locator: locator,
            wstETH: wstETH,
            stETH: lidoStETH,
            burner: burner
        });
        _;
    }
}
