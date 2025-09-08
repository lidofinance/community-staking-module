# IWithdrawalQueue
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/IWithdrawalQueue.sol)


## Functions
### ORACLE_ROLE


```solidity
function ORACLE_ROLE() external view returns (bytes32);
```

### getRoleMember


```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address);
```

### WSTETH


```solidity
function WSTETH() external view returns (address);
```

### MIN_STETH_WITHDRAWAL_AMOUNT

minimal amount of stETH that is possible to withdraw


```solidity
function MIN_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);
```

### MAX_STETH_WITHDRAWAL_AMOUNT

maximum amount of stETH that is possible to withdraw by a single request
Prevents accumulating too much funds per single request fulfillment in the future.

*To withdraw larger amounts, it's recommended to split it to several requests*


```solidity
function MAX_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);
```

### requestWithdrawals


```solidity
function requestWithdrawals(uint256[] calldata _amounts, address _owner)
    external
    returns (uint256[] memory requestIds);
```

### getWithdrawalStatus


```solidity
function getWithdrawalStatus(uint256[] calldata _requestIds)
    external
    view
    returns (WithdrawalRequestStatus[] memory statuses);
```

### getWithdrawalRequests


```solidity
function getWithdrawalRequests(address _owner) external view returns (uint256[] memory requestsIds);
```

### isBunkerModeActive


```solidity
function isBunkerModeActive() external view returns (bool);
```

### onOracleReport


```solidity
function onOracleReport(bool _isBunkerModeNow, uint256 _bunkerStartTimestamp, uint256 _currentReportTimestamp)
    external;
```

## Structs
### WithdrawalRequestStatus

```solidity
struct WithdrawalRequestStatus {
    uint256 amountOfStETH;
    uint256 amountOfShares;
    address owner;
    uint256 timestamp;
    bool isFinalized;
    bool isClaimed;
}
```

