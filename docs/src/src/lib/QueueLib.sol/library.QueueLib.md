# QueueLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/lib/QueueLib.sol)

**Author:**
madlabman


## Functions
### clean

External methods


```solidity
function clean(
    Queue storage self,
    mapping(uint256 => NodeOperator) storage nodeOperators,
    uint256 maxItems,
    TransientUintUintMap queueLookup
) external returns (uint256 removed, uint256 lastRemovedAtDepth, uint256 visited, bool isFinished);
```

### enqueue

Internal methods


```solidity
function enqueue(Queue storage self, uint256 nodeOperatorId, uint256 keysCount) internal returns (Batch item);
```

### dequeue


```solidity
function dequeue(Queue storage self) internal returns (Batch item);
```

### peek


```solidity
function peek(Queue storage self) internal view returns (Batch);
```

### at


```solidity
function at(Queue storage self, uint128 index) internal view returns (Batch);
```

## Structs
### Queue

```solidity
struct Queue {
    uint128 head;
    uint128 tail;
    mapping(uint128 => Batch) queue;
}
```

