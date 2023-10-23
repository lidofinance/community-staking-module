pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/lib/Uint256WithZeroMap.sol";

contract TestStringToUint256WithZeroMap is Test {

    using Uint256WithZeroMap for Uint256WithZeroMap.StringMap;
    Uint256WithZeroMap.StringMap private stringMap;

    function test_stringMapZeroValue() public {
        uint256 value = 0;
        stringMap.set("key", value);
        assertEq(stringMap.get("key"), value);
        assertTrue(stringMap.exists("key"));
        assertFalse(stringMap.exists("unexpected"));
    }

    function test_stringMapRemoveElement() public {
        uint256 value = 1;
        stringMap.set("key", value);
        stringMap.remove("key");
        assertFalse(stringMap.exists("key"));
    }
}
