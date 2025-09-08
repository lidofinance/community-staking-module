# ICSStrikes
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSStrikes.sol)


## Functions
### ORACLE


```solidity
function ORACLE() external view returns (address);
```

### MODULE


```solidity
function MODULE() external view returns (ICSModule);
```

### ACCOUNTING


```solidity
function ACCOUNTING() external view returns (ICSAccounting);
```

### EXIT_PENALTIES


```solidity
function EXIT_PENALTIES() external view returns (ICSExitPenalties);
```

### PARAMETERS_REGISTRY


```solidity
function PARAMETERS_REGISTRY() external view returns (ICSParametersRegistry);
```

### ejector


```solidity
function ejector() external view returns (ICSEjector);
```

### treeRoot


```solidity
function treeRoot() external view returns (bytes32);
```

### treeCid


```solidity
function treeCid() external view returns (string calldata);
```

### setEjector

Set the address of the Ejector contract


```solidity
function setEjector(address _ejector) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_ejector`|`address`|Address of the Ejector contract|


### processBadPerformanceProof

Report multiple CSM keys as bad performing


```solidity
function processBadPerformanceProof(
    KeyStrikes[] calldata keyStrikesList,
    bytes32[] calldata proof,
    bool[] calldata proofFlags,
    address refundRecipient
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keyStrikesList`|`KeyStrikes[]`|List of KeyStrikes structs|
|`proof`|`bytes32[]`|Multi-proof of the strikes|
|`proofFlags`|`bool[]`|Flags to process the multi-proof, see OZ `processMultiProof`|
|`refundRecipient`|`address`|Address to send the refund to|


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

Check the contract accepts the provided multi-proof


```solidity
function verifyProof(
    KeyStrikes[] calldata keyStrikesList,
    bytes[] memory pubkeys,
    bytes32[] calldata proof,
    bool[] calldata proofFlags
) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keyStrikesList`|`KeyStrikes[]`|List of KeyStrikes structs|
|`pubkeys`|`bytes[]`||
|`proof`|`bytes32[]`|Multi-proof of the strikes|
|`proofFlags`|`bool[]`|Flags to process the multi-proof, see OZ `processMultiProof`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if proof is accepted|


### hashLeaf

Get a hash of a leaf a tree of strikes

*Double hash the leaf to prevent second pre-image attacks*


```solidity
function hashLeaf(KeyStrikes calldata keyStrikes, bytes calldata pubkey) external pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keyStrikes`|`KeyStrikes`|KeyStrikes struct|
|`pubkey`|`bytes`|Public key|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Hash of the leaf|


### getInitializedVersion

Returns the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

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

### EjectorSet

```solidity
event EjectorSet(address ejector);
```

## Errors
### ZeroEjectorAddress

```solidity
error ZeroEjectorAddress();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### ZeroOracleAddress

```solidity
error ZeroOracleAddress();
```

### ZeroExitPenaltiesAddress

```solidity
error ZeroExitPenaltiesAddress();
```

### ZeroParametersRegistryAddress

```solidity
error ZeroParametersRegistryAddress();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### SenderIsNotOracle

```solidity
error SenderIsNotOracle();
```

### ValueNotEvenlyDivisible

```solidity
error ValueNotEvenlyDivisible();
```

### InvalidReportData

```solidity
error InvalidReportData();
```

### InvalidProof

```solidity
error InvalidProof();
```

### NotEnoughStrikesToEject

```solidity
error NotEnoughStrikesToEject();
```

## Structs
### KeyStrikes

```solidity
struct KeyStrikes {
    uint256 nodeOperatorId;
    uint256 keyIndex;
    uint256[] data;
}
```

