// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import { DeploymentFixtures } from "test/helpers/Fixtures.sol";
import { ForkHelpersCommon } from "./Common.sol";
import "../../src/interfaces/IVEBO.sol";
import { Utilities } from "../../test/helpers/Utilities.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { NodeOperator } from "../../src/interfaces/ICSModule.sol";

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
        _setBalance(penaltyReporter);
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
        _setBalance(penaltySettler);
        vm.startBroadcast(penaltySettler);
        _;
        vm.stopBroadcast();
    }

    modifier broadcastVerifier() {
        _setUp();
        _setBalance(address(verifier));
        vm.startBroadcast(address(verifier));
        _;
        vm.stopBroadcast();
    }

    modifier broadcastStakingRouter() {
        _setUp();
        _setBalance(address(stakingRouter));
        vm.startBroadcast(address(stakingRouter));
        _;
        vm.stopBroadcast();
    }

    modifier broadcastStranger() {
        _setUp();
        address stranger = nextAddress("stranger");
        _setBalance(stranger);
        vm.startBroadcast(stranger);
        _;
        vm.stopBroadcast();
    }

    function deposit(uint256 depositCount) external broadcastStakingRouter {
        (, , uint256 depositableValidatorsCount) = csm
            .getStakingModuleSummary();
        if (depositCount > depositableValidatorsCount) {
            depositCount = depositableValidatorsCount;
        }
        (, uint256 totalDepositedValidators, ) = csm.getStakingModuleSummary();

        csm.obtainDepositData(depositCount, "");

        (, uint256 totalDepositedValidatorsAfter, ) = csm
            .getStakingModuleSummary();
        assertEq(
            totalDepositedValidatorsAfter,
            totalDepositedValidators + depositCount
        );
    }

    function unvet(
        uint256 noId,
        uint256 vettedKeysCount
    ) external broadcastStakingRouter {
        csm.decreaseVettedSigningKeysCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(vettedKeysCount)))
        );

        assertEq(csm.getNodeOperator(noId).totalVettedKeys, vettedKeysCount);
    }

    function exit(
        uint256 noId,
        uint256 exitedKeysCount
    ) external broadcastStakingRouter {
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(exitedKeysCount)))
        );

        assertEq(csm.getNodeOperator(noId).totalExitedKeys, exitedKeysCount);
    }

    function stuck(
        uint256 noId,
        uint256 stuckKeysCount
    ) external broadcastStakingRouter {
        csm.updateExitedValidatorsCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(stuckKeysCount)))
        );

        assertEq(
            csm.getNodeOperator(noId).stuckValidatorsCount,
            stuckKeysCount
        );
    }

    function withdraw(
        uint256 noId,
        uint256 keyIndex,
        uint256 amount
    ) external broadcastVerifier {
        uint256 withdrawnBefore = csm.getNodeOperator(noId).totalWithdrawnKeys;

        csm.submitWithdrawal(noId, keyIndex, amount, false);

        assertTrue(csm.isValidatorWithdrawn(noId, keyIndex));
        assertEq(
            csm.getNodeOperator(noId).totalWithdrawnKeys,
            withdrawnBefore + 1
        );
    }

    function slash(uint256 noId, uint256 keyIndex) external broadcastVerifier {
        csm.submitInitialSlashing(noId, keyIndex);
        assertTrue(csm.isValidatorSlashed(noId, keyIndex));
    }

    function targetLimit(
        uint256 noId,
        uint256 targetLimitMode,
        uint256 limit
    ) external broadcastStakingRouter {
        csm.updateTargetValidatorsLimits(noId, targetLimitMode, limit);

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(no.targetLimit, limit);
        assertEq(no.targetLimitMode, targetLimitMode);
    }

    function reportStealing(
        uint256 noId,
        uint256 amount
    ) external broadcastPenaltyReporter {
        uint256 lockedBefore = accounting.getActualLockedBond(noId);

        csm.reportELRewardsStealingPenalty(
            noId,
            blockhash(block.number),
            amount
        );

        uint256 lockedAfter = accounting.getActualLockedBond(noId);
        assertEq(
            lockedAfter,
            lockedBefore + amount + csm.EL_REWARDS_STEALING_FINE()
        );
    }

    function cancelStealing(
        uint256 noId,
        uint256 amount
    ) external broadcastPenaltyReporter {
        uint256 lockedBefore = accounting.getActualLockedBond(noId);

        csm.cancelELRewardsStealingPenalty(noId, amount);

        uint256 lockedAfter = accounting.getActualLockedBond(noId);
        assertEq(lockedAfter, lockedBefore - amount);
    }

    function settleStealing(uint256 noId) external broadcastPenaltySettler {
        uint256[] memory noIds = new uint256[](1);
        noIds[0] = noId;
        csm.settleELRewardsStealingPenalty(noIds);

        assertEq(accounting.getActualLockedBond(noId), 0);
    }

    function compensateStealing(
        uint256 noId,
        uint256 amount
    ) external broadcastStranger {
        uint256 lockedBefore = accounting.getActualLockedBond(noId);

        csm.compensateELRewardsStealingPenalty{ value: amount }(noId);

        assertEq(accounting.getActualLockedBond(noId), lockedBefore - amount);
    }

    function exitRequest(
        uint256 noId,
        uint256 validatorIndex,
        bytes calldata validatorPubKey
    ) external {
        _setUp();
        IVEBO vebo = IVEBO(locator.validatorsExitBusOracle());
        bytes memory data;

        bytes3 moduleId = bytes3(uint24(_getCSMId()));
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
        _setBalance(consensus);

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

        _setBalance(address(veboSubmitter));
    }

    error CSMNotFound();

    function _getCSMId() internal view returns (uint256) {
        uint256[] memory ids = stakingRouter.getStakingModuleIds();
        for (uint256 i = ids.length - 1; i > 0; i--) {
            IStakingRouter.StakingModule memory module = stakingRouter
                .getStakingModule(ids[i]);
            if (module.stakingModuleAddress == address(csm)) {
                return ids[i];
            }
        }
        revert CSMNotFound();
    }
}