# IGateSealFactory
[Git Source](https://github.com/lidofinance/community-staking-module/blob/3a4f57c9cf742468b087015f451ef8dce648f719/src/interfaces/IGateSealFactory.sol)


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

