pragma solidity 0.8.21;

library StringToUint256WithZeroMap {

    function set(mapping(string => uint256) storage mapStorage, string memory key, uint256 value) internal {
        mapStorage[key] = value + 1;
    }

    function get(mapping(string => uint256) storage mapStorage, string memory key) internal view returns (uint256) {
        require(exists(mapStorage, key), "StringToUint256WithZeroMap: key does not exist");
        return mapStorage[key] - 1;
    }

    function exists(mapping(string => uint256) storage mapStorage, string memory key) internal view returns (bool) {
        return mapStorage[key] != 0;
    }

    function remove(mapping(string => uint256) storage mapStorage, string memory key) internal {
        delete mapStorage[key];
    }
}
