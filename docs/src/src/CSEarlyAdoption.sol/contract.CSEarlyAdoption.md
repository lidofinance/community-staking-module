# CSEarlyAdoption

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/CSEarlyAdoption.sol)

**Inherits:**
[ICSEarlyAdoption](/src/interfaces/ICSEarlyAdoption.sol/interface.ICSEarlyAdoption.md)

## State Variables

### TREE_ROOT

_Root of the EA members Merkle Tree_

```solidity
bytes32 public immutable TREE_ROOT;
```

### CURVE_ID

_Id of the bond curve to be assigned for the EA members_

```solidity
uint256 public immutable CURVE_ID;
```

### MODULE

_Address of the Staking Module using Early Adoption contract_

```solidity
address public immutable MODULE;
```

### \_consumedAddresses

```solidity
mapping(address => bool) internal _consumedAddresses;
```

## Functions

### constructor

```solidity
constructor(bytes32 treeRoot, uint256 curveId, address module);
```

### consume

Validate EA eligibility proof and mark it as consumed

_Called only by the module_

```solidity
function consume(address member, bytes32[] calldata proof) external;
```

**Parameters**

| Name     | Type        | Description                                |
| -------- | ----------- | ------------------------------------------ |
| `member` | `address`   | Address to be verified alongside the proof |
| `proof`  | `bytes32[]` | Merkle proof of EA eligibility             |

### isConsumed

Check if the address has already consumed EA access

```solidity
function isConsumed(address member) external view returns (bool);
```

**Parameters**

| Name     | Type      | Description      |
| -------- | --------- | ---------------- |
| `member` | `address` | Address to check |

**Returns**

| Name     | Type   | Description   |
| -------- | ------ | ------------- |
| `<none>` | `bool` | Consumed flag |

### verifyProof

Check is the address is eligible to consume EA access

```solidity
function verifyProof(address member, bytes32[] calldata proof) public view returns (bool);
```

**Parameters**

| Name     | Type        | Description                    |
| -------- | ----------- | ------------------------------ |
| `member` | `address`   | Address to check               |
| `proof`  | `bytes32[]` | Merkle proof of EA eligibility |

**Returns**

| Name     | Type   | Description                               |
| -------- | ------ | ----------------------------------------- |
| `<none>` | `bool` | Boolean flag if the proof is valid or not |

### hashLeaf

Get a hash of a leaf in EA Merkle tree

_Double hash the leaf to prevent second preimage attacks_

```solidity
function hashLeaf(address member) public pure returns (bytes32);
```

**Parameters**

| Name     | Type      | Description       |
| -------- | --------- | ----------------- |
| `member` | `address` | EA member address |

**Returns**

| Name     | Type      | Description      |
| -------- | --------- | ---------------- |
| `<none>` | `bytes32` | Hash of the leaf |

## Events

### Consumed

```solidity
event Consumed(address indexed member);
```

## Errors

### InvalidProof

```solidity
error InvalidProof();
```

### AlreadyConsumed

```solidity
error AlreadyConsumed();
```

### InvalidTreeRoot

```solidity
error InvalidTreeRoot();
```

### InvalidCurveId

```solidity
error InvalidCurveId();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### SenderIsNotModule

```solidity
error SenderIsNotModule();
```
