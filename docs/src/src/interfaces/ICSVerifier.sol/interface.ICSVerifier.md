# ICSVerifier

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/interfaces/ICSVerifier.sol)

## Functions

### processSlashingProof

`witness` is a slashing witness against the `beaconBlock`'s state root.

```solidity
function processSlashingProof(
  ProvableBeaconBlockHeader calldata beaconBlock,
  SlashingWitness calldata witness,
  uint256 nodeOperatorId,
  uint256 keyIndex
) external;
```

### processWithdrawalProof

`witness` is a withdrawal witness against the `beaconBlock`'s state root.

```solidity
function processWithdrawalProof(
  ProvableBeaconBlockHeader calldata beaconBlock,
  WithdrawalWitness calldata witness,
  uint256 nodeOperatorId,
  uint256 keyIndex
) external;
```

### processHistoricalWithdrawalProof

`oldHeader` is a beacon block header witness against the `beaconBlock`'s state root.

`witness` is a withdrawal witness against the `oldHeader`'s state root.

```solidity
function processHistoricalWithdrawalProof(
  ProvableBeaconBlockHeader calldata beaconBlock,
  HistoricalHeaderWitness calldata oldBlock,
  WithdrawalWitness calldata witness,
  uint256 nodeOperatorId,
  uint256 keyIndex
) external;
```

## Structs

### ProvableBeaconBlockHeader

```solidity
struct ProvableBeaconBlockHeader {
  BeaconBlockHeader header;
  uint64 rootsTimestamp;
}
```

### SlashingWitness

```solidity
struct SlashingWitness {
  uint64 validatorIndex;
  bytes32 withdrawalCredentials;
  uint64 effectiveBalance;
  uint64 activationEligibilityEpoch;
  uint64 activationEpoch;
  uint64 exitEpoch;
  uint64 withdrawableEpoch;
  bytes32[] validatorProof;
}
```

### WithdrawalWitness

```solidity
struct WithdrawalWitness {
  uint8 withdrawalOffset;
  uint64 withdrawalIndex;
  uint64 validatorIndex;
  uint64 amount;
  bytes32 withdrawalCredentials;
  uint64 effectiveBalance;
  bool slashed;
  uint64 activationEligibilityEpoch;
  uint64 activationEpoch;
  uint64 exitEpoch;
  uint64 withdrawableEpoch;
  bytes32[] withdrawalProof;
  bytes32[] validatorProof;
}
```

### HistoricalHeaderWitness

```solidity
struct HistoricalHeaderWitness {
  BeaconBlockHeader header;
  GIndex rootGIndex;
  bytes32[] proof;
}
```
