# SigningKeys
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/lib/SigningKeys.sol)

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


## Functions
### saveKeysSigs

*store operator keys to storage*


```solidity
function saveKeysSigs(
    uint256 nodeOperatorId,
    uint256 startIndex,
    uint256 keysCount,
    bytes calldata pubkeys,
    bytes calldata signatures
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

*Load operator's keys and signatures from the storage to the given in-memory arrays.*

*The function doesn't check for `pubkeys` and `signatures` out of boundaries access.*


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
|`bufOffset`|`uint256`|start offset in `pubkeys`/`signatures` buffer to place values (in number of keys)|


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

