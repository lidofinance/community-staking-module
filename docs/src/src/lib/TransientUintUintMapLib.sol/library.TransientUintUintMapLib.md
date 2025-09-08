# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/3a4f57c9cf742468b087015f451ef8dce648f719/src/lib/TransientUintUintMapLib.sol)


## Functions
### create


```solidity
function create() internal returns (TransientUintUintMap self);
```

### add


```solidity
function add(TransientUintUintMap self, uint256 key, uint256 value) internal;
```

### set


```solidity
function set(TransientUintUintMap self, uint256 key, uint256 value) internal;
```

### get


```solidity
function get(TransientUintUintMap self, uint256 key) internal view returns (uint256 v);
```

### load


```solidity
function load(bytes32 tslot) internal pure returns (TransientUintUintMap self);
```

### _slot


```solidity
function _slot(TransientUintUintMap self, uint256 key) internal pure returns (uint256 slot);
```

