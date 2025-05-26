# ICSFeeOracle
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSFeeOracle.sol)

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

### FEE_DISTRIBUTOR


```solidity
function FEE_DISTRIBUTOR() external view returns (ICSFeeDistributor);
```

### STRIKES


```solidity
function STRIKES() external view returns (ICSStrikes);
```

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

