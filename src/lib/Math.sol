// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

error Log2Undefined();

library Math {
    /// @dev From solady FixedPointMath.
    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // revert Log2Undefined()
                mstore(0x00, 0x5be3aa5c)
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // prettier-ignore
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Tests if x ∈ [a, b) (mod n)
    ///
    function pointInHalfOpenIntervalModN(
        uint256 x,
        uint256 a,
        uint256 b,
        uint256 n
    ) internal pure returns (bool) {
        return (x + n - a) % n < (b - a) % n;
    }

    /// @notice Tests if x ∈ [a, b] (mod n)
    ///
    function pointInClosedIntervalModN(
        uint256 x,
        uint256 a,
        uint256 b,
        uint256 n
    ) internal pure returns (bool) {
        return (x + n - a) % n <= (b - a) % n;
    }
}
