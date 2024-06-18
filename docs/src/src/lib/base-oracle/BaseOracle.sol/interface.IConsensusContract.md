# IConsensusContract
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/base-oracle/BaseOracle.sol)


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

### getFrameConfig


```solidity
function getFrameConfig() external view returns (uint256 initialEpoch, uint256 epochsPerFrame);
```

### getInitialRefSlot


```solidity
function getInitialRefSlot() external view returns (uint256);
```

