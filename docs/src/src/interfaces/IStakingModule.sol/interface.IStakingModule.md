# IStakingModule

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/interfaces/IStakingModule.sol)

## Functions

### getType

Returns the type of the staking module

```solidity
function getType() external view returns (bytes32);
```

### getStakingModuleSummary

Returns all-validators summary in the staking module

```solidity
function getStakingModuleSummary()
  external
  view
  returns (
    uint256 totalExitedValidators,
    uint256 totalDepositedValidators,
    uint256 depositableValidatorsCount
  );
```

**Returns**

| Name                         | Type      | Description                                                                                                                                                                               |
| ---------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `totalExitedValidators`      | `uint256` | total number of validators in the EXITED state on the Consensus Layer. This value can't decrease in normal conditions                                                                     |
| `totalDepositedValidators`   | `uint256` | total number of validators deposited via the official Deposit Contract. This value is a cumulative counter: even when the validator goes into EXITED state this counter is not decreasing |
| `depositableValidatorsCount` | `uint256` | number of validators in the set available for deposit                                                                                                                                     |

### getNodeOperatorSummary

Returns all-validators summary belonging to the node operator with the given id

```solidity
function getNodeOperatorSummary(
  uint256 _nodeOperatorId
)
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

| Name              | Type      | Description                             |
| ----------------- | --------- | --------------------------------------- |
| `_nodeOperatorId` | `uint256` | id of the operator to return report for |

**Returns**

| Name                         | Type      | Description                                                                                                                                                                               |
| ---------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `targetLimitMode`            | `uint256` | shows whether the current target limit applied to the node operator (1 = soft mode, 2 = forced mode)                                                                                      |
| `targetValidatorsCount`      | `uint256` | relative target active validators limit for operator                                                                                                                                      |
| `stuckValidatorsCount`       | `uint256` | number of validators with an expired request to exit time                                                                                                                                 |
| `refundedValidatorsCount`    | `uint256` | number of validators that can't be withdrawn, but deposit costs were compensated to the Lido by the node operator                                                                         |
| `stuckPenaltyEndTimestamp`   | `uint256` | time when the penalty for stuck validators stops applying to node operator rewards                                                                                                        |
| `totalExitedValidators`      | `uint256` | total number of validators in the EXITED state on the Consensus Layer. This value can't decrease in normal conditions                                                                     |
| `totalDepositedValidators`   | `uint256` | total number of validators deposited via the official Deposit Contract. This value is a cumulative counter: even when the validator goes into EXITED state this counter is not decreasing |
| `depositableValidatorsCount` | `uint256` | number of validators in the set available for deposit                                                                                                                                     |

### getNonce

Returns a counter that MUST change its value whenever the deposit data set changes.
Below is the typical list of actions that requires an update of the nonce:

1. a node operator's deposit data is added
2. a node operator's deposit data is removed
3. a node operator's ready-to-deposit data size is changed
4. a node operator was activated/deactivated
5. a node operator's deposit data is used for the deposit
   Note: Depending on the StakingModule implementation above list might be extended

_In some scenarios, it's allowed to update nonce without actual change of the deposit
data subset, but it MUST NOT lead to the DOS of the staking module via continuous
update of the nonce by the malicious actor_

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
function getNodeOperatorIsActive(uint256 _nodeOperatorId) external view returns (bool);
```

**Parameters**

| Name              | Type      | Description             |
| ----------------- | --------- | ----------------------- |
| `_nodeOperatorId` | `uint256` | Id of the node operator |

### getNodeOperatorIds

Returns up to `_limit` node operator ids starting from the `_offset`. The order of
the returned ids is not defined and might change between calls.

_This view must not revert in case of invalid data passed. When `_offset` exceeds the
total node operators count or when `_limit` is equal to 0 MUST be returned empty array._

```solidity
function getNodeOperatorIds(
  uint256 _offset,
  uint256 _limit
) external view returns (uint256[] memory nodeOperatorIds);
```

### onRewardsMinted

Called by StakingRouter to signal that stETH rewards were minted for this module.

_IMPORTANT: this method SHOULD revert with empty error data ONLY because of "out of gas".
Details about error data: https://docs.soliditylang.org/en/v0.8.9/control-structures.html#error-handling-assert-require-revert-and-exceptions_

```solidity
function onRewardsMinted(uint256 _totalShares) external;
```

**Parameters**

| Name           | Type      | Description                                                           |
| -------------- | --------- | --------------------------------------------------------------------- |
| `_totalShares` | `uint256` | Amount of stETH shares that were minted to reward all node operators. |

### decreaseVettedSigningKeysCount

Called by StakingRouter to decrease the number of vetted keys for node operator with given id

```solidity
function decreaseVettedSigningKeysCount(
  bytes calldata _nodeOperatorIds,
  bytes calldata _vettedSigningKeysCounts
) external;
```

**Parameters**

| Name                       | Type    | Description                                                                |
| -------------------------- | ------- | -------------------------------------------------------------------------- |
| `_nodeOperatorIds`         | `bytes` | bytes packed array of the node operators id                                |
| `_vettedSigningKeysCounts` | `bytes` | bytes packed array of the new number of vetted keys for the node operators |

### updateStuckValidatorsCount

Updates the number of the validators of the given node operator that were requested
to exit but failed to do so in the max allowed time

```solidity
function updateStuckValidatorsCount(
  bytes calldata _nodeOperatorIds,
  bytes calldata _stuckValidatorsCounts
) external;
```

**Parameters**

| Name                     | Type    | Description                                                                     |
| ------------------------ | ------- | ------------------------------------------------------------------------------- |
| `_nodeOperatorIds`       | `bytes` | bytes packed array of the node operators id                                     |
| `_stuckValidatorsCounts` | `bytes` | bytes packed array of the new number of STUCK validators for the node operators |

### updateExitedValidatorsCount

Updates the number of the validators in the EXITED state for node operator with given id

```solidity
function updateExitedValidatorsCount(
  bytes calldata _nodeOperatorIds,
  bytes calldata _exitedValidatorsCounts
) external;
```

**Parameters**

| Name                      | Type    | Description                                                                      |
| ------------------------- | ------- | -------------------------------------------------------------------------------- |
| `_nodeOperatorIds`        | `bytes` | bytes packed array of the node operators id                                      |
| `_exitedValidatorsCounts` | `bytes` | bytes packed array of the new number of EXITED validators for the node operators |

### updateRefundedValidatorsCount

Updates the number of the refunded validators for node operator with the given id

```solidity
function updateRefundedValidatorsCount(
  uint256 _nodeOperatorId,
  uint256 _refundedValidatorsCount
) external;
```

**Parameters**

| Name                       | Type      | Description                                            |
| -------------------------- | --------- | ------------------------------------------------------ |
| `_nodeOperatorId`          | `uint256` | Id of the node operator                                |
| `_refundedValidatorsCount` | `uint256` | New number of refunded validators of the node operator |

### updateTargetValidatorsLimits

Updates the limit of the validators that can be used for deposit

```solidity
function updateTargetValidatorsLimits(
  uint256 _nodeOperatorId,
  uint256 _targetLimitMode,
  uint256 _targetLimit
) external;
```

**Parameters**

| Name               | Type      | Description                       |
| ------------------ | --------- | --------------------------------- |
| `_nodeOperatorId`  | `uint256` | Id of the node operator           |
| `_targetLimitMode` | `uint256` | target limit mode                 |
| `_targetLimit`     | `uint256` | Target limit of the node operator |

### unsafeUpdateValidatorsCount

Unsafely updates the number of validators in the EXITED/STUCK states for node operator with given id
'unsafely' means that this method can both increase and decrease exited and stuck counters

```solidity
function unsafeUpdateValidatorsCount(
  uint256 _nodeOperatorId,
  uint256 _exitedValidatorsCount,
  uint256 _stuckValidatorsCount
) external;
```

**Parameters**

| Name                     | Type      | Description                                           |
| ------------------------ | --------- | ----------------------------------------------------- |
| `_nodeOperatorId`        | `uint256` | Id of the node operator                               |
| `_exitedValidatorsCount` | `uint256` | New number of EXITED validators for the node operator |
| `_stuckValidatorsCount`  | `uint256` | New number of STUCK validator for the node operator   |

### obtainDepositData

Obtains deposit data to be used by StakingRouter to deposit to the Ethereum Deposit
contract

_The method MUST revert when the staking module has not enough deposit data items_

```solidity
function obtainDepositData(
  uint256 _depositsCount,
  bytes calldata _depositCalldata
) external returns (bytes memory publicKeys, bytes memory signatures);
```

**Parameters**

| Name               | Type      | Description                                                                                                                           |
| ------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `_depositsCount`   | `uint256` | Number of deposits to be done                                                                                                         |
| `_depositCalldata` | `bytes`   | Staking module defined data encoded as bytes. IMPORTANT: \_depositCalldata MUST NOT modify the deposit data set of the staking module |

**Returns**

| Name         | Type    | Description                                                           |
| ------------ | ------- | --------------------------------------------------------------------- |
| `publicKeys` | `bytes` | Batch of the concatenated public validators keys                      |
| `signatures` | `bytes` | Batch of the concatenated deposit signatures for returned public keys |

### onExitedAndStuckValidatorsCountsUpdated

Called by StakingRouter after it finishes updating exited and stuck validators
counts for this module's node operators.
Guaranteed to be called after an oracle report is applied, regardless of whether any node
operator in this module has actually received any updated counts as a result of the report
but given that the total number of exited validators returned from getStakingModuleSummary
is the same as StakingRouter expects based on the total count received from the oracle.

_IMPORTANT: this method SHOULD revert with empty error data ONLY because of "out of gas".
Details about error data: https://docs.soliditylang.org/en/v0.8.9/control-structures.html#error-handling-assert-require-revert-and-exceptions_

```solidity
function onExitedAndStuckValidatorsCountsUpdated() external;
```

### onWithdrawalCredentialsChanged

Called by StakingRouter when withdrawal credentials are changed.

_This method MUST discard all StakingModule's unused deposit data cause they become
invalid after the withdrawal credentials are changed_

_IMPORTANT: this method SHOULD revert with empty error data ONLY because of "out of gas".
Details about error data: https://docs.soliditylang.org/en/v0.8.9/control-structures.html#error-handling-assert-require-revert-and-exceptions_

```solidity
function onWithdrawalCredentialsChanged() external;
```

## Events

### NonceChanged

_Event to be emitted on StakingModule's nonce change_

```solidity
event NonceChanged(uint256 nonce);
```

### SigningKeyAdded

_Event to be emitted when a signing key is added to the StakingModule_

```solidity
event SigningKeyAdded(uint256 indexed nodeOperatorId, bytes pubkey);
```

### SigningKeyRemoved

_Event to be emitted when a signing key is removed from the StakingModule_

```solidity
event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);
```
