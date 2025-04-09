# CSFeeOracle
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/CSFeeOracle.sol)

**Inherits:**
[ICSFeeOracle](/src/interfaces/ICSFeeOracle.sol/interface.ICSFeeOracle.md), [BaseOracle](/src/lib/base-oracle/BaseOracle.sol/abstract.BaseOracle.md), [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md), [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)


## State Variables
### SUBMIT_DATA_ROLE
No assets are stored in the contract

An ACL role granting the permission to submit the data for a committee report.


```solidity
bytes32 public constant SUBMIT_DATA_ROLE = keccak256("SUBMIT_DATA_ROLE");
```


### PAUSE_ROLE
An ACL role granting the permission to pause accepting oracle reports


```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE
An ACL role granting the permission to resume accepting oracle reports


```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### RECOVERER_ROLE
An ACL role granting the permission to recover assets


```solidity
bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```


### feeDistributor

```solidity
ICSFeeDistributor public feeDistributor;
```


### strikes
**Note:**
oz-retyped-from: uint256


```solidity
ICSStrikes public strikes;
```


## Functions
### constructor


```solidity
constructor(uint256 secondsPerSlot, uint256 genesisTime) BaseOracle(secondsPerSlot, genesisTime);
```

### initialize

*initialize contract from scratch*


```solidity
function initialize(
    address admin,
    address feeDistributorContract,
    address strikesContract,
    address consensusContract,
    uint256 consensusVersion
) external;
```

### finalizeUpgradeV2

*_setFeeDistributorContract() reverts if zero address*

*_setStrikesContract() reverts if zero address*

*should be called after update on the proxy*


```solidity
function finalizeUpgradeV2(uint256 consensusVersion, address strikesContract) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setFeeDistributorContract

Set a new fee distributor contract

*_setStrikesContract() reverts if zero address*


```solidity
function setFeeDistributorContract(address feeDistributorContract) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeDistributorContract`|`address`|Address of the new fee distributor contract|


### setStrikesContract

Set a new strikes contract


```solidity
function setStrikesContract(address strikesContract) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strikesContract`|`address`|Address of the new strikes contract|


### submitReportData

Submit the data for a committee report


```solidity
function submitReportData(ReportData calldata data, uint256 contractVersion) external whenResumed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`ReportData`|Data for a committee report|
|`contractVersion`|`uint256`|Version of the oracle consensus rules|


### resume

Resume accepting oracle reports


```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause accepting oracle reports for a `duration` seconds


```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### pauseUntil

Pause accepting oracle reports until a timestamp


```solidity
function pauseUntil(uint256 pauseUntilInclusive) external onlyRole(PAUSE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pauseUntilInclusive`|`uint256`|Timestamp until which the oracle reports are paused|


### _setFeeDistributorContract


```solidity
function _setFeeDistributorContract(address feeDistributorContract) internal;
```

### _setStrikesContract


```solidity
function _setStrikesContract(address strikesContract) internal;
```

### _handleConsensusReport

*Called in `submitConsensusReport` after a consensus is reached.*


```solidity
function _handleConsensusReport(ConsensusReport memory, uint256, uint256) internal override;
```

### _handleConsensusReportData


```solidity
function _handleConsensusReportData(ReportData calldata data) internal;
```

### _checkMsgSenderIsAllowedToSubmitData


```solidity
function _checkMsgSenderIsAllowedToSubmitData() internal view;
```

### _onlyRecoverer


```solidity
function _onlyRecoverer() internal view override;
```

