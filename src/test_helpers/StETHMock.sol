// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract StETHMock {
    uint256 public totalPooledEther;
    uint256 public totalShares;
    mapping(address => uint256) public shares;

    constructor(uint256 _totalPooledEther) {
        totalPooledEther = _totalPooledEther;
    }

    function _submit(address _sender, uint256 _value) public returns (uint256) {
        uint256 sharesToMint = getSharesByPooledEth(_value);
        mintShares(_sender, sharesToMint);
        addTotalPooledEther(_value);
        return sharesToMint;
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
     * @notice Transfer `_sharesAmount` stETH shares from `_sender` to `_receiver` using allowance.
     */
    function transferSharesFrom(
        address _sender,
        address _recipient,
        uint256 _sharesAmount
    ) public returns (uint256) {
        require(shares[_sender] >= _sharesAmount, "not enough shares");
        shares[_sender] -= _sharesAmount;
        shares[_recipient] += _sharesAmount;
        return _sharesAmount;
    }
}
