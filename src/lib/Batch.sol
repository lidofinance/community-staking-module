// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

/// @author madlabman
library Batch {
    /// @notice Serialize node operator id, batch start and count of keys into a single bytes32 value
    function serialize(
        uint64 nodeOperatorId,
        uint64 start,
        uint64 count,
        uint64 nonce
    ) internal pure returns (bytes32 s) {
        return bytes32(abi.encodePacked(nodeOperatorId, start, count, nonce));
    }

    /// @notice Deserialize node operator id, batch start and count of keys from a single bytes32 value
    function deserialize(
        bytes32 b
    )
        internal
        pure
        returns (
            uint64 nodeOperatorId,
            uint64 start,
            uint64 count,
            uint64 nonce
        )
    {
        assembly {
            nodeOperatorId := shr(192, b)
            start := shr(128, b)
            count := shr(64, b)
            nonce := b
        }
    }

    function isNil(bytes32 b) internal pure returns (bool) {
        return b == bytes32(0);
    }
}
