pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "src/lib/StringToUint256WithZeroMap.sol";

contract TestStringToUint256WithZeroMap is Test {

    using StringToUint256WithZeroMap for mapping(string => uint256);
    mapping(string => uint256) private map;

    function test_zeroValue() public {
        uint256 value = 0;
        map.set("key", value);
        assertEq(map.get("key"), value);
        assertTrue(map.exists("key"));
        assertFalse(map.exists("unexpected"));
    }

    function test_removeElement() public {
        uint256 value = 1;
        map.set("key", value);
        map.remove("key");
        assertFalse(map.exists("key"));
    }
}
