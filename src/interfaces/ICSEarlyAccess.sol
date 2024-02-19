// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICSEarlyAccess {
    function isEligible(address addr) external view returns (bool);
    function consume(address addr) external;
    function getCurve() external view returns (uint256);
    function setCurve(uint256 curveId) external;
}
