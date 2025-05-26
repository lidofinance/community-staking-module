# IAssetRecovererLib
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/lib/AssetRecovererLib.sol)


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

### NotAllowedToRecover

```solidity
error NotAllowedToRecover();
```

