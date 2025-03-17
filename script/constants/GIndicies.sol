// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { GIndex } from "../../src/lib/GIndex.sol";

// Check using `yarn run gindex`
library GIndicies {
    GIndex constant FIRST_WITHDRAWAL_DENEB =
        GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000000000000e1c004
        );
    GIndex constant FIRST_VALIDATOR_DENEB =
        GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000056000000000028
        );
    GIndex constant HISTORICAL_SUMMARIES_DENEB =
        GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000000000000003b00
        );

    GIndex constant FIRST_WITHDRAWAL_CAPELLA =
        GIndex.wrap(
            0x000000000000000000000000000000000000000000000000000000000161c004
        );
    GIndex constant FIRST_VALIDATOR_CAPELLA =
        GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000096000000000028
        );
    GIndex constant HISTORICAL_SUMMARIES_CAPELLA =
        GIndex.wrap(
            0x0000000000000000000000000000000000000000000000000000000000005b00
        );
}
