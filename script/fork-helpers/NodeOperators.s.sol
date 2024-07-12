// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import { DeploymentFixtures } from "test/helpers/Fixtures.sol";
import { ForkHelpersCommon } from "./Common.sol";
import "../../src/interfaces/IVEBO.sol";
import { Utilities } from "../../test/helpers/Utilities.sol";

contract NodeOperators is
    Script,
    DeploymentFixtures,
    ForkHelpersCommon,
    Utilities
{
    modifier broadcastPenaltyReporter() {
        _setUp();
        address penaltyReporter = csm.getRoleMember(
            csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(),
            0
        );
        _setBalance(penaltyReporter, "1000000000000000000");
        vm.startBroadcast(penaltyReporter);
        _;
        vm.stopBroadcast();
    }

    modifier broadcastPenaltySettler() {
        _setUp();
        address penaltySettler = csm.getRoleMember(
            csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(),
            0
        );
        _setBalance(penaltySettler, "1000000000000000000");
        vm.startBroadcast(penaltySettler);
        _;
        vm.stopBroadcast();
    }

    modifier broadcastVerifier() {
        _setUp();
        _setBalance(address(verifier), "1000000000000000000");
        vm.startBroadcast(address(verifier));
        _;
        vm.stopBroadcast();
    }

    modifier broadcastStakingRouter() {
        _setUp();
        _setBalance(address(stakingRouter), "1000000000000000000");
        vm.startBroadcast(address(stakingRouter));
        _;
        vm.stopBroadcast();
    }

    function deposit(uint256 depositCount) external broadcastStakingRouter {
        (, , uint256 depositableValidatorsCount) = csm
            .getStakingModuleSummary();
        if (depositCount > depositableValidatorsCount) {
            depositCount = depositableValidatorsCount;
        }
        csm.obtainDepositData(depositCount, "");
    }

    function unvet(
        uint256 noId,
        uint256 vettedKeysCount
    ) external broadcastStakingRouter {
        csm.decreaseVettedSigningKeysCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(vettedKeysCount)))
        );
    }

    function exit(
        uint256 noId,
        uint256 exitedKeysCount
    ) external broadcastStakingRouter {
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(exitedKeysCount)))
        );
    }

    function stuck(
        uint256 noId,
        uint256 stuckKeysCount
    ) external broadcastStakingRouter {
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(stuckKeysCount)))
        );
    }

    function withdraw(
        uint256 noId,
        uint256 keyIndex,
        uint256 amount
    ) external broadcastVerifier {
        csm.submitWithdrawal(noId, keyIndex, amount);
    }

    function slash(uint256 noId, uint256 keyIndex) external broadcastVerifier {
        csm.submitInitialSlashing(noId, keyIndex);
    }

    function targetLimit(
        uint256 noId,
        uint256 targetLimitMode,
        uint256 limit
    ) external broadcastStakingRouter {
        csm.updateTargetValidatorsLimits(noId, targetLimitMode, limit);
    }

    function reportStealing(
        uint256 noId,
        uint256 amount
    ) external broadcastPenaltyReporter {
        csm.reportELRewardsStealingPenalty(noId, "", amount);
    }

    function cancelStealing(
        uint256 noId,
        uint256 amount
    ) external broadcastPenaltyReporter {
        csm.cancelELRewardsStealingPenalty(noId, amount);
    }

    function settleStealing(uint256 noId) external broadcastPenaltySettler {
        uint256[] memory noIds = new uint256[](1);
        noIds[0] = noId;
        csm.settleELRewardsStealingPenalty(noIds);
    }

    function exitRequest(
        uint256 noId,
        uint256 validatorIndex,
        bytes calldata validatorPubKey
    ) external {
        _setUp();
        IVEBO vebo = IVEBO(locator.validatorsExitBusOracle());
        bytes memory data;

        bytes3 moduleId = bytes3(uint24(4));
        bytes5 nodeOpId = bytes5(uint40(noId));
        bytes8 validatorIndex = bytes8(uint64(validatorIndex));

        (, uint256 refSlot, , ) = vebo.getConsensusReport();
        uint256 reportRefSlot = refSlot + 1;

        data = abi.encodePacked(
            moduleId,
            nodeOpId,
            validatorIndex,
            validatorPubKey
        );
        IVEBO.ReportData memory report = IVEBO.ReportData({
            consensusVersion: vebo.getConsensusVersion(),
            refSlot: reportRefSlot,
            requestsCount: 1,
            dataFormat: 1,
            data: data
        });

        address consensus = vebo.getConsensusContract();
        _setBalance(consensus, "1000000000000000000");

        vm.startBroadcast(consensus);
        vebo.submitConsensusReport(
            keccak256(abi.encode(report)),
            reportRefSlot,
            block.timestamp + 1 days
        );
        vm.stopBroadcast();

        address veboSubmitter = _prepareVEBOSubmitter(vebo);
        vm.startBroadcast(veboSubmitter);
        vebo.submitReportData(report, vebo.getContractVersion());
        vm.stopBroadcast();
    }

    function _prepareVEBOSubmitter(
        IVEBO vebo
    ) internal returns (address veboSubmitter) {
        address veboAdmin = _prepareAdmin(address(vebo));
        veboSubmitter = nextAddress();

        vm.startBroadcast(veboAdmin);
        vebo.grantRole(vebo.SUBMIT_DATA_ROLE(), address(veboSubmitter));
        vm.stopBroadcast();

        _setBalance(address(veboSubmitter), "1000000000000000000");
    }
}
