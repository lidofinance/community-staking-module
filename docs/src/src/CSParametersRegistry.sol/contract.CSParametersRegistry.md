# CSParametersRegistry
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/CSParametersRegistry.sol)

**Inherits:**
[ICSParametersRegistry](/src/interfaces/ICSParametersRegistry.sol/interface.ICSParametersRegistry.md), Initializable, AccessControlEnumerableUpgradeable

*There are no upper limit checks except for the basis points (BP) values
since with the introduction of Dual Governance any malicious changes to the parameters can be objected by stETH holders.*


## State Variables
### MAX_BP
*Maximal value for basis points (BP)
1 BP = 0.01%*


```solidity
uint256 internal constant MAX_BP = 10000;
```


### QUEUE_LOWEST_PRIORITY
*QUEUE_LOWEST_PRIORITY identifies the range of available priorities: [0; QUEUE_LOWEST_PRIORITY].*


```solidity
uint256 public immutable QUEUE_LOWEST_PRIORITY;
```


### QUEUE_LEGACY_PRIORITY
*QUEUE_LEGACY_PRIORITY is the priority for the CSM v1 queue.*


```solidity
uint256 public immutable QUEUE_LEGACY_PRIORITY;
```


### defaultKeyRemovalCharge

```solidity
uint256 public defaultKeyRemovalCharge;
```


### _keyRemovalCharges

```solidity
mapping(uint256 curveId => MarkedUint248) internal _keyRemovalCharges;
```


### defaultElRewardsStealingAdditionalFine

```solidity
uint256 public defaultElRewardsStealingAdditionalFine;
```


### _elRewardsStealingAdditionalFines

```solidity
mapping(uint256 curveId => MarkedUint248) internal _elRewardsStealingAdditionalFines;
```


### defaultKeysLimit

```solidity
uint256 public defaultKeysLimit;
```


### _keysLimits

```solidity
mapping(uint256 curveId => MarkedUint248) internal _keysLimits;
```


### defaultQueueConfig

```solidity
QueueConfig public defaultQueueConfig;
```


### _queueConfigs

```solidity
mapping(uint256 curveId => QueueConfig) internal _queueConfigs;
```


### defaultRewardShare
*Default value for the reward share. Can be only be set as a flat value due to possible sybil attacks
Decreased reward share for some validators > N will promote sybils. Increased reward share for validators > N will give large operators an advantage*


```solidity
uint256 public defaultRewardShare;
```


### _rewardShareData

```solidity
mapping(uint256 curveId => KeyNumberValueInterval[]) internal _rewardShareData;
```


### defaultPerformanceLeeway
*Default value for the performance leeway. Can be only be set as a flat value due to possible sybil attacks
Decreased performance leeway for some validators > N will promote sybils. Increased performance leeway for validators > N will give large operators an advantage*


```solidity
uint256 public defaultPerformanceLeeway;
```


### _performanceLeewayData

```solidity
mapping(uint256 curveId => KeyNumberValueInterval[]) internal _performanceLeewayData;
```


### defaultStrikesParams

```solidity
StrikesParams public defaultStrikesParams;
```


### _strikesParams

```solidity
mapping(uint256 curveId => StrikesParams) internal _strikesParams;
```


### defaultBadPerformancePenalty

```solidity
uint256 public defaultBadPerformancePenalty;
```


### _badPerformancePenalties

```solidity
mapping(uint256 curveId => MarkedUint248) internal _badPerformancePenalties;
```


### defaultPerformanceCoefficients

```solidity
PerformanceCoefficients public defaultPerformanceCoefficients;
```


### _performanceCoefficients

```solidity
mapping(uint256 curveId => PerformanceCoefficients) internal _performanceCoefficients;
```


### defaultAllowedExitDelay

```solidity
uint256 public defaultAllowedExitDelay;
```


### _allowedExitDelay

```solidity
mapping(uint256 => uint256) internal _allowedExitDelay;
```


### defaultExitDelayPenalty

```solidity
uint256 public defaultExitDelayPenalty;
```


### _exitDelayPenalties

```solidity
mapping(uint256 => MarkedUint248) internal _exitDelayPenalties;
```


### defaultMaxWithdrawalRequestFee

```solidity
uint256 public defaultMaxWithdrawalRequestFee;
```


### _maxWithdrawalRequestFees

```solidity
mapping(uint256 => MarkedUint248) internal _maxWithdrawalRequestFees;
```


## Functions
### constructor


```solidity
constructor(uint256 queueLowestPriority);
```

### initialize

initialize contract


```solidity
function initialize(address admin, InitializationData calldata data) external initializer;
```

### setDefaultKeyRemovalCharge

Set default value for the key removal charge. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`keyRemovalCharge`|`uint256`|value to be set as default for the key removal charge|


### setDefaultElRewardsStealingAdditionalFine

Set default value for the EL rewards stealing additional fine. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultElRewardsStealingAdditionalFine(uint256 fine) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fine`|`uint256`|value to be set as default for the EL rewards stealing additional fine|


### setDefaultKeysLimit

Set default value for the keys limit. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultKeysLimit(uint256 limit) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`limit`|`uint256`|value to be set as default for the keys limit|


### setDefaultRewardShare

Set default value for the reward share. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultRewardShare(uint256 share) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`share`|`uint256`|value to be set as default for the reward share|


### setDefaultPerformanceLeeway

Set default value for the performance leeway. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultPerformanceLeeway(uint256 leeway) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`leeway`|`uint256`|value to be set as default for the performance leeway|


### setDefaultStrikesParams

Set default values for the strikes lifetime and threshold. Default values are used if specific values are not set for the curveId


```solidity
function setDefaultStrikesParams(uint256 lifetime, uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lifetime`|`uint256`|The default number of CSM Performance Oracle frames to store strikes values|
|`threshold`|`uint256`|The default strikes value leading to validator force ejection.|


### setDefaultBadPerformancePenalty

Set default value for the bad performance penalty. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultBadPerformancePenalty(uint256 penalty) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`penalty`|`uint256`|value to be set as default for the bad performance penalty|


### setDefaultPerformanceCoefficients

Set default values for the performance coefficients. Default values are used if specific values are not set for the curveId


```solidity
function setDefaultPerformanceCoefficients(uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attestationsWeight`|`uint256`|value to be set as default for the attestations effectiveness weight|
|`blocksWeight`|`uint256`|value to be set as default for block proposals effectiveness weight|
|`syncWeight`|`uint256`|value to be set as default for sync participation effectiveness weight|


### setDefaultQueueConfig

Set default value for QueueConfig. Default value is used if a specific value is not set for the curveId.


```solidity
function setDefaultQueueConfig(uint256 priority, uint256 maxDeposits) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`priority`|`uint256`|Queue priority.|
|`maxDeposits`|`uint256`|Maximum number of deposits a Node Operator can get via the priority queue.|


### setDefaultAllowedExitDelay

set default value for allowed delay before the exit was initiated exit delay in seconds. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultAllowedExitDelay(uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delay`|`uint256`|value to be set as default for the allowed exit delay|


### setDefaultExitDelayPenalty

set default value for exit delay penalty. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultExitDelayPenalty(uint256 penalty) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`penalty`|`uint256`|value to be set as default for the exit delay penalty|


### setDefaultMaxWithdrawalRequestFee

set default value for max withdrawal request fee. Default value is used if a specific value is not set for the curveId


```solidity
function setDefaultMaxWithdrawalRequestFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|value to be set as default for the max withdrawal request fee|


### setKeyRemovalCharge

Set key removal charge for the curveId.


```solidity
function setKeyRemovalCharge(uint256 curveId, uint256 keyRemovalCharge) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate key removal charge with|
|`keyRemovalCharge`|`uint256`|Key removal charge|


### unsetKeyRemovalCharge

Unset key removal charge for the curveId


```solidity
function unsetKeyRemovalCharge(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom key removal charge for|


### setElRewardsStealingAdditionalFine

Set EL rewards stealing additional fine for the curveId.


```solidity
function setElRewardsStealingAdditionalFine(uint256 curveId, uint256 fine) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate EL rewards stealing additional fine limit with|
|`fine`|`uint256`|EL rewards stealing additional fine|


### unsetElRewardsStealingAdditionalFine

Unset EL rewards stealing additional fine for the curveId


```solidity
function unsetElRewardsStealingAdditionalFine(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom EL rewards stealing additional fine for|


### setKeysLimit

Set keys limit for the curveId.


```solidity
function setKeysLimit(uint256 curveId, uint256 limit) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate keys limit with|
|`limit`|`uint256`|Keys limit|


### unsetKeysLimit

Unset key removal charge for the curveId


```solidity
function unsetKeysLimit(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom key removal charge for|


### setRewardShareData

Set reward share parameters for the curveId

*KeyNumberValueInterval = [[1, 10000], [11, 8000], [51, 5000]] stands for
100% rewards for the first 10 keys, 80% rewards for the keys 11-50, and 50% rewards for the keys > 50*


```solidity
function setRewardShareData(uint256 curveId, KeyNumberValueInterval[] calldata data)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate reward share data with|
|`data`|`KeyNumberValueInterval[]`|Interval values for keys count and reward share percentages in BP (ex. [[1, 10000], [11, 8000], [51, 5000]])|


### unsetRewardShareData

Unset reward share parameters for the curveId


```solidity
function unsetRewardShareData(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom reward share parameters for|


### setPerformanceLeewayData

Set performance leeway parameters for the curveId

*Returns [[1, defaultPerformanceLeeway]] if no intervals are set for the given curveId.*


```solidity
function setPerformanceLeewayData(uint256 curveId, KeyNumberValueInterval[] calldata data)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate performance leeway data with|
|`data`|`KeyNumberValueInterval[]`|Interval values for keys count and performance leeway percentages in BP (ex. [[1, 500], [101, 450], [501, 400]])|


### unsetPerformanceLeewayData

Unset performance leeway parameters for the curveId


```solidity
function unsetPerformanceLeewayData(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom performance leeway parameters for|


### setStrikesParams

Set performance strikes lifetime and threshold for the curveId


```solidity
function setStrikesParams(uint256 curveId, uint256 lifetime, uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE);
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
function unsetStrikesParams(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom performance strikes lifetime and threshold for|


### setBadPerformancePenalty

Set bad performance penalty for the curveId


```solidity
function setBadPerformancePenalty(uint256 curveId, uint256 penalty) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate bad performance penalty with|
|`penalty`|`uint256`|Bad performance penalty|


### unsetBadPerformancePenalty

Unset bad performance penalty for the curveId


```solidity
function unsetBadPerformancePenalty(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom bad performance penalty for|


### setPerformanceCoefficients

Set performance coefficients for the curveId


```solidity
function setPerformanceCoefficients(
    uint256 curveId,
    uint256 attestationsWeight,
    uint256 blocksWeight,
    uint256 syncWeight
) external onlyRole(DEFAULT_ADMIN_ROLE);
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
function unsetPerformanceCoefficients(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom performance coefficients for|


### setQueueConfig

Sets the provided config to the given curve.


```solidity
function setQueueConfig(uint256 curveId, uint256 priority, uint256 maxDeposits) external onlyRole(DEFAULT_ADMIN_ROLE);
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
function unsetQueueConfig(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom config.|


### setAllowedExitDelay

Set allowed exit delay for the curveId in seconds


```solidity
function setAllowedExitDelay(uint256 curveId, uint256 delay) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate allowed exit delay with|
|`delay`|`uint256`|allowed exit delay|


### unsetAllowedExitDelay

Unset exit timeframe deadline delay for the curveId


```solidity
function unsetAllowedExitDelay(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset allowed exit delay for|


### setExitDelayPenalty

Set exit delay penalty for the curveId

*cannot be zero*


```solidity
function setExitDelayPenalty(uint256 curveId, uint256 penalty) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate exit delay penalty with|
|`penalty`|`uint256`|exit delay penalty|


### unsetExitDelayPenalty

Unset exit delay penalty for the curveId


```solidity
function unsetExitDelayPenalty(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset exit delay penalty for|


### setMaxWithdrawalRequestFee

Set max withdrawal request fee for the curveId


```solidity
function setMaxWithdrawalRequestFee(uint256 curveId, uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate max withdrawal request fee with|
|`fee`|`uint256`|max withdrawal request fee|


### unsetMaxWithdrawalRequestFee

Unset max withdrawal request fee for the curveId


```solidity
function unsetMaxWithdrawalRequestFee(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset max withdrawal request fee for|


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


### getRewardShareData

Get reward share parameters by the curveId.

*Returns [[1, defaultRewardShare]] if no intervals are set for the given curveId.*


```solidity
function getRewardShareData(uint256 curveId) external view returns (KeyNumberValueInterval[] memory data);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get reward share data for|


### getPerformanceLeewayData

Get performance leeway parameters by the curveId

*Returns [[1, defaultPerformanceLeeway]] if no intervals are set for the given curveId.*


```solidity
function getPerformanceLeewayData(uint256 curveId) external view returns (KeyNumberValueInterval[] memory data);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get performance leeway data for|


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


### getQueueConfig

Get the queue config for the given curve.


```solidity
function getQueueConfig(uint256 curveId) external view returns (uint32 queuePriority, uint32 maxDeposits);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get the queue config for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`queuePriority`|`uint32`|priority Queue priority.|
|`maxDeposits`|`uint32`|Maximum number of deposits a Node Operator can get via the priority queue.|


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

### _setDefaultKeyRemovalCharge


```solidity
function _setDefaultKeyRemovalCharge(uint256 keyRemovalCharge) internal;
```

### _setDefaultElRewardsStealingAdditionalFine


```solidity
function _setDefaultElRewardsStealingAdditionalFine(uint256 fine) internal;
```

### _setDefaultKeysLimit


```solidity
function _setDefaultKeysLimit(uint256 limit) internal;
```

### _setDefaultRewardShare


```solidity
function _setDefaultRewardShare(uint256 share) internal;
```

### _setDefaultPerformanceLeeway


```solidity
function _setDefaultPerformanceLeeway(uint256 leeway) internal;
```

### _setDefaultStrikesParams


```solidity
function _setDefaultStrikesParams(uint256 lifetime, uint256 threshold) internal;
```

### _setDefaultBadPerformancePenalty


```solidity
function _setDefaultBadPerformancePenalty(uint256 penalty) internal;
```

### _setDefaultPerformanceCoefficients


```solidity
function _setDefaultPerformanceCoefficients(uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight)
    internal;
```

### _setDefaultQueueConfig


```solidity
function _setDefaultQueueConfig(uint256 priority, uint256 maxDeposits) internal;
```

### _setDefaultAllowedExitDelay


```solidity
function _setDefaultAllowedExitDelay(uint256 delay) internal;
```

### _setDefaultExitDelayPenalty


```solidity
function _setDefaultExitDelayPenalty(uint256 penalty) internal;
```

### _setDefaultMaxWithdrawalRequestFee


```solidity
function _setDefaultMaxWithdrawalRequestFee(uint256 fee) internal;
```

### _validateQueueConfig


```solidity
function _validateQueueConfig(uint256 priority, uint256 maxDeposits) internal view;
```

### _validateStrikesParams


```solidity
function _validateStrikesParams(uint256 lifetime, uint256 threshold) internal pure;
```

### _validateAllowedExitDelay


```solidity
function _validateAllowedExitDelay(uint256 delay) internal pure;
```

### _validatePerformanceCoefficients


```solidity
function _validatePerformanceCoefficients(uint256 attestationsWeight, uint256 blocksWeight, uint256 syncWeight)
    internal
    pure;
```

### _validateKeyNumberValueIntervals


```solidity
function _validateKeyNumberValueIntervals(KeyNumberValueInterval[] calldata intervals) private pure;
```

