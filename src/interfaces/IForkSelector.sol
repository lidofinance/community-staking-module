// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { ForkVersion, Slot } from "../lib/Types.sol";

interface IForkSelector {
    function findFork(Slot slot) external view returns (ForkVersion);
}
