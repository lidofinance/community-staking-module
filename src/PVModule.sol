// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { CSModule } from "./CSModule.sol";

contract PVModule is CSModule {
    error NotImplemented();

    constructor(
        bytes32 moduleType,
        address lidoLocator,
        address parametersRegistry,
        address accounting_,
        address exitPenalties
    )
        CSModule(
            moduleType,
            lidoLocator,
            parametersRegistry,
            accounting_,
            exitPenalties
        )
    {}

    function obtainDepositData(
        uint256 /* depositsCount */,
        bytes calldata /* depositCalldata */
    )
        external
        override
        onlyRole(STAKING_ROUTER_ROLE)
        returns (bytes memory publicKeys, bytes memory signatures)
    {
        revert NotImplemented();
    }
}
