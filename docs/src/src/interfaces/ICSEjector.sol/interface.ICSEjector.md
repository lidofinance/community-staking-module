# ICSEjector
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/interfaces/ICSEjector.sol)

**Inherits:**
[IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md)


## Functions
### PAUSE_ROLE


```solidity
function PAUSE_ROLE() external view returns (bytes32);
```

### RESUME_ROLE


```solidity
function RESUME_ROLE() external view returns (bytes32);
```

### BAD_PERFORMER_EJECTOR_ROLE


```solidity
function BAD_PERFORMER_EJECTOR_ROLE() external view returns (bytes32);
```

### MODULE


```solidity
function MODULE() external view returns (ICSModule);
```

### ACCOUNTING


```solidity
function ACCOUNTING() external view returns (ICSAccounting);
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

### ejectBadPerformer

Report Node Operator's key as bad performer and eject it with corresponding penalty

Called by the `CSStrikes` contract.
See `CSStrikes.processBadPerformanceProof` to use this method permissionless


```solidity
function ejectBadPerformer(uint256 nodeOperatorId, uint256 keyIndex, uint256 strikes) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the withdrawn key in the Node Operator's keys storage|
|`strikes`|`uint256`|Strikes of the Node Operator's validator key|


### isValidatorEjected

Check if the given Node Operator's key is reported as ejected


```solidity
function isValidatorEjected(uint256 nodeOperatorId, uint256 keyIndex) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|index of the key to check|


## Events
### EjectionSubmitted

```solidity
event EjectionSubmitted(uint256 indexed nodeOperatorId, uint256 keyIndex, bytes pubkey);
```

## Errors
### SigningKeysInvalidOffset

```solidity
error SigningKeysInvalidOffset();
```

### AlreadyWithdrawn

```solidity
error AlreadyWithdrawn();
```

### AlreadyEjected

```solidity
error AlreadyEjected();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### NotEnoughStrikesToEject

```solidity
error NotEnoughStrikesToEject();
```

### NodeOperatorDoesNotExist

```solidity
error NodeOperatorDoesNotExist();
```

