# IGateSealFactory
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/interfaces/IGateSealFactory.sol)


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

