# ICSFeeDistributor
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSFeeDistributor.sol)

**Inherits:**
[IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md)


## Functions
### RECOVERER_ROLE


```solidity
function RECOVERER_ROLE() external view returns (bytes32);
```

### STETH


```solidity
function STETH() external view returns (IStETH);
```

### ACCOUNTING


```solidity
function ACCOUNTING() external view returns (address);
```

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

### logCid


```solidity
function logCid() external view returns (string calldata);
```

### distributedShares


```solidity
function distributedShares(uint256) external view returns (uint256);
```

### totalClaimableShares


```solidity
function totalClaimableShares() external view returns (uint256);
```

### distributionDataHistoryCount


```solidity
function distributionDataHistoryCount() external view returns (uint256);
```

### rebateRecipient


```solidity
function rebateRecipient() external view returns (address);
```

### getInitializedVersion

Get the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

### setRebateRecipient

Set address to send rebate to


```solidity
function setRebateRecipient(address _rebateRecipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rebateRecipient`|`address`|Address to send rebate to|


### getFeesToDistribute

Get the Amount of stETH shares that can be distributed in favor of the Node Operator


```solidity
function getFeesToDistribute(uint256 nodeOperatorId, uint256 cumulativeFeeShares, bytes32[] calldata proof)
    external
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`cumulativeFeeShares`|`uint256`|Total Amount of stETH shares earned as fees|
|`proof`|`bytes32[]`|Merkle proof of the leaf|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|sharesToDistribute Amount of stETH shares that can be distributed|


### distributeFees

Distribute fees to the Accounting in favor of the Node Operator


```solidity
function distributeFees(uint256 nodeOperatorId, uint256 cumulativeFeeShares, bytes32[] calldata proof)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`cumulativeFeeShares`|`uint256`|Total Amount of stETH shares earned as fees|
|`proof`|`bytes32[]`|Merkle proof of the leaf|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|sharesToDistribute Amount of stETH shares distributed|


### processOracleReport

Receive the data of the Merkle tree from the Oracle contract and process it


```solidity
function processOracleReport(
    bytes32 _treeRoot,
    string calldata _treeCid,
    string calldata _logCid,
    uint256 distributed,
    uint256 rebate,
    uint256 refSlot
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treeRoot`|`bytes32`|Root of the Merkle tree|
|`_treeCid`|`string`|an IPFS CID of the tree|
|`_logCid`|`string`|an IPFS CID of the log|
|`distributed`|`uint256`|an amount of the distributed shares|
|`rebate`|`uint256`|an amount of the rebate shares|
|`refSlot`|`uint256`|refSlot of the report|


### pendingSharesToDistribute

Get the Amount of stETH shares that are pending to be distributed


```solidity
function pendingSharesToDistribute() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|pendingShares Amount shares that are pending to distribute|


### getHistoricalDistributionData

Get the historical record of distribution data


```solidity
function getHistoricalDistributionData(uint256 index) external view returns (DistributionData memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`DistributionData`|index Historical entry index|


### hashLeaf

Get a hash of a leaf

*Double hash the leaf to prevent second preimage attacks*


```solidity
function hashLeaf(uint256 nodeOperatorId, uint256 shares) external pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`shares`|`uint256`|Amount of stETH shares|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Hash of the leaf|


## Events
### OperatorFeeDistributed
*Emitted when fees are distributed*


```solidity
event OperatorFeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);
```

### DistributionDataUpdated
*Emitted when distribution data is updated*


```solidity
event DistributionDataUpdated(uint256 totalClaimableShares, bytes32 treeRoot, string treeCid);
```

### DistributionLogUpdated
*Emitted when distribution log is updated*


```solidity
event DistributionLogUpdated(string logCid);
```

### ModuleFeeDistributed
*It logs how many shares were distributed in the latest report*


```solidity
event ModuleFeeDistributed(uint256 shares);
```

### RebateTransferred
*Emitted when rebate is transferred*


```solidity
event RebateTransferred(uint256 shares);
```

### RebateRecipientSet
*Emitted when rebate recipient is set*


```solidity
event RebateRecipientSet(address recipient);
```

## Errors
### ZeroAccountingAddress

```solidity
error ZeroAccountingAddress();
```

### ZeroStEthAddress

```solidity
error ZeroStEthAddress();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroOracleAddress

```solidity
error ZeroOracleAddress();
```

### ZeroRebateRecipientAddress

```solidity
error ZeroRebateRecipientAddress();
```

### SenderIsNotAccounting

```solidity
error SenderIsNotAccounting();
```

### SenderIsNotOracle

```solidity
error SenderIsNotOracle();
```

### InvalidReportData

```solidity
error InvalidReportData();
```

### InvalidTreeRoot

```solidity
error InvalidTreeRoot();
```

### InvalidTreeCid

```solidity
error InvalidTreeCid();
```

### InvalidLogCID

```solidity
error InvalidLogCID();
```

### InvalidShares

```solidity
error InvalidShares();
```

### InvalidProof

```solidity
error InvalidProof();
```

### FeeSharesDecrease

```solidity
error FeeSharesDecrease();
```

### NotEnoughShares

```solidity
error NotEnoughShares();
```

## Structs
### DistributionData

```solidity
struct DistributionData {
    uint256 refSlot;
    bytes32 treeRoot;
    string treeCid;
    string logCid;
    uint256 distributed;
    uint256 rebate;
}
```

