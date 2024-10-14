# CSVerifier

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/CSVerifier.sol)

**Inherits:**
[ICSVerifier](/src/interfaces/ICSVerifier.sol/interface.ICSVerifier.md)

## State Variables

### BEACON_ROOTS

```solidity
address public constant BEACON_ROOTS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
```

### SLOTS_PER_EPOCH

```solidity
uint64 public immutable SLOTS_PER_EPOCH;
```

### GI_FIRST_WITHDRAWAL_PREV

_This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`._

```solidity
GIndex public immutable GI_FIRST_WITHDRAWAL_PREV;
```

### GI_FIRST_WITHDRAWAL_CURR

_This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`._

```solidity
GIndex public immutable GI_FIRST_WITHDRAWAL_CURR;
```

### GI_FIRST_VALIDATOR_PREV

_This index is relative to a state like: `BeaconState.validators[0]`._

```solidity
GIndex public immutable GI_FIRST_VALIDATOR_PREV;
```

### GI_FIRST_VALIDATOR_CURR

_This index is relative to a state like: `BeaconState.validators[0]`._

```solidity
GIndex public immutable GI_FIRST_VALIDATOR_CURR;
```

### GI_HISTORICAL_SUMMARIES_PREV

_This index is relative to a state like: `BeaconState.historical_summaries`._

```solidity
GIndex public immutable GI_HISTORICAL_SUMMARIES_PREV;
```

### GI_HISTORICAL_SUMMARIES_CURR

_This index is relative to a state like: `BeaconState.historical_summaries`._

```solidity
GIndex public immutable GI_HISTORICAL_SUMMARIES_CURR;
```

### FIRST_SUPPORTED_SLOT

_The very first slot the verifier is supposed to accept proofs for._

```solidity
Slot public immutable FIRST_SUPPORTED_SLOT;
```

### PIVOT_SLOT

_The first slot of the currently compatible fork._

```solidity
Slot public immutable PIVOT_SLOT;
```

### WITHDRAWAL_ADDRESS

_An address withdrawals are supposed to happen to (Lido withdrawal credentials)._

```solidity
address public immutable WITHDRAWAL_ADDRESS;
```

### MODULE

_Staking module contract_

```solidity
ICSModule public immutable MODULE;
```

## Functions

### constructor

_The previous and current forks can be essentially the same._

```solidity
constructor(
  address withdrawalAddress,
  address module,
  uint64 slotsPerEpoch,
  GIndex gIFirstWithdrawalPrev,
  GIndex gIFirstWithdrawalCurr,
  GIndex gIFirstValidatorPrev,
  GIndex gIFirstValidatorCurr,
  GIndex gIHistoricalSummariesPrev,
  GIndex gIHistoricalSummariesCurr,
  Slot firstSupportedSlot,
  Slot pivotSlot
);
```

### processSlashingProof

Verify slashing proof and report slashing to the module for valid proofs

```solidity
function processSlashingProof(
  ProvableBeaconBlockHeader calldata beaconBlock,
  SlashingWitness calldata witness,
  uint256 nodeOperatorId,
  uint256 keyIndex
) external;
```

**Parameters**

| Name             | Type                        | Description                                                   |
| ---------------- | --------------------------- | ------------------------------------------------------------- |
| `beaconBlock`    | `ProvableBeaconBlockHeader` | Beacon block header                                           |
| `witness`        | `SlashingWitness`           | Slashing witness                                              |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator                                       |
| `keyIndex`       | `uint256`                   | Index of the validator key in the Node Operator's key storage |

### processWithdrawalProof

Verify withdrawal proof and report withdrawal to the module for valid proofs

```solidity
function processWithdrawalProof(
  ProvableBeaconBlockHeader calldata beaconBlock,
  WithdrawalWitness calldata witness,
  uint256 nodeOperatorId,
  uint256 keyIndex
) external;
```

**Parameters**

| Name             | Type                        | Description                                                   |
| ---------------- | --------------------------- | ------------------------------------------------------------- |
| `beaconBlock`    | `ProvableBeaconBlockHeader` | Beacon block header                                           |
| `witness`        | `WithdrawalWitness`         | Withdrawal witness                                            |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator                                       |
| `keyIndex`       | `uint256`                   | Index of the validator key in the Node Operator's key storage |

### processHistoricalWithdrawalProof

Verify withdrawal proof against historical summaries data and report withdrawal to the module for valid proofs

```solidity
function processHistoricalWithdrawalProof(
  ProvableBeaconBlockHeader calldata beaconBlock,
  HistoricalHeaderWitness calldata oldBlock,
  WithdrawalWitness calldata witness,
  uint256 nodeOperatorId,
  uint256 keyIndex
) external;
```

**Parameters**

| Name             | Type                        | Description                                                   |
| ---------------- | --------------------------- | ------------------------------------------------------------- |
| `beaconBlock`    | `ProvableBeaconBlockHeader` | Beacon block header                                           |
| `oldBlock`       | `HistoricalHeaderWitness`   | Historical block header witness                               |
| `witness`        | `WithdrawalWitness`         | Withdrawal witness                                            |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator                                       |
| `keyIndex`       | `uint256`                   | Index of the validator key in the Node Operator's key storage |

### \_getParentBlockRoot

```solidity
function _getParentBlockRoot(uint64 blockTimestamp) internal view returns (bytes32);
```

### \_processWithdrawalProof

_`stateRoot` is supposed to be trusted at this point._

```solidity
function _processWithdrawalProof(
  WithdrawalWitness calldata witness,
  Slot stateSlot,
  bytes32 stateRoot,
  bytes memory pubkey
) internal view returns (uint256 withdrawalAmount);
```

### \_getValidatorGI

```solidity
function _getValidatorGI(uint256 offset, Slot stateSlot) internal view returns (GIndex);
```

### \_getWithdrawalGI

```solidity
function _getWithdrawalGI(uint256 offset, Slot stateSlot) internal view returns (GIndex);
```

### \_getHistoricalSummariesGI

```solidity
function _getHistoricalSummariesGI(Slot stateSlot) internal view returns (GIndex);
```

### \_computeEpochAtSlot

```solidity
function _computeEpochAtSlot(Slot slot) internal view returns (uint256);
```

## Errors

### RootNotFound

```solidity
error RootNotFound();
```

### InvalidGIndex

```solidity
error InvalidGIndex();
```

### InvalidBlockHeader

```solidity
error InvalidBlockHeader();
```

### InvalidChainConfig

```solidity
error InvalidChainConfig();
```

### PartialWithdrawal

```solidity
error PartialWithdrawal();
```

### ValidatorNotWithdrawn

```solidity
error ValidatorNotWithdrawn();
```

### InvalidWithdrawalAddress

```solidity
error InvalidWithdrawalAddress();
```

### UnsupportedSlot

```solidity
error UnsupportedSlot(Slot slot);
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### ZeroWithdrawalAddress

```solidity
error ZeroWithdrawalAddress();
```

### InvalidPivotSlot

```solidity
error InvalidPivotSlot();
```
