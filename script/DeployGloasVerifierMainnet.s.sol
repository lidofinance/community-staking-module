// SPDX-FileCopyrightText: 2026 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.33;

import { DeployGloasVerifierBase } from "./DeployGloasVerifier.s.sol";

contract DeployGloasVerifierMainnet is DeployGloasVerifierBase {
    constructor() DeployGloasVerifierBase("mainnet") {
        // TODO: set to GLOAS_FORK_EPOCH * 32 once the mainnet fork is scheduled
        // @see https://github.com/eth-clients/mainnet/blob/main/metadata/config.yaml
        verifierGloasSlot = type(uint64).max;
    }
}
