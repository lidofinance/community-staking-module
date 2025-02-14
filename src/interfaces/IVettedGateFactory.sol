// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IVettedGateFactory {
    event VettedGateCreated(address indexed gate);

    /// @dev Creates a new VettedGate instance behind the OssifiableProxy
    /// @param csm Address of the Community Staking Module
    /// @param curveId Id of the bond curve to be assigned for the eligible members
    /// @param treeRoot Root of the eligible members Merkle Tree
    /// @param admin Address of the admin role
    function create(
        address csm,
        uint256 curveId,
        bytes32 treeRoot,
        address admin
    ) external returns (address instance);
}
