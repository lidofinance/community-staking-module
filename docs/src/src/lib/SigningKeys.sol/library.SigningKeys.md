# SigningKeys
[Git Source](https://github.com/lidofinance/community-staking-module/blob/ef5c94eed5211bf6c350512cf569895da670f26c/src/lib/SigningKeys.sol)

**Author:**
KRogLA


## State Variables
### SIGNING_KEYS_POSITION

```solidity
bytes32 internal constant SIGNING_KEYS_POSITION = keccak256("lido.CommunityStakingModule.signingKeysPosition");
```


### PUBKEY_LENGTH

```solidity
uint64 internal constant PUBKEY_LENGTH = 48;
```


### SIGNATURE_LENGTH

```solidity
uint64 internal constant SIGNATURE_LENGTH = 96;
```


### UINT32_MAX

```solidity
uint256 internal constant UINT32_MAX = type(uint32).max;
```


## Functions
### saveKeysSigs

*store operator keys to storage*


```solidity
function saveKeysSigs(
    uint256 nodeOperatorId,
    uint256 startIndex,
    uint256 keysCount,
    bytes memory pubkeys,
    bytes memory signatures
) internal returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|operator id|
|`startIndex`|`uint256`|start index|
|`keysCount`|`uint256`|keys count to load|
|`pubkeys`|`bytes`|keys buffer to read from|
|`signatures`|`bytes`|signatures buffer to read from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|new total keys count|


### removeKeysSigs

*remove operator keys from storage*


```solidity
function removeKeysSigs(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount, uint256 totalKeysCount)
    internal
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|operator id|
|`startIndex`|`uint256`|start index|
|`keysCount`|`uint256`|keys count to load|
|`totalKeysCount`|`uint256`|current total keys count for operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|new total keys count|


### loadKeysSigs

*load operator keys and signatures from storage*


```solidity
function loadKeysSigs(
    uint256 nodeOperatorId,
    uint256 startIndex,
    uint256 keysCount,
    bytes memory pubkeys,
    bytes memory signatures,
    uint256 bufOffset
) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nodeOperatorId`|`uint256`|operator id|
|`startIndex`|`uint256`|start index|
|`keysCount`|`uint256`|keys count to load|
|`pubkeys`|`bytes`|preallocated kes buffer to read in|
|`signatures`|`bytes`|preallocated signatures buffer to read in|
|`bufOffset`|`uint256`|start offset in `_pubkeys`/`_signatures` buffer to place values (in number of keys)|


### loadKeys


```solidity
function loadKeys(uint256 nodeOperatorId, uint256 startIndex, uint256 keysCount)
    internal
    view
    returns (bytes memory pubkeys);
```

### initKeysSigsBuf


```solidity
function initKeysSigsBuf(uint256 count) internal pure returns (bytes memory, bytes memory);
```

### getKeyOffset


```solidity
function getKeyOffset(bytes32 position, uint256 nodeOperatorId, uint256 keyIndex) internal pure returns (uint256);
```

## Events
### SigningKeyAdded

```solidity
event SigningKeyAdded(uint256 indexed nodeOperatorId, bytes pubkey);
```

### SigningKeyRemoved

```solidity
event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);
```

## Errors
### InvalidKeysCount

```solidity
error InvalidKeysCount();
```

### InvalidLength

```solidity
error InvalidLength();
```

### EmptyKey

```solidity
error EmptyKey();
```

