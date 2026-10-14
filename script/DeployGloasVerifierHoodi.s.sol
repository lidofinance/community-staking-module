// SPDX-FileCopyrightText: 2026 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.33;

import { DeployGloasVerifierBase } from "./DeployGloasVerifier.s.sol";

contract DeployGloasVerifierHoodi is DeployGloasVerifierBase {
    constructor() DeployGloasVerifierBase("hoodi") {
        verifierGloasSlot = 4235264; // GLOAS_FORK_EPOCH = 4235264 / 32 = 132352, @see https://github.com/eth-clients/hoodi/blob/main/metadata/config.yaml#L49
    }
}
