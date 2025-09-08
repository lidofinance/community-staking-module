# ICSBondLock
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSBondLock.sol)


## Functions
### MIN_BOND_LOCK_PERIOD


```solidity
function MIN_BOND_LOCK_PERIOD() external view returns (uint256);
```

### MAX_BOND_LOCK_PERIOD


```solidity
function MAX_BOND_LOCK_PERIOD() external view returns (uint256);
```

### getBondLockPeriod

Get default bond lock period


```solidity
function getBondLockPeriod() external view returns (uint256 period);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`period`|`uint256`|Default bond lock period|


### getLockedBondInfo

Get information about the locked bond for the given Node Operator


```solidity
function getLockedBondInfo(uint256 nodeOperatorId) external view returns (BondLock memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`BondLock`|Locked bond info|


### getActualLockedBond

Get amount of the locked bond in ETH (stETH) by the given Node Operator


```solidity
function getActualLockedBond(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of the actual locked bond|


## Events
### BondLockChanged

```solidity
event BondLockChanged(uint256 indexed nodeOperatorId, uint256 newAmount, uint256 until);
```

### BondLockRemoved

```solidity
event BondLockRemoved(uint256 indexed nodeOperatorId);
```

### BondLockPeriodChanged

```solidity
event BondLockPeriodChanged(uint256 period);
```

## Errors
### InvalidBondLockPeriod

```solidity
error InvalidBondLockPeriod();
```

### InvalidBondLockAmount

```solidity
error InvalidBondLockAmount();
```

## Structs
### BondLock
*Bond lock structure.
It contains:
- amount   |> amount of locked bond
- until    |> timestamp until locked bond is retained*


```solidity
struct BondLock {
    uint128 amount;
    uint128 until;
}
```

