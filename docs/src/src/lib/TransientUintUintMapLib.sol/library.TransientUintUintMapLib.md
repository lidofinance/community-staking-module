# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/lib/TransientUintUintMapLib.sol)


## Functions
### create


```solidity
function create() internal returns (TransientUintUintMap self);
```

### add


```solidity
function add(TransientUintUintMap self, uint256 key, uint256 value) internal;
```

### get


```solidity
function get(TransientUintUintMap self, uint256 key) internal view returns (uint256 v);
```

### _slot


```solidity
function _slot(TransientUintUintMap self, uint256 key) internal pure returns (uint256 slot);
```

