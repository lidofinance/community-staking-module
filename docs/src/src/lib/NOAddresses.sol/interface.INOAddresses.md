# INOAddresses
[Git Source](https://github.com/lidofinance/community-staking-module/blob/8ce9441dce1001c93d75d065f051013ad5908976/src/lib/NOAddresses.sol)

Library for changing and reset node operator's manager and reward addresses

*the only use of this to be a library is to save CSModule contract size via delegatecalls*


## Events
### NodeOperatorManagerAddressChangeProposed

```solidity
event NodeOperatorManagerAddressChangeProposed(
    uint256 indexed nodeOperatorId, address indexed oldProposedAddress, address indexed newProposedAddress
);
```

### NodeOperatorRewardAddressChangeProposed

```solidity
event NodeOperatorRewardAddressChangeProposed(
    uint256 indexed nodeOperatorId, address indexed oldProposedAddress, address indexed newProposedAddress
);
```

### NodeOperatorManagerAddressChanged

```solidity
event NodeOperatorManagerAddressChanged(
    uint256 indexed nodeOperatorId, address indexed oldAddress, address indexed newAddress
);
```

### NodeOperatorRewardAddressChanged

```solidity
event NodeOperatorRewardAddressChanged(
    uint256 indexed nodeOperatorId, address indexed oldAddress, address indexed newAddress
);
```

## Errors
### AlreadyProposed

```solidity
error AlreadyProposed();
```

### SameAddress

```solidity
error SameAddress();
```

### SenderIsNotManagerAddress

```solidity
error SenderIsNotManagerAddress();
```

### SenderIsNotRewardAddress

```solidity
error SenderIsNotRewardAddress();
```

### SenderIsNotProposedAddress

```solidity
error SenderIsNotProposedAddress();
```

### MethodCallIsNotAllowed

```solidity
error MethodCallIsNotAllowed();
```

