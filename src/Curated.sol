// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSModule, CSModule } from "./CSModule.sol";

contract Curated is CSModule {
    constructor(
        bytes32 moduleType,
        address lidoLocator,
        address parametersRegistry,
        address accounting,
        address exitPenalties
    )
        CSModule(
            moduleType,
            lidoLocator,
            parametersRegistry,
            accounting,
            exitPenalties
        )
    {}

    /// @inheritdoc ICSModule
    function isInCuratedMode() public pure override returns (bool) {
        return true;
    }
}
