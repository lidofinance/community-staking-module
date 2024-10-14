# Validator
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/lib/Types.sol)


```solidity
struct Validator {
    bytes pubkey;
    bytes32 withdrawalCredentials;
    uint64 effectiveBalance;
    bool slashed;
    uint64 activationEligibilityEpoch;
    uint64 activationEpoch;
    uint64 exitEpoch;
    uint64 withdrawableEpoch;
}
```

