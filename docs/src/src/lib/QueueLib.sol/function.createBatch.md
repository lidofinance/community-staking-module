# createBatch
[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/lib/QueueLib.sol)

*Instantiate a new Batch to be added to the queue. The `next` field will be determined upon the enqueue.*

*Parameters are uint256 to make usage easier.*


```solidity
function createBatch(uint256 nodeOperatorId, uint256 keysCount) pure returns (Batch item);
```

