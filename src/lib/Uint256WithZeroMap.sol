pragma solidity 0.8.21;

library Uint256WithZeroMap {

    // StringToUint256 Map

    struct StringMap {
        mapping(string => uint256) _inner;
    }

    function set(StringMap storage self, string memory key, uint256 value) internal {
        self._inner[key] = value + 1;
    }

    function get(StringMap storage self, string memory key) internal view returns (uint256) {
        require(exists(self, key), "Uint256WithZeroMap: key does not exist");
        return self._inner[key] - 1;
    }

    function exists(StringMap storage self, string memory key) internal view returns (bool) {
        return self._inner[key] != 0;
    }

    function remove(StringMap storage self, string memory key) internal {
        delete self._inner[key];
    }
}
