# IACL

[Git Source](https://github.com/lidofinance/community-staking-module/blob/49f6937ff74cffecb74206f771c12be0e9e28448/src/interfaces/IACL.sol)

## Functions

### grantPermission

```solidity
function grantPermission(address _entity, address _app, bytes32 _role) external;
```

### getPermissionManager

```solidity
function getPermissionManager(address _app, bytes32 _role) external view returns (address);
```
