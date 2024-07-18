# IConsensusContract
[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/lib/base-oracle/BaseOracle.sol)


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

