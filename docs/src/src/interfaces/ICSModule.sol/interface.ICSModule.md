# ICSModule

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/interfaces/ICSModule.sol)

**Inherits:**
[IStakingModule](/src/interfaces/IStakingModule.sol/interface.IStakingModule.md), [IQueueLib](/src/lib/QueueLib.sol/interface.IQueueLib.md), [INOAddresses](/src/lib/NOAddresses.sol/interface.INOAddresses.md), [IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md)

## Functions

### getNodeOperatorNonWithdrawnKeys

Gets node operator non-withdrawn keys

```solidity
function getNodeOperatorNonWithdrawnKeys(uint256 nodeOperatorId) external view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the node operator |

**Returns**

| Name     | Type      | Description              |
| -------- | --------- | ------------------------ |
| `<none>` | `uint256` | Non-withdrawn keys count |

### getNodeOperator

Returns the node operator by id

```solidity
function getNodeOperator(uint256 nodeOperatorId) external view returns (NodeOperator memory);
```

**Parameters**

| Name             | Type      | Description      |
| ---------------- | --------- | ---------------- |
| `nodeOperatorId` | `uint256` | Node Operator id |

### getSigningKeys

Gets node operator signing keys

```solidity
function getSigningKeys(
  uint256 nodeOperatorId,
  uint256 startIndex,
  uint256 keysCount
) external view returns (bytes memory);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the node operator |
| `startIndex`     | `uint256` | Index of the first key  |
| `keysCount`      | `uint256` | Count of keys to get    |

**Returns**

| Name     | Type    | Description  |
| -------- | ------- | ------------ |
| `<none>` | `bytes` | Signing keys |

### getSigningKeysWithSignatures

Gets node operator signing keys with signatures

```solidity
function getSigningKeysWithSignatures(
  uint256 nodeOperatorId,
  uint256 startIndex,
  uint256 keysCount
) external view returns (bytes memory keys, bytes memory signatures);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the node operator |
| `startIndex`     | `uint256` | Index of the first key  |
| `keysCount`      | `uint256` | Count of keys to get    |

**Returns**

| Name         | Type    | Description                                    |
| ------------ | ------- | ---------------------------------------------- |
| `keys`       | `bytes` | Signing keys                                   |
| `signatures` | `bytes` | Signatures of (deposit_message, domain) tuples |

### submitInitialSlashing

Report node operator's key as slashed and apply initial slashing penalty.

```solidity
function submitInitialSlashing(uint256 nodeOperatorId, uint256 keyIndex) external;
```

**Parameters**

| Name             | Type      | Description                                           |
| ---------------- | --------- | ----------------------------------------------------- |
| `nodeOperatorId` | `uint256` | Operator ID in the module.                            |
| `keyIndex`       | `uint256` | Index of the slashed key in the node operator's keys. |

### submitWithdrawal

Report node operator's key as withdrawn and settle withdrawn amount.

```solidity
function submitWithdrawal(
  uint256 nodeOperatorId,
  uint256 keyIndex,
  uint256 amount,
  bool isSlashed
) external;
```

**Parameters**

| Name             | Type      | Description                                             |
| ---------------- | --------- | ------------------------------------------------------- |
| `nodeOperatorId` | `uint256` | Operator ID in the module.                              |
| `keyIndex`       | `uint256` | Index of the withdrawn key in the node operator's keys. |
| `amount`         | `uint256` | Amount of withdrawn ETH in wei.                         |
| `isSlashed`      | `bool`    | Validator is slashed or not                             |

### depositWstETH

```solidity
function depositWstETH(
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  ICSAccounting.PermitInput calldata permit
) external;
```

### depositStETH

```solidity
function depositStETH(
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  ICSAccounting.PermitInput calldata permit
) external;
```

### depositETH

```solidity
function depositETH(uint256 nodeOperatorId) external payable;
```

## Errors

### NodeOperatorDoesNotExist

```solidity
error NodeOperatorDoesNotExist();
```

### ZeroRewardAddress

```solidity
error ZeroRewardAddress();
```
