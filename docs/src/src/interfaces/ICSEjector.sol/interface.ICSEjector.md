# ICSEjector
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/interfaces/ICSEjector.sol)

**Inherits:**
[IExitTypes](/src/interfaces/IExitTypes.sol/interface.IExitTypes.md)


## Functions
### PAUSE_ROLE


```solidity
function PAUSE_ROLE() external view returns (bytes32);
```

### RESUME_ROLE


```solidity
function RESUME_ROLE() external view returns (bytes32);
```

### STAKING_MODULE_ID


```solidity
function STAKING_MODULE_ID() external view returns (uint256);
```

### MODULE


```solidity
function MODULE() external view returns (ICSModule);
```

### strikes


```solidity
function strikes() external view returns (address);
```

### pauseFor

Pause ejection methods calls


```solidity
function pauseFor(uint256 duration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### resume

Resume ejection methods calls


```solidity
function resume() external;
```

### voluntaryEject

Withdraw the validator key from the Node Operator

Called by the node operator


```solidity
function voluntaryEject(uint256 nodeOperatorId, uint256 startFrom, uint256 keysCount, address refundRecipient)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`startFrom`|`uint256`|Index of the first key to withdraw|
|`keysCount`|`uint256`|Number of keys to withdraw|
|`refundRecipient`|`address`|Address to send the refund to|


### voluntaryEjectByArray

Withdraw the validator key from the Node Operator

Called by the node operator


```solidity
function voluntaryEjectByArray(uint256 nodeOperatorId, uint256[] calldata keyIndices, address refundRecipient)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndices`|`uint256[]`|Array of indices of the keys to withdraw|
|`refundRecipient`|`address`|Address to send the refund to|


### ejectBadPerformer

Eject Node Operator's key as a bad performer

Called by the `CSStrikes` contract.
See `CSStrikes.processBadPerformanceProof` to use this method permissionless


```solidity
function ejectBadPerformer(uint256 nodeOperatorId, bytes calldata publicKeys, address refundRecipient)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKeys`|`bytes`|Concatenated public keys of the Node Operator's validators|
|`refundRecipient`|`address`|Address to send the refund to|


## Errors
### SigningKeysInvalidOffset

```solidity
error SigningKeysInvalidOffset();
```

### AlreadyWithdrawn

```solidity
error AlreadyWithdrawn();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### ZeroStrikesAddress

```solidity
error ZeroStrikesAddress();
```

### NodeOperatorDoesNotExist

```solidity
error NodeOperatorDoesNotExist();
```

### SenderIsNotEligible

```solidity
error SenderIsNotEligible();
```

### SenderIsNotStrikes

```solidity
error SenderIsNotStrikes();
```

