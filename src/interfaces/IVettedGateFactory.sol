// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface IVettedGateFactory {
    event VettedGateCreated(address indexed gate);

    error ZeroImplementationAddress();

    /// @dev address of the VettedGate implementation to be used for the new instances
    /// @return address of the VettedGate implementation
    function VETTED_GATE_IMPL() external view returns (address);

    /// @dev Creates a new VettedGate instance behind the OssifiableProxy based on known implementation address
    /// @param curveId Id of the bond curve to be assigned for the eligible members
    /// @param treeRoot Root of the eligible members Merkle Tree
    /// @param referralsThreshold Number of referrals required for bond curve claim
    /// @param admin Address of the admin role
    function create(
        uint256 curveId,
        bytes32 treeRoot,
        uint256 referralsThreshold,
        address admin
    ) external returns (address instance);
}
