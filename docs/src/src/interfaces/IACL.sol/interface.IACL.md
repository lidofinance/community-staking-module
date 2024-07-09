# IACL

[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/interfaces/IACL.sol)

## Functions

### grantPermission

```solidity
function grantPermission(address _entity, address _app, bytes32 _role) external;
```

### getPermissionManager

```solidity
function getPermissionManager(address _app, bytes32 _role) external view returns (address);
```
