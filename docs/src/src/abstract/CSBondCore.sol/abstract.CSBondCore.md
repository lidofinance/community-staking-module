# CSBondCore
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/abstract/CSBondCore.sol)

**Inherits:**
[ICSBondCore](/src/interfaces/ICSBondCore.sol/interface.ICSBondCore.md)

**Author:**
vgorkavenko

*Bond core mechanics abstract contract
It gives basic abilities to manage bond shares (stETH) of the Node Operator.
It contains:
- store bond shares (stETH)
- get bond shares (stETH) and bond amount
- deposit ETH/stETH/wstETH
- claim ETH/stETH/wstETH
- burn
Should be inherited by Module contract, or Module-related contract.
Internal non-view methods should be used in Module contract with additional requirements (if any).*


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

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Total bond shares (stETH)|


### getBondShares

Get bond shares (stETH) for the given Node Operator


```solidity
function getBondShares(uint256 nodeOperatorId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Bond in stETH shares|


### getBond

Get bond amount in ETH (stETH) for the given Node Operator


```solidity
function getBond(uint256 nodeOperatorId) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|ID of the Node Operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Bond amount in ETH (stETH)|


### _depositETH

*Stake user's ETH with Lido and stores stETH shares as Node Operator's bond shares*


```solidity
function _depositETH(address from, uint256 nodeOperatorId) internal;
```

### _depositStETH

*Transfer user's stETH to the contract and stores stETH shares as Node Operator's bond shares*


```solidity
function _depositStETH(address from, uint256 nodeOperatorId, uint256 amount) internal;
```

### _depositWstETH

*Transfer user's wstETH to the contract, unwrap and store stETH shares as Node Operator's bond shares*


```solidity
function _depositWstETH(address from, uint256 nodeOperatorId, uint256 amount) internal;
```

### _increaseBond


```solidity
function _increaseBond(uint256 nodeOperatorId, uint256 shares) internal;
```

### _claimUnstETH

*Claim Node Operator's excess bond shares (stETH) in ETH by requesting withdrawal from the protocol
As a usual withdrawal request, this claim might be processed on the next stETH rebase*


```solidity
function _claimUnstETH(uint256 nodeOperatorId, uint256 requestedAmountToClaim, address to)
    internal
    returns (uint256 requestId);
```

### _claimStETH

*Claim Node Operator's excess bond shares (stETH) in stETH by transferring shares from the contract*


```solidity
function _claimStETH(uint256 nodeOperatorId, uint256 requestedAmountToClaim, address to)
    internal
    returns (uint256 sharesToClaim);
```

### _claimWstETH

*Claim Node Operator's excess bond shares (stETH) in wstETH by wrapping stETH from the contract and transferring wstETH*


```solidity
function _claimWstETH(uint256 nodeOperatorId, uint256 requestedAmountToClaim, address to)
    internal
    returns (uint256 wstETHAmount);
```

### _burn

*Burn Node Operator's bond shares (stETH). Shares will be burned on the next stETH rebase*

*The contract that uses this implementation should be granted `Burner.REQUEST_BURN_SHARES_ROLE` and have stETH allowance for `Burner`*


```solidity
function _burn(uint256 nodeOperatorId, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`||
|`amount`|`uint256`|Bond amount to burn in ETH (stETH)|


### _charge

*Transfer Node Operator's bond shares (stETH) to charge recipient*


```solidity
function _charge(uint256 nodeOperatorId, uint256 amount, address recipient) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`||
|`amount`|`uint256`|Bond amount to charge in ETH (stETH)|
|`recipient`|`address`|Address to send charged shares|


### _getClaimableBondShares

*Must be overridden in case of additional restrictions on a claimable bond amount*


```solidity
function _getClaimableBondShares(uint256 nodeOperatorId) internal view virtual returns (uint256);
```

### _sharesByEth

*Shortcut for Lido's getSharesByPooledEth*


```solidity
function _sharesByEth(uint256 ethAmount) internal view returns (uint256);
```

### _ethByShares

*Shortcut for Lido's getPooledEthByShares*


```solidity
function _ethByShares(uint256 shares) internal view returns (uint256);
```

### _unsafeReduceBond

*Unsafe reduce bond shares (stETH) (possible underflow). Safety checks should be done outside*


```solidity
function _unsafeReduceBond(uint256 nodeOperatorId, uint256 shares) private;
```

### _reduceBond

*Safe reduce bond shares (stETH). The maximum shares to reduce is the current bond shares*


```solidity
function _reduceBond(uint256 nodeOperatorId, uint256 shares) private returns (uint256 reducedShares);
```

### _getCSBondCoreStorage


```solidity
function _getCSBondCoreStorage() private pure returns (CSBondCoreStorage storage $);
```

## Structs
### CSBondCoreStorage
**Note:**
storage-location: erc7201:CSBondCore


```solidity
struct CSBondCoreStorage {
    mapping(uint256 nodeOperatorId => uint256 shares) bondShares;
    uint256 totalBondShares;
}
```

