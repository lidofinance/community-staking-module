# NOAddresses
[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/lib/NOAddresses.sol)

Library for changing and reset node operator's manager and reward addresses

*the only use of this to be a library is to save CSModule contract size via delegatecalls*


## Functions
### proposeNodeOperatorManagerAddressChange

Propose a new manager address for the Node Operator


```solidity
function proposeNodeOperatorManagerAddressChange(
    mapping(uint256 => NodeOperator) storage nodeOperators,
    uint256 nodeOperatorId,
    address proposedAddress
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperators`|`mapping(uint256 => NodeOperator)`||
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`proposedAddress`|`address`|Proposed manager address|


### confirmNodeOperatorManagerAddressChange

Confirm a new manager address for the Node Operator.
Should be called from the currently proposed address


```solidity
function confirmNodeOperatorManagerAddressChange(
    mapping(uint256 => NodeOperator) storage nodeOperators,
    uint256 nodeOperatorId
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperators`|`mapping(uint256 => NodeOperator)`||
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### proposeNodeOperatorRewardAddressChange

Propose a new reward address for the Node Operator


```solidity
function proposeNodeOperatorRewardAddressChange(
    mapping(uint256 => NodeOperator) storage nodeOperators,
    uint256 nodeOperatorId,
    address proposedAddress
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperators`|`mapping(uint256 => NodeOperator)`||
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`proposedAddress`|`address`|Proposed reward address|


### confirmNodeOperatorRewardAddressChange

Confirm a new reward address for the Node Operator.
Should be called from the currently proposed address


```solidity
function confirmNodeOperatorRewardAddressChange(
    mapping(uint256 => NodeOperator) storage nodeOperators,
    uint256 nodeOperatorId
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperators`|`mapping(uint256 => NodeOperator)`||
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### resetNodeOperatorManagerAddress

Reset the manager address to the reward address.
Should be called from the reward address


```solidity
function resetNodeOperatorManagerAddress(mapping(uint256 => NodeOperator) storage nodeOperators, uint256 nodeOperatorId)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperators`|`mapping(uint256 => NodeOperator)`||
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


## Events
### NodeOperatorManagerAddressChangeProposed

```solidity
event NodeOperatorManagerAddressChangeProposed(
    uint256 indexed nodeOperatorId, address indexed oldProposedAddress, address indexed newProposedAddress
);
```

### NodeOperatorRewardAddressChangeProposed

```solidity
event NodeOperatorRewardAddressChangeProposed(
    uint256 indexed nodeOperatorId, address indexed oldProposedAddress, address indexed newProposedAddress
);
```

### NodeOperatorManagerAddressChanged

```solidity
event NodeOperatorManagerAddressChanged(
    uint256 indexed nodeOperatorId, address indexed oldAddress, address indexed newAddress
);
```

### NodeOperatorRewardAddressChanged

```solidity
event NodeOperatorRewardAddressChanged(
    uint256 indexed nodeOperatorId, address indexed oldAddress, address indexed newAddress
);
```

## Errors
### AlreadyProposed

```solidity
error AlreadyProposed();
```

### SameAddress

```solidity
error SameAddress();
```

### SenderIsNotManagerAddress

```solidity
error SenderIsNotManagerAddress();
```

### SenderIsNotRewardAddress

```solidity
error SenderIsNotRewardAddress();
```

### SenderIsNotProposedAddress

```solidity
error SenderIsNotProposedAddress();
```

### NodeOperatorDoesNotExist

```solidity
error NodeOperatorDoesNotExist();
```

