# IACL

[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/interfaces/IACL.sol)

## Functions

### grantPermission

```solidity
function grantPermission(address _entity, address _app, bytes32 _role) external;
```

### getPermissionManager

```solidity
function getPermissionManager(address _app, bytes32 _role) external view returns (address);
```
