# IConsensusContract
[Git Source](https://github.com/lidofinance/community-staking-module/blob/3a4f57c9cf742468b087015f451ef8dce648f719/src/lib/base-oracle/interfaces/IConsensusContract.sol)


## Functions
### getIsMember


```solidity
function getIsMember(address addr) external view returns (bool);
```

### getCurrentFrame


```solidity
function getCurrentFrame() external view returns (uint256 refSlot, uint256 reportProcessingDeadlineSlot);
```

### getChainConfig


```solidity
function getChainConfig() external view returns (uint256 slotsPerEpoch, uint256 secondsPerSlot, uint256 genesisTime);
```

### getInitialRefSlot


```solidity
function getInitialRefSlot() external view returns (uint256);
```

