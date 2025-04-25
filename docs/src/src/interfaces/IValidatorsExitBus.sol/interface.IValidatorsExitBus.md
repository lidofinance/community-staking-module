# IValidatorsExitBus
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/interfaces/IValidatorsExitBus.sol)


## Functions
### triggerExitsDirectly


```solidity
function triggerExitsDirectly(DirectExitData calldata exitData, address refundRecipient, uint8 exitType)
    external
    payable;
```

## Structs
### DirectExitData

```solidity
struct DirectExitData {
    uint256 stakingModuleId;
    uint256 nodeOperatorId;
    bytes validatorsPubkeys;
}
```

