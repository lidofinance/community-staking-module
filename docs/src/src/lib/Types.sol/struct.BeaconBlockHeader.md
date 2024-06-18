# BeaconBlockHeader
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/Types.sol)


```solidity
struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}
```

