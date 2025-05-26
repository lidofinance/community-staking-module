# ICSModule
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSModule.sol)

**Inherits:**
[IQueueLib](/src/lib/QueueLib.sol/interface.IQueueLib.md), [INOAddresses](/src/lib/NOAddresses.sol/interface.INOAddresses.md), [IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md), [IStakingModule](/src/interfaces/IStakingModule.sol/interface.IStakingModule.md)


## Functions
### PAUSE_ROLE


```solidity
function PAUSE_ROLE() external view returns (bytes32);
```

### RESUME_ROLE


```solidity
function RESUME_ROLE() external view returns (bytes32);
```

### STAKING_ROUTER_ROLE


```solidity
function STAKING_ROUTER_ROLE() external view returns (bytes32);
```

### REPORT_EL_REWARDS_STEALING_PENALTY_ROLE


```solidity
function REPORT_EL_REWARDS_STEALING_PENALTY_ROLE() external view returns (bytes32);
```

### SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE


```solidity
function SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE() external view returns (bytes32);
```

### VERIFIER_ROLE


```solidity
function VERIFIER_ROLE() external view returns (bytes32);
```

### RECOVERER_ROLE


```solidity
function RECOVERER_ROLE() external view returns (bytes32);
```

### CREATE_NODE_OPERATOR_ROLE


```solidity
function CREATE_NODE_OPERATOR_ROLE() external view returns (bytes32);
```

### DEPOSIT_SIZE


```solidity
function DEPOSIT_SIZE() external view returns (uint256);
```

### LIDO_LOCATOR


```solidity
function LIDO_LOCATOR() external view returns (ILidoLocator);
```

### STETH


```solidity
function STETH() external view returns (IStETH);
```

### PARAMETERS_REGISTRY


```solidity
function PARAMETERS_REGISTRY() external view returns (ICSParametersRegistry);
```

### ACCOUNTING


```solidity
function ACCOUNTING() external view returns (ICSAccounting);
```

### EXIT_PENALTIES


```solidity
function EXIT_PENALTIES() external view returns (ICSExitPenalties);
```

### FEE_DISTRIBUTOR


```solidity
function FEE_DISTRIBUTOR() external view returns (address);
```

### QUEUE_LOWEST_PRIORITY


```solidity
function QUEUE_LOWEST_PRIORITY() external view returns (uint256);
```

### QUEUE_LEGACY_PRIORITY


```solidity
function QUEUE_LEGACY_PRIORITY() external view returns (uint256);
```

### accounting

Returns the address of the accounting contract


```solidity
function accounting() external view returns (ICSAccounting);
```

### pauseFor

Pause creation of the Node Operators and keys upload for `duration` seconds.
Existing NO management and reward claims are still available.
To pause reward claims use pause method on CSAccounting


```solidity
function pauseFor(uint256 duration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### resume

Resume creation of the Node Operators and keys upload


```solidity
function resume() external;
```

### getInitializedVersion

Returns the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

### createNodeOperator

Permissioned method to add a new Node Operator
Should be called by `*Gate.sol` contracts. See `PermissionlessGate.sol` and `VettedGate.sol` for examples


```solidity
function createNodeOperator(
    address from,
    NodeOperatorManagementProperties memory managementProperties,
    address referrer
) external returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Sender address. Initial sender address to be used as a default manager and reward addresses. Gates must pass the correct address in order to specify which address should be the owner of the Node Operator|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `from` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `from` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`referrer`|`address`|Optional. Referrer address. Should be passed when Node Operator is created using partners integration|


### addValidatorKeysETH

Add new keys to the existing Node Operator using ETH as a bond


```solidity
function addValidatorKeysETH(
    address from,
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes memory publicKeys,
    bytes memory signatures
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Sender address. Commonly equals to `msg.sender` except for the case of Node Operator creation by `*Gate.sol` contracts|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|


### addValidatorKeysStETH

Add new keys to the existing Node Operator using stETH as a bond

Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert


```solidity
function addValidatorKeysStETH(
    address from,
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes memory publicKeys,
    bytes memory signatures,
    ICSAccounting.PermitInput memory permit
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Sender address. Commonly equals to `msg.sender` except for the case of Node Operator creation by `*Gate.sol` contracts|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`permit`|`ICSAccounting.PermitInput`|Optional. Permit to use stETH as bond|


### addValidatorKeysWstETH

Add new keys to the existing Node Operator using wstETH as a bond

Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert


```solidity
function addValidatorKeysWstETH(
    address from,
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes memory publicKeys,
    bytes memory signatures,
    ICSAccounting.PermitInput memory permit
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Sender address. Commonly equals to `msg.sender` except for the case of Node Operator creation by `*Gate.sol` contracts|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`permit`|`ICSAccounting.PermitInput`|Optional. Permit to use wstETH as bond|


### reportELRewardsStealingPenalty

Report EL rewards stealing for the given Node Operator

The final locked amount will be equal to the stolen funds plus EL stealing additional fine


```solidity
function reportELRewardsStealingPenalty(uint256 nodeOperatorId, bytes32 blockHash, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`blockHash`|`bytes32`|Execution layer block hash of the proposed block with EL rewards stealing|
|`amount`|`uint256`|Amount of stolen EL rewards in ETH|


### compensateELRewardsStealingPenalty

Compensate EL rewards stealing penalty for the given Node Operator to prevent further validator exits

*Can only be called by the Node Operator manager*


```solidity
function compensateELRewardsStealingPenalty(uint256 nodeOperatorId) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### cancelELRewardsStealingPenalty

Cancel previously reported and not settled EL rewards stealing penalty for the given Node Operator

The funds will be unlocked


```solidity
function cancelELRewardsStealingPenalty(uint256 nodeOperatorId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`amount`|`uint256`|Amount of penalty to cancel|


### settleELRewardsStealingPenalty

Settle locked bond for the given Node Operators

*SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE role is expected to be assigned to Easy Track*


```solidity
function settleELRewardsStealingPenalty(uint256[] memory nodeOperatorIds) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorIds`|`uint256[]`|IDs of the Node Operators|


### proposeNodeOperatorManagerAddressChange

Propose a new manager address for the Node Operator


```solidity
function proposeNodeOperatorManagerAddressChange(uint256 nodeOperatorId, address proposedAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`proposedAddress`|`address`|Proposed manager address|


### confirmNodeOperatorManagerAddressChange

Confirm a new manager address for the Node Operator.
Should be called from the currently proposed address


```solidity
function confirmNodeOperatorManagerAddressChange(uint256 nodeOperatorId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### resetNodeOperatorManagerAddress

Reset the manager address to the reward address.
Should be called from the reward address


```solidity
function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### proposeNodeOperatorRewardAddressChange

Propose a new reward address for the Node Operator


```solidity
function proposeNodeOperatorRewardAddressChange(uint256 nodeOperatorId, address proposedAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`proposedAddress`|`address`|Proposed reward address|


### confirmNodeOperatorRewardAddressChange

Confirm a new reward address for the Node Operator.
Should be called from the currently proposed address


```solidity
function confirmNodeOperatorRewardAddressChange(uint256 nodeOperatorId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### changeNodeOperatorRewardAddress

Change rewardAddress if extendedManagerPermissions is enabled for the Node Operator


```solidity
function changeNodeOperatorRewardAddress(uint256 nodeOperatorId, address newAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`newAddress`|`address`|Proposed reward address|


### depositQueuePointers

Get the pointers to the head and tail of queue with the given priority.


```solidity
function depositQueuePointers(uint256 queuePriority) external view returns (uint128 head, uint128 tail);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`queuePriority`|`uint256`|Priority of the queue to get the pointers.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`head`|`uint128`|Pointer to the head of the queue.|
|`tail`|`uint128`|Pointer to the tail of the queue.|


### depositQueueItem

Get the deposit queue item by an index


```solidity
function depositQueueItem(uint256 queuePriority, uint128 index) external view returns (Batch);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`queuePriority`|`uint256`|Priority of the queue to get an item from|
|`index`|`uint128`|Index of a queue item|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Batch`|Deposit queue item from the priority queue|


### cleanDepositQueue

Clean the deposit queue from batches with no depositable keys

*Use **eth_call** to check how many items will be removed*


```solidity
function cleanDepositQueue(uint256 maxItems) external returns (uint256 removed, uint256 lastRemovedAtDepth);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxItems`|`uint256`|How many queue items to review|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`removed`|`uint256`|Count of batches to be removed by visiting `maxItems` batches|
|`lastRemovedAtDepth`|`uint256`|The value to use as `maxItems` to remove `removed` batches if the static call of the method was used|


### updateDepositableValidatorsCount

Update depositable validators data and enqueue all unqueued keys for the given Node Operator

Unqueued stands for vetted but not enqueued keys


```solidity
function updateDepositableValidatorsCount(uint256 nodeOperatorId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### migrateToPriorityQueue

Performs a one-time migration of allocated seats from the legacy queue to a priority queue
for an eligible node operator. This is possible, e.g., in the following scenario: A node
operator with EA curve added their keys before CSM v2 and has no deposits due to a very long
queue. The EA curve gives the node operator the ability to get some count of deposits through
the priority queue. So, by calling the migration method, the node operator can obtain seats
in the priority queue even though they already have seats in the legacy queue.


```solidity
function migrateToPriorityQueue(uint256 nodeOperatorId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### getNodeOperator

Get Node Operator info


```solidity
function getNodeOperator(uint256 nodeOperatorId) external view returns (NodeOperator memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NodeOperator`|Node Operator info|


### getNodeOperatorManagementProperties

Get Node Operator management properties


```solidity
function getNodeOperatorManagementProperties(uint256 nodeOperatorId)
    external
    view
    returns (NodeOperatorManagementProperties memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NodeOperatorManagementProperties`|Node Operator management properties|


### getNodeOperatorOwner

Get Node Operator owner. Owner is manager address if `extendedManagerPermissions` is enabled and reward address otherwise


```solidity
function getNodeOperatorOwner(uint256 nodeOperatorId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Node Operator owner|


### getNodeOperatorNonWithdrawnKeys

Get Node Operator non-withdrawn keys


```solidity
function getNodeOperatorNonWithdrawnKeys(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Non-withdrawn keys count|


### getNodeOperatorTotalDepositedKeys

Get Node Operator total deposited keys


```solidity
function getNodeOperatorTotalDepositedKeys(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total deposited keys count|


### getSigningKeys

Get Node Operator signing keys


```solidity
function getSigningKeys(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount)
    external
    view
    returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`startIndex`|`uint256`|Index of the first key|
|`keysCount`|`uint256`|Count of keys to get|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|Signing keys|


### getSigningKeysWithSignatures

Get Node Operator signing keys with signatures


```solidity
function getSigningKeysWithSignatures(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount)
    external
    view
    returns (bytes memory keys, bytes memory signatures);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`startIndex`|`uint256`|Index of the first key|
|`keysCount`|`uint256`|Count of keys to get|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`keys`|`bytes`|Signing keys|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|


### submitWithdrawals

Report Node Operator's keys as withdrawn and settle withdrawn amount

Called by `CSVerifier` contract.
See `CSVerifier.processWithdrawalProof` to use this method permissionless


```solidity
function submitWithdrawals(ValidatorWithdrawalInfo[] calldata withdrawalsInfo) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalsInfo`|`ValidatorWithdrawalInfo[]`|An array for the validator withdrawals info structs|


### isValidatorWithdrawn

Check if the given Node Operator's key is reported as withdrawn


```solidity
function isValidatorWithdrawn(uint256 nodeOperatorId, uint256 keyIndex) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|index of the key to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Is validator reported as withdrawn or not|


### removeKeys

Remove keys for the Node Operator and confiscate removal charge for each deleted key


```solidity
function removeKeys(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`startIndex`|`uint256`|Index of the first key|
|`keysCount`|`uint256`|Keys count to delete|


## Events
### NodeOperatorAdded

```solidity
event NodeOperatorAdded(
    uint256 indexed nodeOperatorId,
    address indexed managerAddress,
    address indexed rewardAddress,
    bool extendedManagerPermissions
);
```

### ReferrerSet

```solidity
event ReferrerSet(uint256 indexed nodeOperatorId, address indexed referrer);
```

### DepositableSigningKeysCountChanged

```solidity
event DepositableSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 depositableKeysCount);
```

### VettedSigningKeysCountChanged

```solidity
event VettedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 vettedKeysCount);
```

### VettedSigningKeysCountDecreased

```solidity
event VettedSigningKeysCountDecreased(uint256 indexed nodeOperatorId);
```

### DepositedSigningKeysCountChanged

```solidity
event DepositedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 depositedKeysCount);
```

### ExitedSigningKeysCountChanged

```solidity
event ExitedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 exitedKeysCount);
```

### TotalSigningKeysCountChanged

```solidity
event TotalSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 totalKeysCount);
```

### TargetValidatorsCountChanged

```solidity
event TargetValidatorsCountChanged(
    uint256 indexed nodeOperatorId, uint256 targetLimitMode, uint256 targetValidatorsCount
);
```

### WithdrawalSubmitted

```solidity
event WithdrawalSubmitted(uint256 indexed nodeOperatorId, uint256 keyIndex, uint256 amount, bytes pubkey);
```

### BatchEnqueued

```solidity
event BatchEnqueued(uint256 indexed queuePriority, uint256 indexed nodeOperatorId, uint256 count);
```

### KeyRemovalChargeApplied

```solidity
event KeyRemovalChargeApplied(uint256 indexed nodeOperatorId);
```

### ELRewardsStealingPenaltyReported

```solidity
event ELRewardsStealingPenaltyReported(uint256 indexed nodeOperatorId, bytes32 proposedBlockHash, uint256 stolenAmount);
```

### ELRewardsStealingPenaltyCancelled

```solidity
event ELRewardsStealingPenaltyCancelled(uint256 indexed nodeOperatorId, uint256 amount);
```

### ELRewardsStealingPenaltyCompensated

```solidity
event ELRewardsStealingPenaltyCompensated(uint256 indexed nodeOperatorId, uint256 amount);
```

### ELRewardsStealingPenaltySettled

```solidity
event ELRewardsStealingPenaltySettled(uint256 indexed nodeOperatorId);
```

## Errors
### CannotAddKeys

```solidity
error CannotAddKeys();
```

### NodeOperatorDoesNotExist

```solidity
error NodeOperatorDoesNotExist();
```

### SenderIsNotEligible

```solidity
error SenderIsNotEligible();
```

### InvalidVetKeysPointer

```solidity
error InvalidVetKeysPointer();
```

### ExitedKeysHigherThanTotalDeposited

```solidity
error ExitedKeysHigherThanTotalDeposited();
```

### ExitedKeysDecrease

```solidity
error ExitedKeysDecrease();
```

### InvalidInput

```solidity
error InvalidInput();
```

### NotEnoughKeys

```solidity
error NotEnoughKeys();
```

### PriorityQueueAlreadyUsed

```solidity
error PriorityQueueAlreadyUsed();
```

### KeysLimitExceeded

```solidity
error KeysLimitExceeded();
```

### SigningKeysInvalidOffset

```solidity
error SigningKeysInvalidOffset();
```

### AlreadyWithdrawn

```solidity
error AlreadyWithdrawn();
```

### InvalidAmount

```solidity
error InvalidAmount();
```

### ZeroLocatorAddress

```solidity
error ZeroLocatorAddress();
```

### ZeroAccountingAddress

```solidity
error ZeroAccountingAddress();
```

### ZeroExitPenaltiesAddress

```solidity
error ZeroExitPenaltiesAddress();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroSenderAddress

```solidity
error ZeroSenderAddress();
```

### ZeroParametersRegistryAddress

```solidity
error ZeroParametersRegistryAddress();
```

