# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/lib/TransientUintUintMapLib.sol)


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

