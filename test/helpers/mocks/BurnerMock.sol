// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;
import "../../../src/interfaces/IStETH.sol";

contract BurnerMock {
    address public STETH;
    error ZeroBurnAmount();

    constructor(address _stETH) {
        STETH = _stETH;
    }

    function requestBurnMyStETH(uint256 _amountToBurn) external {
        if (_amountToBurn == 0) {
            revert ZeroBurnAmount();
        }

        IStETH(STETH).transferFrom(msg.sender, address(this), _amountToBurn);
    }
}
