# UnstructuredStorage
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/lib/UnstructuredStorage.sol)

Aragon Unstructured Storage library


## Functions
### setStorageAddress


```solidity
function setStorageAddress(bytes32 position, address data) internal;
```

### setStorageUint256


```solidity
function setStorageUint256(bytes32 position, uint256 data) internal;
```

### getStorageAddress


```solidity
function getStorageAddress(bytes32 position) internal view returns (address data);
```

### getStorageUint256


```solidity
function getStorageUint256(bytes32 position) internal view returns (uint256 data);
```

