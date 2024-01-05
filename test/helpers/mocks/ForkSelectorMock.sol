// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { ForkVersion, Slot } from "../../../src/lib/Types.sol";
import { ForkSelector } from "../../../src/ForkSelector.sol";

contract ForkSelectorMock is ForkSelector {
    function usePrater() external {
        this.addForkAtSlot(ForkVersion.wrap(0x03001020), Slot.wrap(5193728));
        this.addForkAtSlot(ForkVersion.wrap(0x04001020), Slot.wrap(7413760));
    }
}
