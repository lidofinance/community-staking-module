// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/// @author madlabman
contract FeeOracleBase is Pausable {
    error AlreadyMember(address member);
    error NotMember(address member);

    error InvalidEpoch(uint64 actual, uint64 expected);
    error ZeroAddress(string field);
    error GenesisTimeNotReached();
    error AlreadyInitialized();
    error NotInitialized();
    error QuorumTooSmall();
    error ReportTooEarly();
    error ReportTooLate();
    error ZeroInterval();
    error DoubleVote();

    event ReportIntervalSet(uint64 reportInterval);
    event MemberRemoved(address member);
    event MemberAdded(address member);
    event QuorumSet(uint64 quorum);

    /// @dev Emitted when a report is submitted
    event ReportSubmitted(
        uint256 indexed epoch,
        address oracleMember,
        bytes32 newRoot,
        string treeCid
    );

    /// @dev Emitted when a report is consolidated
    // forgefmt: disable-next-item
    event ReportConsolidated(
        uint256 indexed epoch,
        bytes32 newRoot,
        string treeCid
    );
}
