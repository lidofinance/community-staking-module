// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { GIndex } from "./lib/GIndex.sol";
import { ForkVersion } from "./lib/Types.sol";
import { UnstructuredStorage } from "./lib/UnstructuredStorage.sol";

import { IGIProvider } from "./interfaces/IGIProvider.sol";

contract GIProvider is IGIProvider {
    using UnstructuredStorage for bytes32;

    struct KV {
        string key;
        GIndex value;
    }

    error Undefined();

    function initialize() external {
        // FIXME: implement.
        // Set admin.
    }

    /// @notice For a given `fork` add 'key -> gindex' values this provider supposed to serve.
    function patchFork(ForkVersion fork, KV[] memory map) external onlyDao {
        for (uint256 i = 0; i < map.length; ) {
            bytes32 position = _getStorageSlot(fork, map[i].key);
            position.setStorageBytes32(map[i].value.unwrap());

            unchecked {
                i++;
            }
        }
    }

    /// @dev key is a jq-like path relative to the first-segment data structure, e.g. `BeaconState.validators[0]` or
    /// `BeaconState.historical_summaries` and `HistoricalSummary.state_summary_root`. If the final segment in the path
    /// is not a primitive type, index is supposed to be an index of a root of the underlying structure. For lists it's
    /// convenient to store an index of the first element to simplify calculation of the index of the i-th element.
    function getIndex(
        ForkVersion fork,
        string memory key
    ) external view returns (GIndex) {
        bytes32 position = _getStorageSlot(fork, key);
        bytes32 value = position.getStorageBytes32();
        if (value == bytes32(0)) {
            revert Undefined();
        }

        return GIndex.wrap(value);
    }

    function _getStorageSlot(
        ForkVersion fork,
        string memory key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(fork, key));
    }

    modifier onlyDao() {
        // FIXME: implement.
        _;
    }
}
