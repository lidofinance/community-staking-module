# ICSBondLock

[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/interfaces/ICSBondLock.sol)

## Functions

### getBondLockRetentionPeriod

```solidity
function getBondLockRetentionPeriod() external view returns (uint256 retention);
```

### getLockedBondInfo

```solidity
function getLockedBondInfo(uint256 nodeOperatorId) external view returns (BondLock memory);
```

### getActualLockedBond

```solidity
function getActualLockedBond(uint256 nodeOperatorId) external view returns (uint256);
```

## Structs

### BondLock

\*Bond lock structure.
It contains:

- amount |> amount of locked bond
- retentionUntil |> timestamp until locked bond is retained\*

```solidity
struct BondLock {
  uint128 amount;
  uint128 retentionUntil;
}
```
