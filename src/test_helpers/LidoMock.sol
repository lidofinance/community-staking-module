// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { StETHMock } from "./StETHMock.sol";

contract LidoMock is StETHMock {
    constructor(uint256 _totalPooledEther) StETHMock(_totalPooledEther) {}

    function submit(address _referal) public payable returns (uint256) {
        uint256 sharesToMint = getSharesByPooledEth(msg.value);
        mintShares(msg.sender, sharesToMint);
        addTotalPooledEther(msg.value);
        return sharesToMint;
    }
}
