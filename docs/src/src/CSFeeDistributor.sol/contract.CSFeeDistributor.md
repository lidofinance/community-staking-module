# CSFeeDistributor

[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/CSFeeDistributor.sol)

**Inherits:**
[ICSFeeDistributor](/src/interfaces/ICSFeeDistributor.sol/interface.ICSFeeDistributor.md), Initializable, AccessControlEnumerableUpgradeable, [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)

**Author:**
madlabman

## State Variables

### RECOVERER_ROLE

```solidity
bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```

### STETH

```solidity
IStETH public immutable STETH;
```

### ACCOUNTING

```solidity
address public immutable ACCOUNTING;
```

### ORACLE

```solidity
address public immutable ORACLE;
```

### treeRoot

Merkle Tree root

```solidity
bytes32 public treeRoot;
```

### treeCid

CID of the published Merkle tree

```solidity
string public treeCid;
```

### distributedShares

Amount of stETH shares sent to the Accounting in favor of the NO

```solidity
mapping(uint256 => uint256) public distributedShares;
```

### totalClaimableShares

Total Amount of stETH shares available for claiming by NOs

```solidity
uint256 public totalClaimableShares;
```

## Functions

### constructor

```solidity
constructor(address stETH, address accounting, address oracle);
```

### initialize

```solidity
function initialize(address admin) external initializer;
```

### distributeFees

Distribute fees to the Accounting in favor of the Node Operator

```solidity
function distributeFees(
  uint256 nodeOperatorId,
  uint256 shares,
  bytes32[] calldata proof
) external returns (uint256 sharesToDistribute);
```

**Parameters**

| Name             | Type        | Description                                 |
| ---------------- | ----------- | ------------------------------------------- |
| `nodeOperatorId` | `uint256`   | ID of the Node Operator                     |
| `shares`         | `uint256`   | Total Amount of stETH shares earned as fees |
| `proof`          | `bytes32[]` | Merkle proof of the leaf                    |

**Returns**

| Name                 | Type      | Description                        |
| -------------------- | --------- | ---------------------------------- |
| `sharesToDistribute` | `uint256` | Amount of stETH shares distributed |

### processOracleReport

Receive the data of the Merkle tree from the Oracle contract and process it

```solidity
function processOracleReport(
  bytes32 _treeRoot,
  string calldata _treeCid,
  uint256 distributed
) external;
```

### recoverERC20

Recover ERC20 tokens (except for stETH) from the contract

_Any stETH transferred to feeDistributor is treated as a donation and can not be recovered_

```solidity
function recoverERC20(address token, uint256 amount) external override;
```

**Parameters**

| Name     | Type      | Description                           |
| -------- | --------- | ------------------------------------- |
| `token`  | `address` | Address of the ERC20 token to recover |
| `amount` | `uint256` | Amount of the ERC20 token to recover  |

### pendingSharesToDistribute

Get the Amount of stETH shares that are pending to be distributed

```solidity
function pendingSharesToDistribute() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                                                |
| -------- | --------- | ---------------------------------------------------------- |
| `<none>` | `uint256` | pendingShares Amount shares that are pending to distribute |

### getFeesToDistribute

Get the Amount of stETH shares that can be distributed in favor of the Node Operator

```solidity
function getFeesToDistribute(
  uint256 nodeOperatorId,
  uint256 shares,
  bytes32[] calldata proof
) public view returns (uint256 sharesToDistribute);
```

**Parameters**

| Name             | Type        | Description                                 |
| ---------------- | ----------- | ------------------------------------------- |
| `nodeOperatorId` | `uint256`   | ID of the Node Operator                     |
| `shares`         | `uint256`   | Total Amount of stETH shares earned as fees |
| `proof`          | `bytes32[]` | Merkle proof of the leaf                    |

**Returns**

| Name                 | Type      | Description                                    |
| -------------------- | --------- | ---------------------------------------------- |
| `sharesToDistribute` | `uint256` | Amount of stETH shares that can be distributed |

### hashLeaf

Get a hash of a leaf

_Double hash the leaf to prevent second preimage attacks_

```solidity
function hashLeaf(uint256 nodeOperatorId, uint256 shares) public pure returns (bytes32);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |
| `shares`         | `uint256` | Amount of stETH shares  |

**Returns**

| Name     | Type      | Description      |
| -------- | --------- | ---------------- |
| `<none>` | `bytes32` | Hash of the leaf |

### \_onlyRecoverer

```solidity
function _onlyRecoverer() internal view override;
```

## Events

### FeeDistributed

_Emitted when fees are distributed_

```solidity
event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);
```

### DistributionDataUpdated

_Emitted when distribution data is updated_

```solidity
event DistributionDataUpdated(uint256 totalClaimableShares, bytes32 treeRoot, string treeCid);
```

## Errors

### ZeroAccountingAddress

```solidity
error ZeroAccountingAddress();
```

### ZeroStEthAddress

```solidity
error ZeroStEthAddress();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroOracleAddress

```solidity
error ZeroOracleAddress();
```

### NotAccounting

```solidity
error NotAccounting();
```

### NotOracle

```solidity
error NotOracle();
```

### InvalidTreeRoot

```solidity
error InvalidTreeRoot();
```

### InvalidTreeCID

```solidity
error InvalidTreeCID();
```

### InvalidShares

```solidity
error InvalidShares();
```

### InvalidProof

```solidity
error InvalidProof();
```

### FeeSharesDecrease

```solidity
error FeeSharesDecrease();
```

### NotEnoughShares

```solidity
error NotEnoughShares();
```
