# BeaconBlockHeader
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/lib/Types.sol)


```solidity
struct BeaconBlockHeader {
    Slot slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}
```

