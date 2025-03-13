# VettedGateFactory
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/VettedGateFactory.sol)

**Inherits:**
[IVettedGateFactory](/src/interfaces/IVettedGateFactory.sol/interface.IVettedGateFactory.md)


## State Variables
### VETTED_GATE_IMPL

```solidity
address public immutable VETTED_GATE_IMPL;
```


## Functions
### constructor


```solidity
constructor(address vettedGateImpl);
```

### create

*Creates a new VettedGate instance behind the OssifiableProxy based on known implementation address*


```solidity
function create(uint256 curveId, bytes32 treeRoot, address admin) external returns (address instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Id of the bond curve to be assigned for the eligible members|
|`treeRoot`|`bytes32`|Root of the eligible members Merkle Tree|
|`admin`|`address`|Address of the admin role|


