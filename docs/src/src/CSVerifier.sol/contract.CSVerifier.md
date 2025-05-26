# CSVerifier
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/CSVerifier.sol)

**Inherits:**
[ICSVerifier](/src/interfaces/ICSVerifier.sol/interface.ICSVerifier.md), AccessControlEnumerable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md)


## State Variables
### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### BEACON_ROOTS

```solidity
address public constant BEACON_ROOTS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
```


### SLOTS_PER_EPOCH

```solidity
uint64 public immutable SLOTS_PER_EPOCH;
```


### GI_FIRST_WITHDRAWAL_PREV
*This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`.*


```solidity
GIndex public immutable GI_FIRST_WITHDRAWAL_PREV;
```


### GI_FIRST_WITHDRAWAL_CURR
*This index is relative to a state like: `BeaconState.latest_execution_payload_header.withdrawals[0]`.*


```solidity
GIndex public immutable GI_FIRST_WITHDRAWAL_CURR;
```


### GI_FIRST_VALIDATOR_PREV
*This index is relative to a state like: `BeaconState.validators[0]`.*


```solidity
GIndex public immutable GI_FIRST_VALIDATOR_PREV;
```


### GI_FIRST_VALIDATOR_CURR
*This index is relative to a state like: `BeaconState.validators[0]`.*


```solidity
GIndex public immutable GI_FIRST_VALIDATOR_CURR;
```


### GI_HISTORICAL_SUMMARIES_PREV
*This index is relative to a state like: `BeaconState.historical_summaries`.*


```solidity
GIndex public immutable GI_HISTORICAL_SUMMARIES_PREV;
```


### GI_HISTORICAL_SUMMARIES_CURR
*This index is relative to a state like: `BeaconState.historical_summaries`.*


```solidity
GIndex public immutable GI_HISTORICAL_SUMMARIES_CURR;
```


### FIRST_SUPPORTED_SLOT
*The very first slot the verifier is supposed to accept proofs for.*


```solidity
Slot public immutable FIRST_SUPPORTED_SLOT;
```


### PIVOT_SLOT
*The first slot of the currently compatible fork.*


```solidity
Slot public immutable PIVOT_SLOT;
```


### WITHDRAWAL_ADDRESS
*An address withdrawals are supposed to happen to (Lido withdrawal credentials).*


```solidity
address public immutable WITHDRAWAL_ADDRESS;
```


### MODULE
*Staking module contract*


```solidity
ICSModule public immutable MODULE;
```


## Functions
### constructor

*The previous and current forks can be essentially the same.*


```solidity
constructor(
    address withdrawalAddress,
    address module,
    uint64 slotsPerEpoch,
    GIndices memory gindices,
    Slot firstSupportedSlot,
    Slot pivotSlot,
    address admin
);
```

### resume

Resume write methods calls


```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause write methods calls for `duration` seconds


```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### processWithdrawalProof

Verify withdrawal proof and report withdrawal to the module for valid proofs


```solidity
function processWithdrawalProof(
    ProvableBeaconBlockHeader calldata beaconBlock,
    WithdrawalWitness calldata witness,
    uint256 nodeOperatorId,
    uint256 keyIndex
) external whenResumed;
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
) external whenResumed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`beaconBlock`|`ProvableBeaconBlockHeader`|Beacon block header|
|`oldBlock`|`HistoricalHeaderWitness`|Historical block header witness|
|`witness`|`WithdrawalWitness`|Withdrawal witness|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the validator key in the Node Operator's key storage|


### _getParentBlockRoot


```solidity
function _getParentBlockRoot(uint64 blockTimestamp) internal view returns (bytes32);
```

### _processWithdrawalProof

*`stateRoot` is supposed to be trusted at this point.*


```solidity
function _processWithdrawalProof(
    WithdrawalWitness calldata witness,
    Slot stateSlot,
    bytes32 stateRoot,
    bytes memory pubkey
) internal view returns (uint256 withdrawalAmount);
```

### _getValidatorGI


```solidity
function _getValidatorGI(uint256 offset, Slot stateSlot) internal view returns (GIndex);
```

### _getWithdrawalGI


```solidity
function _getWithdrawalGI(uint256 offset, Slot stateSlot) internal view returns (GIndex);
```

### _getHistoricalSummariesGI


```solidity
function _getHistoricalSummariesGI(Slot stateSlot) internal view returns (GIndex);
```

### _computeEpochAtSlot


```solidity
function _computeEpochAtSlot(Slot slot) internal view returns (uint256);
```

