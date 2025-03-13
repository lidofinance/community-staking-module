# CSEjector
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/CSEjector.sol)

**Inherits:**
[ICSEjector](/src/interfaces/ICSEjector.sol/interface.ICSEjector.md), Initializable, AccessControlEnumerableUpgradeable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md)


## State Variables
### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### BAD_PERFORMER_EJECTOR_ROLE

```solidity
bytes32 public constant BAD_PERFORMER_EJECTOR_ROLE = keccak256("BAD_PERFORMER_EJECTOR_ROLE");
```


### MODULE

```solidity
ICSModule public immutable MODULE;
```


### ACCOUNTING

```solidity
ICSAccounting public immutable ACCOUNTING;
```


### _isValidatorEjected
*see _keyPointer function for details of noKeyIndexPacked structure*


```solidity
mapping(uint256 noKeyIndexPacked => bool) private _isValidatorEjected;
```


## Functions
### constructor


```solidity
constructor(address module);
```

### initialize

initialize the contract from scratch


```solidity
function initialize(address admin) external initializer;
```

### resume

Resume ejection methods calls


```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause ejection methods calls


```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### ejectBadPerformer

Report Node Operator's key as bad performer and eject it with corresponding penalty


```solidity
function ejectBadPerformer(uint256 nodeOperatorId, uint256 keyIndex, uint256 strikes)
    external
    whenResumed
    onlyRole(BAD_PERFORMER_EJECTOR_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|Index of the withdrawn key in the Node Operator's keys storage|
|`strikes`|`uint256`|Strikes of the Node Operator's validator key|


### isValidatorEjected

Check if the given Node Operator's key is reported as ejected


```solidity
function isValidatorEjected(uint256 nodeOperatorId, uint256 keyIndex) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndex`|`uint256`|index of the key to check|


### _onlyExistingNodeOperator


```solidity
function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view;
```

### _keyPointer

*Both nodeOperatorId and keyIndex are limited to uint64 by the CSModule.sol*


```solidity
function _keyPointer(uint256 nodeOperatorId, uint256 keyIndex) internal pure returns (uint256);
```

