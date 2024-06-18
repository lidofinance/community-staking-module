# AssetRecovererLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/AssetRecovererLib.sol)


## Functions
### recoverEther

*Allows the sender to recover Ether held by the contract.
Emits an EtherRecovered event upon success.*


```solidity
function recoverEther() external;
```

### recoverERC20

*Allows the sender to recover ERC20 tokens held by the contract.*


```solidity
function recoverERC20(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the ERC20 token to recover.|
|`amount`|`uint256`|The amount of the ERC20 token to recover. Emits an ERC20Recovered event upon success.|


### recoverStETHShares

*Allows the sender to recover stETH shares held by the contract.
The use of a separate method for stETH is to avoid rounding problems when converting shares to stETH.*


```solidity
function recoverStETHShares(address lido, uint256 shares) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lido`|`address`|The address of the Lido contract.|
|`shares`|`uint256`|The amount of stETH shares to recover. Emits an StETHRecovered event upon success.|


### recoverERC721

*Allows the sender to recover ERC721 tokens held by the contract.*


```solidity
function recoverERC721(address token, uint256 tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the ERC721 token to recover.|
|`tokenId`|`uint256`|The token ID of the ERC721 token to recover. Emits an ERC721Recovered event upon success.|


### recoverERC1155

*Allows the sender to recover ERC1155 tokens held by the contract.*


```solidity
function recoverERC1155(address token, uint256 tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the ERC1155 token to recover.|
|`tokenId`|`uint256`|The token ID of the ERC1155 token to recover. Emits an ERC1155Recovered event upon success.|


## Events
### EtherRecovered

```solidity
event EtherRecovered(address indexed recipient, uint256 amount);
```

### ERC20Recovered

```solidity
event ERC20Recovered(address indexed token, address indexed recipient, uint256 amount);
```

### StETHSharesRecovered

```solidity
event StETHSharesRecovered(address indexed recipient, uint256 shares);
```

### ERC721Recovered

```solidity
event ERC721Recovered(address indexed token, uint256 tokenId, address indexed recipient);
```

### ERC1155Recovered

```solidity
event ERC1155Recovered(address indexed token, uint256 tokenId, address indexed recipient, uint256 amount);
```

## Errors
### FailedToSendEther

```solidity
error FailedToSendEther();
```

