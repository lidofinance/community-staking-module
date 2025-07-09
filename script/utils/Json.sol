// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Vm } from "forge-std/Vm.sol";

struct JsonObj {
    string ref;
    string str;
}

// @see https://github.com/nomoixyz/vulcan/blob/main/src/_internal/Json.sol
library Json {
    Vm internal constant vm =
        Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function newObj(
        string memory key
    ) internal pure returns (JsonObj memory obj) {
        obj.ref = key;
        obj.str = "";
    }

    function set(
        JsonObj memory obj,
        string memory key,
        address value
    ) internal {
        obj.str = vm.serializeAddress(obj.ref, key, value);
    }

    function set(
        JsonObj memory obj,
        string memory key,
        uint256 value
    ) internal {
        obj.str = vm.serializeUint(obj.ref, key, value);
    }

    function set(
        JsonObj memory obj,
        string memory key,
        bytes memory value
    ) internal {
        obj.str = vm.serializeBytes(obj.ref, key, value);
    }

    function set(
        JsonObj memory obj,
        string memory key,
        string memory value
    ) internal {
        obj.str = vm.serializeString(obj.ref, key, value);
    }
}

using Json for JsonObj global;
