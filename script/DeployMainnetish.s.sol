// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployMainnetish is DeployBase {
    constructor()
        DeployBase(
            // chainId
            1,
            // secondsPerSlot
            12,
            // slotsPerEpoch
            32,
            // clGenesisTime
            1606824023,
            // Verifier supported epoch. Deneb fork epoch so far
            269568,
            // initializationEpoch
            239853,
            // lidoLocatorAddress
            0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb,
            // wstETHAddress
            0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
        )
    {}
}
