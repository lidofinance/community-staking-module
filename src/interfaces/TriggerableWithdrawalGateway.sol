// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface TriggerableWithdrawalGateway {
    /**
     * @dev Submits Triggerable Withdrawal Requests to the Withdrawal Vault as full withdrawal requests
     *      for the specified validator public keys.
     *
     * @param triggerableExitData A packed byte array containing one or more 56-byte items, each representing:
     *        MSB <-------------------------------------------------- LSB
     *        |  3 bytes          |  5 bytes         |    48 bytes     |
     *        |  stakingModuleId  |  nodeOperatorId  | validatorPubkey |
     *
     * @param refundRecipient The address that will receive any excess ETH sent for fees.
     * @param exitType A parameter indicating the type of exit, passed to the Staking Module.
     *
     * Emits `TriggerableExitRequest` event for each validator in list.
     *
     * @notice Reverts if:
     *     - The caller does not have the `ADD_FULL_WITHDRAWAL_REQUEST_ROLE`
     *     - The total fee value sent is insufficient to cover all provided TW requests.
     *     - There is not enough limit quota left in the current frame to process all requests.
     */
    function triggerFullWithdrawals(
        bytes calldata triggerableExitData,
        address refundRecipient,
        uint8 exitType
    ) external payable;
}
