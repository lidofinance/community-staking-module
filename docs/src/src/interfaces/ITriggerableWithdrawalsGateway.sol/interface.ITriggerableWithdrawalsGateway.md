# ITriggerableWithdrawalsGateway
[Git Source](https://github.com/lidofinance/community-staking-module/blob/efc92ba178845b0562e369d8d71b585ba381ab86/src/interfaces/ITriggerableWithdrawalsGateway.sol)


## Functions
### triggerFullWithdrawals

Reverts if:
- The caller does not have the `ADD_FULL_WITHDRAWAL_REQUEST_ROLE`
- The total fee value sent is insufficient to cover all provided TW requests.
- There is not enough limit quota left in the current frame to process all requests.

*Submits Triggerable Withdrawal Requests to the Withdrawal Vault as full withdrawal requests
for the specified validator public keys.*


```solidity
function triggerFullWithdrawals(ValidatorData[] calldata triggerableExitsData, address refundRecipient, uint8 exitType)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`triggerableExitsData`|`ValidatorData[]`|An array of `ValidatorData` structs, each representing a validator for which a withdrawal request will be submitted. Each entry includes: - `stakingModuleId`: ID of the staking module. - `nodeOperatorId`: ID of the node operator. - `pubkey`: Validator public key, 48 bytes length.|
|`refundRecipient`|`address`|The address that will receive any excess ETH sent for fees.|
|`exitType`|`uint8`|A parameter indicating the type of exit, passed to the Staking Module. Emits `TriggerableExitRequest` event for each validator in list.|


