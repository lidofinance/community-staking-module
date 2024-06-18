# IGateSealFactory

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/interfaces/IGateSealFactory.sol)

## Functions

### create_gate_seal

```solidity
function create_gate_seal(
  address sealingCommittee,
  uint256 sealDurationSeconds,
  address[] memory sealables,
  uint256 expiryTimestamp
) external;
```

## Events

### GateSealCreated

```solidity
event GateSealCreated(address gateSeal);
```
