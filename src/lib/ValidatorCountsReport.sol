// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

/// @author skhomuti
library ValidatorCountsReport {
    error InvalidReportData();

    function safeCountOperators(
        bytes calldata ids,
        bytes calldata counts
    ) internal pure returns (uint256) {
        if (
            counts.length / 16 != ids.length / 8 ||
            ids.length % 8 != 0 ||
            counts.length % 16 != 0
        ) {
            revert InvalidReportData();
        }

        return ids.length / 8;
    }

    function next(
        bytes calldata ids,
        bytes calldata counts,
        uint256 offset
    ) internal pure returns (uint256 nodeOperatorId, uint256 keysCount) {
        // prettier-ignore
        assembly ("memory-safe") {
            nodeOperatorId := shr(192, calldataload(add(ids.offset, mul(offset, 8))))
            keysCount := shr(128, calldataload(add(counts.offset, mul(offset, 16))))
        }
    }
}
