// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
pragma solidity 0.8.24;

/// @title Library for manage operator keys in storage
/// @author KRogLA
library SigningKeys {
    using SigningKeys for bytes32;

    bytes32 internal constant SIGNING_KEYS_POSITION =
        keccak256("lido.CommunityStakingModule.signingKeysPosition");

    uint64 internal constant PUBKEY_LENGTH = 48;
    uint64 internal constant SIGNATURE_LENGTH = 96;
    uint256 internal constant UINT64_MAX = 0xFFFFFFFFFFFFFFFF;

    event SigningKeyAdded(uint256 indexed nodeOperatorId, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);

    error InvalidKeysCount();
    error InvalidLength();
    error EmptyKey();

    /// @dev store operator keys to storage
    /// @param nodeOperatorId operator id
    /// @param startIndex start index
    /// @param keysCount keys count to load
    /// @param pubkeys keys buffer to read from
    /// @param signatures signatures buffer to read from
    /// @return new total keys count
    // TODO: Rewrite pubkeys and signatures to calldata
    function saveKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        bytes memory pubkeys,
        bytes memory signatures
    ) internal returns (uint256) {
        if (keysCount == 0 || startIndex + keysCount > UINT64_MAX) {
            revert InvalidKeysCount();
        }
        unchecked {
            if (
                pubkeys.length != keysCount * PUBKEY_LENGTH ||
                signatures.length != keysCount * SIGNATURE_LENGTH
            ) {
                revert InvalidLength();
            }
        }

        uint256 curOffset;
        bool isEmpty;
        bytes memory tmpKey = new bytes(48);

        for (uint256 i; i < keysCount; ) {
            curOffset = SIGNING_KEYS_POSITION.getKeyOffset(
                nodeOperatorId,
                startIndex
            );
            assembly {
                let _ofs := add(add(pubkeys, 0x20), mul(i, 48)) //PUBKEY_LENGTH = 48
                let _part1 := mload(_ofs) // bytes 0..31
                let _part2 := mload(add(_ofs, 0x10)) // bytes 16..47
                isEmpty := iszero(or(_part1, _part2))
                mstore(add(tmpKey, 0x30), _part2) // store 2nd part first
                mstore(add(tmpKey, 0x20), _part1) // store 1st part with overwrite bytes 16-31
            }

            if (isEmpty) {
                revert EmptyKey();
            }

            assembly {
                // store key
                sstore(curOffset, mload(add(tmpKey, 0x20))) // store bytes 0..31
                sstore(add(curOffset, 1), shl(128, mload(add(tmpKey, 0x30)))) // store bytes 32..47
                // store signature
                let _ofs := add(add(signatures, 0x20), mul(i, 96)) //SIGNATURE_LENGTH = 96
                sstore(add(curOffset, 2), mload(_ofs))
                sstore(add(curOffset, 3), mload(add(_ofs, 0x20)))
                sstore(add(curOffset, 4), mload(add(_ofs, 0x40)))
                i := add(i, 1)
                startIndex := add(startIndex, 1)
            }
            emit SigningKeyAdded(nodeOperatorId, tmpKey);
        }
        return startIndex;
    }

    /// @dev remove operator keys from storage
    /// @param nodeOperatorId operator id
    /// @param startIndex start index
    /// @param keysCount keys count to load
    /// @param totalKeysCount current total keys count for operator
    /// @return new total keys count
    function removeKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint256 totalKeysCount
    ) internal returns (uint256) {
        if (
            keysCount == 0 ||
            startIndex + keysCount > totalKeysCount ||
            totalKeysCount > UINT64_MAX
        ) {
            revert InvalidKeysCount();
        }

        uint256 curOffset;
        uint256 lastOffset;
        uint256 j;
        bytes memory tmpKey = new bytes(48);
        // removing from the last index
        for (uint256 i = startIndex + keysCount; i > startIndex; ) {
            unchecked {
                curOffset = SIGNING_KEYS_POSITION.getKeyOffset(
                    nodeOperatorId,
                    i - 1
                );
            }
            assembly {
                // read key
                mstore(add(tmpKey, 0x30), shr(128, sload(add(curOffset, 1)))) // bytes 16..47
                mstore(add(tmpKey, 0x20), sload(curOffset)) // bytes 0..31
            }
            if (i < totalKeysCount) {
                unchecked {
                    lastOffset = SIGNING_KEYS_POSITION.getKeyOffset(
                        nodeOperatorId,
                        totalKeysCount - 1
                    );
                }
                // move last key to deleted key index
                for (j = 0; j < 5; ) {
                    // load 160 bytes (5 slots) containing key and signature
                    assembly {
                        sstore(add(curOffset, j), sload(add(lastOffset, j)))
                        j := add(j, 1)
                    }
                }
                curOffset = lastOffset;
            }
            // clear storage
            for (j = 0; j < 5; ) {
                assembly {
                    sstore(add(curOffset, j), 0)
                    j := add(j, 1)
                }
            }
            assembly {
                totalKeysCount := sub(totalKeysCount, 1)
                i := sub(i, 1)
            }
            emit SigningKeyRemoved(nodeOperatorId, tmpKey);
        }
        return totalKeysCount;
    }

    /// @dev load operator keys and signatures from storage
    /// @param nodeOperatorId operator id
    /// @param startIndex start index
    /// @param keysCount keys count to load
    /// @param pubkeys preallocated kes buffer to read in
    /// @param signatures preallocated signatures buffer to read in
    /// @param bufOffset start offset in `_pubkeys`/`_signatures` buffer to place values (in number of keys)
    function loadKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        bytes memory pubkeys,
        bytes memory signatures,
        uint256 bufOffset
    ) internal view {
        uint256 curOffset;
        for (uint256 i; i < keysCount; ) {
            curOffset = SIGNING_KEYS_POSITION.getKeyOffset(
                nodeOperatorId,
                startIndex + i
            );
            assembly {
                // read key
                let _ofs := add(add(pubkeys, 0x20), mul(add(bufOffset, i), 48)) // PUBKEY_LENGTH = 48
                mstore(add(_ofs, 0x10), shr(128, sload(add(curOffset, 1)))) // bytes 16..47
                mstore(_ofs, sload(curOffset)) // bytes 0..31
                // store signature
                _ofs := add(add(signatures, 0x20), mul(add(bufOffset, i), 96)) // SIGNATURE_LENGTH = 96
                mstore(_ofs, sload(add(curOffset, 2)))
                mstore(add(_ofs, 0x20), sload(add(curOffset, 3)))
                mstore(add(_ofs, 0x40), sload(add(curOffset, 4)))
                i := add(i, 1)
            }
        }
    }

    function loadKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) internal view returns (bytes memory pubkeys) {
        uint256 curOffset;

        pubkeys = new bytes(keysCount * PUBKEY_LENGTH);
        for (uint256 i; i < keysCount; ) {
            curOffset = SIGNING_KEYS_POSITION.getKeyOffset(
                nodeOperatorId,
                startIndex + i
            );
            assembly {
                // read key
                let offset := add(add(pubkeys, 0x20), mul(i, 48)) // PUBKEY_LENGTH = 48
                mstore(add(offset, 0x10), shr(128, sload(add(curOffset, 1)))) // bytes 16..47
                mstore(offset, sload(curOffset)) // bytes 0..31
                i := add(i, 1)
            }
        }
    }

    function initKeysSigsBuf(
        uint256 count
    ) internal pure returns (bytes memory, bytes memory) {
        return (
            new bytes(count * PUBKEY_LENGTH),
            new bytes(count * SIGNATURE_LENGTH)
        );
    }

    function getKeyOffset(
        bytes32 position,
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(position, nodeOperatorId, keyIndex))
            );
    }
}
