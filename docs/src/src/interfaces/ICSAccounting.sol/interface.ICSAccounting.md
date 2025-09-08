# ICSAccounting
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSAccounting.sol)

**Inherits:**
[ICSBondCore](/src/interfaces/ICSBondCore.sol/interface.ICSBondCore.md), [ICSBondCurve](/src/interfaces/ICSBondCurve.sol/interface.ICSBondCurve.md), [ICSBondLock](/src/interfaces/ICSBondLock.sol/interface.ICSBondLock.md), [IAssetRecovererLib](/src/lib/AssetRecovererLib.sol/interface.IAssetRecovererLib.md)


## Functions
### PAUSE_ROLE


```solidity
function PAUSE_ROLE() external view returns (bytes32);
```

### RESUME_ROLE


```solidity
function RESUME_ROLE() external view returns (bytes32);
```

### MANAGE_BOND_CURVES_ROLE


```solidity
function MANAGE_BOND_CURVES_ROLE() external view returns (bytes32);
```

### SET_BOND_CURVE_ROLE


```solidity
function SET_BOND_CURVE_ROLE() external view returns (bytes32);
```

### RECOVERER_ROLE


```solidity
function RECOVERER_ROLE() external view returns (bytes32);
```

### MODULE


```solidity
function MODULE() external view returns (ICSModule);
```

### FEE_DISTRIBUTOR


```solidity
function FEE_DISTRIBUTOR() external view returns (ICSFeeDistributor);
```

### feeDistributor


```solidity
function feeDistributor() external view returns (ICSFeeDistributor);
```

### chargePenaltyRecipient


```solidity
function chargePenaltyRecipient() external view returns (address);
```

### getInitializedVersion

Get the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

### resume

Resume reward claims and deposits


```solidity
function resume() external;
```

### pauseFor

Pause reward claims and deposits for `duration` seconds

*Must be called together with `CSModule.pauseFor`*

*Passing MAX_UINT_256 as `duration` pauses indefinitely*


```solidity
function pauseFor(uint256 duration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`duration`|`uint256`|Duration of the pause in seconds|


### setChargePenaltyRecipient

Set charge recipient address


```solidity
function setChargePenaltyRecipient(address _chargePenaltyRecipient) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_chargePenaltyRecipient`|`address`|Charge recipient address|


### setBondLockPeriod

Set bond lock period


```solidity
function setBondLockPeriod(uint256 period) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`period`|`uint256`|Period in seconds to retain bond lock|


### addBondCurve

Add a new bond curve


```solidity
function addBondCurve(BondCurveIntervalInput[] calldata bondCurve) external returns (uint256 id);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bondCurve`|`BondCurveIntervalInput[]`|Bond curve definition to add|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|Id of the added curve|


### updateBondCurve

Update existing bond curve

*If the curve is updated to a curve with higher values for any point,
Extensive checks should be performed to avoid inconsistency in the keys accounting*


```solidity
function updateBondCurve(uint256 curveId, BondCurveIntervalInput[] calldata bondCurve) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Bond curve ID to update|
|`bondCurve`|`BondCurveIntervalInput[]`|Bond curve definition|


### getRequiredBondForNextKeys

Get the required bond in ETH (inc. missed and excess) for the given Node Operator to upload new deposit data


```solidity
function getRequiredBondForNextKeys(uint256 nodeOperatorId, uint256 additionalKeys) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`additionalKeys`|`uint256`|Number of new keys to add|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Required bond amount in ETH|


### getBondAmountByKeysCountWstETH

Get the bond amount in wstETH required for the `keysCount` keys using the default bond curve


```solidity
function getBondAmountByKeysCountWstETH(uint256 keysCount, uint256 curveId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keysCount`|`uint256`|Keys count to calculate the required bond amount|
|`curveId`|`uint256`|Id of the curve to perform calculations against|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|wstETH amount required for the `keysCount`|


### getRequiredBondForNextKeysWstETH

Get the required bond in wstETH (inc. missed and excess) for the given Node Operator to upload new keys


```solidity
function getRequiredBondForNextKeysWstETH(uint256 nodeOperatorId, uint256 additionalKeys)
    external
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`additionalKeys`|`uint256`|Number of new keys to add|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Required bond in wstETH|


### getUnbondedKeysCount

Get the number of the unbonded keys


```solidity
function getUnbondedKeysCount(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Unbonded keys count|


### getUnbondedKeysCountToEject

Get the number of the unbonded keys to be ejected using a forcedTargetLimit


```solidity
function getUnbondedKeysCountToEject(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Unbonded keys count|


### getBondSummary

Get current and required bond amounts in ETH (stETH) for the given Node Operator

*To calculate excess bond amount subtract `required` from `current` value.
To calculate missed bond amount subtract `current` from `required` value*


```solidity
function getBondSummary(uint256 nodeOperatorId) external view returns (uint256 current, uint256 required);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`current`|`uint256`|Current bond amount in ETH|
|`required`|`uint256`|Required bond amount in ETH|


### getBondSummaryShares

Get current and required bond amounts in stETH shares for the given Node Operator

*To calculate excess bond amount subtract `required` from `current` value.
To calculate missed bond amount subtract `current` from `required` value*


```solidity
function getBondSummaryShares(uint256 nodeOperatorId) external view returns (uint256 current, uint256 required);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`current`|`uint256`|Current bond amount in stETH shares|
|`required`|`uint256`|Required bond amount in stETH shares|


### getClaimableBondShares

Get current claimable bond in stETH shares for the given Node Operator


```solidity
function getClaimableBondShares(uint256 nodeOperatorId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Current claimable bond in stETH shares|


### getClaimableRewardsAndBondShares

Get current claimable bond in stETH shares for the given Node Operator
Includes potential rewards distributed by the Fee Distributor


```solidity
function getClaimableRewardsAndBondShares(
    uint256 nodeOperatorId,
    uint256 cumulativeFeeShares,
    bytes32[] calldata rewardsProof
) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`cumulativeFeeShares`|`uint256`|Cumulative fee stETH shares for the Node Operator|
|`rewardsProof`|`bytes32[]`|Merkle proof of the rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Current claimable bond in stETH shares|


### depositWstETH

Unwrap the user's wstETH and deposit stETH to the bond for the given Node Operator

*Called by CSM exclusively. CSM should check node operator existence and update depositable validators count*


```solidity
function depositWstETH(address from, uint256 nodeOperatorId, uint256 wstETHAmount, PermitInput calldata permit)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Address to unwrap wstETH from|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`wstETHAmount`|`uint256`|Amount of wstETH to deposit|
|`permit`|`PermitInput`|wstETH permit for the contract|


### depositWstETH

Unwrap the user's wstETH and deposit stETH to the bond for the given Node Operator

*Permissionless. Enqueues Node Operator's keys if needed*


```solidity
function depositWstETH(uint256 nodeOperatorId, uint256 wstETHAmount, PermitInput calldata permit) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`wstETHAmount`|`uint256`|Amount of wstETH to deposit|
|`permit`|`PermitInput`|wstETH permit for the contract|


### depositStETH

Deposit user's stETH to the bond for the given Node Operator

*Called by CSM exclusively. CSM should check node operator existence and update depositable validators count*


```solidity
function depositStETH(address from, uint256 nodeOperatorId, uint256 stETHAmount, PermitInput calldata permit)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Address to deposit stETH from.|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`stETHAmount`|`uint256`|Amount of stETH to deposit|
|`permit`|`PermitInput`|stETH permit for the contract|


### depositStETH

Deposit user's stETH to the bond for the given Node Operator

*Permissionless. Enqueues Node Operator's keys if needed*


```solidity
function depositStETH(uint256 nodeOperatorId, uint256 stETHAmount, PermitInput calldata permit) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`stETHAmount`|`uint256`|Amount of stETH to deposit|
|`permit`|`PermitInput`|stETH permit for the contract|


### depositETH

Stake user's ETH with Lido and deposit stETH to the bond

*Called by CSM exclusively. CSM should check node operator existence and update depositable validators count*


```solidity
function depositETH(address from, uint256 nodeOperatorId) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Address to stake ETH and deposit stETH from|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### depositETH

Stake user's ETH with Lido and deposit stETH to the bond

*Permissionless. Enqueues Node Operator's keys if needed*


```solidity
function depositETH(uint256 nodeOperatorId) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### claimRewardsStETH

Claim full reward (fee + bond) in stETH for the given Node Operator with desirable value.
`rewardsProof` and `cumulativeFeeShares` might be empty in order to claim only excess bond

*It's impossible to use single-leaf proof via this method, so this case should be treated carefully by
off-chain tooling, e.g. to make sure a tree has at least 2 leafs.*


```solidity
function claimRewardsStETH(
    uint256 nodeOperatorId,
    uint256 stETHAmount,
    uint256 cumulativeFeeShares,
    bytes32[] calldata rewardsProof
) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`stETHAmount`|`uint256`|Amount of stETH to claim|
|`cumulativeFeeShares`|`uint256`|Cumulative fee stETH shares for the Node Operator|
|`rewardsProof`|`bytes32[]`|Merkle proof of the rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|Amount of stETH shares claimed|


### claimRewardsWstETH

Claim full reward (fee + bond) in wstETH for the given Node Operator available for this moment.
`rewardsProof` and `cumulativeFeeShares` might be empty in order to claim only excess bond

*It's impossible to use single-leaf proof via this method, so this case should be treated carefully by
off-chain tooling, e.g. to make sure a tree has at least 2 leafs.*


```solidity
function claimRewardsWstETH(
    uint256 nodeOperatorId,
    uint256 wstETHAmount,
    uint256 cumulativeFeeShares,
    bytes32[] calldata rewardsProof
) external returns (uint256 claimedWstETHAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`wstETHAmount`|`uint256`|Amount of wstETH to claim|
|`cumulativeFeeShares`|`uint256`|Cumulative fee stETH shares for the Node Operator|
|`rewardsProof`|`bytes32[]`|Merkle proof of the rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`claimedWstETHAmount`|`uint256`|Amount of wstETH claimed|


### claimRewardsUnstETH

Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given Node Operator available for this moment.
`rewardsProof` and `cumulativeFeeShares` might be empty in order to claim only excess bond

*Reverts if amount isn't between `MIN_STETH_WITHDRAWAL_AMOUNT` and `MAX_STETH_WITHDRAWAL_AMOUNT`*

*It's impossible to use single-leaf proof via this method, so this case should be treated carefully by
off-chain tooling, e.g. to make sure a tree has at least 2 leafs.*


```solidity
function claimRewardsUnstETH(
    uint256 nodeOperatorId,
    uint256 stETHAmount,
    uint256 cumulativeFeeShares,
    bytes32[] calldata rewardsProof
) external returns (uint256 requestId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`stETHAmount`|`uint256`|Amount of ETH to request|
|`cumulativeFeeShares`|`uint256`|Cumulative fee stETH shares for the Node Operator|
|`rewardsProof`|`bytes32[]`|Merkle proof of the rewards|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestId`|`uint256`|Withdrawal NFT ID|


### lockBondETH

Lock bond in ETH for the given Node Operator

*Called by CSM exclusively*


```solidity
function lockBondETH(uint256 nodeOperatorId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`amount`|`uint256`|Amount to lock in ETH (stETH)|


### releaseLockedBondETH

Release locked bond in ETH for the given Node Operator

*Called by CSM exclusively*


```solidity
function releaseLockedBondETH(uint256 nodeOperatorId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`amount`|`uint256`|Amount to release in ETH (stETH)|


### settleLockedBondETH

Settle locked bond ETH for the given Node Operator

*Called by CSM exclusively*


```solidity
function settleLockedBondETH(uint256 nodeOperatorId) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### compensateLockedBondETH

Compensate locked bond ETH for the given Node Operator

*Called by CSM exclusively*


```solidity
function compensateLockedBondETH(uint256 nodeOperatorId) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|


### setBondCurve

Set the bond curve for the given Node Operator

*Updates depositable validators count in CSM to ensure key pointers consistency*


```solidity
function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`curveId`|`uint256`|ID of the bond curve to set|


### penalize

Penalize bond by burning stETH shares of the given Node Operator


```solidity
function penalize(uint256 nodeOperatorId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`amount`|`uint256`|Amount to penalize in ETH (stETH)|


### chargeFee

Charge fee from bond by transferring stETH shares of the given Node Operator to the charge recipient


```solidity
function chargeFee(uint256 nodeOperatorId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`amount`|`uint256`|Amount to charge in ETH (stETH)|


### pullFeeRewards

Pull fees from CSFeeDistributor to the Node Operator's bond

*Permissionless method. Can be called before penalty application to ensure that rewards are also penalized*


```solidity
function pullFeeRewards(uint256 nodeOperatorId, uint256 cumulativeFeeShares, bytes32[] calldata rewardsProof)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|
|`cumulativeFeeShares`|`uint256`|Cumulative fee stETH shares for the Node Operator|
|`rewardsProof`|`bytes32[]`|Merkle proof of the rewards|


### renewBurnerAllowance

Service method to update allowance to Burner in case it has changed


```solidity
function renewBurnerAllowance() external;
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
### SenderIsNotModule

```solidity
error SenderIsNotModule();
```

### SenderIsNotEligible

```solidity
error SenderIsNotEligible();
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

### InvalidBondCurvesLength

```solidity
error InvalidBondCurvesLength();
```

## Structs
### PermitInput

```solidity
struct PermitInput {
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}
```

