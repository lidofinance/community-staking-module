// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICSEarlyAccess {
    function isEligible(address addr) external view returns (bool);
    function setCurve(uint256 curveId) external;
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable;
}
