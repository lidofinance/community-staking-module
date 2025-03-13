# IGateSealFactory
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/IGateSealFactory.sol)


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

