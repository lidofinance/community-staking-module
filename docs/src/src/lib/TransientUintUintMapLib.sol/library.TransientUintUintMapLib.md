# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/TransientUintUintMapLib.sol)


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

