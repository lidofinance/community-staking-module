# IACL

[Git Source](https://github.com/lidofinance/community-staking-module/blob/5d5ee8e87614e268bb3181747a86b3f5fe7a75e2/src/interfaces/IACL.sol)

## Functions

### grantPermission

```solidity
function grantPermission(address _entity, address _app, bytes32 _role) external;
```

### getPermissionManager

```solidity
function getPermissionManager(address _app, bytes32 _role) external view returns (address);
```
