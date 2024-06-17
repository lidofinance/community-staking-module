# NodeOperator

[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/interfaces/ICSModule.sol)

```solidity
struct NodeOperator {
  uint32 totalAddedKeys;
  uint32 totalWithdrawnKeys;
  uint32 totalDepositedKeys;
  uint32 totalVettedKeys;
  uint32 stuckValidatorsCount;
  uint32 depositableValidatorsCount;
  uint32 targetLimit;
  uint8 targetLimitMode;
  uint32 totalExitedKeys;
  uint32 enqueuedCount;
  address managerAddress;
  address proposedManagerAddress;
  address rewardAddress;
  address proposedRewardAddress;
}
```
