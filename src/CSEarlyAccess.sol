// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "./interfaces/ICSModule.sol";

contract CSEarlyAccess {
    mapping(address => bool) private earlyAccessList;
    uint256 private curveId;

    error InvalidCurveId();

    function isEligible(address sender) external view returns (bool) {
        return true;
    }

    function consume(address sender) external {
        require(!earlyAccessList[sender], "CSEarlyAccess: already consumed");
        earlyAccessList[sender] = true;
    }

    function getCurve() external view returns (uint256) {
        return curveId;
    }

    function setCurve(uint256 _curveId) external {
        curveId = _curveId;
    }
}
