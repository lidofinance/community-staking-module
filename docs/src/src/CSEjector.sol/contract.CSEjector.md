# CSEjector
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/CSEjector.sol)

**Inherits:**
[ICSEjector](/src/interfaces/ICSEjector.sol/interface.ICSEjector.md), [ExitTypes](/src/abstract/ExitTypes.sol/abstract.ExitTypes.md), Initializable, AccessControlEnumerableUpgradeable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md)


## State Variables
### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### STAKING_MODULE_ID

```solidity
uint256 public immutable STAKING_MODULE_ID;
```


### MODULE

```solidity
ICSModule public immutable MODULE;
```


### VEB

```solidity
IValidatorsExitBus public immutable VEB;
```


### strikes

```solidity
address public strikes;
```


## Functions
### onlyStrikes


```solidity
modifier onlyStrikes();
```

### constructor


```solidity
constructor(address module, uint256 stakingModuleId);
```

### initialize

initialize the contract from scratch


```solidity
function initialize(address admin, address _strikes) external initializer;
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


### voluntaryEject

Withdraw the validator key from the Node Operator


```solidity
function voluntaryEject(uint256 nodeOperatorId, uint256 startFrom, uint256 keysCount, address refundRecipient)
    external
    payable
    whenResumed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`startFrom`|`uint256`|Index of the first key to withdraw|
|`keysCount`|`uint256`|Number of keys to withdraw|
|`refundRecipient`|`address`|Address to send the refund to|


### voluntaryEjectByArray

Withdraw the validator key from the Node Operator

*this method is intentionally copy-pasted from the voluntaryEject method with keys changes*


```solidity
function voluntaryEjectByArray(uint256 nodeOperatorId, uint256[] calldata keyIndices, address refundRecipient)
    external
    payable
    whenResumed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`keyIndices`|`uint256[]`|Array of indices of the keys to withdraw|
|`refundRecipient`|`address`|Address to send the refund to|


### ejectBadPerformer

Eject Node Operator's key as a bad performer


```solidity
function ejectBadPerformer(uint256 nodeOperatorId, bytes calldata publicKeys, address refundRecipient)
    external
    payable
    whenResumed
    onlyStrikes;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`publicKeys`|`bytes`|Concatenated public keys of the Node Operator's validators|
|`refundRecipient`|`address`|Address to send the refund to|


