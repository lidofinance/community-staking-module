// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStETH } from "../../../src/interfaces/IStETH.sol";

contract WithdrawalQueueMockBase {
    /// @dev Contains both stETH token amount and its corresponding shares amount
    event WithdrawalRequested(
        uint256 indexed requestId,
        address indexed requestor,
        address indexed owner,
        uint256 amountOfStETH,
        uint256 amountOfShares
    );
}

contract WithdrawalQueueMock is WithdrawalQueueMockBase {
    IStETH public stETH;

    uint256 public constant MIN_STETH_WITHDRAWAL_AMOUNT = 100;

    uint256 public constant MAX_STETH_WITHDRAWAL_AMOUNT = 1000 ether;

    constructor(address _stETH) {
        stETH = IStETH(_stETH);
    }

    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds) {
        requestIds = new uint256[](_amounts.length);
        for (uint256 i = 0; i < _amounts.length; ++i) {
            require(
                _amounts[i] <= MAX_STETH_WITHDRAWAL_AMOUNT,
                "amount is greater than MAX_STETH_WITHDRAWAL_AMOUNT"
            );
            require(
                _amounts[i] >= MIN_STETH_WITHDRAWAL_AMOUNT,
                "amount is less than MIN_STETH_WITHDRAWAL_AMOUNT"
            );
            stETH.transferFrom(msg.sender, address(this), _amounts[i]);
            emit WithdrawalRequested(
                i + 1,
                msg.sender,
                _owner,
                _amounts[i],
                stETH.getSharesByPooledEth(_amounts[i])
            );
            requestIds[i] = i + 1;
        }
    }
}
