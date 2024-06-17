# ICSAccounting

[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/interfaces/ICSAccounting.sol)

**Inherits:**
[ICSBondCore](/src/interfaces/ICSBondCore.sol/interface.ICSBondCore.md), [ICSBondCurve](/src/interfaces/ICSBondCurve.sol/interface.ICSBondCurve.md), [ICSBondLock](/src/interfaces/ICSBondLock.sol/interface.ICSBondLock.md)

## Functions

### feeDistributor

```solidity
function feeDistributor() external view returns (ICSFeeDistributor);
```

### chargeRecipient

```solidity
function chargeRecipient() external view returns (address);
```

### getRequiredBondForNextKeys

```solidity
function getRequiredBondForNextKeys(
  uint256 nodeOperatorId,
  uint256 additionalKeys
) external view returns (uint256);
```

### getBondAmountByKeysCountWstETH

```solidity
function getBondAmountByKeysCountWstETH(
  uint256 keysCount,
  uint256 curveId
) external view returns (uint256);
```

### getBondAmountByKeysCountWstETH

```solidity
function getBondAmountByKeysCountWstETH(
  uint256 keysCount,
  BondCurve memory curve
) external view returns (uint256);
```

### getRequiredBondForNextKeysWstETH

```solidity
function getRequiredBondForNextKeysWstETH(
  uint256 nodeOperatorId,
  uint256 additionalKeys
) external view returns (uint256);
```

### getUnbondedKeysCount

```solidity
function getUnbondedKeysCount(uint256 nodeOperatorId) external view returns (uint256);
```

### getUnbondedKeysCountToEject

```solidity
function getUnbondedKeysCountToEject(uint256 nodeOperatorId) external view returns (uint256);
```

### depositWstETH

```solidity
function depositWstETH(
  address from,
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  PermitInput calldata permit
) external;
```

### depositStETH

```solidity
function depositStETH(
  address from,
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  PermitInput calldata permit
) external;
```

### depositETH

```solidity
function depositETH(address from, uint256 nodeOperatorId) external payable;
```

### claimRewardsStETH

```solidity
function claimRewardsStETH(
  uint256 nodeOperatorId,
  uint256 stETHAmount,
  address rewardAddress,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

### claimRewardsWstETH

```solidity
function claimRewardsWstETH(
  uint256 nodeOperatorId,
  uint256 wstETHAmount,
  address rewardAddress,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

### claimRewardsUnstETH

```solidity
function claimRewardsUnstETH(
  uint256 nodeOperatorId,
  uint256 stEthAmount,
  address rewardAddress,
  uint256 cumulativeFeeShares,
  bytes32[] calldata rewardsProof
) external;
```

### lockBondETH

```solidity
function lockBondETH(uint256 nodeOperatorId, uint256 amount) external;
```

### releaseLockedBondETH

```solidity
function releaseLockedBondETH(uint256 nodeOperatorId, uint256 amount) external;
```

### settleLockedBondETH

```solidity
function settleLockedBondETH(uint256 nodeOperatorId) external returns (uint256);
```

### compensateLockedBondETH

```solidity
function compensateLockedBondETH(uint256 nodeOperatorId) external payable;
```

### setBondCurve

```solidity
function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external;
```

### resetBondCurve

```solidity
function resetBondCurve(uint256 nodeOperatorId) external;
```

### penalize

```solidity
function penalize(uint256 nodeOperatorId, uint256 amount) external;
```

### chargeFee

```solidity
function chargeFee(uint256 nodeOperatorId, uint256 amount) external;
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
