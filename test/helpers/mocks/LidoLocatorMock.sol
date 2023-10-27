// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract LidoLocatorMock {
    address public l;
    address public b;
    address public wq;

    constructor(address _lido, address _burner, address _wq) {
        l = _lido;
        b = _burner;
        wq = _wq;
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
}
