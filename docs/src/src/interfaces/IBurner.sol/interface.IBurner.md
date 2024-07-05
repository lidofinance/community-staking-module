# IBurner

[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/interfaces/IBurner.sol)

## Functions

### REQUEST_BURN_SHARES_ROLE

```solidity
function REQUEST_BURN_SHARES_ROLE() external view returns (bytes32);
```

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
```

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address);
```

### grantRole

```solidity
function grantRole(bytes32 role, address account) external;
```

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool);
```

### requestBurnShares

```solidity
function requestBurnShares(address _from, uint256 _sharesAmountToBurn) external;
```
