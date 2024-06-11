// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

// As defined in phase0/beacon-chain.md:159
type Slot is uint64;

function unwrap(Slot slot) pure returns (uint64 unwraped) {
    unwraped = Slot.unwrap(slot);
}

using { unwrap } for Slot global;

// As defined in capella/beacon-chain.md:99
struct Withdrawal {
    uint64 index;
    uint64 validatorIndex;
    address withdrawalAddress;
    uint64 amount;
}

// As defined in phase0/beacon-chain.md:356
struct Validator {
    bytes pubkey;
    bytes32 withdrawalCredentials;
    uint64 effectiveBalance;
    bool slashed;
    uint64 activationEligibilityEpoch;
    uint64 activationEpoch;
    uint64 exitEpoch;
    uint64 withdrawableEpoch;
}

// As defined in phase0/beacon-chain.md:436
struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}
