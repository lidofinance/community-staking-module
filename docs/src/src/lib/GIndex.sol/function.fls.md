# fls
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/GIndex.sol)

*From Solady LibBit, see https://github.com/Vectorized/solady/blob/main/src/utils/LibBit.sol.*

*Find last set.
Returns the index of the most significant bit of `x`,
counting from the least significant bit position.
If `x` is zero, returns 256.*


```solidity
function fls(uint256 x) pure returns (uint256 r);
```
