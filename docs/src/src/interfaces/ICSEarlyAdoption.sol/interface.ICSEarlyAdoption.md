# ICSEarlyAdoption
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/ICSEarlyAdoption.sol)

Legacy interface for the early adoption contract
Used only in scripts and tests


## Functions
### CURVE_ID


```solidity
function CURVE_ID() external view returns (uint256);
```

### TREE_ROOT


```solidity
function TREE_ROOT() external view returns (bytes32);
```

### MODULE


```solidity
function MODULE() external view returns (address);
```

### verifyProof

Check is the address is eligible to consume EA access


```solidity
function verifyProof(address member, bytes32[] calldata proof) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|Address to check|
|`proof`|`bytes32[]`|Merkle proof of EA eligibility|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Boolean flag if the proof is valid or not|


### consume

Validate EA eligibility proof and mark it as consumed

*Called only by the module*


```solidity
function consume(address member, bytes32[] calldata proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|Address to be verified alongside the proof|
|`proof`|`bytes32[]`|Merkle proof of EA eligibility|


### isConsumed

Check if the address has already consumed EA access


```solidity
function isConsumed(address member) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|Address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Consumed flag|


### hashLeaf

Get a hash of a leaf in EA Merkle tree

*Double hash the leaf to prevent second preimage attacks*


```solidity
function hashLeaf(address member) external pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|EA member address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Hash of the leaf|


## Events
### Consumed

```solidity
event Consumed(address indexed member);
```

## Errors
### InvalidProof

```solidity
error InvalidProof();
```

### AlreadyConsumed

```solidity
error AlreadyConsumed();
```

### InvalidTreeRoot

```solidity
error InvalidTreeRoot();
```

### InvalidCurveId

```solidity
error InvalidCurveId();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### SenderIsNotModule

```solidity
error SenderIsNotModule();
```

