# ValidatorCountsReport
[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/lib/ValidatorCountsReport.sol)

**Author:**
skhomuti


## Functions
### safeCountOperators


```solidity
function safeCountOperators(bytes calldata ids, bytes calldata counts) internal pure returns (uint256);
```

### next


```solidity
function next(bytes calldata ids, bytes calldata counts, uint256 offset)
    internal
    pure
    returns (uint256 nodeOperatorId, uint256 keysCount);
```

## Errors
### InvalidReportData

```solidity
error InvalidReportData();
```

