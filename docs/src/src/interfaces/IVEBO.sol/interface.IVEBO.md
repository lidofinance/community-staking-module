# IVEBO
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/IVEBO.sol)


## Functions
### SUBMIT_DATA_ROLE


```solidity
function SUBMIT_DATA_ROLE() external view returns (bytes32);
```

### getRoleMember


```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address);
```

### grantRole


```solidity
function grantRole(bytes32 role, address account) external;
```

### getConsensusVersion


```solidity
function getConsensusVersion() external view returns (uint256);
```

### getContractVersion


```solidity
function getContractVersion() external view returns (uint256);
```

### getConsensusContract


```solidity
function getConsensusContract() external view returns (address);
```

### getConsensusReport


```solidity
function getConsensusReport()
    external
    view
    returns (bytes32 hash, uint256 refSlot, uint256 processingDeadlineTime, bool processingStarted);
```

### submitConsensusReport


```solidity
function submitConsensusReport(bytes32 reportHash, uint256 refSlot, uint256 deadline) external;
```

### submitReportData


```solidity
function submitReportData(ReportData calldata data, uint256 contractVersion) external;
```

## Structs
### ReportData

```solidity
struct ReportData {
    uint256 consensusVersion;
    uint256 refSlot;
    uint256 requestsCount;
    uint256 dataFormat;
    bytes data;
}
```

