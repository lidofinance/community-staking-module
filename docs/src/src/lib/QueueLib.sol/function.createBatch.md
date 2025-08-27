# createBatch
[Git Source](https://github.com/lidofinance/community-staking-module/blob/3a4f57c9cf742468b087015f451ef8dce648f719/src/lib/QueueLib.sol)

*Instantiate a new Batch to be added to the queue. The `next` field will be determined upon the enqueue.*

*Parameters are uint256 to make usage easier.*


```solidity
function createBatch(uint256 nodeOperatorId, uint256 keysCount) pure returns (Batch item);
```

