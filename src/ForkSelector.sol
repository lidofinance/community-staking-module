// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IForkSelector } from "./interfaces/IForkSelector.sol";
import { ForkVersion, Slot } from "./lib/Types.sol";

contract ForkSelector is IForkSelector {
    ForkVersion[] public supportedVersions;
    Slot[] public versionsLookup;
    Slot public terminalSlot = Slot.wrap(type(uint64).max);

    address internal _admin;

    error NoSuitableForkVersion(Slot slot);
    error UnexpectedOrder();
    error Unauthorized(address sender);
    error ZeroAddress();
    error Ossified();

    function initialize(address admin) external {
        if (admin == address(0)) {
            revert ZeroAddress();
        }

        _admin = admin;
    }

    /// @dev If any fork introduces a changed generalized index, we need to add it here.
    /// @dev The list of `versionsLookup` is expected to be sorted in ascending order.
    function addForkAtSlot(ForkVersion fork, Slot slot) external onlyAdmin {
        // Allow adding forks at slots before the terminal slot.
        if (Slot.unwrap(slot) > Slot.unwrap(terminalSlot)) {
            revert Ossified();
        }

        if (
            versionsLookup.length > 0 &&
            Slot.unwrap(versionsLookup[versionsLookup.length - 1]) >=
            Slot.unwrap(slot)
        ) {
            revert UnexpectedOrder();
        }

        supportedVersions.push(fork);
        versionsLookup.push(slot);
    }

    function ossifyAtSlot(Slot slot) external onlyAdmin notOssified {
        terminalSlot = slot;
    }

    /// @dev returns the fork version suitable for the given slot number given the requirements to generalized indices.
    function findFork(Slot slot) external view returns (ForkVersion) {
        if (Slot.unwrap(slot) > Slot.unwrap(terminalSlot)) {
            revert NoSuitableForkVersion(slot);
        }

        for (uint256 i = versionsLookup.length; i > 0; i--) {
            if (Slot.unwrap(slot) > Slot.unwrap(versionsLookup[i - 1])) {
                return supportedVersions[i - 1];
            }
        }

        // Basically, too old slot provided.
        revert NoSuitableForkVersion(slot);
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert Unauthorized(msg.sender);
        }
        _;
    }

    modifier notOssified() {
        if (Slot.unwrap(terminalSlot) != type(uint64).max) {
            revert Ossified();
        }
        _;
    }
}
