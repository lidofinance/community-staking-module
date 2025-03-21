# ICSBondCurve
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/interfaces/ICSBondCurve.sol)


## Functions
### MIN_CURVE_LENGTH


```solidity
function MIN_CURVE_LENGTH() external view returns (uint256);
```

### MAX_CURVE_LENGTH


```solidity
function MAX_CURVE_LENGTH() external view returns (uint256);
```

### DEFAULT_BOND_CURVE_ID


```solidity
function DEFAULT_BOND_CURVE_ID() external view returns (uint256);
```

### getCurvesCount

Get the number of available curves


```solidity
function getCurvesCount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Number of available curves|


### getCurveInfo

Return bond curve for the given curve id

*Reverts if `curveId` is invalid*


```solidity
function getCurveInfo(uint256 curveId) external view returns (BondCurve memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve id to get bond curve for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`BondCurve`|Bond curve|


### getBondCurve

Get bond curve for the given Node Operator


```solidity
function getBondCurve(uint256 nodeOperatorId) external view returns (BondCurve memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`BondCurve`|Bond curve|


### getBondCurveId

Get bond curve ID for the given Node Operator


```solidity
function getBondCurveId(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Bond curve ID|


### getBondAmountByKeysCount

Get required bond in ETH for the given number of keys for default bond curve

*To calculate the amount for the new keys 2 calls are required:
getBondAmountByKeysCount(newTotal) - getBondAmountByKeysCount(currentTotal)*


```solidity
function getBondAmountByKeysCount(uint256 keys, uint256 curveId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keys`|`uint256`|Number of keys to get required bond for|
|`curveId`|`uint256`|Id of the curve to perform calculations against|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount for particular keys count|


### getBondAmountByKeysCount

Get required bond in ETH for the given number of keys for particular bond curve.

*To calculate the amount for the new keys 2 calls are required:
getBondAmountByKeysCount(newTotal, curve) - getBondAmountByKeysCount(currentTotal, curve)*


```solidity
function getBondAmountByKeysCount(uint256 keys, BondCurve memory curve) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keys`|`uint256`|Number of keys to get required bond for|
|`curve`|`BondCurve`|Bond curve to perform calculations against|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Required bond amount in ETH (stETH) for particular keys count|


### getKeysCountByBondAmount

Get keys count for the given bond amount with default bond curve


```solidity
function getKeysCountByBondAmount(uint256 amount, uint256 curveId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Bond amount in ETH (stETH)to get keys count for|
|`curveId`|`uint256`|Id of the curve to perform calculations against|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Keys count|


### getKeysCountByBondAmount

Get keys count for the given bond amount for particular bond curve.


```solidity
function getKeysCountByBondAmount(uint256 amount, BondCurve memory curve) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Bond amount to get keys count for|
|`curve`|`BondCurve`|Bond curve to perform calculations against|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Keys count|


## Events
### BondCurveAdded

```solidity
event BondCurveAdded(uint256[] bondCurve);
```

### BondCurveUpdated

```solidity
event BondCurveUpdated(uint256 indexed curveId, uint256[] bondCurve);
```

### BondCurveSet

```solidity
event BondCurveSet(uint256 indexed nodeOperatorId, uint256 curveId);
```

## Errors
### InvalidBondCurveLength

```solidity
error InvalidBondCurveLength();
```

### InvalidBondCurveMaxLength

```solidity
error InvalidBondCurveMaxLength();
```

### InvalidBondCurveValues

```solidity
error InvalidBondCurveValues();
```

### InvalidBondCurveId

```solidity
error InvalidBondCurveId();
```

### InvalidInitialisationCurveId

```solidity
error InvalidInitialisationCurveId();
```

## Structs
### BondCurve
*Bond curve structure.
It contains:
- points |> total bond amount for particular keys count
- trend  |> value for the next keys after described points
For example, how the curve points look like:
Points Array Index  |>       0          1          2          i
Bond Amount         |>   [ 2 ETH ] [ 3.9 ETH ] [ 5.7 ETH ] [ ... ]
Keys Count          |>       1          2          3        i + 1
Bond Amount (ETH)
^
|
6 -
| ------------------ 5.7 ETH --> .
5.5 -                              ..^
|                             .  |
5 -                            .   |
|                           .    |
4.5 -                          .     |
|                         .      |
4 -                       ..       |
| ------- 3.9 ETH --> ..         |
3.5 -                    .^          |
|                  .. |          |
3 -                ..   |          |
|               .     |          |
2.5 -              .      |          |
|            ..       |          |
2 - -------->..         |          |
|          ^          |          |
|----------|----------|----------|----------|----> Keys Count
|          1          2          3          i*


```solidity
struct BondCurve {
    uint256[] points;
    uint256 trend;
}
```

