# ValidatorCountsReport
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/ValidatorCountsReport.sol)

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
