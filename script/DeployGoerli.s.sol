// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployGoerli is DeployBase {
    constructor()
        DeployBase(
            // chainId
            5,
            // secondsPerSlot
            12,
            // slotsPerEpoch
            32,
            // clGenesisTime
            1614588812,
            // initializationEpoch
            215502,
            // lidoLocatorAddress
            0x1eDf09b5023DC86737b59dE68a8130De878984f5,
            // wstETHAddress
            0x6320cD32aA674d2898A68ec82e869385Fc5f7E2f
        )
    {}
}
