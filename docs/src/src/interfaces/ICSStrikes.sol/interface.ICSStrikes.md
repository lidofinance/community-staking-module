# ICSStrikes
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/ICSStrikes.sol)


## Functions
### ORACLE


```solidity
function ORACLE() external view returns (address);
```

### treeRoot


```solidity
function treeRoot() external view returns (bytes32);
```

### treeCid


```solidity
function treeCid() external view returns (string calldata);
```

### processBadPerformanceProof

Report Node Operator's key as bad performing


```solidity
function processBadPerformanceProof(
    uint256 nodeOperatorId,
    uint256 keyIndex,
    uint256[] calldata strikesData,
    bytes32[] calldata proof
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the withdrawn key in the Node Operator's keys storage|
|`strikesData`|`uint256[]`|Strikes of the Node Operator's validator key. TODO: value is to be defined (timestamps or refSlots ?)|
|`proof`|`bytes32[]`|Proof of the strikes|


### processOracleReport

Receive the data of the Merkle tree from the Oracle contract and process it

*New tree might be empty and it is valid value because of `strikesLifetime`*


```solidity
function processOracleReport(bytes32 _treeRoot, string calldata _treeCid) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treeRoot`|`bytes32`|Root of the Merkle tree|
|`_treeCid`|`string`|an IPFS CID of the tree|


### verifyProof

Check if Key is eligible to be ejected


```solidity
function verifyProof(
    uint256 nodeOperatorId,
    bytes calldata pubkey,
    uint256[] calldata strikesData,
    bytes32[] calldata proof
) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`pubkey`|`bytes`|Pubkey of the Node Operator|
|`strikesData`|`uint256[]`|Strikes of the Node Operator|
|`proof`|`bytes32[]`|Merkle proof of the leaf|


### hashLeaf

Get a hash of a leaf

*Double hash the leaf to prevent second pre-image attacks*


```solidity
function hashLeaf(uint256 nodeOperatorId, bytes calldata pubkey, uint256[] calldata strikes)
    external
    pure
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`pubkey`|`bytes`|pubkey of the Node Operator|
|`strikes`|`uint256[]`|Strikes of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Hash of the leaf|


## Events
### StrikesDataUpdated
*Emitted when strikes data is updated*


```solidity
event StrikesDataUpdated(bytes32 treeRoot, string treeCid);
```

### StrikesDataWiped
*Emitted when strikes is updated from non-empty to empty*


```solidity
event StrikesDataWiped();
```

## Errors
### ZeroEjectorAddress

```solidity
error ZeroEjectorAddress();
```

### ZeroOracleAddress

```solidity
error ZeroOracleAddress();
```

### ZeroEjectionFeeAmount

```solidity
error ZeroEjectionFeeAmount();
```

### ZeroBadPerformancePenaltyAmount

```solidity
error ZeroBadPerformancePenaltyAmount();
```

### NotOracle

```solidity
error NotOracle();
```

### InvalidReportData

```solidity
error InvalidReportData();
```

### InvalidProof

```solidity
error InvalidProof();
```

