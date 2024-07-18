# TransientUintUintMapLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/lib/TransientUintUintMapLib.sol)


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

