# ICSFeeDistributor

[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/interfaces/ICSFeeDistributor.sol)

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
  uint256 _distributedShares
) external;
```

### pendingSharesToDistribute

Returns the amount of shares that are pending to be distributed

```solidity
function pendingSharesToDistribute() external view returns (uint256);
```
