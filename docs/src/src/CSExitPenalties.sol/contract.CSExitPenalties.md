# CSExitPenalties
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/CSExitPenalties.sol)

**Inherits:**
[ICSExitPenalties](/src/interfaces/ICSExitPenalties.sol/interface.ICSExitPenalties.md), [ExitTypes](/src/abstract/ExitTypes.sol/abstract.ExitTypes.md)


## State Variables
### MODULE

```solidity
ICSModule public immutable MODULE;
```


### PARAMETERS_REGISTRY

```solidity
ICSParametersRegistry public immutable PARAMETERS_REGISTRY;
```


### ACCOUNTING

```solidity
ICSAccounting public immutable ACCOUNTING;
```


### STRIKES

```solidity
address public immutable STRIKES;
```


### _exitPenaltyInfo

```solidity
mapping(bytes32 keyPointer => ExitPenaltyInfo) private _exitPenaltyInfo;
```


## Functions
### onlyModule


```solidity
modifier onlyModule();
```

### onlyStrikes


```solidity
modifier onlyStrikes();
```

### constructor


```solidity
constructor(address module, address parametersRegistry, address strikes);
```

### processExitDelayReport

Handles tracking and penalization logic for a validator that remains active beyond its eligible exit window.

*see IStakingModule.reportValidatorExitDelay for details*


```solidity
function processExitDelayReport(uint256 nodeOperatorId, bytes calldata publicKey, uint256 eligibleToExitInSec)
    external
    onlyModule;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|The ID of the node operator whose validator's status is being delivered.|
|`publicKey`|`bytes`|The public key of the validator being reported.|
|`eligibleToExitInSec`|`uint256`|The duration (in seconds) indicating how long the validator has been eligible to exit but has not exited.|


### processTriggeredExit

Process the triggered exit report


```solidity
function processTriggeredExit(
    uint256 nodeOperatorId,
    bytes calldata publicKey,
    uint256 withdrawalRequestPaidFee,
    uint256 exitType
) external onlyModule;
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
function processStrikesReport(uint256 nodeOperatorId, bytes calldata publicKey) external onlyStrikes;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKey`|`bytes`|Public key of the validator|


### isValidatorExitDelayPenaltyApplicable

Determines whether a validator exit status should be updated and will have affect on Node Operator.

*there is a `onlyModule` modifier to prevent using it from outside
as it gives a false-positive information for non-existent node operators.
use `isValidatorExitDelayPenaltyApplicable` in the CSModule.sol instead*


```solidity
function isValidatorExitDelayPenaltyApplicable(
    uint256 nodeOperatorId,
    bytes calldata publicKey,
    uint256 eligibleToExitInSec
) external view onlyModule returns (bool);
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


### getExitPenaltyInfo

get delayed exit penalty info for the given Node Operator


```solidity
function getExitPenaltyInfo(uint256 nodeOperatorId, bytes calldata publicKey)
    external
    view
    returns (ExitPenaltyInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKey`|`bytes`|Public key of the validator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ExitPenaltyInfo`|penaltyInfo Delayed exit penalty info|


### _keyPointer


```solidity
function _keyPointer(uint256 nodeOperatorId, bytes memory publicKey) internal pure returns (bytes32);
```

