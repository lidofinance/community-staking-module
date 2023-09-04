// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

contract LidoLocatorMock {
    address public l;
    address public b;

    constructor(address _lido, address _burner) {
        l = _lido;
        b = _burner;
    }

    function lido() external view returns (address) {
        return l;
    }

    function burner() external view returns (address) {
        return b;
    }
}
