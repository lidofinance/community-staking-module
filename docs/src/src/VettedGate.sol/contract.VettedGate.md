# VettedGate
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/VettedGate.sol)

**Inherits:**
[IVettedGate](/src/interfaces/IVettedGate.sol/interface.IVettedGate.md), AccessControlEnumerableUpgradeable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md), [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)


## State Variables
### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```


### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```


### RECOVERER_ROLE

```solidity
bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```


### SET_TREE_ROLE

```solidity
bytes32 public constant SET_TREE_ROLE = keccak256("SET_TREE_ROLE");
```


### START_REFERRAL_SEASON_ROLE

```solidity
bytes32 public constant START_REFERRAL_SEASON_ROLE = keccak256("START_REFERRAL_SEASON_ROLE");
```


### END_REFERRAL_SEASON_ROLE

```solidity
bytes32 public constant END_REFERRAL_SEASON_ROLE = keccak256("END_REFERRAL_SEASON_ROLE");
```


### MODULE
*Address of the Staking Module*


```solidity
ICSModule public immutable MODULE;
```


### ACCOUNTING
*Address of the CS Accounting*


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


### treeCid
*CID of the eligible members Merkle Tree*


```solidity
string public treeCid;
```


### _consumedAddresses

```solidity
mapping(address => bool) internal _consumedAddresses;
```


### isReferralProgramSeasonActive
Optional referral program ///


```solidity
bool public isReferralProgramSeasonActive;
```


### referralProgramSeasonNumber

```solidity
uint256 public referralProgramSeasonNumber;
```


### referralCurveId
*Id of the bond curve for referral program*


```solidity
uint256 public referralCurveId;
```


### referralsThreshold
*Number of referrals required for bond curve claim*


```solidity
uint256 public referralsThreshold;
```


### _referralCounts
*Referral counts for referrers for seasons*


```solidity
mapping(bytes32 => uint256) internal _referralCounts;
```


### _consumedReferrers

```solidity
mapping(bytes32 => bool) internal _consumedReferrers;
```


## Functions
### constructor


```solidity
constructor(address module);
```

### initialize


```solidity
function initialize(uint256 _curveId, bytes32 _treeRoot, string calldata _treeCid, address admin)
    external
    initializer;
```

### resume

Resume the contract


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


### startNewReferralProgramSeason

Start referral program season


```solidity
function startNewReferralProgramSeason(uint256 _referralCurveId, uint256 _referralsThreshold)
    external
    onlyRole(START_REFERRAL_SEASON_ROLE)
    returns (uint256 season);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referralCurveId`|`uint256`|Curve Id for the referral curve|
|`_referralsThreshold`|`uint256`|Minimum number of referrals to be eligible to claim the curve|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`season`|`uint256`|Id of the started season|


### endCurrentReferralProgramSeason

End referral program season


```solidity
function endCurrentReferralProgramSeason() external onlyRole(END_REFERRAL_SEASON_ROLE);
```

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
) external payable whenResumed returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible to join via the gate|
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
) external whenResumed returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`permit`|`ICSAccounting.PermitInput`|Optional. Permit to use stETH as bond|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible to join via the gate|
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
) external whenResumed returns (uint256 nodeOperatorId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Signing keys count|
|`publicKeys`|`bytes`|Public keys to submit|
|`signatures`|`bytes`|Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata|
|`managementProperties`|`NodeOperatorManagementProperties`|Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`. If set to true `resetNodeOperatorManagerAddress` method will be disabled|
|`permit`|`ICSAccounting.PermitInput`|Optional. Permit to use wstETH as bond|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible to join via the gate|
|`referrer`|`address`|Optional. Referrer address. Should be passed when Node Operator is created using partners integration|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the created Node Operator|


### claimBondCurve

Claim the bond curve for the eligible Node Operator

*Should be called by the reward address of the Node Operator
In case of the extended manager permissions, should be called by the manager address*


```solidity
function claimBondCurve(uint256 nodeOperatorId, bytes32[] calldata proof) external whenResumed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the Node Operator|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible to join via the gate|


### claimReferrerBondCurve

Claim the referral program bond curve for the eligible Node Operator


```solidity
function claimReferrerBondCurve(uint256 nodeOperatorId, bytes32[] calldata proof) external whenResumed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|Id of the Node Operator|
|`proof`|`bytes32[]`|Merkle proof of the sender being eligible to join via the gate|


### setTreeParams

Set the root of the eligible members Merkle Tree


```solidity
function setTreeParams(bytes32 _treeRoot, string calldata _treeCid) external onlyRole(SET_TREE_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treeRoot`|`bytes32`|New root of the Merkle Tree|
|`_treeCid`|`string`|New CID of the Merkle Tree|


### getReferralsCount

Get the number of referrals for the given referrer in the current or last season


```solidity
function getReferralsCount(address referrer) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referrer`|`address`|Referrer address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Number of referrals for the given referrer in the current or last season|


### getReferralsCount

Get the number of referrals for the given referrer in the current or last season


```solidity
function getReferralsCount(address referrer, uint256 season) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referrer`|`address`|Referrer address|
|`season`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Number of referrals for the given referrer in the current or last season|


### getInitializedVersion

Returns the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

### isReferrerConsumed

Check if the address has already consumed referral program bond curve


```solidity
function isReferrerConsumed(address referrer) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referrer`|`address`|Address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Consumed flag|


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
function _consume(bytes32[] calldata proof) internal;
```

### _setTreeParams


```solidity
function _setTreeParams(bytes32 _treeRoot, string calldata _treeCid) internal;
```

### _bumpReferralCount


```solidity
function _bumpReferralCount(address referrer, uint256 referralNodeOperatorId) internal;
```

### _seasonedAddress


```solidity
function _seasonedAddress(address referrer) internal view returns (bytes32);
```

### _onlyNodeOperatorOwner

*Verifies that the sender is the owner of the node operator*


```solidity
function _onlyNodeOperatorOwner(uint256 nodeOperatorId) internal view;
```

### _onlyRecoverer


```solidity
function _onlyRecoverer() internal view override;
```

### _seasonedAddress


```solidity
function _seasonedAddress(address referrer, uint256 season) internal pure returns (bytes32);
```

