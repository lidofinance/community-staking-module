// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

contract LidoLocatorMock {
    address public l;
    address public b;
    address public wq;
    address public el;
    address public t;

    constructor(
        address _lido,
        address _burner,
        address _wq,
        address _el,
        address _t
    ) {
        l = _lido;
        b = _burner;
        wq = _wq;
        el = _el;
        t = _t;
    }

    function lido() external view returns (address) {
        return l;
    }

    function burner() external view returns (address) {
        return b;
    }

    function withdrawalQueue() external view returns (address) {
        return wq;
    }

    function elRewardsVault() external view returns (address) {
        return el;
    }

    function treasury() external view returns (address) {
        return t;
    }
}
