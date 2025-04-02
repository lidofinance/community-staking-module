// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { CSEjector } from "../src/CSEjector.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { ICSEjector } from "../src/interfaces/ICSEjector.sol";
import { IStakingModule } from "../src/interfaces/IStakingModule.sol";
import { ICSModule, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { CSMMock, AccountingMock } from "./helpers/mocks/CSMMock.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract CSEjectorTest is Test, Utilities, Fixtures {
    CSEjector internal ejector;
    CSMMock internal csm;
    address internal stranger;
    address internal admin;
    ICSAccounting internal accounting;

    function setUp() public {
        csm = new CSMMock();
        accounting = CSMMock(csm).accounting();
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        ejector = new CSEjector(address(csm));
        _enableInitializers(address(ejector));
        ejector.initialize(admin);
        bytes32 role = ejector.BAD_PERFORMER_EJECTOR_ROLE();
        vm.prank(admin);
        ejector.grantRole(role, address(this));
    }

    function test_constructor() public {
        ejector = new CSEjector(address(csm));
        assertEq(address(ejector.MODULE()), address(csm));
        assertEq(address(ejector.ACCOUNTING()), address(csm.accounting()));
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSEjector.ZeroModuleAddress.selector);
        new CSEjector(address(0));
    }

    function test_initializer() public {
        ejector = new CSEjector(address(csm));
        _enableInitializers(address(ejector));

        ejector.initialize(admin);

        assertEq(ejector.getRoleMemberCount(ejector.DEFAULT_ADMIN_ROLE()), 1);
        assertEq(ejector.getRoleMember(ejector.DEFAULT_ADMIN_ROLE(), 0), admin);
    }

    function test_initializer_RevertWhen_ZeroAdminAddress() public {
        ejector = new CSEjector(address(csm));
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

    function test_ejectBadPerformer() public {
        uint256 keyIndex = 0;
        uint256 noId = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);
        uint256 penalty = csm.PARAMETERS_REGISTRY().getBadPerformancePenalty(0);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        vm.expectEmit(address(ejector));
        emit ICSEjector.EjectionSubmitted(noId, keyIndex, pubkey);
        vm.expectCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, penalty)
        );
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);

        assertTrue(ejector.isValidatorEjected(noId, keyIndex));

        // TODO: check ejection contract call
    }

    function test_ejectBadPerformer_NoPenalty() public {
        uint256 keyIndex = 0;
        uint256 noId = 0;
        bytes memory pubkey = csm.getSigningKeys(0, 0, 1);
        csm.PARAMETERS_REGISTRY().setBadPerformancePenalty(0, 0);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        vm.expectEmit(address(ejector));
        emit ICSEjector.EjectionSubmitted(noId, keyIndex, pubkey);
        expectNoCall(
            address(accounting),
            abi.encodeWithSelector(accounting.penalize.selector, noId, 0)
        );
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);

        assertTrue(ejector.isValidatorEjected(noId, keyIndex));

        // TODO: check ejection contract call
    }

    function test_ejectBadPerformer_RevertWhen_NoNodeOperator() public {
        vm.expectRevert(ICSEjector.NodeOperatorDoesNotExist.selector);
        ejector.ejectBadPerformer(0, 0, 0);
    }

    function test_ejectBadPerformer_RevertWhen_InvalidKeyIndexOffset() public {
        uint256 keyIndex = 0;
        uint256 noId = 0;
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(0);
        csm.mock_setNodeOperatorsCount(1);

        vm.expectRevert(ICSEjector.SigningKeysInvalidOffset.selector);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
    }

    function test_ejectBadPerformer_RevertWhen_AlreadyEjected() public {
        uint256 keyIndex = 0;
        uint256 noId = 0;
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 2;
        strikesData[2] = 3;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
        vm.expectRevert(ICSEjector.AlreadyEjected.selector);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
    }

    function test_ejectBadPerformer_RevertWhen_AlreadyWithdrawn() public {
        uint256 keyIndex = 0;
        uint256 noId = 0;
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

    function test_ejectBadPerformer_RevertWhen_NotEnoughStrikesToEject()
        public
    {
        uint256 keyIndex = 0;
        uint256 noId = 0;
        uint256[] memory strikesData = new uint256[](2);
        strikesData[0] = 1;
        strikesData[1] = 2;

        csm.mock_setNodeOperatorTotalDepositedKeys(1);
        csm.mock_setNodeOperatorsCount(1);

        vm.expectRevert(ICSEjector.NotEnoughStrikesToEject.selector);
        ejector.ejectBadPerformer(noId, keyIndex, strikesData.length);
    }
}
