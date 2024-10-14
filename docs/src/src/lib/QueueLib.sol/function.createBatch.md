# createBatch
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/lib/QueueLib.sol)

*Instantiate a new Batch to be added to the queue. The `next` field will be determined upon the enqueue.*

*Parameters are uint256 to make usage easier.*


```solidity
function createBatch(uint256 nodeOperatorId, uint256 keysCount) pure returns (Batch item);
```

