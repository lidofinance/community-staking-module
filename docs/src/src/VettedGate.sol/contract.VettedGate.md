# VettedGate
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/VettedGate.sol)

**Inherits:**
[IVettedGate](/src/interfaces/IVettedGate.sol/interface.IVettedGate.md), AccessControlEnumerableUpgradeable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md)


## State Variables
### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### SET_TREE_ROOT_ROLE

```solidity
bytes32 public constant SET_TREE_ROOT_ROLE = keccak256("SET_TREE_ROOT_ROLE");
```


### CSM
*Address of the Community Staking Module*


```solidity
ICSModule public immutable CSM;
```


### ACCOUNTING
*Address of the CSM Accounting*


```solidity
ICSAccounting public immutable ACCOUNTING;
```


### curveId
*Id of the bond curve to be assigned for the eligible members*


```solidity
uint256 public curveId;
```


### treeRoot
*Root of the eligible members Merkle Tree*


```solidity
bytes32 public treeRoot;
```


### _consumedAddresses

```solidity
mapping(address => bool) internal _consumedAddresses;
```


## Functions
### constructor


```solidity
constructor(address csm);
```

### initialize


```solidity
function initialize(uint256 _curveId, bytes32 _treeRoot, address admin) external initializer;
```

### resume

Resume the contract

*there is no check for curve existence as this contract might be created before the curve is added*


```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause the contract for a given duration
Pausing the contract prevent creating new node operators using VettedGate
and claiming beneficial curve for the existing ones


```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause|


### addNodeOperatorETH

Add a new Node Operator using ETH as a bond.
At least one deposit data and corresponding bond should be provided


```solidity
function addNodeOperatorETH(
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures,
    NodeOperatorManagementProperties calldata managementProperties,
    bytes32[] calldata proof,
    address referrer
) external payable returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible for the beneficial curve|
|`referrer`|`address`|Optional. Referrer address. Should be passed when Node Operator is created using partners integration|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the created Node Operator|


### addNodeOperatorStETH

Add a new Node Operator using stETH as a bond.
At least one deposit data and corresponding bond should be provided


```solidity
function addNodeOperatorStETH(
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures,
    NodeOperatorManagementProperties calldata managementProperties,
    ICSAccounting.PermitInput calldata permit,
    bytes32[] calldata proof,
    address referrer
) external returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`permit`|`ICSAccounting.PermitInput`|Optional. Permit to use stETH as bond|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible for the beneficial curve|
|`referrer`|`address`|Optional. Referrer address. Should be passed when Node Operator is created using partners integration|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the created Node Operator|


### addNodeOperatorWstETH

Add a new Node Operator using wstETH as a bond.
At least one deposit data and corresponding bond should be provided


```solidity
function addNodeOperatorWstETH(
    uint256 keysCount,
    bytes calldata publicKeys,
    bytes calldata signatures,
    NodeOperatorManagementProperties calldata managementProperties,
    ICSAccounting.PermitInput calldata permit,
    bytes32[] calldata proof,
    address referrer
) external returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`permit`|`ICSAccounting.PermitInput`|Optional. Permit to use wstETH as bond|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible for the beneficial curve|
|`referrer`|`address`|Optional. Referrer address. Should be passed when Node Operator is created using partners integration|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the created Node Operator|


### claimBondCurve

Consume the bond curve for the eligible Node Operator

*Should be called by the reward address of the Node Operator
In case of the extended manager permissions, should be called by the manager address*


```solidity
function claimBondCurve(uint256 nodeOperatorId, bytes32[] calldata proof) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the Node Operator|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible for the beneficial curve|


### setTreeRoot

Set the root of the eligible members Merkle Tree


```solidity
function setTreeRoot(bytes32 _treeRoot) external onlyRole(SET_TREE_ROOT_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treeRoot`|`bytes32`|New root of the Merkle Tree|


### isConsumed

Check if the address has already consumed the curve


```solidity
function isConsumed(address member) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|Address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Consumed flag|


### verifyProof

Check is the address is eligible to consume beneficial curve


```solidity
function verifyProof(address member, bytes32[] calldata proof) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|Address to check|
|`proof`|`bytes32[]`|Merkle proof of the beneficial curve eligibility|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Boolean flag if the proof is valid or not|


### hashLeaf

Get a hash of a leaf in the Merkle tree

*Double hash the leaf to prevent second preimage attacks*


```solidity
function hashLeaf(address member) public pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`member`|`address`|eligible member address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Hash of the leaf|


### _consume


```solidity
function _consume(bytes32[] calldata proof) internal whenResumed;
```

### _setTreeRoot


```solidity
function _setTreeRoot(bytes32 _treeRoot) internal;
```

