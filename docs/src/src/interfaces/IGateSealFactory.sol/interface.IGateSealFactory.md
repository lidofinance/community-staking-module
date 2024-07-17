# IGateSealFactory

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/interfaces/IGateSealFactory.sol)

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
