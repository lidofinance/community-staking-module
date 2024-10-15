# ICSFeeDistributor

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/interfaces/ICSFeeDistributor.sol)

**Inherits:**
[IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md)

## Functions

### getFeesToDistribute

```solidity
function getFeesToDistribute(
  uint256 nodeOperatorId,
  uint256 shares,
  bytes32[] calldata proof
) external view returns (uint256);
```

### distributeFees

```solidity
function distributeFees(
  uint256 nodeOperatorId,
  uint256 shares,
  bytes32[] calldata proof
) external returns (uint256);
```

### processOracleReport

```solidity
function processOracleReport(
  bytes32 _treeRoot,
  string calldata _treeCid,
  string calldata _logCid,
  uint256 _distributedShares
) external;
```

### pendingSharesToDistribute

Returns the amount of shares that are pending to be distributed

```solidity
function pendingSharesToDistribute() external view returns (uint256);
```
