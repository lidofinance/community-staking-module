// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { IValidatorsExitBus } from "../../../src/interfaces/IValidatorsExitBus.sol";

contract VEBMock {
    uint256 public constant MOCK_REFUND_PERCENTAGE_BP = 1000;
    event Refund(address indexed to, uint256 amount);
    error TransferFailed();

    receive() external payable {}

    function triggerExitsDirectly(
        IValidatorsExitBus.DirectExitData calldata /* exitData */,
        address refundRecipient,
        uint8 exitType
    ) external payable {
        uint256 refund = (msg.value * MOCK_REFUND_PERCENTAGE_BP) / 10000;
        if (refund == 0) {
            return;
        }
        (bool success, ) = refundRecipient.call{ value: refund }("");
        if (!success) {
            revert TransferFailed();
        }
    }
}
