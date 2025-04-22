// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { ICSEjector } from "../../../src/interfaces/ICSEjector.sol";
import { ICSModule } from "../../../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";
import { ExitPenaltyInfo } from "../../../src/interfaces/ICSEjector.sol";

contract EjectorMock is ICSEjector {
    ICSModule public MODULE;
    ICSAccounting public ACCOUNTING;
    bytes32 public PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public BAD_PERFORMER_EJECTOR_ROLE =
        keccak256("BAD_PERFORMER_EJECTOR_ROLE");
    ExitPenaltyInfo internal penaltyInfo;

    constructor(address _module) {
        MODULE = ICSModule(_module);
    }

    function pauseFor(uint256 duration) external {}

    function resume() external {}

    function processExitDelayReport(
        uint256,
        bytes calldata,
        uint256
    ) external {}

    function processTriggeredExit(
        uint256,
        bytes calldata,
        uint256,
        uint256
    ) external {}

    function voluntaryEject(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external payable {}

    function ejectBadPerformer(uint256, uint256, uint256) external payable {}

    function isValidatorExitDelayPenaltyApplicable(
        uint256,
        bytes calldata,
        uint256
    ) external view returns (bool) {
        return false;
    }

    function mock_setDelayedExitPenaltyInfo(
        ExitPenaltyInfo memory _penaltyInfo
    ) external {
        penaltyInfo = _penaltyInfo;
    }

    function getDelayedExitPenaltyInfo(
        uint256,
        bytes calldata
    ) external view returns (ExitPenaltyInfo memory) {
        return penaltyInfo;
    }
}
