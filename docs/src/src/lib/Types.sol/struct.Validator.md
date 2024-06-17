# Validator
[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/lib/Types.sol)


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

