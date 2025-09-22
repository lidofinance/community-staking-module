// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

/**
 * @title Interface for Snapshot delegation
 */
interface IDelegation {
    function setDelegate(bytes32 _id, address _delegate) external;
}
