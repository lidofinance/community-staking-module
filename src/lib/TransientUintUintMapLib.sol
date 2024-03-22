// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

struct TransientUintUintMap {
    // solhint-disable-next-line lido-csm/vars-with-underscore
    bytes32 __ptr; // Basically to get a unique storage slot.
}

using TransientUintUintMapLib for TransientUintUintMap global;

library TransientUintUintMapLib {
    function clear(TransientUintUintMap storage self) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let salt := tload(self.slot)
            mstore(0x00, self.slot) // Load the slot into the scratch space. Can be used to differ to different instances.
            mstore(0x20, salt) // Load the salt into the scratch space.
            tstore(self.slot, keccak256(0x00, 0x40)) // Compute the new salt as the hash of slot and old salt.
        }
    }

    function add(
        TransientUintUintMap storage self,
        uint256 key,
        uint256 value
    ) internal {
        uint256 slot = _slot(self, key);
        /// @solidity memory-safe-assembly
        assembly {
            let v := tload(slot)
            // NOTE: Here's no overflow check.
            v := add(v, value)
            tstore(slot, v)
        }
    }

    function get(
        TransientUintUintMap storage self,
        uint256 key
    ) internal view returns (uint256 v) {
        uint256 slot = _slot(self, key);
        /// @solidity memory-safe-assembly
        assembly {
            v := tload(slot)
        }
    }

    function _slot(
        TransientUintUintMap storage self,
        uint256 key
    ) internal view returns (uint256 slot) {
        // Compute an address in the transient storage in the same manner it works for storage mappings.
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, tload(self.slot))
            mstore(0x20, key)
            slot := keccak256(0x00, 0x40)
        }
    }
}
