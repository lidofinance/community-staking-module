// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

/// @author skhomuti
library ValidatorCountsReport {
    error InvalidReportData();

    function safeCountOperators(
        bytes calldata ids,
        bytes calldata counts
    ) internal pure returns (uint256 count) {
        assembly ("memory-safe") {
            // counts.length / 16 != ids.length / 8
            if iszero(eq(div(counts.length, 16), div(ids.length, 8))) {
                // InvalidReportData
                mstore(0x00, 0xc6726884)
                revert(0x1c, 0x04)
            }

            // counts.length % 16 != 0
            if iszero(iszero(mod(counts.length, 16))) {
                // InvalidReportData
                mstore(0x00, 0xc6726884)
                revert(0x1c, 0x04)
            }

            // ids.length % 8 != 0
            if iszero(iszero(mod(ids.length, 8))) {
                // InvalidReportData
                mstore(0x00, 0xc6726884)
                revert(0x1c, 0x04)
            }

            count := div(ids.length, 8)
        }
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
