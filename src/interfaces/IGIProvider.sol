// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { ForkVersion } from "../lib/Types.sol";
import { GIndex } from "../lib/GIndex.sol";

interface IGIProvider {
    function getIndex(
        ForkVersion fork,
        string memory key
    ) external view returns (GIndex);
}
