# ICSEarlyAdoption

[Git Source](https://github.com/lidofinance/community-staking-module/blob/d66a4396f737199bcc2932e5dd1066d022d333e0/src/interfaces/ICSEarlyAdoption.sol)

## Functions

### CURVE_ID

```solidity
function CURVE_ID() external view returns (uint256);
```

### TREE_ROOT

```solidity
function TREE_ROOT() external view returns (bytes32);
```

### verifyProof

```solidity
function verifyProof(address addr, bytes32[] calldata proof) external view returns (bool);
```

### consume

```solidity
function consume(address sender, bytes32[] calldata proof) external;
```

### isConsumed

```solidity
function isConsumed(address sender) external view returns (bool);
```
