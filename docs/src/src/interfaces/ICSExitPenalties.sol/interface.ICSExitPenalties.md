# ICSExitPenalties
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/interfaces/ICSExitPenalties.sol)

**Inherits:**
[IExitTypes](/src/interfaces/IExitTypes.sol/interface.IExitTypes.md)


## Functions
### MODULE


```solidity
function MODULE() external view returns (ICSModule);
```

### ACCOUNTING


```solidity
function ACCOUNTING() external view returns (ICSAccounting);
```

### strikes


```solidity
function strikes() external view returns (address);
```

### processExitDelayReport

Process the delayed exit report


```solidity
function processExitDelayReport(uint256 nodeOperatorId, bytes calldata publicKey, uint256 eligibleToExitInSec)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKey`|`bytes`|Public key of the validator|
|`eligibleToExitInSec`|`uint256`|The time in seconds when the validator is eligible to exit|


### processTriggeredExit

Process the triggered exit report


```solidity
function processTriggeredExit(
    uint256 nodeOperatorId,
    bytes calldata publicKey,
    uint256 withdrawalRequestPaidFee,
    uint256 exitType
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKey`|`bytes`|Public key of the validator|
|`withdrawalRequestPaidFee`|`uint256`|The fee paid for the withdrawal request|
|`exitType`|`uint256`|The type of the exit (0 - direct exit, 1 - forced exit)|


### processStrikesReport

Process the strikes report


```solidity
function processStrikesReport(uint256 nodeOperatorId, bytes calldata publicKey) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKey`|`bytes`|Public key of the validator|


### isValidatorExitDelayPenaltyApplicable

Determines whether a validator exit status should be updated and will have affect on Node Operator.

*called only by CSM*


```solidity
function isValidatorExitDelayPenaltyApplicable(
    uint256 nodeOperatorId,
    bytes calldata publicKey,
    uint256 eligibleToExitInSec
) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|The ID of the node operator.|
|`publicKey`|`bytes`|Validator's public key.|
|`eligibleToExitInSec`|`uint256`|The number of seconds the validator was eligible to exit but did not.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool Returns true if contract should receive updated validator's status.|


### getDelayedExitPenaltyInfo

get delayed exit penalty info for the given Node Operator


```solidity
function getDelayedExitPenaltyInfo(uint256 nodeOperatorId, bytes calldata publicKey)
    external
    view
    returns (ExitPenaltyInfo memory penaltyInfo);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKey`|`bytes`|Public key of the validator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`penaltyInfo`|`ExitPenaltyInfo`|Delayed exit penalty info|


## Events
### ValidatorExitDelayProcessed

```solidity
event ValidatorExitDelayProcessed(uint256 indexed nodeOperatorId, bytes pubkey, uint256 delayPenalty);
```

### TriggeredExitFeeRecorded

```solidity
event TriggeredExitFeeRecorded(
    uint256 indexed nodeOperatorId, uint256 indexed exitType, bytes pubkey, uint256 withdrawalRequestFee
);
```

### StrikesPenaltyProcessed

```solidity
event StrikesPenaltyProcessed(uint256 indexed nodeOperatorId, bytes pubkey, uint256 strikesPenalty);
```

## Errors
### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### ZeroParametersRegistryAddress

```solidity
error ZeroParametersRegistryAddress();
```

### ZeroAccountingAddress

```solidity
error ZeroAccountingAddress();
```

### ZeroStrikesAddress

```solidity
error ZeroStrikesAddress();
```

### SenderIsNotModule

```solidity
error SenderIsNotModule();
```

### SenderIsNotStrikes

```solidity
error SenderIsNotStrikes();
```

### ValidatorExitDelayNotApplicable

```solidity
error ValidatorExitDelayNotApplicable();
```

### ValidatorExitDelayAlreadyReported

```solidity
error ValidatorExitDelayAlreadyReported();
```

