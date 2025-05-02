# VettedGateFactory
[Git Source](https://github.com/lidofinance/community-staking-module/blob/d9f9dfd1023f7776110e7eb983ac3b5174e93893/src/VettedGateFactory.sol)

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
function create(uint256 curveId, bytes32 treeRoot, string calldata treeCid, address admin)
    external
    returns (address instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Id of the bond curve to be assigned for the eligible members|
|`treeRoot`|`bytes32`|Root of the eligible members Merkle Tree|
|`treeCid`|`string`|CID of the eligible members Merkle Tree|
|`admin`|`address`|Address of the admin role|


