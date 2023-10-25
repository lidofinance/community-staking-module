pragma solidity 0.8.21;

library StringToUint256WithZeroMap {

    function set(mapping(string => uint256) storage self, string memory key, uint256 value) internal {
        self[key] = value + 1;
    }

    function get(mapping(string => uint256) storage self, string memory key) internal view returns (uint256) {
        require(exists(self, key), "StringToUint256WithZeroMap: key does not exist");
        return self[key] - 1;
    }

    function exists(mapping(string => uint256) storage self, string memory key) internal view returns (bool) {
        return self[key] != 0;
    }

    function remove(mapping(string => uint256) storage self, string memory key) internal {
        delete self[key];
    }
}
