// SPDX-FileCopyrightText: 2026 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.33;

import { UnstructuredStorage } from "./UnstructuredStorage.sol";
import { ICuratedModule } from "../interfaces/ICuratedModule.sol";

library TopUpAllocationLib {
    using UnstructuredStorage for bytes32;

    bytes32 private constant TOP_UP_ALLOCATION_ENABLED_POSITION =
        keccak256("lido.CuratedModule.topUpAllocationEnabled");

    function setState(uint256 nodeOperatorId, bool enabled) internal {
        bytes32 slot = _enabledSlot(nodeOperatorId);
        uint256 value = enabled ? 1 : 0;
        if (slot.getStorageUint256() == value) revert ICuratedModule.TopUpAllocationStateUnchanged();
        slot.setStorageUint256(value);
    }

    function isEnabled(uint256 nodeOperatorId) internal view returns (bool) {
        return _enabledSlot(nodeOperatorId).getStorageUint256() != 0;
    }

    function _enabledSlot(uint256 nodeOperatorId) private pure returns (bytes32) {
        return keccak256(abi.encode(nodeOperatorId, TOP_UP_ALLOCATION_ENABLED_POSITION));
    }
}
