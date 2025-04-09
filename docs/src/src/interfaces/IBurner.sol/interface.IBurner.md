# IBurner
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/interfaces/IBurner.sol)


## Functions
### REQUEST_BURN_MY_STETH_ROLE


```solidity
function REQUEST_BURN_MY_STETH_ROLE() external view returns (bytes32);
```

### REQUEST_BURN_SHARES_ROLE


```solidity
function REQUEST_BURN_SHARES_ROLE() external view returns (bytes32);
```

### DEFAULT_ADMIN_ROLE


```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
```

### getRoleMember


```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address);
```

### grantRole


```solidity
function grantRole(bytes32 role, address account) external;
```

### revokeRole


```solidity
function revokeRole(bytes32 role, address account) external;
```

### hasRole


```solidity
function hasRole(bytes32 role, address account) external view returns (bool);
```

### requestBurnMyStETH


```solidity
function requestBurnMyStETH(uint256 _stETHAmountToBurn) external;
```

