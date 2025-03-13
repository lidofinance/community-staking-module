# CSStrikes
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/CSStrikes.sol)

**Inherits:**
[ICSStrikes](/src/interfaces/ICSStrikes.sol/interface.ICSStrikes.md)

**Author:**
vgorkavenko


## State Variables
### ORACLE

```solidity
address public immutable ORACLE;
```


### EJECTOR

```solidity
ICSEjector public immutable EJECTOR;
```


### treeRoot
The latest Merkle Tree root


```solidity
bytes32 public treeRoot;
```


### treeCid
CID of the last published Merkle tree


```solidity
string public treeCid;
```


## Functions
### constructor


```solidity
constructor(address ejector, address oracle);
```

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


### processBadPerformanceProof

Report Node Operator's key as bad performing

*should be both empty or not empty*


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


### verifyProof

Check if Key is eligible to be ejected


```solidity
function verifyProof(
    uint256 nodeOperatorId,
    bytes memory pubkey,
    uint256[] calldata strikesData,
    bytes32[] calldata proof
) public view returns (bool);
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
function hashLeaf(uint256 nodeOperatorId, bytes memory pubkey, uint256[] calldata strikesData)
    public
    pure
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`pubkey`|`bytes`|pubkey of the Node Operator|
|`strikesData`|`uint256[]`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Hash of the leaf|


### _getSigningKeys


```solidity
function _getSigningKeys(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount)
    internal
    view
    returns (bytes memory keys);
```

