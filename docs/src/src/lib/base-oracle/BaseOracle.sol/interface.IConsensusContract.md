# IConsensusContract
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/lib/base-oracle/BaseOracle.sol)


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

