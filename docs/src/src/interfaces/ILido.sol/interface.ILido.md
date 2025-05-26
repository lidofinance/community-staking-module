# ILido
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ILido.sol)

**Inherits:**
[IStETH](/src/interfaces/IStETH.sol/interface.IStETH.md)


## Functions
### STAKING_CONTROL_ROLE


```solidity
function STAKING_CONTROL_ROLE() external view returns (bytes32);
```

### submit


```solidity
function submit(address _referal) external payable returns (uint256);
```

### deposit


```solidity
function deposit(uint256 _maxDepositsCount, uint256 _stakingModuleId, bytes calldata _depositCalldata) external;
```

### removeStakingLimit


```solidity
function removeStakingLimit() external;
```

### kernel


```solidity
function kernel() external returns (address);
```

### sharesOf


```solidity
function sharesOf(address _account) external view returns (uint256);
```

