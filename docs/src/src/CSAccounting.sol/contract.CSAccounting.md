# CSAccounting

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/CSAccounting.sol)

**Inherits:**
[ICSAccounting](/src/interfaces/ICSAccounting.sol/interface.ICSAccounting.md), [CSBondCore](/src/abstract/CSBondCore.sol/abstract.CSBondCore.md), [CSBondCurve](/src/abstract/CSBondCurve.sol/abstract.CSBondCurve.md), [CSBondLock](/src/abstract/CSBondLock.sol/abstract.CSBondLock.md), [PausableUntil](/src/lib/utils/PausableUntil.sol/contract.PausableUntil.md), AccessControlEnumerableUpgradeable, [AssetRecoverer](/src/abstract/AssetRecoverer.sol/abstract.AssetRecoverer.md)

**Author:**
vgorkavenko

This contract stores the Node Operators' bonds in the form of stETH shares,
so it should be considered in the recovery process

## State Variables

### PAUSE_ROLE

```solidity
bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
```

### RESUME_ROLE

```solidity
bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
```

### ACCOUNTING_MANAGER_ROLE

```solidity
bytes32 public constant ACCOUNTING_MANAGER_ROLE = keccak256("ACCOUNTING_MANAGER_ROLE");
```

### MANAGE_BOND_CURVES_ROLE

```solidity
bytes32 public constant MANAGE_BOND_CURVES_ROLE = keccak256("MANAGE_BOND_CURVES_ROLE");
```

### SET_BOND_CURVE_ROLE

```solidity
bytes32 public constant SET_BOND_CURVE_ROLE = keccak256("SET_BOND_CURVE_ROLE");
```

### RESET_BOND_CURVE_ROLE

```solidity
bytes32 public constant RESET_BOND_CURVE_ROLE = keccak256("RESET_BOND_CURVE_ROLE");
```

### RECOVERER_ROLE

```solidity
bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");
```

### CSM

```solidity
ICSModule public immutable CSM;
```

### feeDistributor

```solidity
ICSFeeDistributor public feeDistributor;
```

### chargePenaltyRecipient

```solidity
address public chargePenaltyRecipient;
```

## Functions

### onlyCSM

```solidity
modifier onlyCSM();
```

### constructor

```solidity
constructor(
  address lidoLocator,
  address communityStakingModule,
  uint256 maxCurveLength,
  uint256 minBondLockRetentionPeriod,
  uint256 maxBondLockRetentionPeriod
)
  CSBondCore(lidoLocator)
  CSBondCurve(maxCurveLength)
  CSBondLock(minBondLockRetentionPeriod, maxBondLockRetentionPeriod);
```

**Parameters**

| Name                         | Type      | Description                                           |
| ---------------------------- | --------- | ----------------------------------------------------- |
| `lidoLocator`                | `address` | Lido locator contract address                         |
| `communityStakingModule`     | `address` | Community Staking Module contract address             |
| `maxCurveLength`             | `uint256` | Max number of the points in the bond curves           |
| `minBondLockRetentionPeriod` | `uint256` | Min time in seconds for the bondLock retention period |
| `maxBondLockRetentionPeriod` | `uint256` | Max time in seconds for the bondLock retention period |

### initialize

```solidity
function initialize(
  uint256[] calldata bondCurve,
  address admin,
  address _feeDistributor,
  uint256 bondLockRetentionPeriod,
  address _chargePenaltyRecipient
) external initializer;
```

**Parameters**

| Name                      | Type        | Description                                 |
| ------------------------- | ----------- | ------------------------------------------- |
| `bondCurve`               | `uint256[]` | Initial bond curve                          |
| `admin`                   | `address`   | Admin role member address                   |
| `_feeDistributor`         | `address`   | Fee Distributor contract address            |
| `bondLockRetentionPeriod` | `uint256`   | Retention period for locked bond in seconds |
| `_chargePenaltyRecipient` | `address`   | Recipient of the charge penalty type        |

### resume

Resume reward claims and deposits

```solidity
function resume() external onlyRole(RESUME_ROLE);
```

### pauseFor

Pause reward claims and deposits for `duration` seconds

_Must be called together with `CSModule.pauseFor`_

_Passing MAX_UINT_256 as `duration` pauses indefinitely_

```solidity
function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE);
```

**Parameters**

| Name       | Type      | Description                      |
| ---------- | --------- | -------------------------------- |
| `duration` | `uint256` | Duration of the pause in seconds |

### setChargePenaltyRecipient

Set charge recipient address

```solidity
function setChargePenaltyRecipient(
  address _chargePenaltyRecipient
) external onlyRole(ACCOUNTING_MANAGER_ROLE);
```

**Parameters**

| Name                      | Type      | Description              |
| ------------------------- | --------- | ------------------------ |
| `_chargePenaltyRecipient` | `address` | Charge recipient address |

### setLockedBondRetentionPeriod

Set bond lock retention period

```solidity
function setLockedBondRetentionPeriod(uint256 retention) external onlyRole(ACCOUNTING_MANAGER_ROLE);
```

**Parameters**

| Name        | Type      | Description                           |
| ----------- | --------- | ------------------------------------- |
| `retention` | `uint256` | Period in seconds to retain bond lock |

### addBondCurve

Add a new bond curve

```solidity
function addBondCurve(
  uint256[] calldata bondCurve
) external onlyRole(MANAGE_BOND_CURVES_ROLE) returns (uint256 id);
```

**Parameters**

| Name        | Type        | Description                  |
| ----------- | ----------- | ---------------------------- |
| `bondCurve` | `uint256[]` | Bond curve definition to add |

**Returns**

| Name | Type      | Description           |
| ---- | --------- | --------------------- |
| `id` | `uint256` | Id of the added curve |

### updateBondCurve

Update existing bond curve

```solidity
function updateBondCurve(
  uint256 curveId,
  uint256[] calldata bondCurve
) external onlyRole(MANAGE_BOND_CURVES_ROLE);
```

**Parameters**

| Name        | Type        | Description             |
| ----------- | ----------- | ----------------------- |
| `curveId`   | `uint256`   | Bond curve ID to update |
| `bondCurve` | `uint256[]` | Bond curve definition   |

### setBondCurve

Set the bond curve for the given Node Operator

```solidity
function setBondCurve(
  uint256 nodeOperatorId,
  uint256 curveId
) external onlyRole(SET_BOND_CURVE_ROLE);
```

**Parameters**

| Name             | Type      | Description                 |
| ---------------- | --------- | --------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator     |
| `curveId`        | `uint256` | ID of the bond curve to set |

### resetBondCurve

Reset bond curve to the default one for the given Node Operator

```solidity
function resetBondCurve(uint256 nodeOperatorId) external onlyRole(RESET_BOND_CURVE_ROLE);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### depositETH

Stake user's ETH with Lido and deposit stETH to the bond

_Called by CSM exclusively_

```solidity
function depositETH(address from, uint256 nodeOperatorId) external payable whenResumed onlyCSM;
```

**Parameters**

| Name             | Type      | Description                                 |
| ---------------- | --------- | ------------------------------------------- |
| `from`           | `address` | Address to stake ETH and deposit stETH from |
| `nodeOperatorId` | `uint256` | ID of the Node Operator                     |

### depositStETH

Deposit user's stETH to the bond for the given Node Operator

_Called by CSM exclusively_

```solidity
function depositStETH(
  address from,
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  PermitInput calldata permit
) external whenResumed onlyCSM;
```

**Parameters**

| Name             | Type          | Description                   |
| ---------------- | ------------- | ----------------------------- |
| `from`           | `address`     | Address to deposit stETH from |
| `nodeOperatorId` | `uint256`     | ID of the Node Operator       |
| `stETHAmount`    | `uint256`     | Amount of stETH to deposit    |
| `permit`         | `PermitInput` | stETH permit for the contract |

### depositWstETH

Unwrap the user's wstETH and deposit stETH to the bond for the given Node Operator

_Called by CSM exclusively_

```solidity
function depositWstETH(
  address from,
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  PermitInput calldata permit
) external whenResumed onlyCSM;
```

**Parameters**

| Name             | Type          | Description                    |
| ---------------- | ------------- | ------------------------------ |
| `from`           | `address`     | Address to unwrap wstETH from  |
| `nodeOperatorId` | `uint256`     | ID of the Node Operator        |
| `wstETHAmount`   | `uint256`     | Amount of wstETH to deposit    |
| `permit`         | `PermitInput` | wstETH permit for the contract |

### claimRewardsStETH

Claim full reward (fee + bond) in stETH for the given Node Operator with desirable value.
`rewardsProof` and `cumulativeFeeShares` might be empty in order to claim only excess bond

_Called by CSM exclusively_

```solidity
function claimRewardsStETH(
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  address rewardAddress,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external whenResumed onlyCSM;
```

**Parameters**

| Name                  | Type        | Description                                       |
| --------------------- | ----------- | ------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                           |
| `stETHAmount`         | `uint256`   | Amount of stETH to claim                          |
| `rewardAddress`       | `address`   | Reward address of the node operator               |
| `cumulativeFeeShares` | `uint256`   | Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Merkle proof of the rewards                       |

### claimRewardsWstETH

Claim full reward (fee + bond) in wstETH for the given Node Operator available for this moment.
`rewardsProof` and `cumulativeFeeShares` might be empty in order to claim only excess bond

_Called by CSM exclusively_

```solidity
function claimRewardsWstETH(
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  address rewardAddress,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external whenResumed onlyCSM;
```

**Parameters**

| Name                  | Type        | Description                                       |
| --------------------- | ----------- | ------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                           |
| `wstETHAmount`        | `uint256`   | Amount of wstETH to claim                         |
| `rewardAddress`       | `address`   | Reward address of the node operator               |
| `cumulativeFeeShares` | `uint256`   | Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Merkle proof of the rewards                       |

### claimRewardsUnstETH

Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given Node Operator available for this moment.
`rewardsProof` and `cumulativeFeeShares` might be empty in order to claim only excess bond

_Reverts if amount isn't between `MIN_STETH_WITHDRAWAL_AMOUNT` and `MAX_STETH_WITHDRAWAL_AMOUNT`_

_Called by CSM exclusively_

```solidity
function claimRewardsUnstETH(
  uint256 nodeOperatorId,
  uint256 stEthAmount,
  address rewardAddress,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external whenResumed onlyCSM;
```

**Parameters**

| Name                  | Type        | Description                                       |
| --------------------- | ----------- | ------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                           |
| `stEthAmount`         | `uint256`   | Amount of ETH to request                          |
| `rewardAddress`       | `address`   | Reward address of the node operator               |
| `cumulativeFeeShares` | `uint256`   | Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Merkle proof of the rewards                       |

### lockBondETH

Lock bond in ETH for the given Node Operator

_Called by CSM exclusively_

```solidity
function lockBondETH(uint256 nodeOperatorId, uint256 amount) external onlyCSM;
```

**Parameters**

| Name             | Type      | Description                   |
| ---------------- | --------- | ----------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator       |
| `amount`         | `uint256` | Amount to lock in ETH (stETH) |

### releaseLockedBondETH

Release locked bond in ETH for the given Node Operator

_Called by CSM exclusively_

```solidity
function releaseLockedBondETH(uint256 nodeOperatorId, uint256 amount) external onlyCSM;
```

**Parameters**

| Name             | Type      | Description                      |
| ---------------- | --------- | -------------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator          |
| `amount`         | `uint256` | Amount to release in ETH (stETH) |

### compensateLockedBondETH

Compensate locked bond ETH for the given Node Operator

```solidity
function compensateLockedBondETH(uint256 nodeOperatorId) external payable onlyCSM;
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### settleLockedBondETH

Settle locked bond ETH for the given Node Operator

_Called by CSM exclusively_

```solidity
function settleLockedBondETH(
  uint256 nodeOperatorId
) external onlyCSM returns (uint256 settledAmount);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

### penalize

Penalize bond by burning stETH shares of the given Node Operator

_Called by CSM exclusively_

```solidity
function penalize(uint256 nodeOperatorId, uint256 amount) external onlyCSM;
```

**Parameters**

| Name             | Type      | Description                       |
| ---------------- | --------- | --------------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator           |
| `amount`         | `uint256` | Amount to penalize in ETH (stETH) |

### chargeFee

Charge fee from bond by transferring stETH shares of the given Node Operator to the charge recipient

_Called by CSM exclusively_

```solidity
function chargeFee(uint256 nodeOperatorId, uint256 amount) external onlyCSM;
```

**Parameters**

| Name             | Type      | Description                     |
| ---------------- | --------- | ------------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator         |
| `amount`         | `uint256` | Amount to charge in ETH (stETH) |

### pullFeeRewards

Pull fees from CSFeeDistributor to the Node Operator's bond

_Permissionless method. Can be called before penalty application to ensure that rewards are also penalized_

```solidity
function pullFeeRewards(
  uint256 nodeOperatorId,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

**Parameters**

| Name                  | Type        | Description                                       |
| --------------------- | ----------- | ------------------------------------------------- |
| `nodeOperatorId`      | `uint256`   | ID of the Node Operator                           |
| `cumulativeFeeShares` | `uint256`   | Cumulative fee stETH shares for the Node Operator |
| `rewardsProof`        | `bytes32[]` | Merkle proof of the rewards                       |

### recoverERC20

Recover ERC20 tokens from the contract

```solidity
function recoverERC20(address token, uint256 amount) external override;
```

**Parameters**

| Name     | Type      | Description                           |
| -------- | --------- | ------------------------------------- |
| `token`  | `address` | Address of the ERC20 token to recover |
| `amount` | `uint256` | Amount of the ERC20 token to recover  |

### recoverStETHShares

Recover all stETH shares from the contract

_Accounts for the bond funds stored during recovery_

```solidity
function recoverStETHShares() external;
```

### renewBurnerAllowance

Service method to update allowance to Burner in case it has changed

```solidity
function renewBurnerAllowance() external;
```

### getBondSummary

Get current and required bond amounts in ETH (stETH) for the given Node Operator

_To calculate excess bond amount subtract `required` from `current` value.
To calculate missed bond amount subtract `current` from `required` value_

```solidity
function getBondSummary(
  uint256 nodeOperatorId
) public view returns (uint256 current, uint256 required);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name       | Type      | Description                 |
| ---------- | --------- | --------------------------- |
| `current`  | `uint256` | Current bond amount in ETH  |
| `required` | `uint256` | Required bond amount in ETH |

### getBondSummaryShares

Get current and required bond amounts in stETH shares for the given Node Operator

_To calculate excess bond amount subtract `required` from `current` value.
To calculate missed bond amount subtract `current` from `required` value_

```solidity
function getBondSummaryShares(
  uint256 nodeOperatorId
) public view returns (uint256 current, uint256 required);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name       | Type      | Description                          |
| ---------- | --------- | ------------------------------------ |
| `current`  | `uint256` | Current bond amount in stETH shares  |
| `required` | `uint256` | Required bond amount in stETH shares |

### getUnbondedKeysCount

Get the number of the unbonded keys

```solidity
function getUnbondedKeysCount(uint256 nodeOperatorId) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description         |
| -------- | --------- | ------------------- |
| `<none>` | `uint256` | Unbonded keys count |

### getUnbondedKeysCountToEject

Get the number of the unbonded keys to be ejected using a forcedTargetLimit

```solidity
function getUnbondedKeysCountToEject(uint256 nodeOperatorId) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description         |
| -------- | --------- | ------------------- |
| `<none>` | `uint256` | Unbonded keys count |

### getRequiredBondForNextKeys

Get the required bond in ETH (inc. missed and excess) for the given Node Operator to upload new deposit data

```solidity
function getRequiredBondForNextKeys(
  uint256 nodeOperatorId,
  uint256 additionalKeys
) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description               |
| ---------------- | --------- | ------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator   |
| `additionalKeys` | `uint256` | Number of new keys to add |

**Returns**

| Name     | Type      | Description                 |
| -------- | --------- | --------------------------- |
| `<none>` | `uint256` | Required bond amount in ETH |

### getBondAmountByKeysCountWstETH

Get the bond amount in wstETH required for the `keysCount` keys using the default bond curve

```solidity
function getBondAmountByKeysCountWstETH(
  uint256 keysCount,
  uint256 curveId
) public view returns (uint256);
```

**Parameters**

| Name        | Type      | Description                                      |
| ----------- | --------- | ------------------------------------------------ |
| `keysCount` | `uint256` | Keys count to calculate the required bond amount |
| `curveId`   | `uint256` | Id of the curve to perform calculations against  |

**Returns**

| Name     | Type      | Description                                |
| -------- | --------- | ------------------------------------------ |
| `<none>` | `uint256` | wstETH amount required for the `keysCount` |

### getBondAmountByKeysCountWstETH

Get the bond amount in wstETH required for the `keysCount` keys using the custom bond curve

```solidity
function getBondAmountByKeysCountWstETH(
  uint256 keysCount,
  BondCurve memory curve
) public view returns (uint256);
```

**Parameters**

| Name        | Type        | Description                                                                                                |
| ----------- | ----------- | ---------------------------------------------------------------------------------------------------------- |
| `keysCount` | `uint256`   | Keys count to calculate the required bond amount                                                           |
| `curve`     | `BondCurve` | Bond curve definition. Use CSBondCurve.getBondCurve(id) method to get the definition for the exiting curve |

**Returns**

| Name     | Type      | Description                                |
| -------- | --------- | ------------------------------------------ |
| `<none>` | `uint256` | wstETH amount required for the `keysCount` |

### getRequiredBondForNextKeysWstETH

Get the required bond in wstETH (inc. missed and excess) for the given Node Operator to upload new keys

```solidity
function getRequiredBondForNextKeysWstETH(
  uint256 nodeOperatorId,
  uint256 additionalKeys
) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description               |
| ---------------- | --------- | ------------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator   |
| `additionalKeys` | `uint256` | Number of new keys to add |

**Returns**

| Name     | Type      | Description             |
| -------- | --------- | ----------------------- |
| `<none>` | `uint256` | Required bond in wstETH |

### \_pullFeeRewards

```solidity
function _pullFeeRewards(
  uint256 nodeOperatorId,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) internal;
```

### \_getClaimableBondShares

_Overrides the original implementation to account for a locked bond and withdrawn validators_

```solidity
function _getClaimableBondShares(uint256 nodeOperatorId) internal view override returns (uint256);
```

### \_getUnbondedKeysCount

_Unbonded stands for the amount of the keys not fully covered with the bond_

```solidity
function _getUnbondedKeysCount(
  uint256 nodeOperatorId,
  bool accountLockedBond
) internal view returns (uint256);
```

### \_onlyRecoverer

10 wei added to account for possible stETH rounding errors
https://github.com/lidofinance/lido-dao/issues/442#issuecomment-1182264205.
Should be sufficient for ~ 40 years

```solidity
function _onlyRecoverer() internal view override;
```

### \_onlyExistingNodeOperator

```solidity
function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view;
```

### \_setChargePenaltyRecipient

```solidity
function _setChargePenaltyRecipient(address _chargePenaltyRecipient) private;
```

## Events

### BondLockCompensated

```solidity
event BondLockCompensated(uint256 indexed nodeOperatorId, uint256 amount);
```

### ChargePenaltyRecipientSet

```solidity
event ChargePenaltyRecipientSet(address chargePenaltyRecipient);
```

## Errors

### SenderIsNotCSM

```solidity
error SenderIsNotCSM();
```

### ZeroModuleAddress

```solidity
error ZeroModuleAddress();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### ZeroFeeDistributorAddress

```solidity
error ZeroFeeDistributorAddress();
```

### ZeroChargePenaltyRecipientAddress

```solidity
error ZeroChargePenaltyRecipientAddress();
```

### NodeOperatorDoesNotExist

```solidity
error NodeOperatorDoesNotExist();
```

### ElRewardsVaultReceiveFailed

```solidity
error ElRewardsVaultReceiveFailed();
```
