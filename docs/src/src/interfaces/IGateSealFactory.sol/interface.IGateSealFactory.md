# IGateSealFactory
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/IGateSealFactory.sol)


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

