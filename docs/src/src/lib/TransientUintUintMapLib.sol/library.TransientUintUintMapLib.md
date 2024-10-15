# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/lib/TransientUintUintMapLib.sol)


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

