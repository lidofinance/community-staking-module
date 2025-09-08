# CSStrikes
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/CSStrikes.sol)

**Inherits:**
[ICSStrikes](/src/interfaces/ICSStrikes.sol/interface.ICSStrikes.md), Initializable, AccessControlEnumerableUpgradeable

**Author:**
vgorkavenko


## State Variables
### ORACLE

```solidity
address public immutable ORACLE;
```


### MODULE

```solidity
ICSModule public immutable MODULE;
```


### ACCOUNTING

```solidity
ICSAccounting public immutable ACCOUNTING;
```


### EXIT_PENALTIES

```solidity
ICSExitPenalties public immutable EXIT_PENALTIES;
```


### PARAMETERS_REGISTRY

```solidity
ICSParametersRegistry public immutable PARAMETERS_REGISTRY;
```


### ejector

```solidity
ICSEjector public ejector;
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
### onlyOracle


```solidity
modifier onlyOracle();
```

### constructor


```solidity
constructor(address module, address oracle, address exitPenalties, address parametersRegistry);
```

### initialize


```solidity
function initialize(address admin, address _ejector) external initializer;
```

### setEjector

Set the address of the Ejector contract


```solidity
function setEjector(address _ejector) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_ejector`|`address`|Address of the Ejector contract|


### processOracleReport

Receive the data of the Merkle tree from the Oracle contract and process it

*New tree might be empty and it is valid value because of `strikesLifetime`*


```solidity
function processOracleReport(bytes32 _treeRoot, string calldata _treeCid) external onlyOracle;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treeRoot`|`bytes32`|Root of the Merkle tree|
|`_treeCid`|`string`|an IPFS CID of the tree|


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


### getInitializedVersion

Returns the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

### verifyProof

Check the contract accepts the provided multi-proof


```solidity
function verifyProof(
    KeyStrikes[] calldata keyStrikesList,
    bytes[] memory pubkeys,
    bytes32[] calldata proof,
    bool[] calldata proofFlags
) public view returns (bool);
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
function hashLeaf(KeyStrikes calldata keyStrikes, bytes memory pubkey) public pure returns (bytes32);
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


### _setEjector


```solidity
function _setEjector(address _ejector) internal;
```

### _ejectByStrikes


```solidity
function _ejectByStrikes(KeyStrikes calldata keyStrikes, bytes memory pubkey, uint256 value, address refundRecipient)
    internal;
```

