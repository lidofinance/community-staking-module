// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { CSEjector } from "../src/CSEjector.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { ICSEjector, ExitPenaltyInfo } from "../src/interfaces/ICSEjector.sol";
import { IStakingModule } from "../src/interfaces/IStakingModule.sol";
import { ICSModule, NodeOperator, NodeOperatorManagementProperties } from "../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { CSMMock, AccountingMock } from "./helpers/mocks/CSMMock.sol";
import { CSParametersRegistryMock } from "./helpers/mocks/CSParametersRegistryMock.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSEjectorTestBase is Test, Utilities, Fixtures {
    CSEjector internal ejector;
    CSMMock internal csm;
    address internal stranger;
    address internal admin;
    ICSAccounting internal accounting;
    CSParametersRegistryMock internal parametersRegistry;
    uint256 internal constant noId = 0;

    function setUp() public {
        csm = new CSMMock();
        parametersRegistry = CSParametersRegistryMock(
            address(csm.PARAMETERS_REGISTRY())
        );
        accounting = CSMMock(csm).accounting();
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        ejector = new CSEjector(
            address(csm),
            address(parametersRegistry),
            address(accounting)
        );
        _enableInitializers(address(ejector));
        ejector.initialize(admin);
        bytes32 role = ejector.BAD_PERFORMER_EJECTOR_ROLE();
        vm.prank(admin);
        ejector.grantRole(role, address(this));
    }
}

contract CSEjectorTestMisc is CSEjectorTestBase {
    function test_constructor() public {
        ejector = new CSEjector(
            address(csm),
            address(parametersRegistry),
            address(accounting)
        );
        assertEq(address(ejector.MODULE()), address(csm));
        assertEq(
            address(ejector.PARAMETERS_REGISTRY()),
            address(parametersRegistry)
        );
        assertEq(address(ejector.ACCOUNTING()), address(accounting));
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSEjector.ZeroModuleAddress.selector);
        new CSEjector(
            address(0),
            address(parametersRegistry),
            address(accounting)
        );
    }

    function test_constructor_RevertWhen_ZeroParametersRegistryAddress()
        public
    {
        vm.expectRevert(ICSEjector.ZeroParametersRegistryAddress.selector);
        new CSEjector(address(csm), address(0), address(accounting));
    }

    function test_constructor_RevertWhen_ZeroAccountingAddress() public {
        vm.expectRevert(ICSEjector.ZeroAccountingAddress.selector);
        new CSEjector(address(csm), address(parametersRegistry), address(0));
    }

    function test_initializer() public {
        ejector = new CSEjector(
            address(csm),
            address(parametersRegistry),
            address(accounting)
        );
        _enableInitializers(address(ejector));

        ejector.initialize(admin);

        assertEq(ejector.getRoleMemberCount(ejector.DEFAULT_ADMIN_ROLE()), 1);
        assertEq(ejector.getRoleMember(ejector.DEFAULT_ADMIN_ROLE(), 0), admin);
    }

    function test_initializer_RevertWhen_ZeroAdminAddress() public {
        ejector = new CSEjector(
            address(csm),
            address(parametersRegistry),
            address(accounting)
        );
        _enableInitializers(address(ejector));

        vm.expectRevert(ICSEjector.ZeroAdminAddress.selector);
        ejector.initialize(address(0));
    }

    function test_pauseFor() public {
        vm.startPrank(admin);
        ejector.grantRole(ejector.PAUSE_ROLE(), admin);

        vm.expectEmit(address(ejector));
        emit PausableUntil.Paused(100);
        ejector.pauseFor(100);

        vm.stopPrank();
        assertTrue(ejector.isPaused());
    }

    function test_pauseFor_revertWhen_noRole() public {
        expectRoleRevert(admin, ejector.PAUSE_ROLE());
        vm.prank(admin);
        ejector.pauseFor(100);
    }

    function test_resume() public {
        vm.startPrank(admin);
        ejector.grantRole(ejector.PAUSE_ROLE(), admin);
        ejector.grantRole(ejector.RESUME_ROLE(), admin);
        ejector.pauseFor(100);

        vm.expectEmit(address(ejector));
        emit PausableUntil.Resumed();
        ejector.resume();

        vm.stopPrank();
        assertFalse(ejector.isPaused());
    }

    function test_resume_revertWhen_noRole() public {
        expectRoleRevert(admin, ejector.RESUME_ROLE());
        vm.prank(admin);
        ejector.resume();
    }
}

contract CSEjectorTestVoluntaryEject is CSEjectorTestBase {
    function test_voluntaryEject() public {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);

        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorManagementProperties(
            NodeOperatorManagementProperties(
                address(this),
                address(this),
                false
            )
        );

        uint256 exitType = ejector.VOLUNTARY_EXIT_TYPE_ID();
        ejector.voluntaryEject(noId, keyIndex);

        // TODO: check ejection contract call
    }

    function test_voluntaryEject_revertWhen_senderIsNotEligible() public {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);

        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorManagementProperties(
            NodeOperatorManagementProperties(stranger, stranger, false)
        );

        vm.expectRevert(ICSEjector.SenderIsNotEligible.selector);
        ejector.voluntaryEject(noId, keyIndex);
    }

    function test_voluntaryEject_revertWhen_senderIsNotEligible_managerAddress()
        public
    {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);

        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorManagementProperties(
            NodeOperatorManagementProperties(address(this), stranger, false)
        );

        vm.expectRevert(ICSEjector.SenderIsNotEligible.selector);
        ejector.voluntaryEject(noId, keyIndex);
    }

    function test_voluntaryEject_revertWhen_senderIsNotEligible_extendedManager_fromRewardAddress()
        public
    {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);

        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorManagementProperties(
            NodeOperatorManagementProperties(stranger, address(this), true)
        );

        vm.expectRevert(ICSEjector.SenderIsNotEligible.selector);
        ejector.voluntaryEject(noId, keyIndex);
    }

    function test_voluntaryEject_revertWhen_signingKeysInvalidOffset() public {
        uint256 keyIndex = 1;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setNodeOperatorManagementProperties(
            NodeOperatorManagementProperties(
                address(this),
                address(this),
                false
            )
        );

        vm.expectRevert(ICSEjector.SigningKeysInvalidOffset.selector);
        ejector.voluntaryEject(noId, keyIndex);
    }

    function test_voluntaryEject_revertWhen_signingKeysInvalidOffset_nonDepositedKey()
        public
    {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);

        csm.mock_setNodeOperatorTotalDepositedKeys(0);
        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setNodeOperatorManagementProperties(
            NodeOperatorManagementProperties(
                address(this),
                address(this),
                false
            )
        );

        vm.expectRevert(ICSEjector.SigningKeysInvalidOffset.selector);
        ejector.voluntaryEject(noId, keyIndex);
    }
}

contract CSEjectorTestEjectBadPerformer is CSEjectorTestBase {
    function test_ejectBadPerformer() public {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);
        uint256 penalty = parametersRegistry.getBadPerformancePenalty(0);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        uint256 exitType = ejector.STRIKES_EXIT_TYPE_ID();
        vm.expectEmit(address(ejector));
        emit ICSEjector.BadPerformancePenaltyProcessed(noId, pubkey, penalty);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);

        // TODO: check ejection contract call
    }

    function test_ejectBadPerformer_doubleCall() public {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);
        uint256 penalty = parametersRegistry.getBadPerformancePenalty(0);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        uint256 exitType = ejector.STRIKES_EXIT_TYPE_ID();
        vm.expectEmit(address(ejector));
        emit ICSEjector.BadPerformancePenaltyProcessed(noId, pubkey, penalty);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);

        parametersRegistry.setBadPerformancePenalty(0, penalty + 1);

        vm.recordLogs();
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(
            entries.length,
            0,
            "ejector should not emit event on double call"
        );

        assertEq(
            ejector
                .getDelayedExitPenaltyInfo(noId, pubkey)
                .strikesPenalty
                .value,
            penalty,
            "penalty should not be updated"
        );
    }

    function test_ejectBadPerformer_NoPenalty() public {
        uint256 keyIndex = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);
        parametersRegistry.setBadPerformancePenalty(0, 0);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        uint256 exitType = ejector.STRIKES_EXIT_TYPE_ID();
        vm.expectEmit(address(ejector));
        emit ICSEjector.BadPerformancePenaltyProcessed(noId, pubkey, 0);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);

        // TODO: check ejection contract call
    }

    function test_ejectBadPerformer_RevertWhen_NoNodeOperator() public {
        vm.expectRevert(ICSEjector.NodeOperatorDoesNotExist.selector);
        ejector.ejectBadPerformer(0, 0, 0);
    }

    function test_ejectBadPerformer_RevertWhen_InvalidKeyIndexOffset() public {
        uint256 keyIndex = 0;
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(0);
        csm.mock_setNodeOperatorsCount(1);

        vm.expectRevert(ICSEjector.SigningKeysInvalidOffset.selector);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
    }

    function test_ejectBadPerformer_RevertWhen_NotEnoughStrikesToEject()
        public
    {
        uint256 keyIndex = 0;
        uint256[] memory strikesData = new uint256[](2);
        strikesData[0] = 1;
        strikesData[1] = 2;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        vm.expectRevert(ICSEjector.NotEnoughStrikesToEject.selector);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
    }

    function test_ejectBadPerformer_RevertWhen_AlreadyWithdrawn() public {
        uint256 keyIndex = 0;
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);
        csm.mock_setIsValidatorWithdrawn(true);

        vm.expectRevert(ICSEjector.AlreadyWithdrawn.selector);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
    }
}

contract CSEjectorTestProcessExitDelayReport is CSEjectorTestBase {
    function test_processExitDelayReport() public {
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId) + 1;
        bytes memory publicKey = randomBytes(48);
        uint256 penalty = parametersRegistry.getExitDelayPenalty(0);

        vm.expectEmit(address(ejector));
        emit ICSEjector.ValidatorExitDelayProcessed(noId, publicKey, penalty);
        vm.prank(address(csm));
        ejector.processExitDelayReport(noId, publicKey, eligibleToExit);

        ExitPenaltyInfo memory exitPenaltyInfo = ejector
            .getDelayedExitPenaltyInfo(noId, publicKey);
        assertEq(exitPenaltyInfo.delayPenalty.value, penalty);
    }

    function test_processExitDelayReport_revertWhen_notApplicable() public {
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId) + 1;
        bytes memory publicKey = randomBytes(48);

        vm.expectRevert(ICSEjector.ValidatorExitDelayNotApplicable.selector);
        vm.prank(address(csm));
        ejector.processExitDelayReport(
            noId,
            publicKey,
            eligibleToExit - 1 seconds
        );
    }

    function test_processExitDelayReport_alreadyReported() public {
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId) + 1;
        bytes memory publicKey = randomBytes(48);

        vm.prank(address(csm));
        ejector.processExitDelayReport(noId, publicKey, eligibleToExit);

        vm.prank(address(csm));
        vm.recordLogs();
        ejector.processExitDelayReport(noId, publicKey, eligibleToExit + 1);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_processExitDelayReport_alreadyReported_changePenalty()
        public
    {
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId) + 1;
        bytes memory publicKey = randomBytes(48);
        uint256 prevExitDelayPenalty = parametersRegistry.getExitDelayPenalty(
            0
        );
        vm.prank(address(csm));
        ejector.processExitDelayReport(noId, publicKey, eligibleToExit);

        parametersRegistry.setExitDelayPenalty(0, prevExitDelayPenalty + 1);

        vm.prank(address(csm));
        vm.recordLogs();
        ejector.processExitDelayReport(noId, publicKey, eligibleToExit + 1);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);

        assertEq(
            ejector
                .getDelayedExitPenaltyInfo(noId, publicKey)
                .delayPenalty
                .value,
            prevExitDelayPenalty,
            "exit delay penalty should not be updated"
        );
    }

    function test_processExitDelayReport_revertWhen_SenderIsNotModule() public {
        uint256 eligibleToExit = csm.exitDeadlineThreshold(noId) + 1;
        bytes memory publicKey = randomBytes(48);

        vm.prank(stranger);
        vm.expectRevert(ICSEjector.SenderIsNotModule.selector);
        ejector.processExitDelayReport(noId, publicKey, eligibleToExit);
    }
}

contract CSEjectorTestProcessTriggeredExit is CSEjectorTestBase {
    function test_processTriggeredExit() public {
        bytes memory publicKey = randomBytes(48);
        uint256 paidFee = 0.1 ether;
        uint256 exitType = ejector.STRIKES_EXIT_TYPE_ID();

        vm.expectEmit(address(ejector));
        emit ICSEjector.TriggeredExitFeeRecorded(
            noId,
            exitType,
            publicKey,
            paidFee
        );
        vm.prank(address(csm));
        ejector.processTriggeredExit(noId, publicKey, paidFee, exitType);

        ExitPenaltyInfo memory exitPenaltyInfo = ejector
            .getDelayedExitPenaltyInfo(noId, publicKey);
        assertEq(exitPenaltyInfo.withdrawalRequestFee, paidFee);
    }

    function test_processTriggeredExit_voluntaryExit() public {
        bytes memory publicKey = randomBytes(48);
        uint256 paidFee = 0.1 ether;
        uint256 exitType = ejector.VOLUNTARY_EXIT_TYPE_ID();

        vm.recordLogs();

        vm.prank(address(csm));
        ejector.processTriggeredExit(noId, publicKey, paidFee, exitType);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);

        ExitPenaltyInfo memory exitPenaltyInfo = ejector
            .getDelayedExitPenaltyInfo(noId, publicKey);
        assertEq(exitPenaltyInfo.withdrawalRequestFee, 0);
    }

    function test_processTriggeredExit_doubleReporting() public {
        bytes memory publicKey = randomBytes(48);
        uint256 initialPaidFee = 0.1 ether;
        uint256 newPaidFee = 0.2 ether;
        uint256 exitType = ejector.STRIKES_EXIT_TYPE_ID();

        vm.prank(address(csm));
        ejector.processTriggeredExit(noId, publicKey, initialPaidFee, exitType);

        vm.recordLogs();

        vm.prank(address(csm));
        ejector.processTriggeredExit(noId, publicKey, newPaidFee, exitType);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);

        ExitPenaltyInfo memory exitPenaltyInfo = ejector
            .getDelayedExitPenaltyInfo(noId, publicKey);
        assertEq(
            exitPenaltyInfo.withdrawalRequestFee,
            initialPaidFee,
            "paid fee should not be updated"
        );
    }

    function test_processTriggeredExit_feeMoreThanMax() public {
        bytes memory publicKey = randomBytes(48);
        uint256 maxFee = parametersRegistry.getMaxWithdrawalRequestFee(0);
        uint256 paidFee = maxFee + 0.1 ether;
        uint256 exitType = ejector.STRIKES_EXIT_TYPE_ID();

        vm.prank(address(csm));
        ejector.processTriggeredExit(noId, publicKey, paidFee, exitType);

        ExitPenaltyInfo memory exitPenaltyInfo = ejector
            .getDelayedExitPenaltyInfo(noId, publicKey);
        assertEq(
            exitPenaltyInfo.withdrawalRequestFee,
            maxFee,
            "paid fee should be capped to max fee"
        );
    }
}
