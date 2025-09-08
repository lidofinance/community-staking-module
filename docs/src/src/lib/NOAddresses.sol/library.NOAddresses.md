# NOAddresses
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/lib/NOAddresses.sol)


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


### changeNodeOperatorRewardAddress

Change rewardAddress if extendedManagerPermissions is enabled for the Node Operator.
Should be called from the current manager address


```solidity
function changeNodeOperatorRewardAddress(
    mapping(uint256 => NodeOperator) storage nodeOperators,
    uint256 nodeOperatorId,
    address newAddress
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperators`|`mapping(uint256 => NodeOperator)`||
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`newAddress`|`address`|New reward address|


