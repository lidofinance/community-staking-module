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
            1695902100,
            // Verifier supported epoch. Deneb fork epoch so far
            29696,
            // initializationEpoch
            8888,
            // lidoLocatorAddress
            0x5bF85BadDac33F91B38617c18a3F829f912Ca060
        )
    {}
}
