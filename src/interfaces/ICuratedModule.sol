// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSModule } from "./ICSModule.sol";

interface ICuratedModule is ICSModule {
    error NotImplemented();

    function NODE_OWNER_ADMIN_ROLE() external view returns (bytes32);

    /// @notice Change both reward and manager addresses of a node operator.
    /// @param nodeOperatorId ID of the Node Operator
    /// @param newManagerAddress New manager address
    /// @param newRewardAddress New reward address
    function changeNodeOperatorAddresses(
        uint256 nodeOperatorId,
        address newManagerAddress,
        address newRewardAddress
    ) external;
}
