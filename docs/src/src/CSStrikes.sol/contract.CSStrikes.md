# CSStrikes
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/CSStrikes.sol)

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
### constructor


```solidity
constructor(address module, address oracle, address exitPenalties);
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
    bytes32[] calldata proof,
    address refundRecipient
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the withdrawn key in the Node Operator's keys storage|
|`strikesData`|`uint256[]`|Strikes of the Node Operator's validator key. TODO: value is to be defined (timestamps or refSlots ?)|
|`proof`|`bytes32[]`|Proof of the strikes|
|`refundRecipient`|`address`|Address to send the refund to|


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


### _setEjector


```solidity
function _setEjector(address _ejector) internal;
```

