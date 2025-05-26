// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import { DeploymentFixtures } from "test/helpers/Fixtures.sol";
import { ForkHelpersCommon } from "./Common.sol";

contract PauseResume is Script, DeploymentFixtures, ForkHelpersCommon {
    address internal csmAdmin;
    address internal accountingAdmin;

    modifier broadcastCSMAdmin() {
        _setUp();
        csmAdmin = _prepareAdmin(address(csm));
        vm.startBroadcast(csmAdmin);
        _;
        vm.stopBroadcast();
    }

    modifier broadcastAccountingAdmin() {
        _setUp();
        accountingAdmin = _prepareAdmin(address(accounting));
        vm.startBroadcast(accountingAdmin);
        _;
        vm.stopBroadcast();
    }

    function pauseCSM() external broadcastCSMAdmin {
        csm.grantRole(csm.PAUSE_ROLE(), csmAdmin);
        csm.pauseFor(type(uint256).max);

        assertTrue(csm.isPaused());
    }

    function resumeCSM() external broadcastCSMAdmin {
        csm.grantRole(csm.RESUME_ROLE(), csmAdmin);
        csm.resume();

        assertFalse(csm.isPaused());
    }

    function pauseAccounting() external broadcastAccountingAdmin {
        accounting.grantRole(accounting.PAUSE_ROLE(), accountingAdmin);
        accounting.pauseFor(type(uint256).max);

        assertTrue(accounting.isPaused());
    }

    function resumeAccounting() external broadcastAccountingAdmin {
        accounting.grantRole(accounting.RESUME_ROLE(), accountingAdmin);
        accounting.resume();

        assertFalse(accounting.isPaused());
    }
}
