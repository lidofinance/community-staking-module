# IWstETH
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/IWstETH.sol)


## Functions
### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### approve


```solidity
function approve(address _spender, uint256 _amount) external returns (bool);
```

### wrap


```solidity
function wrap(uint256 _stETHAmount) external returns (uint256);
```

### unwrap


```solidity
function unwrap(uint256 _wstETHAmount) external returns (uint256);
```

### transferFrom


```solidity
function transferFrom(address sender, address recipient, uint256 amount) external;
```

### transfer


```solidity
function transfer(address recipient, uint256 amount) external;
```

### getStETHByWstETH


```solidity
function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
```

### getWstETHByStETH


```solidity
function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
```

### permit


```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external;
```

### allowance


```solidity
function allowance(address _owner, address _spender) external view returns (uint256);
```

