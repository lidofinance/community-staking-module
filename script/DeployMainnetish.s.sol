// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployMainnetish is DeployBase {
    constructor()
        DeployBase(
            // name
            "mainnet",
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
            // lidoLocatorAddress
            0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb,
            // votingAddress
            0x2e59A20f205bB85a89C53f1936454680651E618e,
            // oracleReportEpochsPerFrame
            225 * 28 // 28 days
        )
    {}
}
