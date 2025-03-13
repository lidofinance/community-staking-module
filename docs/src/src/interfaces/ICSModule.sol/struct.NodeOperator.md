# NodeOperator
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/ICSModule.sol)


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
    bool extendedManagerPermissions;
    bool usedPriorityQueue;
}
```

