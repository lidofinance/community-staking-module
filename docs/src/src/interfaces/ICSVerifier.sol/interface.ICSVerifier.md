# ICSVerifier
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSVerifier.sol)


## Functions
### PAUSE_ROLE


```solidity
function PAUSE_ROLE() external view returns (bytes32);
```

### RESUME_ROLE


```solidity
function RESUME_ROLE() external view returns (bytes32);
```

### BEACON_ROOTS


```solidity
function BEACON_ROOTS() external view returns (address);
```

### SLOTS_PER_EPOCH


```solidity
function SLOTS_PER_EPOCH() external view returns (uint64);
```

### GI_FIRST_WITHDRAWAL_PREV


```solidity
function GI_FIRST_WITHDRAWAL_PREV() external view returns (GIndex);
```

### GI_FIRST_WITHDRAWAL_CURR


```solidity
function GI_FIRST_WITHDRAWAL_CURR() external view returns (GIndex);
```

### GI_FIRST_VALIDATOR_PREV


```solidity
function GI_FIRST_VALIDATOR_PREV() external view returns (GIndex);
```

### GI_FIRST_VALIDATOR_CURR


```solidity
function GI_FIRST_VALIDATOR_CURR() external view returns (GIndex);
```

### GI_HISTORICAL_SUMMARIES_PREV


```solidity
function GI_HISTORICAL_SUMMARIES_PREV() external view returns (GIndex);
```

### GI_HISTORICAL_SUMMARIES_CURR


```solidity
function GI_HISTORICAL_SUMMARIES_CURR() external view returns (GIndex);
```

### FIRST_SUPPORTED_SLOT


```solidity
function FIRST_SUPPORTED_SLOT() external view returns (Slot);
```

### PIVOT_SLOT


```solidity
function PIVOT_SLOT() external view returns (Slot);
```

### WITHDRAWAL_ADDRESS


```solidity
function WITHDRAWAL_ADDRESS() external view returns (address);
```

### MODULE


```solidity
function MODULE() external view returns (ICSModule);
```

### pauseFor

Pause write methods calls for `duration` seconds


```solidity
function pauseFor(uint256 duration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### resume

Resume write methods calls


```solidity
function resume() external;
```

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

|Name|Type|Description|
|----|----|-----------|
|`beaconBlock`|`ProvableBeaconBlockHeader`|Beacon block header|
|`witness`|`WithdrawalWitness`|Withdrawal witness against the `beaconBlock`'s state root.|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the validator key in the Node Operator's key storage|


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

|Name|Type|Description|
|----|----|-----------|
|`beaconBlock`|`ProvableBeaconBlockHeader`|Beacon block header|
|`oldBlock`|`HistoricalHeaderWitness`|Historical block header witness|
|`witness`|`WithdrawalWitness`|Withdrawal witness|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the validator key in the Node Operator's key storage|


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

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### InvalidPivotSlot

```solidity
error InvalidPivotSlot();
```

## Structs
### GIndices

```solidity
struct GIndices {
    GIndex gIFirstWithdrawalPrev;
    GIndex gIFirstWithdrawalCurr;
    GIndex gIFirstValidatorPrev;
    GIndex gIFirstValidatorCurr;
    GIndex gIHistoricalSummariesPrev;
    GIndex gIHistoricalSummariesCurr;
}
```

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

