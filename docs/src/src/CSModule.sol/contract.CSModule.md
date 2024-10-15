# CSModule

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/CSModule.sol)

**Inherits:**
[ICSModule](/src/interfaces/ICSModule.sol/interface.ICSModule.md), Initializable, AccessControlEnumerableUpgradeable, [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md), [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)

## State Variables

### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```

### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```

### MODULE_MANAGER_ROLE

```solidity
bytes32 public constant MODULE_MANAGER_ROLE = keccak256("MODULE_MANAGER_ROLE");
```

### STAKING_ROUTER_ROLE

```solidity
bytes32 public constant STAKING_ROUTER_ROLE = keccak256("STAKING_ROUTER_ROLE");
```

### REPORT_EL_REWARDS_STEALING_PENALTY_ROLE

```solidity
bytes32 public constant REPORT_EL_REWARDS_STEALING_PENALTY_ROLE = keccak256("REPORT_EL_REWARDS_STEALING_PENALTY_ROLE");
```

### SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE

```solidity
bytes32 public constant SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE = keccak256("SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE");
```

### VERIFIER_ROLE

```solidity
bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
```

### RECOVERER_ROLE

```solidity
bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```

### DEPOSIT_SIZE

```solidity
uint256 private constant DEPOSIT_SIZE = 32 ether;
```

### FORCED_TARGET_LIMIT_MODE_ID

```solidity
uint8 private constant FORCED_TARGET_LIMIT_MODE_ID = 2;
```

### INITIAL_SLASHING_PENALTY

```solidity
uint256 public immutable INITIAL_SLASHING_PENALTY;
```

### EL_REWARDS_STEALING_FINE

```solidity
uint256 public immutable EL_REWARDS_STEALING_FINE;
```

### MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE

```solidity
uint256 public immutable MAX_SIGNING_KEYS_PER_OPERATOR_BEFORE_PUBLIC_RELEASE;
```

### MAX_KEY_REMOVAL_CHARGE

```solidity
uint256 public immutable MAX_KEY_REMOVAL_CHARGE;
```

### MODULE_TYPE

```solidity
bytes32 private immutable MODULE_TYPE;
```

### LIDO_LOCATOR

```solidity
ILidoLocator public immutable LIDO_LOCATOR;
```

### STETH

```solidity
IStETH public immutable STETH;
```

### keyRemovalCharge

```solidity
uint256 public keyRemovalCharge;
```

### depositQueue

```solidity
QueueLib.Queue public depositQueue;
```

### accounting

```solidity
ICSAccounting public accounting;
```

### earlyAdoption

```solidity
ICSEarlyAdoption public earlyAdoption;
```

### publicRelease

```solidity
bool public publicRelease;
```

### \_nonce

```solidity
uint256 private _nonce;
```

### \_nodeOperators

```solidity
mapping(uint256 => NodeOperator) private _nodeOperators;
```

### \_isValidatorWithdrawn

```solidity
mapping(uint256 noKeyIndexPacked => bool) private _isValidatorWithdrawn;
```

### \_isValidatorSlashed

```solidity
mapping(uint256 noKeyIndexPacked => bool) private _isValidatorSlashed;
```

### \_totalDepositedValidators

```solidity
uint64 private _totalDepositedValidators;
```

### \_totalExitedValidators

```solidity
uint64 private _totalExitedValidators;
```

### \_depositableValidatorsCount

```solidity
uint64 private _depositableValidatorsCount;
```

### \_nodeOperatorsCount

```solidity
uint64 private _nodeOperatorsCount;
```

## Functions

### constructor

```solidity
constructor(
  bytes32 moduleType,
  uint256 minSlashingPenaltyQuotient,
  uint256 elRewardsStealingFine,
  uint256 maxKeysPerOperatorEA,
  uint256 maxKeyRemovalCharge,
  address lidoLocator
);
```

### initialize

```solidity
function initialize(
  address _accounting,
  address _earlyAdoption,
  uint256 _keyRemovalCharge,
  address admin
) external initializer;
```

### resume

Resume creation of the Node Operators and keys upload

```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause creation of the Node Operators and keys upload for `duration` seconds.
Existing NO management and reward claims are still available.
To pause reward claims use pause method on CSAccounting

```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```

**Parameters**

| Name       | Type      | Description                      |
| ---------- | --------- | -------------------------------- |
| `duration` | `uint256` | Duration of the pause in seconds |

### activatePublicRelease

Activate public release mode
Enable permissionless creation of the Node Operators
Remove the keys limit for the Node Operators

```solidity
function activatePublicRelease() external onlyRole(MODULE_MANAGER_ROLE);
```

### setKeyRemovalCharge

Set the key removal charge amount.
A charge is taken from the bond for each removed key

```solidity
function setKeyRemovalCharge(uint256 amount) external onlyRole(MODULE_MANAGER_ROLE);
```

**Parameters**

| Name     | Type      | Description                                                    |
| -------- | --------- | -------------------------------------------------------------- |
| `amount` | `uint256` | Amount of stETH in wei to be charged for removing a single key |

### addNodeOperatorETH

Add a new Node Operator using ETH as a bond.
At least one deposit data and corresponding bond should be provided

```solidity
function addNodeOperatorETH(
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures,
  NodeOperatorManagementProperties calldata managementProperties,
  bytes32[] calldata eaProof,
  address referrer
) external payable whenResumed;
```

**Parameters**

| Name                   | Type                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `keysCount`            | `uint256`                          | Signing keys count                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `publicKeys`           | `bytes`                            | Public keys to submit                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `signatures`           | `bytes`                            | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata                                                                                                                                                                                                                                                                                                           |
| `managementProperties` | `NodeOperatorManagementProperties` | Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress. If set to true `resetNodeOperatorManagerAddress` method will be disabled |
| `eaProof`              | `bytes32[]`                        | Optional. Merkle proof of the sender being eligible for the Early Adoption                                                                                                                                                                                                                                                                                                                                                                                       |
| `referrer`             | `address`                          | Optional. Referrer address. Should be passed when Node Operator is created using partners integration                                                                                                                                                                                                                                                                                                                                                            |

### addNodeOperatorStETH

Add a new Node Operator using stETH as a bond.
At least one deposit data and corresponding bond should be provided

Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert

```solidity
function addNodeOperatorStETH(
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures,
  NodeOperatorManagementProperties calldata managementProperties,
  ICSAccounting.PermitInput calldata permit,
  bytes32[] calldata eaProof,
  address referrer
) external whenResumed;
```

**Parameters**

| Name                   | Type                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `keysCount`            | `uint256`                          | Signing keys count                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `publicKeys`           | `bytes`                            | Public keys to submit                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `signatures`           | `bytes`                            | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata                                                                                                                                                                                                                                                                                                           |
| `managementProperties` | `NodeOperatorManagementProperties` | Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress. If set to true `resetNodeOperatorManagerAddress` method will be disabled |
| `permit`               | `ICSAccounting.PermitInput`        | Optional. Permit to use stETH as bond                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `eaProof`              | `bytes32[]`                        | Optional. Merkle proof of the sender being eligible for the Early Adoption                                                                                                                                                                                                                                                                                                                                                                                       |
| `referrer`             | `address`                          | Optional. Referrer address. Should be passed when Node Operator is created using partners integration                                                                                                                                                                                                                                                                                                                                                            |

### addNodeOperatorWstETH

Add a new Node Operator using wstETH as a bond.
At least one deposit data and corresponding bond should be provided

Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert

```solidity
function addNodeOperatorWstETH(
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures,
  NodeOperatorManagementProperties calldata managementProperties,
  ICSAccounting.PermitInput calldata permit,
  bytes32[] calldata eaProof,
  address referrer
) external whenResumed;
```

**Parameters**

| Name                   | Type                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `keysCount`            | `uint256`                          | Signing keys count                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `publicKeys`           | `bytes`                            | Public keys to submit                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `signatures`           | `bytes`                            | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata                                                                                                                                                                                                                                                                                                           |
| `managementProperties` | `NodeOperatorManagementProperties` | Optional. Management properties to be used for the Node Operator. managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used. rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used. extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress. If set to true `resetNodeOperatorManagerAddress` method will be disabled |
| `permit`               | `ICSAccounting.PermitInput`        | Optional. Permit to use wstETH as bond                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `eaProof`              | `bytes32[]`                        | Optional. Merkle proof of the sender being eligible for the Early Adoption                                                                                                                                                                                                                                                                                                                                                                                       |
| `referrer`             | `address`                          | Optional. Referrer address. Should be passed when Node Operator is created using partners integration                                                                                                                                                                                                                                                                                                                                                            |

### addValidatorKeysETH

Add new keys to the existing Node Operator using ETH as a bond

```solidity
function addValidatorKeysETH(
  uint256 nodeOperatorId,
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures
) external payable whenResumed;
```

**Parameters**

| Name             | Type      | Description                                                                                                                                            |
| ---------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `nodeOperatorId` | `uint256` | ID of the Node Operator                                                                                                                                |
| `keysCount`      | `uint256` | Signing keys count                                                                                                                                     |
| `publicKeys`     | `bytes`   | Public keys to submit                                                                                                                                  |
| `signatures`     | `bytes`   | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata |

### addValidatorKeysStETH

Add new keys to the existing Node Operator using stETH as a bond

Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert

```solidity
function addValidatorKeysStETH(
  uint256 nodeOperatorId,
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures,
  ICSAccounting.PermitInput calldata permit
) external whenResumed;
```

**Parameters**

| Name             | Type                        | Description                                                                                                                                            |
| ---------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator                                                                                                                                |
| `keysCount`      | `uint256`                   | Signing keys count                                                                                                                                     |
| `publicKeys`     | `bytes`                     | Public keys to submit                                                                                                                                  |
| `signatures`     | `bytes`                     | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata |
| `permit`         | `ICSAccounting.PermitInput` | Optional. Permit to use stETH as bond                                                                                                                  |

### addValidatorKeysWstETH

Add new keys to the existing Node Operator using wstETH as a bond

Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert

```solidity
function addValidatorKeysWstETH(
  uint256 nodeOperatorId,
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures,
  ICSAccounting.PermitInput calldata permit
) external whenResumed;
```

**Parameters**

| Name             | Type                        | Description                                                                                                                                            |
| ---------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator                                                                                                                                |
| `keysCount`      | `uint256`                   | Signing keys count                                                                                                                                     |
| `publicKeys`     | `bytes`                     | Public keys to submit                                                                                                                                  |
| `signatures`     | `bytes`                     | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata |
| `permit`         | `ICSAccounting.PermitInput` | Optional. Permit to use wstETH as bond                                                                                                                 |

### depositETH

Stake user's ETH with Lido and make a deposit in stETH to the bond of the existing Node Operator

```solidity
function depositETH(uint256 nodeOperatorId) external payable;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### depositStETH

Deposit user's stETH to the bond of the existing Node Operator

```solidity
function depositStETH(
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  ICSAccounting.PermitInput calldata permit
) external;
```

**Parameters**

| Name             | Type                        | Description                           |
| ---------------- | --------------------------- | ------------------------------------- |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator               |
| `stETHAmount`    | `uint256`                   | Amount of stETH to deposit            |
| `permit`         | `ICSAccounting.PermitInput` | Optional. Permit to use stETH as bond |

### depositWstETH

Unwrap the user's wstETH and make a deposit in stETH to the bond of the existing Node Operator

```solidity
function depositWstETH(
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  ICSAccounting.PermitInput calldata permit
) external;
```

**Parameters**

| Name             | Type                        | Description                            |
| ---------------- | --------------------------- | -------------------------------------- |
| `nodeOperatorId` | `uint256`                   | ID of the Node Operator                |
| `wstETHAmount`   | `uint256`                   | Amount of wstETH to deposit            |
| `permit`         | `ICSAccounting.PermitInput` | Optional. Permit to use wstETH as bond |

### claimRewardsStETH

Claim full reward (fees + bond rewards) in stETH for the given Node Operator

If `stETHAmount` exceeds the current claimable amount, the claimable amount will be used instead

If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim

```solidity
function claimRewardsStETH(
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

**Parameters**

| Name                  | Type        | Description                                                 |
| --------------------- | ----------- | ----------------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                                     |
| `stETHAmount`         | `uint256`   | Amount of stETH to claim                                    |
| `cumulativeFeeShares` | `uint256`   | Optional. Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Optional. Merkle proof of the rewards                       |

### claimRewardsWstETH

Claim full reward (fees + bond rewards) in wstETH for the given Node Operator

If `wstETHAmount` exceeds the current claimable amount, the claimable amount will be used instead

If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim

```solidity
function claimRewardsWstETH(
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

**Parameters**

| Name                  | Type        | Description                                                 |
| --------------------- | ----------- | ----------------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                                     |
| `wstETHAmount`        | `uint256`   | Amount of wstETH to claim                                   |
| `cumulativeFeeShares` | `uint256`   | Optional. Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Optional. Merkle proof of the rewards                       |

### claimRewardsUnstETH

Request full reward (fees + bond rewards) in Withdrawal NFT (unstETH) for the given Node Operator

Amounts less than `MIN_STETH_WITHDRAWAL_AMOUNT` (see LidoWithdrawalQueue contract) are not allowed

Amounts above `MAX_STETH_WITHDRAWAL_AMOUNT` should be requested in several transactions

If `ethAmount` exceeds the current claimable amount, the claimable amount will be used instead

If `rewardsProof` is not provided, only excess bond (bond rewards) will be available for claim

_Reverts if amount isn't between `MIN_STETH_WITHDRAWAL_AMOUNT` and `MAX_STETH_WITHDRAWAL_AMOUNT`_

```solidity
function claimRewardsUnstETH(
  uint256 nodeOperatorId,
  uint256 stEthAmount,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

**Parameters**

| Name                  | Type        | Description                                                 |
| --------------------- | ----------- | ----------------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                                     |
| `stEthAmount`         | `uint256`   | Amount of ETH to request                                    |
| `cumulativeFeeShares` | `uint256`   | Optional. Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Optional. Merkle proof of the rewards                       |

### proposeNodeOperatorManagerAddressChange

Propose a new manager address for the Node Operator

```solidity
function proposeNodeOperatorManagerAddressChange(
  uint256 nodeOperatorId,
  address proposedAddress
) external;
```

**Parameters**

| Name              | Type      | Description              |
| ----------------- | --------- | ------------------------ |
| `nodeOperatorId`  | `uint256` | ID of the Node Operator  |
| `proposedAddress` | `address` | Proposed manager address |

### confirmNodeOperatorManagerAddressChange

Confirm a new manager address for the Node Operator.
Should be called from the currently proposed address

```solidity
function confirmNodeOperatorManagerAddressChange(uint256 nodeOperatorId) external;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### proposeNodeOperatorRewardAddressChange

Propose a new reward address for the Node Operator

```solidity
function proposeNodeOperatorRewardAddressChange(
  uint256 nodeOperatorId,
  address proposedAddress
) external;
```

**Parameters**

| Name              | Type      | Description             |
| ----------------- | --------- | ----------------------- |
| `nodeOperatorId`  | `uint256` | ID of the Node Operator |
| `proposedAddress` | `address` | Proposed reward address |

### confirmNodeOperatorRewardAddressChange

Confirm a new reward address for the Node Operator.
Should be called from the currently proposed address

```solidity
function confirmNodeOperatorRewardAddressChange(uint256 nodeOperatorId) external;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### resetNodeOperatorManagerAddress

Reset the manager address to the reward address.
Should be called from the reward address

```solidity
function resetNodeOperatorManagerAddress(uint256 nodeOperatorId) external;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### changeNodeOperatorRewardAddress

Change rewardAddress if extendedManagerPermissions is enabled for the Node Operator

```solidity
function changeNodeOperatorRewardAddress(uint256 nodeOperatorId, address newAddress) external;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |
| `newAddress`     | `address` | Proposed reward address |

### onRewardsMinted

Called when rewards are minted for the module

_Called by StakingRouter_

_Passes through the minted stETH shares to the fee distributor_

```solidity
function onRewardsMinted(uint256 totalShares) external onlyRole(STAKING_ROUTER_ROLE);
```

### updateStuckValidatorsCount

Update stuck validators count for Node Operators

_Called by StakingRouter_

_If the stuck keys count is above zero for the Node Operator,
the depositable validators count is set to 0 for this Node Operator_

```solidity
function updateStuckValidatorsCount(
  bytes calldata nodeOperatorIds,
  bytes calldata stuckValidatorsCounts
) external onlyRole(STAKING_ROUTER_ROLE);
```

**Parameters**

| Name                    | Type    | Description                                   |
| ----------------------- | ------- | --------------------------------------------- |
| `nodeOperatorIds`       | `bytes` | bytes packed array of Node Operator IDs       |
| `stuckValidatorsCounts` | `bytes` | bytes packed array of stuck validators counts |

### updateExitedValidatorsCount

Update exited validators count for Node Operators

_Called by StakingRouter_

```solidity
function updateExitedValidatorsCount(
  bytes calldata nodeOperatorIds,
  bytes calldata exitedValidatorsCounts
) external onlyRole(STAKING_ROUTER_ROLE);
```

**Parameters**

| Name                     | Type    | Description                                    |
| ------------------------ | ------- | ---------------------------------------------- |
| `nodeOperatorIds`        | `bytes` | bytes packed array of Node Operator IDs        |
| `exitedValidatorsCounts` | `bytes` | bytes packed array of exited validators counts |

### updateRefundedValidatorsCount

Update refunded validators count for the Node Operator.
Non supported in CSM

_Called by StakingRouter_

_Always reverts_

_`refundedValidatorsCount` is not used in the module_

```solidity
function updateRefundedValidatorsCount(uint256, uint256) external onlyRole(STAKING_ROUTER_ROLE);
```

### updateTargetValidatorsLimits

Update target validators limits for Node Operator

_Called by StakingRouter_

```solidity
function updateTargetValidatorsLimits(
  uint256 nodeOperatorId,
  uint256 targetLimitMode,
  uint256 targetLimit
) external onlyRole(STAKING_ROUTER_ROLE);
```

**Parameters**

| Name              | Type      | Description                                                                                                                |
| ----------------- | --------- | -------------------------------------------------------------------------------------------------------------------------- |
| `nodeOperatorId`  | `uint256` | ID of the Node Operator                                                                                                    |
| `targetLimitMode` | `uint256` | Target limit mode for the Node Operator (see https://hackmd.io/@lido/BJXRTxMRp) 0 - disabled 1 - soft mode 2 - forced mode |
| `targetLimit`     | `uint256` | Target limit of validators                                                                                                 |

### onExitedAndStuckValidatorsCountsUpdated

Called when exited and stuck validators counts updated.
This method is not used in CSM, hence it is empty

_Called by StakingRouter_

```solidity
function onExitedAndStuckValidatorsCountsUpdated() external onlyRole(STAKING_ROUTER_ROLE);
```

### unsafeUpdateValidatorsCount

Unsafe update of validators count for Node Operator by the DAO

_Called by StakingRouter_

```solidity
function unsafeUpdateValidatorsCount(
  uint256 nodeOperatorId,
  uint256 exitedValidatorsKeysCount,
  uint256 stuckValidatorsKeysCount
) external onlyRole(STAKING_ROUTER_ROLE);
```

**Parameters**

| Name                        | Type      | Description              |
| --------------------------- | --------- | ------------------------ |
| `nodeOperatorId`            | `uint256` | ID of the Node Operator  |
| `exitedValidatorsKeysCount` | `uint256` | Exited validators counts |
| `stuckValidatorsKeysCount`  | `uint256` | Stuck validators counts  |

### decreaseVettedSigningKeysCount

Called to decrease the number of vetted keys for Node Operators with given ids

_Called by StakingRouter_

```solidity
function decreaseVettedSigningKeysCount(
  bytes calldata nodeOperatorIds,
  bytes calldata vettedSigningKeysCounts
) external onlyRole(STAKING_ROUTER_ROLE);
```

**Parameters**

| Name                      | Type    | Description                                                                 |
| ------------------------- | ------- | --------------------------------------------------------------------------- |
| `nodeOperatorIds`         | `bytes` | Bytes packed array of the Node Operator ids                                 |
| `vettedSigningKeysCounts` | `bytes` | Bytes packed array of the new numbers of vetted keys for the Node Operators |

### removeKeys

Remove keys for the Node Operator and confiscate removal charge for each deleted key

```solidity
function removeKeys(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount) external;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |
| `startIndex`     | `uint256` | Index of the first key  |
| `keysCount`      | `uint256` | Keys count to delete    |

### normalizeQueue

Perform queue normalization for the given Node Operator

Normalization stands for adding vetted but not enqueued keys to the queue

```solidity
function normalizeQueue(uint256 nodeOperatorId) external;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### reportELRewardsStealingPenalty

Report EL rewards stealing for the given Node Operator

The amount equal to the stolen funds plus EL stealing fine will be locked

```solidity
function reportELRewardsStealingPenalty(
  uint256 nodeOperatorId,
  bytes32 blockHash,
  uint256 amount
) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE);
```

**Parameters**

| Name             | Type      | Description                                                               |
| ---------------- | --------- | ------------------------------------------------------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator                                                   |
| `blockHash`      | `bytes32` | Execution layer block hash of the proposed block with EL rewards stealing |
| `amount`         | `uint256` | Amount of stolen EL rewards in ETH                                        |

### cancelELRewardsStealingPenalty

Cancel previously reported and not settled EL rewards stealing penalty for the given Node Operator

The funds will be unlocked

```solidity
function cancelELRewardsStealingPenalty(
  uint256 nodeOperatorId,
  uint256 amount
) external onlyRole(REPORT_EL_REWARDS_STEALING_PENALTY_ROLE);
```

**Parameters**

| Name             | Type      | Description                 |
| ---------------- | --------- | --------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator     |
| `amount`         | `uint256` | Amount of penalty to cancel |

### settleELRewardsStealingPenalty

Settle locked bond for the given Node Operators

_SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE role is expected to be assigned to Easy Track_

```solidity
function settleELRewardsStealingPenalty(
  uint256[] calldata nodeOperatorIds
) external onlyRole(SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE);
```

**Parameters**

| Name              | Type        | Description               |
| ----------------- | ----------- | ------------------------- |
| `nodeOperatorIds` | `uint256[]` | IDs of the Node Operators |

### compensateELRewardsStealingPenalty

Compensate EL rewards stealing penalty for the given Node Operator to prevent further validator exits

_Can only be called by the Node Operator manager_

```solidity
function compensateELRewardsStealingPenalty(uint256 nodeOperatorId) external payable;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### submitWithdrawal

Report Node Operator's key as withdrawn and settle withdrawn amount

Called by the Verifier contract.
See `CSVerifier.processWithdrawalProof` to use this method permissionless

```solidity
function submitWithdrawal(
  uint256 nodeOperatorId,
  uint256 keyIndex,
  uint256 amount,
  bool isSlashed
) external onlyRole(VERIFIER_ROLE);
```

**Parameters**

| Name             | Type      | Description                                                    |
| ---------------- | --------- | -------------------------------------------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator                                        |
| `keyIndex`       | `uint256` | Index of the withdrawn key in the Node Operator's keys storage |
| `amount`         | `uint256` | Amount of withdrawn ETH in wei                                 |
| `isSlashed`      | `bool`    | Validator is slashed or not                                    |

### submitInitialSlashing

Report Node Operator's key as slashed and apply the initial slashing penalty

Called by the Verifier contract.
See `CSVerifier.processSlashingProof` to use this method permissionless

```solidity
function submitInitialSlashing(
  uint256 nodeOperatorId,
  uint256 keyIndex
) external onlyRole(VERIFIER_ROLE);
```

**Parameters**

| Name             | Type      | Description                                                  |
| ---------------- | --------- | ------------------------------------------------------------ |
| `nodeOperatorId` | `uint256` | ID of the Node Operator                                      |
| `keyIndex`       | `uint256` | Index of the slashed key in the Node Operator's keys storage |

### onWithdrawalCredentialsChanged

Called by the Staking Router when withdrawal credentials changed by DAO

_Called by StakingRouter_

_Resets the key removal charge_

_Changing the WC means that the current deposit data in the queue is not valid anymore and can't be deposited
So, the key removal charge should be reset to 0 to allow Node Operators to remove the keys without any charge.
After keys removal the DAO should set the new key removal charge._

```solidity
function onWithdrawalCredentialsChanged() external onlyRole(STAKING_ROUTER_ROLE);
```

### obtainDepositData

Get the next `depositsCount` of depositable keys with signatures from the queue

_Called by StakingRouter_

_Second param `depositCalldata` is not used_

```solidity
function obtainDepositData(
  uint256 depositsCount,
  bytes calldata
) external onlyRole(STAKING_ROUTER_ROLE) returns (bytes memory publicKeys, bytes memory signatures);
```

**Parameters**

| Name            | Type      | Description              |
| --------------- | --------- | ------------------------ |
| `depositsCount` | `uint256` | Count of deposits to get |
| `<none>`        | `bytes`   |                          |

**Returns**

| Name         | Type    | Description |
| ------------ | ------- | ----------- |
| `publicKeys` | `bytes` | Public keys |
| `signatures` | `bytes` | Signatures  |

### cleanDepositQueue

Clean the deposit queue from batches with no depositable keys

_Use **eth_call** to check how many items will be removed_

```solidity
function cleanDepositQueue(
  uint256 maxItems
) external returns (uint256 removed, uint256 lastRemovedAtDepth);
```

**Parameters**

| Name       | Type      | Description                    |
| ---------- | --------- | ------------------------------ |
| `maxItems` | `uint256` | How many queue items to review |

**Returns**

| Name                 | Type      | Description                                                                                          |
| -------------------- | --------- | ---------------------------------------------------------------------------------------------------- |
| `removed`            | `uint256` | Count of batches to be removed by visiting `maxItems` batches                                        |
| `lastRemovedAtDepth` | `uint256` | The value to use as `maxItems` to remove `removed` batches if the static call of the method was used |

### depositQueueItem

Get the deposit queue item by an index

```solidity
function depositQueueItem(uint128 index) external view returns (Batch);
```

**Parameters**

| Name    | Type      | Description           |
| ------- | --------- | --------------------- |
| `index` | `uint128` | Index of a queue item |

**Returns**

| Name     | Type    | Description        |
| -------- | ------- | ------------------ |
| `<none>` | `Batch` | Deposit queue item |

### isValidatorSlashed

Check if the given Node Operator's key is reported as slashed

```solidity
function isValidatorSlashed(uint256 nodeOperatorId, uint256 keyIndex) external view returns (bool);
```

**Parameters**

| Name             | Type      | Description               |
| ---------------- | --------- | ------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator   |
| `keyIndex`       | `uint256` | Index of the key to check |

**Returns**

| Name     | Type   | Description                        |
| -------- | ------ | ---------------------------------- |
| `<none>` | `bool` | Validator reported as slashed flag |

### isValidatorWithdrawn

Check if the given Node Operator's key is reported as withdrawn

```solidity
function isValidatorWithdrawn(
  uint256 nodeOperatorId,
  uint256 keyIndex
) external view returns (bool);
```

**Parameters**

| Name             | Type      | Description               |
| ---------------- | --------- | ------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator   |
| `keyIndex`       | `uint256` | index of the key to check |

**Returns**

| Name     | Type   | Description                          |
| -------- | ------ | ------------------------------------ |
| `<none>` | `bool` | Validator reported as withdrawn flag |

### getType

Get the module type

```solidity
function getType() external view returns (bytes32);
```

**Returns**

| Name     | Type      | Description |
| -------- | --------- | ----------- |
| `<none>` | `bytes32` | Module type |

### getStakingModuleSummary

Get staking module summary

```solidity
function getStakingModuleSummary()
  external
  view
  returns (
    uint256 totalExitedValidators,
    uint256 totalDepositedValidators,
    uint256 depositableValidatorsCount
  );
```

### getNodeOperator

Get Node Operator info

```solidity
function getNodeOperator(uint256 nodeOperatorId) external view returns (NodeOperator memory);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type           | Description        |
| -------- | -------------- | ------------------ |
| `<none>` | `NodeOperator` | Node Operator info |

### getNodeOperatorNonWithdrawnKeys

Get Node Operator non-withdrawn keys

```solidity
function getNodeOperatorNonWithdrawnKeys(uint256 nodeOperatorId) external view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description              |
| -------- | --------- | ------------------------ |
| `<none>` | `uint256` | Non-withdrawn keys count |

### getNodeOperatorSummary

Get Node Operator summary

depositableValidatorsCount depends on:

- totalVettedKeys
- totalDepositedKeys
- totalExitedKeys
- targetLimitMode
- targetValidatorsCount
- totalUnbondedKeys
- totalStuckKeys

```solidity
function getNodeOperatorSummary(
  uint256 nodeOperatorId
)
  external
  view
  returns (
    uint256 targetLimitMode,
    uint256 targetValidatorsCount,
    uint256 stuckValidatorsCount,
    uint256 refundedValidatorsCount,
    uint256 stuckPenaltyEndTimestamp,
    uint256 totalExitedValidators,
    uint256 totalDepositedValidators,
    uint256 depositableValidatorsCount
  );
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name                         | Type      | Description                          |
| ---------------------------- | --------- | ------------------------------------ |
| `targetLimitMode`            | `uint256` | Target limit mode                    |
| `targetValidatorsCount`      | `uint256` | Target validators count              |
| `stuckValidatorsCount`       | `uint256` | Stuck validators count               |
| `refundedValidatorsCount`    | `uint256` | Refunded validators count            |
| `stuckPenaltyEndTimestamp`   | `uint256` | Stuck penalty end timestamp (unused) |
| `totalExitedValidators`      | `uint256` | Total exited validators              |
| `totalDepositedValidators`   | `uint256` | Total deposited validators           |
| `depositableValidatorsCount` | `uint256` | Depositable validators count         |

### getSigningKeys

Get Node Operator signing keys

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
| `nodeOperatorId` | `uint256` | ID of the Node Operator |
| `startIndex`     | `uint256` | Index of the first key  |
| `keysCount`      | `uint256` | Count of keys to get    |

**Returns**

| Name     | Type    | Description  |
| -------- | ------- | ------------ |
| `<none>` | `bytes` | Signing keys |

### getSigningKeysWithSignatures

Get Node Operator signing keys with signatures

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
| `nodeOperatorId` | `uint256` | ID of the Node Operator |
| `startIndex`     | `uint256` | Index of the first key  |
| `keysCount`      | `uint256` | Count of keys to get    |

**Returns**

| Name         | Type    | Description                                                                                                                                            |
| ------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `keys`       | `bytes` | Signing keys                                                                                                                                           |
| `signatures` | `bytes` | Signatures of `(deposit_message_root, domain)` tuples https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata |

### getNonce

Get nonce of the module

```solidity
function getNonce() external view returns (uint256);
```

### getNodeOperatorsCount

Get total number of Node Operators

```solidity
function getNodeOperatorsCount() external view returns (uint256);
```

### getActiveNodeOperatorsCount

Get total number of active Node Operators

```solidity
function getActiveNodeOperatorsCount() external view returns (uint256);
```

### getNodeOperatorIsActive

Get Node Operator active status

```solidity
function getNodeOperatorIsActive(uint256 nodeOperatorId) external view returns (bool);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type   | Description                    |
| -------- | ------ | ------------------------------ |
| `<none>` | `bool` | active Operator is active flag |

### getNodeOperatorIds

Get IDs of Node Operators

```solidity
function getNodeOperatorIds(
  uint256 offset,
  uint256 limit
) external view returns (uint256[] memory nodeOperatorIds);
```

**Parameters**

| Name     | Type      | Description                                 |
| -------- | --------- | ------------------------------------------- |
| `offset` | `uint256` | Offset of the first Node Operator ID to get |
| `limit`  | `uint256` | Count of Node Operator IDs to get           |

**Returns**

| Name              | Type        | Description               |
| ----------------- | ----------- | ------------------------- |
| `nodeOperatorIds` | `uint256[]` | IDs of the Node Operators |

### \_incrementModuleNonce

```solidity
function _incrementModuleNonce() internal;
```

### \_createNodeOperator

```solidity
function _createNodeOperator(
  NodeOperatorManagementProperties calldata managementProperties,
  address referrer,
  bytes32[] calldata proof
) internal returns (uint256 noId, uint256 curveId);
```

### \_addKeysAndUpdateDepositableValidatorsCount

```solidity
function _addKeysAndUpdateDepositableValidatorsCount(
  uint256 nodeOperatorId,
  uint256 keysCount,
  bytes calldata publicKeys,
  bytes calldata signatures
) internal;
```

### \_setKeyRemovalCharge

```solidity
function _setKeyRemovalCharge(uint256 amount) internal;
```

### \_updateExitedValidatorsCount

_Update exited validators count for a single Node Operator_

_Allows decrease the count for unsafe updates_

```solidity
function _updateExitedValidatorsCount(
  uint256 nodeOperatorId,
  uint256 exitedValidatorsCount,
  bool allowDecrease
) internal;
```

### \_updateStuckValidatorsCount

```solidity
function _updateStuckValidatorsCount(uint256 nodeOperatorId, uint256 stuckValidatorsCount) internal;
```

### \_updateDepositableValidatorsCount

```solidity
function _updateDepositableValidatorsCount(
  uint256 nodeOperatorId,
  bool incrementNonceIfUpdated
) internal;
```

### \_onlyNodeOperatorManager

```solidity
function _onlyNodeOperatorManager(uint256 nodeOperatorId) internal view;
```

### \_onlyNodeOperatorManagerOrRewardAddresses

```solidity
function _onlyNodeOperatorManagerOrRewardAddresses(uint256 nodeOperatorId) internal view;
```

### \_onlyExistingNodeOperator

```solidity
function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view;
```

### \_onlyValidIndexRange

```solidity
function _onlyValidIndexRange(
  uint256 nodeOperatorId,
  uint256 startIndex,
  uint256 keysCount
) internal view;
```

### \_onlyRecoverer

```solidity
function _onlyRecoverer() internal view override;
```

### \_keyPointer

_Both nodeOperatorId and keyIndex are limited to uint64 by the contract_

```solidity
function _keyPointer(uint256 nodeOperatorId, uint256 keyIndex) internal pure returns (uint256);
```

## Events

### NodeOperatorAdded

```solidity
event NodeOperatorAdded(
  uint256 indexed nodeOperatorId,
  address indexed managerAddress,
  address indexed rewardAddress
);
```

### ReferrerSet

```solidity
event ReferrerSet(uint256 indexed nodeOperatorId, address indexed referrer);
```

### DepositableSigningKeysCountChanged

```solidity
event DepositableSigningKeysCountChanged(
  uint256 indexed nodeOperatorId,
  uint256 depositableKeysCount
);
```

### VettedSigningKeysCountChanged

```solidity
event VettedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 vettedKeysCount);
```

### VettedSigningKeysCountDecreased

```solidity
event VettedSigningKeysCountDecreased(uint256 indexed nodeOperatorId);
```

### DepositedSigningKeysCountChanged

```solidity
event DepositedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 depositedKeysCount);
```

### ExitedSigningKeysCountChanged

```solidity
event ExitedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 exitedKeysCount);
```

### StuckSigningKeysCountChanged

```solidity
event StuckSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 stuckKeysCount);
```

### TotalSigningKeysCountChanged

```solidity
event TotalSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 totalKeysCount);
```

### TargetValidatorsCountChanged

```solidity
event TargetValidatorsCountChanged(
  uint256 indexed nodeOperatorId,
  uint256 targetLimitMode,
  uint256 targetValidatorsCount
);
```

### WithdrawalSubmitted

```solidity
event WithdrawalSubmitted(
  uint256 indexed nodeOperatorId,
  uint256 keyIndex,
  uint256 amount,
  bytes pubkey
);
```

### InitialSlashingSubmitted

```solidity
event InitialSlashingSubmitted(uint256 indexed nodeOperatorId, uint256 keyIndex, bytes pubkey);
```

### PublicRelease

```solidity
event PublicRelease();
```

### KeyRemovalChargeSet

```solidity
event KeyRemovalChargeSet(uint256 amount);
```

### KeyRemovalChargeApplied

```solidity
event KeyRemovalChargeApplied(uint256 indexed nodeOperatorId);
```

### ELRewardsStealingPenaltyReported

```solidity
event ELRewardsStealingPenaltyReported(
  uint256 indexed nodeOperatorId,
  bytes32 proposedBlockHash,
  uint256 stolenAmount
);
```

### ELRewardsStealingPenaltyCancelled

```solidity
event ELRewardsStealingPenaltyCancelled(uint256 indexed nodeOperatorId, uint256 amount);
```

### ELRewardsStealingPenaltyCompensated

```solidity
event ELRewardsStealingPenaltyCompensated(uint256 indexed nodeOperatorId, uint256 amount);
```

### ELRewardsStealingPenaltySettled

```solidity
event ELRewardsStealingPenaltySettled(uint256 indexed nodeOperatorId);
```

## Errors

### SenderIsNotEligible

```solidity
error SenderIsNotEligible();
```

### InvalidVetKeysPointer

```solidity
error InvalidVetKeysPointer();
```

### StuckKeysHigherThanNonExited

```solidity
error StuckKeysHigherThanNonExited();
```

### ExitedKeysHigherThanTotalDeposited

```solidity
error ExitedKeysHigherThanTotalDeposited();
```

### ExitedKeysDecrease

```solidity
error ExitedKeysDecrease();
```

### InvalidInput

```solidity
error InvalidInput();
```

### NotEnoughKeys

```solidity
error NotEnoughKeys();
```

### SigningKeysInvalidOffset

```solidity
error SigningKeysInvalidOffset();
```

### AlreadySubmitted

```solidity
error AlreadySubmitted();
```

### AlreadyActivated

```solidity
error AlreadyActivated();
```

### InvalidAmount

```solidity
error InvalidAmount();
```

### NotAllowedToJoinYet

```solidity
error NotAllowedToJoinYet();
```

### MaxSigningKeysCountExceeded

```solidity
error MaxSigningKeysCountExceeded();
```

### NotSupported

```solidity
error NotSupported();
```

### ZeroLocatorAddress

```solidity
error ZeroLocatorAddress();
```

### ZeroAccountingAddress

```solidity
error ZeroAccountingAddress();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```
