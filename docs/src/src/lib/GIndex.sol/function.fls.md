# fls
[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/lib/GIndex.sol)

*From Solady LibBit, see https://github.com/Vectorized/solady/blob/main/src/utils/LibBit.sol.*

*Find last set.
Returns the index of the most significant bit of `x`,
counting from the least significant bit position.
If `x` is zero, returns 256.*


```solidity
function fls(uint256 x) pure returns (uint256 r);
```

