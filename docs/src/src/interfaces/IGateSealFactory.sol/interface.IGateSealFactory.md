# IGateSealFactory

[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/interfaces/IGateSealFactory.sol)

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
