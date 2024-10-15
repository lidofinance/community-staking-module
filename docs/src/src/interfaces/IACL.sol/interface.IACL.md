# IACL

[Git Source](https://github.com/lidofinance/community-staking-module/blob/ed13582ed87bf90a004e225eef6ca845b31d396d/src/interfaces/IACL.sol)

## Functions

### grantPermission

```solidity
function grantPermission(address _entity, address _app, bytes32 _role) external;
```

### getPermissionManager

```solidity
function getPermissionManager(address _app, bytes32 _role) external view returns (address);
```
