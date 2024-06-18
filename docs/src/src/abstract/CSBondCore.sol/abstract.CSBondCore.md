# CSBondCore

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/abstract/CSBondCore.sol)

**Inherits:**
[ICSBondCore](/src/interfaces/ICSBondCore.sol/interface.ICSBondCore.md)

**Author:**
vgorkavenko

\*Bond core mechanics abstract contract
It gives basic abilities to manage bond shares (stETH) of the Node Operator.
It contains:

- store bond shares (stETH)
- get bond shares (stETH) and bond amount
- deposit ETH/stETH/wstETH
- claim ETH/stETH/wstETH
- burn
  Should be inherited by Module contract, or Module-related contract.
  Internal non-view methods should be used in Module contract with additional requirements (if any).\*

## State Variables

### LIDO_LOCATOR

```solidity
ILidoLocator public immutable LIDO_LOCATOR;
```

### LIDO

```solidity
ILido public immutable LIDO;
```

### WITHDRAWAL_QUEUE

```solidity
IWithdrawalQueue public immutable WITHDRAWAL_QUEUE;
```

### WSTETH

```solidity
IWstETH public immutable WSTETH;
```

### CS_BOND_CORE_STORAGE_LOCATION

```solidity
bytes32 private constant CS_BOND_CORE_STORAGE_LOCATION =
    0x23f334b9eb5378c2a1573857b8f9d9ca79959360a69e73d3f16848e56ec92100;
```

## Functions

### constructor

```solidity
constructor(address lidoLocator);
```

### totalBondShares

Get total bond shares (stETH) stored on the contract

```solidity
function totalBondShares() public view returns (uint256);
```

**Returns**

| Name     | Type      | Description               |
| -------- | --------- | ------------------------- |
| `<none>` | `uint256` | Total bond shares (stETH) |

### getBondShares

Get bond shares (stETH) for the given Node Operator

```solidity
function getBondShares(uint256 nodeOperatorId) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description          |
| -------- | --------- | -------------------- |
| `<none>` | `uint256` | Bond in stETH shares |

### getBond

Get bond amount in ETH (stETH) for the given Node Operator

```solidity
function getBond(uint256 nodeOperatorId) public view returns (uint256);
```

**Parameters**

| Name             | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `nodeOperatorId` | `uint256` | ID of the Node Operator |

**Returns**

| Name     | Type      | Description                |
| -------- | --------- | -------------------------- |
| `<none>` | `uint256` | Bond amount in ETH (stETH) |

### \_depositETH

_Stake user's ETH with Lido and stores stETH shares as Node Operator's bond shares_

```solidity
function _depositETH(address from, uint256 nodeOperatorId) internal;
```

### \_depositStETH

_Transfer user's stETH to the contract and stores stETH shares as Node Operator's bond shares_

```solidity
function _depositStETH(address from, uint256 nodeOperatorId, uint256 amount) internal;
```

### \_depositWstETH

_Transfer user's wstETH to the contract, unwrap and store stETH shares as Node Operator's bond shares_

```solidity
function _depositWstETH(address from, uint256 nodeOperatorId, uint256 amount) internal;
```

### \_increaseBond

```solidity
function _increaseBond(uint256 nodeOperatorId, uint256 shares) internal;
```

### \_claimUnstETH

_Claim Node Operator's excess bond shares (stETH) in ETH by requesting withdrawal from the protocol
As a usual withdrawal request, this claim might be processed on the next stETH rebase_

```solidity
function _claimUnstETH(uint256 nodeOperatorId, uint256 amountToClaim, address to) internal;
```

### \_claimStETH

_Claim Node Operator's excess bond shares (stETH) in stETH by transferring shares from the contract_

```solidity
function _claimStETH(uint256 nodeOperatorId, uint256 amountToClaim, address to) internal;
```

### \_claimWstETH

_Claim Node Operator's excess bond shares (stETH) in wstETH by wrapping stETH from the contract and transferring wstETH_

```solidity
function _claimWstETH(uint256 nodeOperatorId, uint256 amountToClaim, address to) internal;
```

### \_burn

_Burn Node Operator's bond shares (stETH). Shares will be burned on the next stETH rebase_

_The method sender should be granted as `Burner.REQUEST_BURN_SHARES_ROLE` and make stETH allowance for `Burner`_

```solidity
function _burn(uint256 nodeOperatorId, uint256 amount) internal;
```

**Parameters**

| Name             | Type      | Description                        |
| ---------------- | --------- | ---------------------------------- |
| `nodeOperatorId` | `uint256` |                                    |
| `amount`         | `uint256` | Bond amount to burn in ETH (stETH) |

### \_charge

_Transfer Node Operator's bond shares (stETH) to charge recipient to pay some fee_

```solidity
function _charge(uint256 nodeOperatorId, uint256 amount, address recipient) internal;
```

**Parameters**

| Name             | Type      | Description                          |
| ---------------- | --------- | ------------------------------------ |
| `nodeOperatorId` | `uint256` |                                      |
| `amount`         | `uint256` | Bond amount to charge in ETH (stETH) |
| `recipient`      | `address` |                                      |

### \_getClaimableBondShares

_Must be overridden in case of additional restrictions on a claimable bond amount_

```solidity
function _getClaimableBondShares(uint256 nodeOperatorId) internal view virtual returns (uint256);
```

### \_sharesByEth

_Shortcut for Lido's getSharesByPooledEth_

```solidity
function _sharesByEth(uint256 ethAmount) internal view returns (uint256);
```

### \_ethByShares

_Shortcut for Lido's getPooledEthByShares_

```solidity
function _ethByShares(uint256 shares) internal view returns (uint256);
```

### \_unsafeReduceBond

_Unsafe reduce bond shares (stETH) (possible underflow). Safety checks should be done outside_

```solidity
function _unsafeReduceBond(uint256 nodeOperatorId, uint256 shares) private;
```

### \_reduceBond

_Safe reduce bond shares (stETH). The maximum shares to reduce is the current bond shares_

```solidity
function _reduceBond(
  uint256 nodeOperatorId,
  uint256 shares
) private returns (uint256 reducedShares);
```

### \_getCSBondCoreStorage

```solidity
function _getCSBondCoreStorage() private pure returns (CSBondCoreStorage storage $);
```

## Events

### BondDepositedETH

```solidity
event BondDepositedETH(uint256 indexed nodeOperatorId, address from, uint256 amount);
```

### BondClaimedUnstETH

```solidity
event BondClaimedUnstETH(
  uint256 indexed nodeOperatorId,
  address to,
  uint256 amount,
  uint256 requestId
);
```

### BondDepositedWstETH

```solidity
event BondDepositedWstETH(uint256 indexed nodeOperatorId, address from, uint256 amount);
```

### BondClaimedWstETH

```solidity
event BondClaimedWstETH(uint256 indexed nodeOperatorId, address to, uint256 amount);
```

### BondDepositedStETH

```solidity
event BondDepositedStETH(uint256 indexed nodeOperatorId, address from, uint256 amount);
```

### BondClaimedStETH

```solidity
event BondClaimedStETH(uint256 indexed nodeOperatorId, address to, uint256 amount);
```

### BondBurned

```solidity
event BondBurned(uint256 indexed nodeOperatorId, uint256 toBurnAmount, uint256 burnedAmount);
```

### BondCharged

```solidity
event BondCharged(uint256 indexed nodeOperatorId, uint256 toChargeAmount, uint256 chargedAmount);
```

## Errors

### ZeroLocatorAddress

```solidity
error ZeroLocatorAddress();
```

## Structs

### CSBondCoreStorage

```solidity
struct CSBondCoreStorage {
  mapping(uint256 nodeOperatorId => uint256 shares) bondShares;
  uint256 totalBondShares;
}
```
