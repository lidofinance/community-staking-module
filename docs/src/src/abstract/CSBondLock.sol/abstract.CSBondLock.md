# CSBondLock

[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/abstract/CSBondLock.sol)

**Inherits:**
[ICSBondLock](/src/interfaces/ICSBondLock.sol/interface.ICSBondLock.md), Initializable

**Author:**
vgorkavenko

\*Bond lock mechanics abstract contract.
It gives the ability to lock the bond amount of the Node Operator.
There is a period of time during which the module can settle the lock in any way (for example, by penalizing the bond).
After that period, the lock is removed, and the bond amount is considered unlocked.
The contract contains:

- set default bond lock retention period
- get default bond lock retention period
- lock bond
- get locked bond info
- get actual locked bond amount
- reduce locked bond amount
- remove bond lock
  It should be inherited by a module contract or a module-related contract.
  Internal non-view methods should be used in the Module contract with additional requirements (if any).\*

## State Variables

### CS_BOND_LOCK_STORAGE_LOCATION

```solidity
bytes32 private constant CS_BOND_LOCK_STORAGE_LOCATION =
    0x78c5a36767279da056404c09083fca30cf3ea61c442cfaba6669f76a37393f00;
```

### MIN_BOND_LOCK_RETENTION_PERIOD

```solidity
uint256 public immutable MIN_BOND_LOCK_RETENTION_PERIOD;
```

### MAX_BOND_LOCK_RETENTION_PERIOD

```solidity
uint256 public immutable MAX_BOND_LOCK_RETENTION_PERIOD;
```

## Functions

### constructor

```solidity
constructor(uint256 minBondLockRetentionPeriod, uint256 maxBondLockRetentionPeriod);
```

### getBondLockRetentionPeriod

Get default bond lock retention period

```solidity
function getBondLockRetentionPeriod() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                        |
| -------- | --------- | ---------------------------------- |
| `<none>` | `uint256` | Default bond lock retention period |

### getLockedBondInfo

Get information about the locked bond for the given Node Operator

```solidity
function getLockedBondInfo(uint256 nodeOperatorId) public view returns (BondLock memory);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type       | Description      |
| -------- | ---------- | ---------------- |
| `<none>` | `BondLock` | Locked bond info |

### getActualLockedBond

Get amount of the locked bond in ETH (stETH) by the given Node Operator

```solidity
function getActualLockedBond(uint256 nodeOperatorId) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description                      |
| -------- | --------- | -------------------------------- |
| `<none>` | `uint256` | Amount of the actual locked bond |

### \_lock

_Lock bond amount for the given Node Operator until the retention period._

```solidity
function _lock(uint256 nodeOperatorId, uint256 amount) internal;
```

### \_reduceAmount

_Reduce locked bond amount for the given Node Operator without changing retention period_

```solidity
function _reduceAmount(uint256 nodeOperatorId, uint256 amount) internal;
```

### \_remove

_Remove bond lock for the given Node Operator_

```solidity
function _remove(uint256 nodeOperatorId) internal;
```

### \_\_CSBondLock_init

```solidity
function __CSBondLock_init(uint256 retentionPeriod) internal onlyInitializing;
```

### \_setBondLockRetentionPeriod

_Set default bond lock retention period. That period will be sum with the current block timestamp of lock tx_

```solidity
function _setBondLockRetentionPeriod(uint256 retentionPeriod) internal;
```

### \_changeBondLock

```solidity
function _changeBondLock(uint256 nodeOperatorId, uint256 amount, uint256 retentionUntil) private;
```

### \_getCSBondLockStorage

```solidity
function _getCSBondLockStorage() private pure returns (CSBondLockStorage storage $);
```

## Events

### BondLockChanged

```solidity
event BondLockChanged(uint256 indexed nodeOperatorId, uint256 newAmount, uint256 retentionUntil);
```

### BondLockRetentionPeriodChanged

```solidity
event BondLockRetentionPeriodChanged(uint256 retentionPeriod);
```

## Errors

### InvalidBondLockRetentionPeriod

```solidity
error InvalidBondLockRetentionPeriod();
```

### InvalidBondLockAmount

```solidity
error InvalidBondLockAmount();
```

## Structs

### CSBondLockStorage

```solidity
struct CSBondLockStorage {
  uint256 bondLockRetentionPeriod;
  mapping(uint256 nodeOperatorId => BondLock) bondLock;
}
```
