# Validator
[Git Source](https://github.com/lidofinance/community-staking-module/blob/3a4f57c9cf742468b087015f451ef8dce648f719/src/lib/Types.sol)


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

