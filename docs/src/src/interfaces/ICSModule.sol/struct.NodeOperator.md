# NodeOperator

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/interfaces/ICSModule.sol)

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
