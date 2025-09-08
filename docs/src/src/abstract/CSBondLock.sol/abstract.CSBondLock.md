# CSBondLock
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/abstract/CSBondLock.sol)

**Inherits:**
[ICSBondLock](/src/interfaces/ICSBondLock.sol/interface.ICSBondLock.md), Initializable

**Author:**
vgorkavenko

*Bond lock mechanics abstract contract.
It gives the ability to lock the bond amount of the Node Operator.
There is a period of time during which the module can settle the lock in any way (for example, by penalizing the bond).
After that period, the lock is removed, and the bond amount is considered unlocked.
The contract contains:
- set default bond lock period
- get default bond lock period
- lock bond
- get locked bond info
- get actual locked bond amount
- reduce locked bond amount
- remove bond lock
It should be inherited by a module contract or a module-related contract.
Internal non-view methods should be used in the Module contract with additional requirements (if any).*


## State Variables
### CS_BOND_LOCK_STORAGE_LOCATION

```solidity
bytes32 private constant CS_BOND_LOCK_STORAGE_LOCATION =
    0x78c5a36767279da056404c09083fca30cf3ea61c442cfaba6669f76a37393f00;
```


### MIN_BOND_LOCK_PERIOD

```solidity
uint256 public immutable MIN_BOND_LOCK_PERIOD;
```


### MAX_BOND_LOCK_PERIOD

```solidity
uint256 public immutable MAX_BOND_LOCK_PERIOD;
```


## Functions
### constructor


```solidity
constructor(uint256 minBondLockPeriod, uint256 maxBondLockPeriod);
```

### getBondLockPeriod

Get default bond lock period


```solidity
function getBondLockPeriod() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|period Default bond lock period|


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
function getActualLockedBond(uint256 nodeOperatorId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of the actual locked bond|


### _lock

*Lock bond amount for the given Node Operator until the period.*


```solidity
function _lock(uint256 nodeOperatorId, uint256 amount) internal;
```

### _reduceAmount

*Reduce the locked bond amount for the given Node Operator without changing the lock period*


```solidity
function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal;
```

### _remove

*Remove bond lock for the given Node Operator*


```solidity
function _remove(uint256 nodeOperatorId) internal;
```

### __CSBondLock_init


```solidity
function __CSBondLock_init(uint256 period) internal onlyInitializing;
```

### _setBondLockPeriod

*Set default bond lock period. That period will be added to the block timestamp of the lock translation to determine the bond lock duration*


```solidity
function _setBondLockPeriod(uint256 period) internal;
```

### _changeBondLock


```solidity
function _changeBondLock(uint256 nodeOperatorId, uint256 amount, uint256 until) private;
```

### _getCSBondLockStorage


```solidity
function _getCSBondLockStorage() private pure returns (CSBondLockStorage storage $);
```

## Structs
### CSBondLockStorage
**Note:**
storage-location: erc7201:CSBondLock


```solidity
struct CSBondLockStorage {
    uint256 bondLockPeriod;
    mapping(uint256 nodeOperatorId => BondLock) bondLock;
}
```

