// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/// @author madlabman
library Batch {
    /// @notice Serialize node operator id and batch start and end epochs into a single bytes32 value
    function serialize(
        uint128 nodeOperatorId,
        uint64 start,
        uint64 end
    ) internal pure returns (bytes32 s) {
        return bytes32(abi.encodePacked(nodeOperatorId, start, end));
    }

    /// @notice Deserialize node operator id and batch start and end epochs from a single bytes32 value
    function deserialize(
        bytes32 b
    ) internal pure returns (uint128 nodeOperatorId, uint64 start, uint64 end) {
        assembly {
            nodeOperatorId := shr(128, b)
            start := shr(64, b)
            end := b
        }
    }

    function isNil(bytes32 b) internal pure returns (bool) {
        return b == bytes32(0);
    }
}
