// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/// @author madlabman
contract Utilities {
    bytes32 internal seed = keccak256("seed sEed seEd");

    function nextAddress() internal returns (address) {
        address a = address(
            uint160(uint256(keccak256(abi.encodePacked(seed))))
        );
        seed = keccak256(abi.encodePacked(seed));
        return a;
    }
}
