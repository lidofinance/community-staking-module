# CSParametersRegistry
[Git Source](https://github.com/lidofinance/community-staking-module/blob/86cbb28dad521bfac5576c8a7b405bc33b32f44d/src/CSParametersRegistry.sol)

**Inherits:**
[ICSParametersRegistry](/src/interfaces/ICSParametersRegistry.sol/interface.ICSParametersRegistry.md), Initializable, AccessControlEnumerableUpgradeable


## State Variables
### MAX_BP

```solidity
uint256 internal constant MAX_BP = 10000;
```


### defaultKeyRemovalCharge

```solidity
uint256 public defaultKeyRemovalCharge;
```


### _keyRemovalCharges

```solidity
mapping(uint256 => MarkedUint248) internal _keyRemovalCharges;
```


### defaultElRewardsStealingAdditionalFine

```solidity
uint256 public defaultElRewardsStealingAdditionalFine;
```


### _elRewardsStealingAdditionalFines

```solidity
mapping(uint256 => MarkedUint248) internal _elRewardsStealingAdditionalFines;
```


### defaultKeysLimit

```solidity
uint256 public defaultKeysLimit;
```


### _keysLimits

```solidity
mapping(uint256 => MarkedUint248) internal _keysLimits;
```


### defaultQueueConfig

```solidity
QueueConfig public defaultQueueConfig;
```


### _queueConfigs

```solidity
mapping(uint256 curveId => MarkedQueueConfig) internal _queueConfigs;
```


### defaultRewardShare
*Default value for the reward share. Can be only be set as a flat value due to possible sybil attacks
Decreased reward share for some validators > N will promote sybils. Increased reward share for validators > N will give large operators an advantage*


```solidity
uint256 public defaultRewardShare;
```


### _rewardShareData

```solidity
mapping(uint256 => PivotsAndValues) internal _rewardShareData;
```


### defaultPerformanceLeeway
*Default value for the performance leeway. Can be only be set as a flat value due to possible sybil attacks
Decreased performance leeway for some validators > N will promote sybils. Increased performance leeway for validators > N will give large operators an advantage*


```solidity
uint256 public defaultPerformanceLeeway;
```


### _performanceLeewayData

```solidity
mapping(uint256 => PivotsAndValues) internal _performanceLeewayData;
```


### defaultStrikesParams

```solidity
StrikesParams public defaultStrikesParams;
```


### _strikesParams

```solidity
mapping(uint256 => MarkedStrikesParams) internal _strikesParams;
```


### defaultBadPerformancePenalty

```solidity
uint256 public defaultBadPerformancePenalty;
```


### _badPerformancePenalties

```solidity
mapping(uint256 => MarkedUint248) internal _badPerformancePenalties;
```


### defaultPerformanceCoefficients

```solidity
PerformanceCoefficients public defaultPerformanceCoefficients;
```


### _performanceCoefficients

```solidity
mapping(uint256 => MarkedPerformanceCoefficients) internal _performanceCoefficients;
```


### QUEUE_LOWEST_PRIORITY

```solidity
uint256 public immutable QUEUE_LOWEST_PRIORITY;
```


### QUEUE_LEGACY_PRIORITY

```solidity
uint256 public immutable QUEUE_LEGACY_PRIORITY;
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

*keyPivots = [10, 50] and rewardShares = [10000, 8000, 5000] stands for
100% rewards for the keys 1-10, 80% rewards for the keys 11-50, and 50% rewards for the keys > 50*


```solidity
function setRewardShareData(uint256 curveId, uint256[] calldata keyPivots, uint256[] calldata rewardShares)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate reward share data with|
|`keyPivots`|`uint256[]`|Pivot numbers of the keys (ex. [10, 50])|
|`rewardShares`|`uint256[]`|Reward share percentages in BP (ex. [10000, 8000, 5000])|


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

*keyPivots = [20, 100] and performanceLeeways = [500, 450, 400] stands for
5% performance leeway for the keys 1-20, 4.5% performance leeway for the keys 21-100, and 4% performance leeway for the keys > 100*


```solidity
function setPerformanceLeewayData(uint256 curveId, uint256[] calldata keyPivots, uint256[] calldata performanceLeeways)
    external
    onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to associate performance leeway data with|
|`keyPivots`|`uint256[]`|Pivot numbers of the keys (ex. [20, 100])|
|`performanceLeeways`|`uint256[]`|Performance leeway percentages in BP (ex. [500, 450, 400])|


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
function setQueueConfig(uint256 curveId, QueueConfig calldata config) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to set the config.|
|`config`|`QueueConfig`|Config to be used for the curve.|


### unsetQueueConfig

Set the given curve's config to the default one.


```solidity
function unsetQueueConfig(uint256 curveId) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to unset custom config.|


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

*Reverts if the values are not set for the given curveId.*


```solidity
function getRewardShareData(uint256 curveId)
    external
    view
    returns (uint256[] memory keyPivots, uint256[] memory rewardShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get reward share data for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`keyPivots`|`uint256[]`|Pivot numbers of the keys (ex. [10, 50])|
|`rewardShares`|`uint256[]`|Reward share percentages in BP (ex. [10000, 8000, 5000])|


### getPerformanceLeewayData

Get performance leeway parameters by the curveId

*Reverts if the values are not set for the given curveId.*


```solidity
function getPerformanceLeewayData(uint256 curveId)
    external
    view
    returns (uint256[] memory keyPivots, uint256[] memory performanceLeeways);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`curveId`|`uint256`|Curve Id to get performance leeway data for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`keyPivots`|`uint256[]`|Pivot numbers of the keys (ex. [100, 500])|
|`performanceLeeways`|`uint256[]`|Performance leeway percentages in BP (ex. [500, 450, 400])|


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

### _validateStrikesParams


```solidity
function _validateStrikesParams(uint256 lifetime, uint256 threshold) internal pure;
```

