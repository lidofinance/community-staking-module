# CSModule
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/CSModule.sol)

**Inherits:**
[ICSModule](/src/interfaces/ICSModule.sol/interface.ICSModule.md), Initializable, AccessControlEnumerableUpgradeable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md), [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)


## State Variables
### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### STAKING_ROUTER_ROLE

```solidity
bytes32 public constant STAKING_ROUTER_ROLE = keccak256("STAKING_ROUTER_ROLE");
```


### REPORT_EL_REWARDS_STEALING_PENALTY_ROLE

```solidity
bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE = keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE");
```


### SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE

```solidity
bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE = keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE");
```


### VERIFIER_ROLE

```solidity
bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
```


### RECOVERER_ROLE

```solidity
bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```


### CREATE_NODE_OPERATOR_ROLE

```solidity
bytes32 public constant CREATE_NODE_OPERATOR_ROLE = keccak256("CREATE_NODE_OPERATOR_ROLE");
```


### DEPOSIT_SIZE

```solidity
uint256 private constant DEPOSIT_SIZE = 32 ether;
```


### FORCED_TARGET_LIMIT_MODE_ID

```solidity
uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2;
```


### MODULE_TYPE

```solidity
bytes32 private immutable MODULE_TYPE;
```


### LIDO_LOCATOR

```solidity
ILidoLocator public immutable LIDO_LOCATOR;
```


### STETH

```solidity
IStETH public immutable STETH;
```


### PARAMETERS_REGISTRY

```solidity
ICSParametersRegistry public immutable PARAMETERS_REGISTRY;
```


### QUEUE_LOWEST_PRIORITY
*QUEUE_LOWEST_PRIORITY identifies the range of available priorities: [0; QUEUE_LOWEST_PRIORITY].*


```solidity
uint256 public immutable QUEUE_LOWEST_PRIORITY;
```


### QUEUE_LEGACY_PRIORITY

```solidity
uint256 public immutable QUEUE_LEGACY_PRIORITY;
```


### _queueByPriority
**Notes:**
- oz-renamed-from: keyRemovalCharge

- oz-retyped-from: uint256


```solidity
mapping(uint256 queuePriority => QueueLib.Queue queue) internal _queueByPriority;
```


### legacyQueue
*Legacy queue (priority=QUEUE_LEGACY_PRIORITY), that should be removed in the future once there are no more batches in it.*

**Note:**
oz-renamed-from: depositQueue


```solidity
QueueLib.Queue public legacyQueue;
```


### accounting

```solidity
ICSAccounting public accounting;
```


### _isValidatorExitDelayed
**Notes:**
- oz-renamed-from: earlyAdoption

- oz-retyped-from: address


```solidity
mapping(uint256 noKeyIndexPacked => uint256) private _isValidatorExitDelayed;
```


### _nonce

```solidity
uint256 private _nonce;
```


### _nodeOperators

```solidity
mapping(uint256 => NodeOperator) private _nodeOperators;
```


### _isValidatorWithdrawn
*see _keyPointer function for details of noKeyIndexPacked structure*


```solidity
mapping(uint256 noKeyIndexPacked => bool) private _isValidatorWithdrawn;
```


### _isValidatorSlashed
*DEPRECATED! No writes expected after Pectra hard-fork*


```solidity
mapping(uint256 noKeyIndexPacked => bool) private _isValidatorSlashed;
```


### _totalDepositedValidators

```solidity
uint64 private _totalDepositedValidators;
```


### _totalExitedValidators

```solidity
uint64 private _totalExitedValidators;
```


### _depositableValidatorsCount

```solidity
uint64 private _depositableValidatorsCount;
```


### _nodeOperatorsCount

```solidity
uint64 private _nodeOperatorsCount;
```


## Functions
### constructor


```solidity
constructor(bytes32 moduleType, address lidoLocator, address parametersRegistry);
```

### initialize

initialize the module from scratch


```solidity
function initialize(address _accounting, address admin) external reinitializer(2);
```

### finalizeUpgradeV2

*should be called after update on the proxy*


```solidity
function finalizeUpgradeV2() external reinitializer(2);
```

### resume

Resume creation of the Node Operators and keys upload


```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause creation of the Node Operators and keys upload for `duration` seconds.
Existing NO management and reward claims are still available.
To pause reward claims use pause method on CSAccounting


```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### createNodeOperator

Permissioned method to add a new Node Operator
Should be called by `*Gate.sol` contracts. See `PermissionlessGate.sol` and `VettedGate.sol` for examples


```solidity
function createNodeOperator(
    address from,
    NodeOperatorManagementProperties calldata managementProperties,
    address referrer
) external onlyRole(CREATE_NODE_OPERATOR_ROLE) whenResumed returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Sender address. Initial sender address to be used as a default manager and reward addresses|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `from` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `from` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`referrer`|`address`|Optional. Referrer address. Should be passed when Node Operator is created using partners integration|


### addValidatorKeysETH

Add new keys to the existing Node Operator using ETH as a bond


```solidity
function addValidatorKeysETH(
    address from,
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures
) external payable whenResumed;
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


```solidity
function addValidatorKeysStETH(
    address from,
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures,
    ICSAccounting.PermitInput calldata permit
) external whenResumed;
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


```solidity
function addValidatorKeysWstETH(
    address from,
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures,
    ICSAccounting.PermitInput calldata permit
) external whenResumed;
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


### onRewardsMinted

Called by StakingRouter to signal that stETH rewards were minted for this module.

*Passes through the minted stETH shares to the fee distributor*


```solidity
function onRewardsMinted(uint256 totalShares) external onlyRole(STAKING_ROUTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`totalShares`|`uint256`|Amount of stETH shares that were minted to reward all node operators.|


### updateExitedValidatorsCount

Updates the number of the validators in the EXITED state for node operator with given id


```solidity
function updateExitedValidatorsCount(bytes calldata nodeOperatorIds, bytes calldata exitedValidatorsCounts)
    external
    onlyRole(STAKING_ROUTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorIds`|`bytes`|bytes packed array of the node operators id|
|`exitedValidatorsCounts`|`bytes`|bytes packed array of the new number of EXITED validators for the node operators|


### updateTargetValidatorsLimits

Updates the limit of the validators that can be used for deposit


```solidity
function updateTargetValidatorsLimits(uint256 nodeOperatorId, uint256 targetLimitMode, uint256 targetLimit)
    external
    onlyRole(STAKING_ROUTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`targetLimitMode`|`uint256`|Target limit mode for the Node Operator (see https://hackmd.io/@lido/BJXRTxMRp) 0 - disabled 1 - soft mode 2 - forced mode|
|`targetLimit`|`uint256`|Target limit of validators|


### onExitedAndStuckValidatorsCountsUpdated

Called by StakingRouter after it finishes updating exited and stuck validators
counts for this module's node operators.
Guaranteed to be called after an oracle report is applied, regardless of whether any node
operator in this module has actually received any updated counts as a result of the report
but given that the total number of exited validators returned from getStakingModuleSummary
is the same as StakingRouter expects based on the total count received from the oracle.

*This method is not used in CSM, hence it is do nothing*


```solidity
function onExitedAndStuckValidatorsCountsUpdated() external onlyRole(STAKING_ROUTER_ROLE);
```

### unsafeUpdateValidatorsCount

Unsafely updates the number of validators in the EXITED/STUCK states for node operator with given id
'unsafely' means that this method can both increase and decrease exited and stuck counters


```solidity
function unsafeUpdateValidatorsCount(
    uint256 nodeOperatorId,
    uint256 exitedValidatorsKeysCount,
    uint256 stuckValidatorsKeysCount
) external onlyRole(STAKING_ROUTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the node operator|
|`exitedValidatorsKeysCount`|`uint256`||
|`stuckValidatorsKeysCount`|`uint256`||


### decreaseVettedSigningKeysCount

Called by StakingRouter to decrease the number of vetted keys for Node Operators with given ids


```solidity
function decreaseVettedSigningKeysCount(bytes calldata nodeOperatorIds, bytes calldata vettedSigningKeysCounts)
    external
    onlyRole(STAKING_ROUTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorIds`|`bytes`|Bytes packed array of the Node Operator ids|
|`vettedSigningKeysCounts`|`bytes`|Bytes packed array of the new numbers of vetted keys for the Node Operators|


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


### updateDepositableValidatorsCount

TODO: Consider renaming


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

*TODO: Remove the method in the next major release.*


```solidity
function migrateToPriorityQueue(uint256 nodeOperatorId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### reportELRewardsStealingPenalty

Report EL rewards stealing for the given Node Operator


```solidity
function reportELRewardsStealingPenalty(uint256 nodeOperatorId, bytes32 blockHash, uint256 amount)
    external
    onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`blockHash`|`bytes32`|Execution layer block hash of the proposed block with EL rewards stealing|
|`amount`|`uint256`|Amount of stolen EL rewards in ETH|


### cancelELRewardsStealingPenalty

Cancel previously reported and not settled EL rewards stealing penalty for the given Node Operator


```solidity
function cancelELRewardsStealingPenalty(uint256 nodeOperatorId, uint256 amount)
    external
    onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE);
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
function settleELRewardsStealingPenalty(uint256[] calldata nodeOperatorIds)
    external
    onlyRole(SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorIds`|`uint256[]`|IDs of the Node Operators|


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


### submitWithdrawals

Report Node Operator's keys as withdrawn and settle withdrawn amount


```solidity
function submitWithdrawals(ValidatorWithdrawalInfo[] calldata withdrawalsInfo) external onlyRole(VERIFIER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalsInfo`|`ValidatorWithdrawalInfo[]`|An array for the validator withdrawals info structs|


### onWithdrawalCredentialsChanged

Called by StakingRouter when withdrawal credentials are changed.

*Does nothing*

*Changing the WC means that the current deposit data in the queue is not valid anymore and can't be deposited.
DSM will unvet current keys.
The key removal charge should be reset to 0 to allow Node Operators to remove the keys without any charge.
After keys removal the DAO should set the new key removal charge.*


```solidity
function onWithdrawalCredentialsChanged() external onlyRole(STAKING_ROUTER_ROLE);
```

### reportValidatorExitDelay

Handles tracking and penalization logic for validators that remain active beyond their eligible exit window.

*This function is called to report the current exit-related status of validator belonging to a specific node operator.
It accepts a validator public key associated with the duration (in seconds) they was eligible to exit but have not.
This data could be used to trigger penalties for the node operator if validator has been non-exiting for too long.*


```solidity
function reportValidatorExitDelay(uint256, uint256, bytes calldata, uint256) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`bytes`||
|`<none>`|`uint256`||


### onValidatorExitTriggered

Handles the triggerable exit event validator belonging to a specific node operator.

*This function is called when a validator is exited using the triggerable exit request on EL.*


```solidity
function onValidatorExitTriggered(uint256, bytes calldata, uint256, uint256) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`||
|`<none>`|`bytes`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||


### obtainDepositData

Get the next `depositsCount` of depositable keys with signatures from the queue

*Second param `depositCalldata` is not used*


```solidity
function obtainDepositData(uint256 depositsCount, bytes calldata)
    external
    onlyRole(STAKING_ROUTER_ROLE)
    returns (bytes memory publicKeys, bytes memory signatures);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`depositsCount`|`uint256`|Number of deposits to be done|
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`publicKeys`|`bytes`|Batch of the concatenated public validators keys|
|`signatures`|`bytes`|Batch of the concatenated deposit signatures for returned public keys|


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


### getInitializedVersion

Returns the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

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
|`index`|`uint128`|Index of a queue item (continuous numbering)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Batch`|Deposit queue item and the priority of the queue|


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
|`<none>`|`bool`|Validator reported as withdrawn flag|


### getType

Returns the type of the staking module


```solidity
function getType() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Module type|


### getStakingModuleSummary

Returns all-validators summary in the staking module


```solidity
function getStakingModuleSummary()
    external
    view
    returns (uint256 totalExitedValidators, uint256 totalDepositedValidators, uint256 depositableValidatorsCount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalExitedValidators`|`uint256`|total number of validators in the EXITED state on the Consensus Layer. This value can't decrease in normal conditions|
|`totalDepositedValidators`|`uint256`|total number of validators deposited via the official Deposit Contract. This value is a cumulative counter: even when the validator goes into EXITED state this counter is not decreasing|
|`depositableValidatorsCount`|`uint256`|number of validators in the set available for deposit|


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


### getNodeOperatorSummary

depositableValidatorsCount depends on:
- totalVettedKeys
- totalDepositedKeys
- totalExitedKeys
- targetLimitMode
- targetValidatorsCount
- totalUnbondedKeys
- totalStuckKeys


```solidity
function getNodeOperatorSummary(uint256 nodeOperatorId)
    external
    view
    returns (
        uint256 targetLimitMode,
        uint256 targetValidatorsCount,
        uint256 stuckValidatorsCount,
        uint256 refundedValidatorsCount,
        uint256 stuckPenaltyEndTimestamp,
        uint256 totalExitedValidators,
        uint256 totalDepositedValidators,
        uint256 depositableValidatorsCount
    );
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|id of the operator to return report for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`targetLimitMode`|`uint256`|shows whether the current target limit applied to the node operator (1 = soft mode, 2 = forced mode)|
|`targetValidatorsCount`|`uint256`|relative target active validators limit for operator|
|`stuckValidatorsCount`|`uint256`|number of validators with an expired request to exit time|
|`refundedValidatorsCount`|`uint256`|number of validators that can't be withdrawn, but deposit costs were compensated to the Lido by the node operator|
|`stuckPenaltyEndTimestamp`|`uint256`|time when the penalty for stuck validators stops applying to node operator rewards|
|`totalExitedValidators`|`uint256`|total number of validators in the EXITED state on the Consensus Layer. This value can't decrease in normal conditions|
|`totalDepositedValidators`|`uint256`|total number of validators deposited via the official Deposit Contract. This value is a cumulative counter: even when the validator goes into EXITED state this counter is not decreasing|
|`depositableValidatorsCount`|`uint256`|number of validators in the set available for deposit|


### getNodeOperatorTotalDepositedKeys

Get Node Operator total deposited keys


```solidity
function getNodeOperatorTotalDepositedKeys(uint256 nodeOperatorId) external view returns (uint256 totalDepositedKeys);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalDepositedKeys`|`uint256`|Total deposited keys count|


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


### getNonce

Get nonce of the module


```solidity
function getNonce() external view returns (uint256);
```

### getNodeOperatorsCount

Returns total number of node operators


```solidity
function getNodeOperatorsCount() external view returns (uint256);
```

### getActiveNodeOperatorsCount

Returns number of active node operators


```solidity
function getActiveNodeOperatorsCount() external view returns (uint256);
```

### getNodeOperatorIsActive

Returns if the node operator with given id is active


```solidity
function getNodeOperatorIsActive(uint256 nodeOperatorId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the node operator|


### getNodeOperatorIds

Returns up to `limit` node operator ids starting from the `offset`. The order of
the returned ids is not defined and might change between calls.

*This view must not revert in case of invalid data passed. When `offset` exceeds the
total node operators count or when `limit` is equal to 0 MUST be returned empty array.*


```solidity
function getNodeOperatorIds(uint256 offset, uint256 limit) external view returns (uint256[] memory nodeOperatorIds);
```

### isValidatorExitDelayPenaltyApplicable

Determines whether a validator exit status should be updated and will have affect on Node Operator.


```solidity
function isValidatorExitDelayPenaltyApplicable(uint256, uint256, bytes calldata, uint256)
    external
    view
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`bytes`||
|`<none>`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool Returns true if contract should receive updated validator's status.|


### exitDeadlineThreshold

Returns the delay after which a validator is considered late.


```solidity
function exitDeadlineThreshold(uint256 nodeOperatorId) external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The exit deadline threshold.|


### _incrementModuleNonce


```solidity
function _incrementModuleNonce() internal;
```

### _addKeysAndUpdateDepositableValidatorsCount


```solidity
function _addKeysAndUpdateDepositableValidatorsCount(
    uint256 nodeOperatorId,
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures
) internal;
```

### _updateExitedValidatorsCount

*Update exited validators count for a single Node Operator*

*Allows decrease the count for unsafe updates*


```solidity
function _updateExitedValidatorsCount(uint256 nodeOperatorId, uint256 exitedValidatorsCount, bool allowDecrease)
    internal;
```

### _updateDepositableValidatorsCount


```solidity
function _updateDepositableValidatorsCount(uint256 nodeOperatorId, bool incrementNonceIfUpdated) internal;
```

### _enqueueNodeOperatorKeys


```solidity
function _enqueueNodeOperatorKeys(uint256 nodeOperatorId) internal;
```

### _enqueueNodeOperatorKeys


```solidity
function _enqueueNodeOperatorKeys(uint256 nodeOperatorId, uint256 queuePriority, uint32 maxKeys) internal;
```

### _getQueue

*Acts as a proxy to `_queueByPriority` till `legacyQueue` deprecation.*

*TODO: Remove in CSM v3.*


```solidity
function _getQueue(uint256 priority) internal view returns (QueueLib.Queue storage q);
```

### _checkCanAddKeys


```solidity
function _checkCanAddKeys(uint256 nodeOperatorId, address who) internal view;
```

### _onlyNodeOperatorManager


```solidity
function _onlyNodeOperatorManager(uint256 nodeOperatorId, address from) internal view;
```

### _onlyExistingNodeOperator


```solidity
function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view;
```

### _onlyValidIndexRange


```solidity
function _onlyValidIndexRange(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount) internal view;
```

### _onlyRecoverer


```solidity
function _onlyRecoverer() internal view override;
```

### _keyPointer

*Both nodeOperatorId and keyIndex are limited to uint64 by the contract*


```solidity
function _keyPointer(uint256 nodeOperatorId, uint256 keyIndex) internal pure returns (uint256);
```

