# createBatch
[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/lib/QueueLib.sol)

*Instantiate a new Batch to be added to the queue. The `next` field will be determined upon the enqueue.*

*Parameters are uint256 to make usage easier.*


```solidity
function createBatch(uint256 nodeOperatorId, uint256 keysCount) pure returns (Batch item);
```

