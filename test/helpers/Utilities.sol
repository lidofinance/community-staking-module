// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { CommonBase } from "forge-std/Base.sol";

/// @author madlabman
contract Utilities is CommonBase {
    bytes32 internal seed = keccak256("seed sEed seEd");

    function nextAddress() internal returns (address) {
        bytes32 buf = keccak256(abi.encodePacked(seed));
        address a = address(uint160(uint256(buf)));
        seed = buf;
        return a;
    }

    function nextAddress(string memory label) internal returns (address) {
        address a = nextAddress();
        vm.label(a, label);
        return a;
    }

    function keysSignatures(
        uint256 keysCount
    ) public pure returns (bytes memory, bytes memory) {
        return keysSignatures(keysCount, 0);
    }

    function keysSignatures(
        uint256 keysCount,
        uint16 startIndex
    ) public pure returns (bytes memory, bytes memory) {
        bytes memory keys;
        bytes memory signatures;
        for (uint16 i = startIndex; i < startIndex + keysCount; i++) {
            bytes memory index = abi.encodePacked(i + 1);
            bytes memory key = bytes.concat(
                new bytes(48 - index.length),
                index
            );
            bytes memory sign = bytes.concat(
                new bytes(96 - index.length),
                index
            );
            keys = bytes.concat(keys, key);
            signatures = bytes.concat(signatures, sign);
        }
        return (keys, signatures);
    }

    function randomBytes(uint256 length) public returns (bytes memory b) {
        b = new bytes(length);

        for (;;) {
            bytes32 buf = keccak256(abi.encodePacked(seed));
            seed = buf;

            for (uint256 i = 0; i < 32; i++) {
                if (length == 0) {
                    return b;
                }
                length--;
                b[length] = buf[i];
            }
        }
    }

    function checkChainId(uint256 chainId) public view {
        if (chainId != block.chainid) {
            revert("wrong chain id");
        }
    }

    function accessErrorString(
        address account,
        bytes32 role
    ) internal pure returns (string memory) {
        string memory errorString = "AccessControl: account ";
        errorString = string.concat(errorString, vm.toString(account));
        errorString = string.concat(errorString, " is missing role ");
        errorString = string.concat(errorString, vm.toString(role));
        return errorString;
    }
}
