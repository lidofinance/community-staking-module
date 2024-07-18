# CSBondCurve

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/abstract/CSBondCurve.sol)

**Inherits:**
[ICSBondCurve](/src/interfaces/ICSBondCurve.sol/interface.ICSBondCurve.md), Initializable

**Author:**
vgorkavenko

\*Bond curve mechanics abstract contract
It gives the ability to build bond curves for flexible bond math.
There is a default bond curve for all Node Operators, which might be 'overridden' for a particular Node Operator.
It contains:

- add bond curve
- get bond curve info
- set default bond curve
- set bond curve for the given Node Operator
- get bond curve for the given Node Operator
- get required bond amount for the given keys count
- get keys count for the given bond amount
  It should be inherited by a module contract or a module-related contract.
  Internal non-view methods should be used in the Module contract with additional requirements (if any).\*

## State Variables

### CS_BOND_CURVE_STORAGE_LOCATION

```solidity
bytes32 private constant CS_BOND_CURVE_STORAGE_LOCATION =
    0x8f22e270e477f5becb8793b61d439ab7ae990ed8eba045eb72061c0e6cfe1500;
```

### MIN_CURVE_LENGTH

```solidity
uint256 public constant MIN_CURVE_LENGTH = 1;
```

### DEFAULT_BOND_CURVE_ID

```solidity
uint256 public constant DEFAULT_BOND_CURVE_ID = 0;
```

### MAX_CURVE_LENGTH

```solidity
uint256 public immutable MAX_CURVE_LENGTH;
```

## Functions

### constructor

```solidity
constructor(uint256 maxCurveLength);
```

### getCurveInfo

Return bond curve for the given curve id

_Get default bond curve info if `curveId` is `0` or invalid_

```solidity
function getCurveInfo(uint256 curveId) public view returns (BondCurve memory);
```

**Parameters**

| Name      | Type      | Description                    |
| --------- | --------- | ------------------------------ |
| `curveId` | `uint256` | Curve id to get bond curve for |

**Returns**

| Name     | Type        | Description |
| -------- | ----------- | ----------- |
| `<none>` | `BondCurve` | Bond curve  |

### getBondCurve

Get bond curve for the given Node Operator

```solidity
function getBondCurve(uint256 nodeOperatorId) public view returns (BondCurve memory);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type        | Description |
| -------- | ----------- | ----------- |
| `<none>` | `BondCurve` | Bond curve  |

### getBondCurveId

Get bond curve ID for the given Node Operator

```solidity
function getBondCurveId(uint256 nodeOperatorId) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description   |
| -------- | --------- | ------------- |
| `<none>` | `uint256` | Bond curve ID |

### getBondAmountByKeysCount

Get required bond in ETH for the given number of keys for default bond curve

_To calculate the amount for the new keys 2 calls are required:
getBondAmountByKeysCount(newTotal) - getBondAmountByKeysCount(currentTotal)_

```solidity
function getBondAmountByKeysCount(uint256 keys, uint256 curveId) public view returns (uint256);
```

**Parameters**

| Name      | Type      | Description                                     |
| --------- | --------- | ----------------------------------------------- |
| `keys`    | `uint256` | Number of keys to get required bond for         |
| `curveId` | `uint256` | Id of the curve to perform calculations against |

**Returns**

| Name     | Type      | Description                      |
| -------- | --------- | -------------------------------- |
| `<none>` | `uint256` | Amount for particular keys count |

### getKeysCountByBondAmount

Get keys count for the given bond amount with default bond curve

```solidity
function getKeysCountByBondAmount(uint256 amount, uint256 curveId) public view returns (uint256);
```

**Parameters**

| Name      | Type      | Description                                     |
| --------- | --------- | ----------------------------------------------- |
| `amount`  | `uint256` | Bond amount in ETH (stETH)to get keys count for |
| `curveId` | `uint256` | Id of the curve to perform calculations against |

**Returns**

| Name     | Type      | Description |
| -------- | --------- | ----------- |
| `<none>` | `uint256` | Keys count  |

### getBondAmountByKeysCount

Get required bond in ETH for the given number of keys for particular bond curve.

_To calculate the amount for the new keys 2 calls are required:
getBondAmountByKeysCount(newTotal, curve) - getBondAmountByKeysCount(currentTotal, curve)_

```solidity
function getBondAmountByKeysCount(
  uint256 keys,
  BondCurve memory curve
) public pure returns (uint256);
```

**Parameters**

| Name    | Type        | Description                                |
| ------- | ----------- | ------------------------------------------ |
| `keys`  | `uint256`   | Number of keys to get required bond for    |
| `curve` | `BondCurve` | Bond curve to perform calculations against |

**Returns**

| Name     | Type      | Description                                                   |
| -------- | --------- | ------------------------------------------------------------- |
| `<none>` | `uint256` | Required bond amount in ETH (stETH) for particular keys count |

### getKeysCountByBondAmount

Get keys count for the given bond amount for particular bond curve.

```solidity
function getKeysCountByBondAmount(
  uint256 amount,
  BondCurve memory curve
) public pure returns (uint256);
```

**Parameters**

| Name     | Type        | Description                                |
| -------- | ----------- | ------------------------------------------ |
| `amount` | `uint256`   | Bond amount to get keys count for          |
| `curve`  | `BondCurve` | Bond curve to perform calculations against |

**Returns**

| Name     | Type      | Description |
| -------- | --------- | ----------- |
| `<none>` | `uint256` | Keys count  |

### \_\_CSBondCurve_init

```solidity
function __CSBondCurve_init(uint256[] calldata defaultBondCurvePoints) internal onlyInitializing;
```

### \_addBondCurve

_Add a new bond curve to the array_

```solidity
function _addBondCurve(uint256[] calldata curvePoints) internal returns (uint256);
```

### \_updateBondCurve

_Update existing bond curve_

```solidity
function _updateBondCurve(uint256 curveId, uint256[] calldata curvePoints) internal;
```

### \_setBondCurve

_Sets bond curve for the given Node Operator
It will be used for the Node Operator instead of the previously set curve_

```solidity
function _setBondCurve(uint256 nodeOperatorId, uint256 curveId) internal;
```

### \_resetBondCurve

_Reset bond curve for the given Node Operator to default.
(for example, because of breaking the rules by Node Operator)_

```solidity
function _resetBondCurve(uint256 nodeOperatorId) internal;
```

### \_checkBondCurve

```solidity
function _checkBondCurve(uint256[] calldata curvePoints) private view;
```

### \_searchKeysCount

```solidity
function _searchKeysCount(
  uint256 amount,
  uint256[] memory curvePoints
) private pure returns (uint256);
```

### \_getCSBondCurveStorage

```solidity
function _getCSBondCurveStorage() private pure returns (CSBondCurveStorage storage $);
```

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

### CSBondCurveStorage

```solidity
struct CSBondCurveStorage {
  BondCurve[] bondCurves;
  mapping(uint256 nodeOperatorId => uint256 bondCurveId) operatorBondCurveId;
}
```
