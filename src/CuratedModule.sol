// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICuratedModule } from "./interfaces/ICuratedModule.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";

import { CSModule } from "./CSModule.sol";

import { NOAddresses } from "./lib/NOAddresses.sol";

contract CuratedModule is ICuratedModule, CSModule {
    bytes32 public constant OPERATOR_ADDRESSES_ADMIN_ROLE =
        keccak256("OPERATOR_ADDRESSES_ADMIN_ROLE");

    constructor(
        bytes32 moduleType,
        address lidoLocator,
        address parametersRegistry,
        address _accounting, // solhint-disable-line lido-csm/vars-with-underscore
        address exitPenalties
    )
        CSModule(
            moduleType,
            lidoLocator,
            parametersRegistry,
            _accounting,
            exitPenalties
        )
    {}

    function obtainDepositData(
        uint256,
        /* depositsCount */
        bytes calldata /* depositCalldata */
    )
        external
        override(CSModule, IStakingModule)
        onlyRole(STAKING_ROUTER_ROLE)
        returns (bytes memory publicKeys, bytes memory signatures)
    {
        revert ICuratedModule.NotImplemented();
    }

    /// @inheritdoc ICuratedModule
    function changeNodeOperatorAddresses(
        uint256 nodeOperatorId,
        address newManagerAddress,
        address newRewardAddress
    ) external onlyRole(OPERATOR_ADDRESSES_ADMIN_ROLE) {
        NOAddresses.changeNodeOperatorAddresses(
            _nodeOperators,
            nodeOperatorId,
            newManagerAddress,
            newRewardAddress
        );
    }
}
