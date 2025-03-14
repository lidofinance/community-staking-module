# ICSFeeOracle
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/ICSFeeOracle.sol)

**Inherits:**
[IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md)


## Functions
### SUBMIT_DATA_ROLE


```solidity
function SUBMIT_DATA_ROLE() external view returns (bytes32);
```

### PAUSE_ROLE


```solidity
function PAUSE_ROLE() external view returns (bytes32);
```

### RESUME_ROLE


```solidity
function RESUME_ROLE() external view returns (bytes32);
```

### RECOVERER_ROLE


```solidity
function RECOVERER_ROLE() external view returns (bytes32);
```

### feeDistributor


```solidity
function feeDistributor() external view returns (ICSFeeDistributor);
```

### setFeeDistributorContract

Set a new fee distributor contract


```solidity
function setFeeDistributorContract(address feeDistributorContract) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeDistributorContract`|`address`|Address of the new fee distributor contract|


### setStrikesContract

Set a new strikes contract


```solidity
function setStrikesContract(address strikesContract) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strikesContract`|`address`|Address of the new strikes contract|


### submitReportData

Submit the data for a committee report


```solidity
function submitReportData(ReportData calldata data, uint256 contractVersion) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`ReportData`|Data for a committee report|
|`contractVersion`|`uint256`|Version of the oracle consensus rules|


### resume

Resume accepting oracle reports


```solidity
function resume() external;
```

### pauseFor

Pause accepting oracle reports for a `duration` seconds


```solidity
function pauseFor(uint256 duration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### pauseUntil

Pause accepting oracle reports until a timestamp


```solidity
function pauseUntil(uint256 pauseUntilInclusive) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pauseUntilInclusive`|`uint256`|Timestamp until which the oracle reports are paused|


## Events
### FeeDistributorContractSet
*Emitted when a new fee distributor contract is set*


```solidity
event FeeDistributorContractSet(address feeDistributorContract);
```

### StrikesContractSet
*Emitted when a new strikes contract is set*


```solidity
event StrikesContractSet(address strikesContract);
```

## Errors
### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroFeeDistributorAddress

```solidity
error ZeroFeeDistributorAddress();
```

### ZeroStrikesAddress

```solidity
error ZeroStrikesAddress();
```

### SenderNotAllowed

```solidity
error SenderNotAllowed();
```

## Structs
### ReportData

```solidity
struct ReportData {
    uint256 consensusVersion;
    uint256 refSlot;
    bytes32 treeRoot;
    string treeCid;
    string logCid;
    uint256 distributed;
    uint256 rebate;
    bytes32 strikesTreeRoot;
    string strikesTreeCid;
}
```

