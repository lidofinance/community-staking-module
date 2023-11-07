// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployHolesky is DeployBase {
    constructor()
        DeployBase(
            // chainId
            17000,
            // secondsPerSlot
            12,
            // slotsPerEpoch
            32,
            // clGenesisTime
            1695902100,
            // initializationEpoch
            8888,
            // lidoLocatorAddress
            0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8,
            // wstETHAddress
            0x8d09a4502Cc8Cf1547aD300E066060D043f6982D
        )
    {}
}
