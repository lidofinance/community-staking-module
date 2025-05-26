# IStETH
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/IStETH.sol)


## Functions
### getPooledEthByShares

Get stETH amount by the provided shares amount

*dual to `getSharesByPooledEth`.*


```solidity
function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sharesAmount`|`uint256`|shares amount|


### getSharesByPooledEth

Get shares amount by the provided stETH amount

*dual to `getPooledEthByShares`.*


```solidity
function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_pooledEthAmount`|`uint256`|stETH amount|


### sharesOf

Get shares amount of the provided account


```solidity
function sharesOf(address _account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_account`|`address`|provided account address.|


### balanceOf


```solidity
function balanceOf(address _account) external view returns (uint256);
```

### transferSharesFrom

Transfer `_sharesAmount` stETH shares from `_sender` to `_receiver` using allowance.


```solidity
function transferSharesFrom(address _sender, address _recipient, uint256 _sharesAmount) external returns (uint256);
```

### transferShares

Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.


```solidity
function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);
```

### transfer

Moves `_pooledEthAmount` stETH from the caller's account to the `_recipient` account.


```solidity
function transfer(address _recipient, uint256 _amount) external returns (bool);
```

### transferFrom

Moves `_pooledEthAmount` stETH from the `_sender` account to the `_recipient` account.


```solidity
function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
```

### approve


```solidity
function approve(address _spender, uint256 _amount) external returns (bool);
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

