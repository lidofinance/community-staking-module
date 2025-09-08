# ICSParametersRegistry
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ICSParametersRegistry.sol)


## Functions
### QUEUE_LOWEST_PRIORITY

The lowest priority a deposit queue can be assigned with.


```solidity
function QUEUE_LOWEST_PRIORITY() external view returns (uint256);
```

### QUEUE_LEGACY_PRIORITY

The priority reserved to be used for legacy queue only.


```solidity
function QUEUE_LEGACY_PRIORITY() external view returns (uint256);
```

### setDefaultKeyRemovalCharge

Set default value for the key removal charge. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keyRemovalCharge`|`uint256`|value to be set as default for the key removal charge|


### defaultKeyRemovalCharge

Get default value for the key removal charge


```solidity
function defaultKeyRemovalCharge() external returns (uint256);
```

### setDefaultElRewardsStealingAdditionalFine

Set default value for the EL rewards stealing additional fine. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultElRewardsStealingAdditionalFine(uint256 fine) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fine`|`uint256`|value to be set as default for the EL rewards stealing additional fine|


### defaultElRewardsStealingAdditionalFine

Get default value for the EL rewards stealing additional fine


```solidity
function defaultElRewardsStealingAdditionalFine() external returns (uint256);
```

### setDefaultKeysLimit

Set default value for the keys limit. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultKeysLimit(uint256 limit) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`limit`|`uint256`|value to be set as default for the keys limit|


### defaultKeysLimit

Get default value for the key removal charge


```solidity
function defaultKeysLimit() external returns (uint256);
```

### setDefaultRewardShare

Set default value for the reward share. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultRewardShare(uint256 share) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`share`|`uint256`|value to be set as default for the reward share|


### defaultRewardShare

Get default value for the reward share


```solidity
function defaultRewardShare() external returns (uint256);
```

### setDefaultPerformanceLeeway

Set default value for the performance leeway. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultPerformanceLeeway(uint256 leeway) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`leeway`|`uint256`|value to be set as default for the performance leeway|


### defaultPerformanceLeeway

Get default value for the performance leeway


```solidity
function defaultPerformanceLeeway() external returns (uint256);
```

### setDefaultStrikesParams

Set default values for the strikes lifetime and threshold. Default values are used if specific values are not set for the curveId


```solidity
function setDefaultStrikesParams(uint256 lifetime, uint256 threshold) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lifetime`|`uint256`|The default number of CSM Performance Oracle frames to store strikes values|
|`threshold`|`uint256`|The default strikes value leading to validator force ejection.|


### defaultStrikesParams

Get default value for the strikes lifetime (frames count) and threshold (integer)


```solidity
function defaultStrikesParams() external returns (uint32, uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|lifetime The default number of CSM Performance Oracle frames to store strikes values|
|`<none>`|`uint32`|threshold The default strikes value leading to validator force ejection.|


### setDefaultBadPerformancePenalty

Set default value for the bad performance penalty. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultBadPerformancePenalty(uint256 penalty) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`penalty`|`uint256`|value to be set as default for the bad performance penalty|


### defaultBadPerformancePenalty

Get default value for the bad performance penalty


```solidity
function defaultBadPerformancePenalty() external returns (uint256);
```

### setDefaultPerformanceCoefficients

Set default values for the performance coefficients. Default values are used if specific values are not set for the curveId


```solidity
function setDefaultPerformanceCoefficients(uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attestationsWeight`|`uint256`|value to be set as default for the attestations effectiveness weight|
|`blocksWeight`|`uint256`|value to be set as default for block proposals effectiveness weight|
|`syncWeight`|`uint256`|value to be set as default for sync participation effectiveness weight|


### defaultPerformanceCoefficients

Get default value for the performance coefficients


```solidity
function defaultPerformanceCoefficients() external returns (uint32, uint32, uint32);
```

### setDefaultAllowedExitDelay

set default value for allowed delay before the exit was initiated exit delay in seconds. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultAllowedExitDelay(uint256 delay) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delay`|`uint256`|value to be set as default for the allowed exit delay|


### setDefaultExitDelayPenalty

set default value for exit delay penalty. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultExitDelayPenalty(uint256 penalty) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`penalty`|`uint256`|value to be set as default for the exit delay penalty|


### setDefaultMaxWithdrawalRequestFee

set default value for max withdrawal request fee. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultMaxWithdrawalRequestFee(uint256 fee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|value to be set as default for the max withdrawal request fee|


### defaultAllowedExitDelay

Get default value for the allowed exit delay


```solidity
function defaultAllowedExitDelay() external returns (uint256);
```

### setKeyRemovalCharge

Set key removal charge for the curveId.


```solidity
function setKeyRemovalCharge(uint256 curveId, uint256 keyRemovalCharge) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate key removal charge with|
|`keyRemovalCharge`|`uint256`|Key removal charge|


### unsetKeyRemovalCharge

Unset key removal charge for the curveId


```solidity
function unsetKeyRemovalCharge(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom key removal charge for|


### getKeyRemovalCharge

Get key removal charge by the curveId. A charge is taken from the bond for each removed key from CSM

*`defaultKeyRemovalCharge` is returned if the value is not set for the given curveId.*


```solidity
function getKeyRemovalCharge(uint256 curveId) external view returns (uint256 keyRemovalCharge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get key removal charge for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`keyRemovalCharge`|`uint256`|Key removal charge|


### setElRewardsStealingAdditionalFine

Set EL rewards stealing additional fine for the curveId.


```solidity
function setElRewardsStealingAdditionalFine(uint256 curveId, uint256 fine) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate EL rewards stealing additional fine limit with|
|`fine`|`uint256`|EL rewards stealing additional fine|


### unsetElRewardsStealingAdditionalFine

Unset EL rewards stealing additional fine for the curveId


```solidity
function unsetElRewardsStealingAdditionalFine(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom EL rewards stealing additional fine for|


### getElRewardsStealingAdditionalFine

Get EL rewards stealing additional fine by the curveId. Additional fine is added to the EL rewards stealing penalty by CSM

*`defaultElRewardsStealingAdditionalFine` is returned if the value is not set for the given curveId.*


```solidity
function getElRewardsStealingAdditionalFine(uint256 curveId) external view returns (uint256 fine);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get EL rewards stealing additional fine for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fine`|`uint256`|EL rewards stealing additional fine|


### setKeysLimit

Set keys limit for the curveId.


```solidity
function setKeysLimit(uint256 curveId, uint256 limit) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate keys limit with|
|`limit`|`uint256`|Keys limit|


### unsetKeysLimit

Unset key removal charge for the curveId


```solidity
function unsetKeysLimit(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom key removal charge for|


### getKeysLimit

Get keys limit by the curveId. A limit indicates the maximal amount of the non-exited keys Node Operator can upload

*`defaultKeysLimit` is returned if the value is not set for the given curveId.*


```solidity
function getKeysLimit(uint256 curveId) external view returns (uint256 limit);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get keys limit for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`limit`|`uint256`|Keys limit|


### setRewardShareData

Set reward share parameters for the curveId

*KeyNumberValueInterval = [[1, 10000], [11, 8000], [51, 5000]] stands for
100% rewards for the first 10 keys, 80% rewards for the keys 11-50, and 50% rewards for the keys > 50*


```solidity
function setRewardShareData(uint256 curveId, KeyNumberValueInterval[] calldata data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate reward share data with|
|`data`|`KeyNumberValueInterval[]`|Interval values for keys count and reward share percentages in BP (ex. [[1, 10000], [11, 8000], [51, 5000]])|


### unsetRewardShareData

Unset reward share parameters for the curveId


```solidity
function unsetRewardShareData(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom reward share parameters for|


### getRewardShareData

Get reward share parameters by the curveId.

*Returns [[1, defaultRewardShare]] if no intervals are set for the given curveId.*

*KeyNumberValueInterval = [[1, 10000], [11, 8000], [51, 5000]] stands for
100% rewards for the first 10 keys, 80% rewards for the keys 11-50, and 50% rewards for the keys > 50*


```solidity
function getRewardShareData(uint256 curveId) external view returns (KeyNumberValueInterval[] memory data);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get reward share data for|


### setDefaultQueueConfig

Set default value for QueueConfig. Default value is used if a specific value is not set for the curveId.


```solidity
function setDefaultQueueConfig(uint256 priority, uint256 maxDeposits) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`priority`|`uint256`|Queue priority.|
|`maxDeposits`|`uint256`|Maximum number of deposits a Node Operator can get via the priority queue.|


### setQueueConfig

Sets the provided config to the given curve.


```solidity
function setQueueConfig(uint256 curveId, uint256 priority, uint256 maxDeposits) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to set the config.|
|`priority`|`uint256`|Priority of the queue|
|`maxDeposits`|`uint256`|Max deposits in prioritized queue|


### unsetQueueConfig

Set the given curve's config to the default one.


```solidity
function unsetQueueConfig(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom config.|


### getQueueConfig

Get the queue config for the given curve.


```solidity
function getQueueConfig(uint256 curveId) external view returns (uint32 priority, uint32 maxDeposits);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get the queue config for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`priority`|`uint32`|Queue priority.|
|`maxDeposits`|`uint32`|Maximum number of deposits a Node Operator can get via the priority queue.|


### setPerformanceLeewayData

Set performance leeway parameters for the curveId

*Returns [[1, defaultPerformanceLeeway]] if no intervals are set for the given curveId.*

*KeyNumberValueInterval = [[1, 500], [101, 450], [501, 400]] stands for
5% performance leeway for the first 100 keys, 4.5% performance leeway for the keys 101-500, and 4% performance leeway for the keys > 500*


```solidity
function setPerformanceLeewayData(uint256 curveId, KeyNumberValueInterval[] calldata data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate performance leeway data with|
|`data`|`KeyNumberValueInterval[]`|Interval values for keys count and performance leeway percentages in BP (ex. [[1, 500], [101, 450], [501, 400]])|


### unsetPerformanceLeewayData

Unset performance leeway parameters for the curveId


```solidity
function unsetPerformanceLeewayData(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom performance leeway parameters for|


### getPerformanceLeewayData

Get performance leeway parameters by the curveId

*Returns [[1, defaultPerformanceLeeway]] if no intervals are set for the given curveId.*

*KeyNumberValueInterval = [[1, 500], [101, 450], [501, 400]] stands for
5% performance leeway for the first 100 keys, 4.5% performance leeway for the keys 101-500, and 4% performance leeway for the keys > 500*


```solidity
function getPerformanceLeewayData(uint256 curveId) external view returns (KeyNumberValueInterval[] memory data);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get performance leeway data for|


### setStrikesParams

Set performance strikes lifetime and threshold for the curveId


```solidity
function setStrikesParams(uint256 curveId, uint256 lifetime, uint256 threshold) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate performance strikes lifetime and threshold with|
|`lifetime`|`uint256`|Number of CSM Performance Oracle frames to store strikes values|
|`threshold`|`uint256`|The strikes value leading to validator force ejection|


### unsetStrikesParams

Unset custom performance strikes lifetime and threshold for the curveId


```solidity
function unsetStrikesParams(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom performance strikes lifetime and threshold for|


### getStrikesParams

Get performance strikes lifetime and threshold by the curveId

*`defaultStrikesParams` are returned if the value is not set for the given curveId*


```solidity
function getStrikesParams(uint256 curveId) external view returns (uint256 lifetime, uint256 threshold);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get performance strikes lifetime and threshold for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lifetime`|`uint256`|Number of CSM Performance Oracle frames to store strikes values|
|`threshold`|`uint256`|The strikes value leading to validator force ejection|


### setBadPerformancePenalty

Set bad performance penalty for the curveId


```solidity
function setBadPerformancePenalty(uint256 curveId, uint256 penalty) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate bad performance penalty with|
|`penalty`|`uint256`|Bad performance penalty|


### unsetBadPerformancePenalty

Unset bad performance penalty for the curveId


```solidity
function unsetBadPerformancePenalty(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom bad performance penalty for|


### getBadPerformancePenalty

Get bad performance penalty by the curveId

*`defaultBadPerformancePenalty` is returned if the value is not set for the given curveId.*


```solidity
function getBadPerformancePenalty(uint256 curveId) external view returns (uint256 penalty);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get bad performance penalty for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`penalty`|`uint256`|Bad performance penalty|


### setPerformanceCoefficients

Set performance coefficients for the curveId


```solidity
function setPerformanceCoefficients(
    uint256 curveId,
    uint256 attestationsWeight,
    uint256 blocksWeight,
    uint256 syncWeight
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate performance coefficients with|
|`attestationsWeight`|`uint256`|Attestations effectiveness weight|
|`blocksWeight`|`uint256`|Block proposals effectiveness weight|
|`syncWeight`|`uint256`|Sync participation effectiveness weight|


### unsetPerformanceCoefficients

Unset custom performance coefficients for the curveId


```solidity
function unsetPerformanceCoefficients(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom performance coefficients for|


### getPerformanceCoefficients

Get performance coefficients by the curveId

*`defaultPerformanceCoefficients` are returned if the value is not set for the given curveId.*


```solidity
function getPerformanceCoefficients(uint256 curveId)
    external
    view
    returns (uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get performance coefficients for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`attestationsWeight`|`uint256`|Attestations effectiveness weight|
|`blocksWeight`|`uint256`|Block proposals effectiveness weight|
|`syncWeight`|`uint256`|Sync participation effectiveness weight|


### setAllowedExitDelay

Set allowed exit delay for the curveId in seconds


```solidity
function setAllowedExitDelay(uint256 curveId, uint256 delay) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate allowed exit delay with|
|`delay`|`uint256`|allowed exit delay|


### unsetAllowedExitDelay

Unset exit timeframe deadline delay for the curveId


```solidity
function unsetAllowedExitDelay(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset allowed exit delay for|


### getAllowedExitDelay

Get allowed exit delay by the curveId in seconds

*`defaultAllowedExitDelay` is returned if the value is not set for the given curveId.*


```solidity
function getAllowedExitDelay(uint256 curveId) external view returns (uint256 delay);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get allowed exit delay for|


### setExitDelayPenalty

Set exit delay penalty for the curveId

*cannot be zero*


```solidity
function setExitDelayPenalty(uint256 curveId, uint256 penalty) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate exit delay penalty with|
|`penalty`|`uint256`|exit delay penalty|


### unsetExitDelayPenalty

Unset exit delay penalty for the curveId


```solidity
function unsetExitDelayPenalty(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset exit delay penalty for|


### getExitDelayPenalty

Get exit delay penalty by the curveId

*`defaultExitDelayPenalty` is returned if the value is not set for the given curveId.*


```solidity
function getExitDelayPenalty(uint256 curveId) external view returns (uint256 penalty);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get exit delay penalty for|


### setMaxWithdrawalRequestFee

Set max withdrawal request fee for the curveId


```solidity
function setMaxWithdrawalRequestFee(uint256 curveId, uint256 fee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate max withdrawal request fee with|
|`fee`|`uint256`|max withdrawal request fee|


### unsetMaxWithdrawalRequestFee

Unset max withdrawal request fee for the curveId


```solidity
function unsetMaxWithdrawalRequestFee(uint256 curveId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset max withdrawal request fee for|


### getMaxWithdrawalRequestFee

Get max withdrawal request fee by the curveId

*`defaultMaxWithdrawalRequestFee` is returned if the value is not set for the given curveId.*


```solidity
function getMaxWithdrawalRequestFee(uint256 curveId) external view returns (uint256 fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get max withdrawal request fee for|


### getInitializedVersion

Returns the initialized version of the contract


```solidity
function getInitializedVersion() external view returns (uint64);
```

## Events
### DefaultKeyRemovalChargeSet

```solidity
event DefaultKeyRemovalChargeSet(uint256 value);
```

### DefaultElRewardsStealingAdditionalFineSet

```solidity
event DefaultElRewardsStealingAdditionalFineSet(uint256 value);
```

### DefaultKeysLimitSet

```solidity
event DefaultKeysLimitSet(uint256 value);
```

### DefaultRewardShareSet

```solidity
event DefaultRewardShareSet(uint256 value);
```

### DefaultPerformanceLeewaySet

```solidity
event DefaultPerformanceLeewaySet(uint256 value);
```

### DefaultStrikesParamsSet

```solidity
event DefaultStrikesParamsSet(uint256 lifetime, uint256 threshold);
```

### DefaultBadPerformancePenaltySet

```solidity
event DefaultBadPerformancePenaltySet(uint256 value);
```

### DefaultPerformanceCoefficientsSet

```solidity
event DefaultPerformanceCoefficientsSet(uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight);
```

### DefaultQueueConfigSet

```solidity
event DefaultQueueConfigSet(uint256 priority, uint256 maxDeposits);
```

### DefaultAllowedExitDelaySet

```solidity
event DefaultAllowedExitDelaySet(uint256 delay);
```

### DefaultExitDelayPenaltySet

```solidity
event DefaultExitDelayPenaltySet(uint256 penalty);
```

### DefaultMaxWithdrawalRequestFeeSet

```solidity
event DefaultMaxWithdrawalRequestFeeSet(uint256 fee);
```

### KeyRemovalChargeSet

```solidity
event KeyRemovalChargeSet(uint256 indexed curveId, uint256 keyRemovalCharge);
```

### ElRewardsStealingAdditionalFineSet

```solidity
event ElRewardsStealingAdditionalFineSet(uint256 indexed curveId, uint256 fine);
```

### KeysLimitSet

```solidity
event KeysLimitSet(uint256 indexed curveId, uint256 limit);
```

### RewardShareDataSet

```solidity
event RewardShareDataSet(uint256 indexed curveId, KeyNumberValueInterval[] data);
```

### PerformanceLeewayDataSet

```solidity
event PerformanceLeewayDataSet(uint256 indexed curveId, KeyNumberValueInterval[] data);
```

### StrikesParamsSet

```solidity
event StrikesParamsSet(uint256 indexed curveId, uint256 lifetime, uint256 threshold);
```

### BadPerformancePenaltySet

```solidity
event BadPerformancePenaltySet(uint256 indexed curveId, uint256 penalty);
```

### PerformanceCoefficientsSet

```solidity
event PerformanceCoefficientsSet(
    uint256 indexed curveId, uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight
);
```

### KeyRemovalChargeUnset

```solidity
event KeyRemovalChargeUnset(uint256 indexed curveId);
```

### ElRewardsStealingAdditionalFineUnset

```solidity
event ElRewardsStealingAdditionalFineUnset(uint256 indexed curveId);
```

### KeysLimitUnset

```solidity
event KeysLimitUnset(uint256 indexed curveId);
```

### RewardShareDataUnset

```solidity
event RewardShareDataUnset(uint256 indexed curveId);
```

### PerformanceLeewayDataUnset

```solidity
event PerformanceLeewayDataUnset(uint256 indexed curveId);
```

### StrikesParamsUnset

```solidity
event StrikesParamsUnset(uint256 indexed curveId);
```

### BadPerformancePenaltyUnset

```solidity
event BadPerformancePenaltyUnset(uint256 indexed curveId);
```

### PerformanceCoefficientsUnset

```solidity
event PerformanceCoefficientsUnset(uint256 indexed curveId);
```

### QueueConfigSet

```solidity
event QueueConfigSet(uint256 indexed curveId, uint256 priority, uint256 maxDeposits);
```

### QueueConfigUnset

```solidity
event QueueConfigUnset(uint256 indexed curveId);
```

### AllowedExitDelaySet

```solidity
event AllowedExitDelaySet(uint256 indexed curveId, uint256 delay);
```

### AllowedExitDelayUnset

```solidity
event AllowedExitDelayUnset(uint256 indexed curveId);
```

### ExitDelayPenaltySet

```solidity
event ExitDelayPenaltySet(uint256 indexed curveId, uint256 penalty);
```

### ExitDelayPenaltyUnset

```solidity
event ExitDelayPenaltyUnset(uint256 indexed curveId);
```

### MaxWithdrawalRequestFeeSet

```solidity
event MaxWithdrawalRequestFeeSet(uint256 indexed curveId, uint256 fee);
```

### MaxWithdrawalRequestFeeUnset

```solidity
event MaxWithdrawalRequestFeeUnset(uint256 indexed curveId);
```

## Errors
### InvalidRewardShareData

```solidity
error InvalidRewardShareData();
```

### InvalidPerformanceLeewayData

```solidity
error InvalidPerformanceLeewayData();
```

### InvalidKeyNumberValueIntervals

```solidity
error InvalidKeyNumberValueIntervals();
```

### InvalidPerformanceCoefficients

```solidity
error InvalidPerformanceCoefficients();
```

### InvalidStrikesParams

```solidity
error InvalidStrikesParams();
```

### ZeroMaxDeposits

```solidity
error ZeroMaxDeposits();
```

### ZeroAdminAddress

```solidity
error ZeroAdminAddress();
```

### QueueCannotBeUsed

```solidity
error QueueCannotBeUsed();
```

### InvalidAllowedExitDelay

```solidity
error InvalidAllowedExitDelay();
```

### ZeroQueueLowestPriority

```solidity
error ZeroQueueLowestPriority();
```

## Structs
### MarkedUint248

```solidity
struct MarkedUint248 {
    uint248 value;
    bool isValue;
}
```

### QueueConfig

```solidity
struct QueueConfig {
    uint32 priority;
    uint32 maxDeposits;
}
```

### StrikesParams

```solidity
struct StrikesParams {
    uint32 lifetime;
    uint32 threshold;
}
```

### PerformanceCoefficients

```solidity
struct PerformanceCoefficients {
    uint32 attestationsWeight;
    uint32 blocksWeight;
    uint32 syncWeight;
}
```

### InitializationData

```solidity
struct InitializationData {
    uint256 keyRemovalCharge;
    uint256 elRewardsStealingAdditionalFine;
    uint256 keysLimit;
    uint256 rewardShare;
    uint256 performanceLeeway;
    uint256 strikesLifetime;
    uint256 strikesThreshold;
    uint256 defaultQueuePriority;
    uint256 defaultQueueMaxDeposits;
    uint256 badPerformancePenalty;
    uint256 attestationsWeight;
    uint256 blocksWeight;
    uint256 syncWeight;
    uint256 defaultAllowedExitDelay;
    uint256 defaultExitDelayPenalty;
    uint256 defaultMaxWithdrawalRequestFee;
}
```

### KeyNumberValueInterval
*Defines a value interval starting from `minKeyNumber`.
All keys with number >= `minKeyNumber` are assigned the corresponding `value`
until the next interval begins. Intervals must be sorted by ascending `minKeyNumber`
and must start from one (i.e., the first interval must have minKeyNumber == 1).
Example: [{1, 10000}, {11, 8000}] means first 10 keys with 10000, other keys with 8000.*


```solidity
struct KeyNumberValueInterval {
    uint256 minKeyNumber;
    uint256 value;
}
```

