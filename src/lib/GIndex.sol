// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Math } from "./Math.sol";

type GIndex is bytes32;

using {
    isRoot,
    isParentOf,
    index,
    width,
    shr,
    shl,
    concat,
    unwrap
} for GIndex global;

error IndexOutOfRange();

/// @param gI Is a generalized index of a node in a tree.
/// @param p Is a power of a tree level the node belongs to.
/// @return GIndex
function pack(uint256 gI, uint8 p) pure returns (GIndex) {
    if (gI > type(uint248).max) {
        revert IndexOutOfRange();
    }

    // NOTE: We can consider adding additional metadata like a fork version.
    return GIndex.wrap(bytes32((gI << 8) | p));
}

function unwrap(GIndex self) pure returns (bytes32) {
    return GIndex.unwrap(self);
}

function isRoot(GIndex self) pure returns (bool) {
    return index(self) == 1;
}

function index(GIndex self) pure returns (uint256) {
    return uint256(unwrap(self)) >> 8;
}

function width(GIndex self) pure returns (uint256) {
    return 1 << pow(self);
}

function pow(GIndex self) pure returns (uint8) {
    return uint8(uint256(unwrap(self)));
}

/// @return Generalized index of the nth neighbor of the node to the right.
function shr(GIndex self, uint256 n) pure returns (GIndex) {
    uint256 i = index(self);
    uint256 w = width(self);

    if ((i % w) + n >= w) {
        revert IndexOutOfRange();
    }

    return pack(i + n, pow(self));
}

/// @return Generalized index of the nth neighbor of the node to the left.
function shl(GIndex self, uint256 n) pure returns (GIndex) {
    uint256 i = index(self);
    uint256 w = width(self);

    if (i % w < n) {
        revert IndexOutOfRange();
    }

    return pack(i - n, pow(self));
}

// See https://github.com/protolambda/remerkleable/blob/91ed092d08ef0ba5ab076f0a34b0b371623db728/remerkleable/tree.py#L46
function concat(GIndex lhs, GIndex rhs) pure returns (GIndex) {
    uint256 lhsBitLen = Math.log2(index(lhs));
    uint256 rhsBitLen = Math.log2(index(rhs));

    // TODO: Shift operations have no overflow check. Does solidity multiplication have such a check?
    if (lhsBitLen + rhsBitLen > 248) {
        revert IndexOutOfRange();
    }

    return
        pack(
            (index(lhs) << rhsBitLen) | (index(rhs) ^ (1 << rhsBitLen)),
            pow(rhs)
        );
}

function isParentOf(GIndex self, GIndex other) pure returns (bool) {
    uint256 anchor = index(self);
    uint256 gI = index(other);

    if (anchor >= gI) {
        return false;
    }

    while (gI > 0) {
        if (gI == anchor) {
            return true;
        }

        gI = gI >> 1;
    }

    return false;
}
