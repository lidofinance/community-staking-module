// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

/**
 * @title Interface for Lido Voting contract
 */
interface IVoting {
    function assignDelegate(address _delegate) external;
}
