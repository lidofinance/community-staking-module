// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity 0.8.21;

interface ILidoLocator {
    function lido() external view returns (address);

    function burner() external view returns (address);
}
