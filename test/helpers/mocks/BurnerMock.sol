// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract BurnerMock {
    function requestBurnShares(
        address _from,
        uint256 _sharesAmountToBurn
    ) external {}
}
