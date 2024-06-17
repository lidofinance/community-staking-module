# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/lib/TransientUintUintMapLib.sol)


## Functions
### clear


```solidity
function clear(TransientUintUintMap storage self) internal;
```

### add


```solidity
function add(TransientUintUintMap storage self, uint256 key, uint256 value) internal;
```

### get


```solidity
function get(TransientUintUintMap storage self, uint256 key) internal view returns (uint256 v);
```

### _slot


```solidity
function _slot(TransientUintUintMap storage self, uint256 key) internal view returns (uint256 slot);
```

