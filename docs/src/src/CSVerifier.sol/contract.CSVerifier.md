# CSVerifier

[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/CSVerifier.sol)

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

### GI_HISTORICAL_SUMMARIES

_This index is relative to a state like: `BeaconState.historical_summaries`._

```solidity
GIndex public immutable GI_HISTORICAL_SUMMARIES;
```

### GI_FIRST_WITHDRAWAL

_This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`._

```solidity
GIndex public immutable GI_FIRST_WITHDRAWAL;
```

### GI_FIRST_VALIDATOR

_This index is relative to a state like: `BeaconState.validators[0]`._

```solidity
GIndex public immutable GI_FIRST_VALIDATOR;
```

### FIRST_SUPPORTED_SLOT

_The very first slot the verifier is supposed to accept proofs for._

```solidity
Slot public immutable FIRST_SUPPORTED_SLOT;
```

### LOCATOR

_Lido Locator contract_

```solidity
ILidoLocator public immutable LOCATOR;
```

### MODULE

_Staking module contract_

```solidity
ICSModule public immutable MODULE;
```

## Functions

### constructor

```solidity
constructor(
  address locator,
  address module,
  uint64 slotsPerEpoch,
  GIndex gIHistoricalSummaries,
  GIndex gIFirstWithdrawal,
  GIndex gIFirstValidator,
  Slot firstSupportedSlot
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
  uint256 stateEpoch,
  bytes32 stateRoot,
  bytes memory pubkey
) internal view returns (uint256 withdrawalAmount);
```

### \_getValidatorGI

```solidity
function _getValidatorGI(uint256 offset) internal view returns (GIndex);
```

### \_getWithdrawalGI

```solidity
function _getWithdrawalGI(uint256 offset) internal view returns (GIndex);
```

### \_computeEpochAtSlot

```solidity
function _computeEpochAtSlot(uint256 slot) internal view returns (uint256);
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

### PartialWitdrawal

```solidity
error PartialWitdrawal();
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
error UnsupportedSlot(uint256 slot);
```

### ZeroLocatorAddress

```solidity
error ZeroLocatorAddress();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```
