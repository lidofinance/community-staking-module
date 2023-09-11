// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { IStETH } from "../interfaces/IStETH.sol";

contract WstETHMock {
    IStETH public stETH;

    mapping(address => uint256) public _balance;
    uint256 public _totalSupply;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(address _stETH) {
        stETH = IStETH(_stETH);
    }

    function unwrap(uint256 _wstETHAmount) public returns (uint256) {
        require(_wstETHAmount > 0, "wstETH: zero amount unwrap not allowed");
        uint256 stETHAmount = stETH.getPooledEthByShares(_wstETHAmount);
        _burn(msg.sender, _wstETHAmount);
        stETH.transfer(msg.sender, stETHAmount);
        return stETHAmount;
    }

    function wrap(uint256 _stETHAmount) external returns (uint256) {
        require(_stETHAmount > 0, "wstETH: can't wrap zero stETH");
        uint256 wstETHAmount = stETH.getSharesByPooledEth(_stETHAmount);
        _mint(msg.sender, wstETHAmount);
        stETH.transferFrom(msg.sender, address(this), _stETHAmount);
        return wstETHAmount;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public {
        _balance[sender] -= amount;
        _balance[recipient] += amount;
    }

    function _mint(address _account, uint256 _amount) internal {
        _totalSupply += _amount;
        _balance[_account] += _amount;
    }

    function _burn(address _account, uint256 _amount) internal {
        _totalSupply -= _amount;
        _balance[_account] -= _amount;
    }
}
