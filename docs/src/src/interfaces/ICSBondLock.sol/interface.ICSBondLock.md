# ICSBondLock

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/interfaces/ICSBondLock.sol)

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
