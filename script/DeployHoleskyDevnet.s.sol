// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";

contract DeployHoleskyDevnet is DeployBase {
    constructor()
        DeployBase(
            // name
            "holesky-devnet",
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
            0x5bF85BadDac33F91B38617c18a3F829f912Ca060,
            // votingAddress
            0xd8B7F4EFd16e913648C6E9B74772BC3C38203301,
            // oracleReportEpochsPerFrame
            225 // 1 days
        )
    {}
}
