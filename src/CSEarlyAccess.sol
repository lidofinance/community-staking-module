// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "./interfaces/ICSModule.sol";
import "./interfaces/ICSAccounting.sol";

contract CSEarlyAccess {
    mapping(address => bool) private earlyAccessList;
    uint256 private curveId;
    ICSModule public csm;
    ICSAccounting public accounting;

    error InvalidCurveId();

    constructor(address csmAddress, address accountingAddress) {
        csm = ICSModule(csmAddress);
        accounting = ICSAccounting(accountingAddress);
    }

    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable onlyEligible {
        _consume();
        uint256 nodeOperatorId = csm.createNodeOperator();
        accounting.setBondCurve(nodeOperatorId, curveId);
        uint256 bond = accounting.getRequiredBondForNextKeys(nodeOperatorId, keysCount);
        csm.addValidatorKeysETH{ value: msg.value }(nodeOperatorId, keysCount, publicKeys, signatures);
    }

    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable onlyEligible {
        _consume();
        uint256 nodeOperatorId = csm.createNodeOperator();
        accounting.setBondCurve(nodeOperatorId, curveId);
        csm.addValidatorKeysETH(nodeOperatorId, keysCount, publicKeys, signatures);
    }

    function addNodeOperatorStETHWithPermit(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external payable onlyEligible {
        _consume();
        uint256 nodeOperatorId = csm.createNodeOperator();
        accounting.setBondCurve(nodeOperatorId, curveId);
        csm.addValidatorKeysStETHWithPermit(nodeOperatorId, keysCount, publicKeys, signatures, permit);
    }

    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures
    ) external payable onlyEligible {
        _consume();
        uint256 nodeOperatorId = csm.createNodeOperator();
        accounting.setBondCurve(nodeOperatorId, curveId);
        csm.addValidatorKeysWstETH(nodeOperatorId, keysCount, publicKeys, signatures);
    }

    function addNodeOperatorWstETHWithPermit(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        ICSAccounting.PermitInput calldata permit
    ) external payable onlyEligible {
        _consume();
        uint256 nodeOperatorId = csm.createNodeOperator();
        accounting.setBondCurve(nodeOperatorId, curveId);
        csm.addValidatorKeysWstETHWithPermit(nodeOperatorId, keysCount, publicKeys, signatures, permit);
    }

    function isEligible(address sender) public view returns (bool) {
        // TODO: implement eligibility check
        return true;
    }

    function _consume() internal {
        require(!earlyAccessList[msg.sender], "CSEarlyAccess: already consumed");
        earlyAccessList[msg.sender] = true;
    }

    function setCurve(uint256 _curveId) external {
        require(accounting.getCurveInfo(_curveId).points.length != 0, "CSEarlyAccess: invalid curve id");
        curveId = _curveId;
    }

    modifier onlyEligible() {
        require(isEligible(msg.sender), "CSEarlyAccess: not eligible");
        _;
    }
}
