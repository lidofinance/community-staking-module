# CSFeeOracle

[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/CSFeeOracle.sol)

**Inherits:**
[BaseOracle](/src/lib/base-oracle/BaseOracle.sol/abstract.BaseOracle.md), [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md), [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)

## State Variables

### CONTRACT_MANAGER_ROLE

An ACL role granting the permission to manage the contract (update variables).

```solidity
bytes32 public constant CONTRACT_MANAGER_ROLE = keccak256("CONTRACT_MANAGER_ROLE");
```

### SUBMIT_DATA_ROLE

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

### MAX_BP

```solidity
uint256 internal constant MAX_BP = 10000;
```

### feeDistributor

```solidity
ICSFeeDistributor public feeDistributor;
```

### avgPerfLeewayBP

Leeway in basis points used to determine the underperforming validators threshold.
`threshold` = `avgPerfBP` - `avgPerfLeewayBP`, where `avgPerfBP` is an average
performance over the network computed by the off-chain oracle.

```solidity
uint256 public avgPerfLeewayBP;
```

## Functions

### constructor

```solidity
constructor(uint256 secondsPerSlot, uint256 genesisTime) BaseOracle(secondsPerSlot, genesisTime);
```

### initialize

```solidity
function initialize(
  address admin,
  address feeDistributorContract,
  address consensusContract,
  uint256 consensusVersion,
  uint256 _avgPerfLeewayBP
) external;
```

### setFeeDistributorContract

Set a new fee distributor contract

_\_setFeeDistributorContract() reverts if zero address_

```solidity
function setFeeDistributorContract(
  address feeDistributorContract
) external onlyRole(CONTRACT_MANAGER_ROLE);
```

**Parameters**

| Name                     | Type      | Description                                 |
| ------------------------ | --------- | ------------------------------------------- |
| `feeDistributorContract` | `address` | Address of the new fee distributor contract |

### setPerformanceLeeway

Set a new performance threshold value in basis points

```solidity
function setPerformanceLeeway(uint256 valueBP) external onlyRole(CONTRACT_MANAGER_ROLE);
```

**Parameters**

| Name      | Type      | Description                           |
| --------- | --------- | ------------------------------------- |
| `valueBP` | `uint256` | performance threshold in basis points |

### submitReportData

Submit the data for a committee report

```solidity
function submitReportData(ReportData calldata data, uint256 contractVersion) external whenResumed;
```

**Parameters**

| Name              | Type         | Description                           |
| ----------------- | ------------ | ------------------------------------- |
| `data`            | `ReportData` | Data for a committee report           |
| `contractVersion` | `uint256`    | Version of the oracle consensus rules |

### resume

Resume accepting oracle reports

```solidity
function resume() external whenPaused onlyRole(RESUME_ROLE);
```

### pauseFor

Pause accepting oracle reports for a `duration` seconds

```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```

**Parameters**

| Name       | Type      | Description                      |
| ---------- | --------- | -------------------------------- |
| `duration` | `uint256` | Duration of the pause in seconds |

### pauseUntil

Pause accepting oracle reports until a timestamp

```solidity
function pauseUntil(uint256 pauseUntilInclusive) external onlyRole(PAUSE_ROLE);
```

**Parameters**

| Name                  | Type      | Description                                         |
| --------------------- | --------- | --------------------------------------------------- |
| `pauseUntilInclusive` | `uint256` | Timestamp until which the oracle reports are paused |

### \_setFeeDistributorContract

```solidity
function _setFeeDistributorContract(address feeDistributorContract) internal;
```

### \_setPerformanceLeeway

```solidity
function _setPerformanceLeeway(uint256 valueBP) internal;
```

### \_handleConsensusReport

_Called in `submitConsensusReport` after a consensus is reached._

```solidity
function _handleConsensusReport(ConsensusReport memory, uint256, uint256) internal override;
```

### \_handleConsensusReportData

```solidity
function _handleConsensusReportData(ReportData calldata data) internal;
```

### \_checkMsgSenderIsAllowedToSubmitData

```solidity
function _checkMsgSenderIsAllowedToSubmitData() internal view;
```

### \_onlyRecoverer

```solidity
function _onlyRecoverer() internal view override;
```

## Events

### FeeDistributorContractSet

_Emitted when a new fee distributor contract is set_

```solidity
event FeeDistributorContractSet(address feeDistributorContract);
```

### PerfLeewaySet

```solidity
event PerfLeewaySet(uint256 valueBP);
```

### ReportSettled

_Emitted when a report is settled._

```solidity
event ReportSettled(uint256 indexed refSlot, uint256 distributed, bytes32 treeRoot, string treeCid);
```

## Errors

### InvalidPerfThreshold

```solidity
error InvalidPerfThreshold();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroFeeDistributorAddress

```solidity
error ZeroFeeDistributorAddress();
```

### InvalidPerfLeeway

```solidity
error InvalidPerfLeeway();
```

### SenderNotAllowed

```solidity
error SenderNotAllowed();
```

## Structs

### ReportData

No assets are stored in the contract

```solidity
struct ReportData {
  uint256 consensusVersion;
  uint256 refSlot;
  bytes32 treeRoot;
  string treeCid;
  uint256 distributed;
}
```
