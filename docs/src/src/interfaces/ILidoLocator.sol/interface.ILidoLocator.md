# ILidoLocator
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/interfaces/ILidoLocator.sol)


## Functions
### accountingOracle


```solidity
function accountingOracle() external view returns (address);
```

### burner


```solidity
function burner() external view returns (address);
```

### coreComponents


```solidity
function coreComponents() external view returns (address, address, address, address, address, address);
```

### depositSecurityModule


```solidity
function depositSecurityModule() external view returns (address);
```

### elRewardsVault


```solidity
function elRewardsVault() external view returns (address);
```

### legacyOracle


```solidity
function legacyOracle() external view returns (address);
```

### lido


```solidity
function lido() external view returns (address);
```

### oracleDaemonConfig


```solidity
function oracleDaemonConfig() external view returns (address);
```

### oracleReportComponentsForLido


```solidity
function oracleReportComponentsForLido()
    external
    view
    returns (address, address, address, address, address, address, address);
```

### oracleReportSanityChecker


```solidity
function oracleReportSanityChecker() external view returns (address);
```

### postTokenRebaseReceiver


```solidity
function postTokenRebaseReceiver() external view returns (address);
```

### stakingRouter


```solidity
function stakingRouter() external view returns (address payable);
```

### treasury


```solidity
function treasury() external view returns (address);
```

### validatorsExitBusOracle


```solidity
function validatorsExitBusOracle() external view returns (address);
```

### withdrawalQueue


```solidity
function withdrawalQueue() external view returns (address);
```

### withdrawalVault


```solidity
function withdrawalVault() external view returns (address);
```

## Errors
### ZeroAddress

```solidity
error ZeroAddress();
```

