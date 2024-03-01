// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { PermitTokenBase } from "../Permit.sol";

contract StETHMock is PermitTokenBase {
    uint256 public totalPooledEther;
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    error NotEnoughShares(uint256 balance);

    constructor(uint256 _totalPooledEther) {
        totalPooledEther = _totalPooledEther;
    }

    function mintShares(address _account, uint256 _sharesAmount) public {
        shares[_account] += _sharesAmount;
        totalShares += _sharesAmount;
    }

    function addTotalPooledEther(uint256 _pooledEtherAmount) public {
        totalPooledEther += _pooledEtherAmount;
    }

    /**
     * @notice Get stETH amount by the provided shares amount
     * @param _sharesAmount shares amount
     * @dev dual to `getSharesByPooledEth`.
     */
    function getPooledEthByShares(
        uint256 _sharesAmount
    ) public view returns (uint256) {
        return (_sharesAmount * totalPooledEther) / totalShares;
    }

    /**
     * @notice Get shares amount by the provided stETH amount
     * @param _pooledEthAmount stETH amount
     * @dev dual to `getPooledEthByShares`.
     */
    function getSharesByPooledEth(
        uint256 _pooledEthAmount
    ) public view returns (uint256) {
        return (_pooledEthAmount * totalShares) / totalPooledEther;
    }

    /**
     * @notice Get shares amount of the provided account
     * @param _account provided account address.
     */
    function sharesOf(address _account) public view returns (uint256) {
        return shares[_account];
    }

    /**
     * @return the amount of tokens owned by the `_account`.
     *
     * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
     * total Ether controlled by the protocol. See `sharesOf`.
     */
    function balanceOf(address _account) external view returns (uint256) {
        return getPooledEthByShares(shares[_account]);
    }

    /**
     * @notice Moves `_amount` token amount from the caller's account to the `_recipient` account.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        uint256 _sharesToTransfer = getSharesByPooledEth(_amount);
        transferSharesFrom(_sender, _recipient, _sharesToTransfer);
        return true;
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        uint256 _sharesToTransfer = getSharesByPooledEth(_amount);
        transferShares(_recipient, _sharesToTransfer);
        return true;
    }

    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) public returns (uint256) {
        require(shares[msg.sender] >= _sharesAmount, "not enough shares");
        shares[msg.sender] -= _sharesAmount;
        shares[_recipient] += _sharesAmount;
        return _sharesAmount;
    }

    /**
     * @notice Transfer `_sharesAmount` stETH shares from `_sender` to `_receiver` using allowance.
     */
    function transferSharesFrom(
        address _sender,
        address _recipient,
        uint256 _sharesAmount
    ) public returns (uint256) {
        if (shares[_sender] < _sharesAmount) {
            revert NotEnoughShares(shares[_sender]);
        }
        shares[_sender] -= _sharesAmount;
        shares[_recipient] += _sharesAmount;
        return _sharesAmount;
    }
}
