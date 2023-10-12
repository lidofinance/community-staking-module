pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/lib/Uint256WithZeroMap.sol";

contract TestStringToUint256WithZeroMap is Test {

    using Uint256WithZeroMap for Uint256WithZeroMap.StringMap;
    using Uint256WithZeroMap for Uint256WithZeroMap.AddressMap;
    Uint256WithZeroMap.StringMap private stringMap;
    Uint256WithZeroMap.AddressMap private addressMap;

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

    function test_addressMapZeroValue() public {
        uint256 value = 0;
        addressMap.set(address(0), value);
        assertEq(addressMap.get(address(0)), value);
        assertTrue(addressMap.exists(address(0)));
        assertFalse(addressMap.exists(address(1)));
    }

    function test_addressMapRemoveElement() public {
        uint256 value = 1;
        addressMap.set(address(0), value);
        addressMap.remove(address(0));
        assertFalse(addressMap.exists(address(0)));
    }
}
