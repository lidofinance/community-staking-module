# IGateSealFactory

[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/interfaces/IGateSealFactory.sol)

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
