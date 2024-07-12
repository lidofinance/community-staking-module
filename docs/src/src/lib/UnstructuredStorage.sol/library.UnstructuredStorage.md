# UnstructuredStorage
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/lib/UnstructuredStorage.sol)

Aragon Unstructured Storage library


## Functions
### setStorageBool


```solidity
function setStorageBool(bytes32 position, bool data) internal;
```

### setStorageAddress


```solidity
function setStorageAddress(bytes32 position, address data) internal;
```

### setStorageBytes32


```solidity
function setStorageBytes32(bytes32 position, bytes32 data) internal;
```

### setStorageUint256


```solidity
function setStorageUint256(bytes32 position, uint256 data) internal;
```

### getStorageBool


```solidity
function getStorageBool(bytes32 position) internal view returns (bool data);
```

### getStorageAddress


```solidity
function getStorageAddress(bytes32 position) internal view returns (address data);
```

### getStorageBytes32


```solidity
function getStorageBytes32(bytes32 position) internal view returns (bytes32 data);
```

### getStorageUint256


```solidity
function getStorageUint256(bytes32 position) internal view returns (uint256 data);
```

