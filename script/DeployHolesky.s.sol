// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployHolesky is DeployBase {
    constructor()
        DeployBase(
            // name
            "holesky",
            // chainId
            17000,
            // secondsPerSlot
            12,
            // slotsPerEpoch
            32,
            // clGenesisTime
            1695902400,
            // Verifier supported epoch. Deneb fork epoch so far
            29696,
            // lidoLocatorAddress
            0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8,
            // votingAddress
            0xdA7d2573Df555002503F29aA4003e398d28cc00f,
            // oracleReportEpochsPerFrame
            225 * 28 // 28 days
        )
    {}
}
