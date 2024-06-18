# QueueLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/QueueLib.sol)

**Author:**
madlabman


## Functions
### normalize

External methods


```solidity
function normalize(Queue storage self, mapping(uint256 => NodeOperator) storage nodeOperators, uint256 nodeOperatorId)
    external;
```

### clean


```solidity
function clean(
    Queue storage self,
    mapping(uint256 => NodeOperator) storage nodeOperators,
    TransientUintUintMap storage queueLookup,
    uint256 maxItems
) external returns (uint256 toRemove);
```

### enqueue

Internal methods


```solidity
function enqueue(Queue storage self, uint256 nodeOperatorId, uint256 keysCount) internal returns (Batch added);
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

## Events
### BatchEnqueued

```solidity
event BatchEnqueued(uint256 indexed nodeOperatorId, uint256 count);
```

## Errors
### InvalidIndex

```solidity
error InvalidIndex();
```

### QueueIsEmpty

```solidity
error QueueIsEmpty();
```

### QueueLookupNoLimit

```solidity
error QueueLookupNoLimit();
```

## Structs
### Queue

```solidity
struct Queue {
    uint128 head;
    uint128 length;
    mapping(uint128 => Batch) queue;
}
```

