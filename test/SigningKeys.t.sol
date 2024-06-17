// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
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
        uint256 bufOffset
    ) external view returns (bytes memory keys, bytes memory sigs) {
        (keys, sigs) = SigningKeys.initKeysSigsBuf(keysCount + bufOffset);
        SigningKeys.loadKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            keys,
            sigs,
            bufOffset
        );
    }
}

contract SigningKeysTestBase is Test, Utilities {
    uint64 internal constant PUBKEY_LENGTH = 48;
    uint64 internal constant SIGNATURE_LENGTH = 96;

    Library signingKeys;

    function setUp() public {
        signingKeys = new Library();
    }
}

contract SigningKeysSaveTest is SigningKeysTestBase {
    function test_saveKeysSigs() public {
        uint256 keysCount = 1;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount,
            startIndex
        );
        vm.expectEmit(true, true, true, true, address(signingKeys));
        emit SigningKeys.SigningKeyAdded(nodeOperatorId, pubkeys);
        uint256 newKeysCount = signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );

        assertEq(newKeysCount, startIndex + keysCount);
    }

    function test_saveKeysSigs_revertWhen_zeroKeys() public {
        uint256 keysCount = 0;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount,
            startIndex
        );

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );
    }

    function test_saveKeysSigs_revertWhen_toManyKeys() public {
        uint256 keysCount = type(uint32).max;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;

        (bytes memory pubkeys, bytes memory signatures) = (
            new bytes(0),
            new bytes(0)
        );

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );
    }

    function test_saveKeysSigs_revertWhen_invalidSigsLen() public {
        uint256 keysCount = 10;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
        (bytes memory pubkeys, ) = keysSignatures(keysCount, startIndex);
        vm.expectRevert(SigningKeys.InvalidLength.selector);
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            new bytes(0)
        );
    }

    function test_saveKeysSigs_revertWhen_invalidPubkeysLen() public {
        uint256 keysCount = 10;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
        (, bytes memory signatures) = keysSignatures(keysCount, startIndex);
        vm.expectRevert(SigningKeys.InvalidLength.selector);
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            new bytes(0),
            signatures
        );
    }

    function test_saveKeysSigs_revertWhen_EmptyKey() public {
        uint256 keysCount = 10;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
        (
            bytes memory pubkeys,
            bytes memory signatures
        ) = keysSignaturesWithZeroKey(keysCount, startIndex, 3);

        vm.expectRevert(SigningKeys.EmptyKey.selector);
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );
    }

    function testFuzz_saveKeysSigs(
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount
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
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount,
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
}

contract SigningKeysRemoveTest is SigningKeysTestBase {
    function test_removeKeysSigs() public {
        uint256 keysCount = 1;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
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

        vm.expectEmit(true, true, true, true, address(signingKeys));
        emit SigningKeys.SigningKeyRemoved(nodeOperatorId, pubkeys);
        uint256 newTotalKeysCount = signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            totalKeysCount
        );

        assertEq(newTotalKeysCount, totalKeysCount - keysCount);
    }

    function test_removeKeysSigs_noKeysAdded() public {
        uint256 keysCount = 10;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;

        vm.expectEmit(true, true, true, true, address(signingKeys));
        emit SigningKeys.SigningKeyRemoved(
            nodeOperatorId,
            new bytes(PUBKEY_LENGTH)
        );
        signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            startIndex + keysCount
        );
    }

    function test_removeKeysSigs_revertWhen_zeroKeys() public {
        uint256 keysCount = 1;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex,
            0,
            keysCount + startIndex
        );
    }

    function test_removeKeysSigs_revertWhen_keysPlusStartHigherThanTotal()
        public
    {
        uint256 keysCount = 1;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            startIndex + keysCount - 1
        );
    }

    function test_removeKeysSigs_revertWhen_totalKeysToHigh() public {
        uint256 keysCount = 1;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;

        vm.expectRevert(SigningKeys.InvalidKeysCount.selector);
        signingKeys.removeKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            uint256(type(uint32).max) + 1
        );
    }

    function testFuzz_removeKeysSigs_offsetRigth(
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount,
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
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount,
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
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount
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
}

contract SigningKeysLoadTest is SigningKeysTestBase {
    function test_loadKeys() public {
        uint256 keysCount = 10;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;
        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount,
            startIndex
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

        assertEq(loadedPubkeys, pubkeys);
    }

    function testFuzz_loadKeys(
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount
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

        assertEq(loadedPubkeys.length, keysCount * PUBKEY_LENGTH);
    }

    function testFuzz_loadKeys_empty(
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount
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

        assertEq(loadedPubkeys.length, keysCount * PUBKEY_LENGTH);
    }

    function test_loadKeysSigs() public {
        uint256 keysCount = 10;
        uint16 startIndex = 2;
        uint256 nodeOperatorId = 154;

        (bytes memory pubkeys, bytes memory signatures) = keysSignatures(
            keysCount,
            startIndex
        );
        signingKeys.saveKeysSigs(
            nodeOperatorId,
            startIndex,
            keysCount,
            pubkeys,
            signatures
        );

        (bytes memory loadedKeys, bytes memory loadedSigs) = signingKeys
            .loadKeysSigs(nodeOperatorId, startIndex, keysCount, 0);

        assertEq(loadedKeys, pubkeys);
        assertEq(loadedSigs, signatures);
    }

    function testFuzz_loadKeysSigs(
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount,
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

        (bytes memory loadedKeys, bytes memory loadedSigs) = signingKeys
            .loadKeysSigs(nodeOperatorId, startIndex, keysCount, offset);

        assertEq(loadedKeys.length, (offset + keysCount) * PUBKEY_LENGTH);
        assertEq(loadedSigs.length, (offset + keysCount) * SIGNATURE_LENGTH);
    }

    function testFuzz_loadKeysSigs_empty(
        uint64 nodeOperatorId,
        uint32 startIndex,
        uint32 keysCount,
        uint256 offset
    ) public {
        vm.assume(keysCount > 0);
        vm.assume(keysCount < 200);
        vm.assume(offset < 100);
        unchecked {
            vm.assume(startIndex + keysCount > startIndex);
        }
        vm.assume(startIndex + keysCount < type(uint32).max);

        (bytes memory loadedKeys, bytes memory loadedSigs) = signingKeys
            .loadKeysSigs(nodeOperatorId, startIndex, keysCount, offset);

        assertEq(loadedKeys.length, (offset + keysCount) * PUBKEY_LENGTH);
        assertEq(loadedSigs.length, (offset + keysCount) * SIGNATURE_LENGTH);
    }
}
