// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { SigningKeys } from "../src/lib/SigningKeys.sol";
import { Utilities } from "./helpers/Utilities.sol";

// Wrap the library internal methods to make an actual call to them.
// Supposed to be used with `expectRevert` cheatcode and to pass
// calldata arguments.
contract Library {
    function saveKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        bytes memory pubkeys,
        bytes memory signatures
    ) external returns (uint256) {
        return
            SigningKeys.saveKeysSigs(
                nodeOperatorId,
                startIndex,
                keysCount,
                pubkeys,
                signatures
            );
    }

    function removeKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint256 totalKeysCount
    ) external returns (uint256) {
        return
            SigningKeys.removeKeysSigs(
                nodeOperatorId,
                startIndex,
                keysCount,
                totalKeysCount
            );
    }

    function loadKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) external view returns (bytes memory pubkeys) {
        return SigningKeys.loadKeys(nodeOperatorId, startIndex, keysCount);
    }

    function loadKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        bytes memory pubkeys,
        bytes memory signatures,
        uint256 bufOffset
    ) external view {
        SigningKeys.loadKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures,
            bufOffset
        );
    }
}

contract SigningKeysTest is Test, Utilities {
    Library signingKeys;

    function setUp() public {
        signingKeys = new Library();
    }

    function testFuzz_saveKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 100);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount,
            uint16(startIndex)
        );
        uint256 newKeysCount = signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );

        assertEq(newKeysCount, startIndex + keysCount);
    }

    function testFuzz_saveKeysSigs_reverWhen_EmptyKey(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint8 offset
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 100);
        vm.assume(offset < keysCount);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (
            bytes memory pubkeys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, uint16(startIndex), offset);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );
    }

    function testFuzz_removeKeysSigs_offsetRigth(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint8 offset
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 100);
        vm.assume(offset < keysCount);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 totalKeysCount = signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );

        uint256 newTotalKeysCount = signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex + offset,
            keysCount - offset,
            totalKeysCount
        );

        assertEq(newTotalKeysCount, totalKeysCount - keysCount + offset);
    }

    function testFuzz_removeKeysSigs_offsetLeft(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint8 offset
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 100);
        vm.assume(offset < keysCount);
        vm.assume(startIndex > offset);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 totalKeysCount = signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );

        uint256 newTotalKeysCount = signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex - offset,
            keysCount - offset,
            totalKeysCount
        );

        assertEq(newTotalKeysCount, totalKeysCount - keysCount + offset);
    }

    function testFuzz_removeKeysSigs_NoKeysAdded(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 200);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        uint256 totalKeysCount = startIndex + keysCount;

        uint256 newTotalKeysCount = signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            totalKeysCount
        );

        assertEq(newTotalKeysCount, totalKeysCount - keysCount);
    }

    function testFuzz_loadKeys(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 100);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount,
            uint16(startIndex)
        );
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );

        bytes memory loadedPubkeys = signingKeys.loadKeys(
            nodeOperatorId,
            startIndex,
            keysCount
        );

        assertEq(loadedPubkeys.length, keysCount * 48);
    }

    function testFuzz_loadKeys_empty(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 500);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        bytes memory loadedPubkeys = signingKeys.loadKeys(
            nodeOperatorId,
            startIndex,
            keysCount
        );

        assertEq(loadedPubkeys.length, keysCount * 48);
    }

    function testFuzz_loadKeysSigs(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint256 offset
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 100);
        vm.assume(offset < 100);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory pubkeys, bytes memory sigs) = keysSignatures(
            keysCount,
            uint16(startIndex)
        );
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            sigs
        );

        (bytes memory publicKeys, bytes memory signatures) = SigningKeys
            .initKeysSigsBuf(offset + keysCount);

        signingKeys.loadKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            publicKeys,
            signatures,
            offset
        );
    }

    function testFuzz_loadKeysSigs_empty(
        uint256 nodeOperatorId,
        uint256 startIndex,
        uint256 keysCount,
        uint256 offset
    ) public view {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 200);
        vm.assume(offset < 100);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory publicKeys, bytes memory signatures) = SigningKeys
            .initKeysSigsBuf(offset + keysCount);

        signingKeys.loadKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            publicKeys,
            signatures,
            offset
        );
    }
}
