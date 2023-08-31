// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StETHMock is ERC20("stETHMock", "stETHMock") {
    event TransferShares(
        address indexed from,
        address indexed to,
        uint256 sharesValue
    );

    function transferShares(
        address to,
        uint256 shares
    ) external returns (uint256) {
        _mint(to, shares);
        emit TransferShares(msg.sender, to, shares);
        return shares;
    }
}
