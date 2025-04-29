// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { DeployParams, DeployParamsV1 } from "../../../script/DeployBase.s.sol";
import { HashConsensus } from "../../../src/lib/base-oracle/HashConsensus.sol";
import { BaseOracle } from "../../../src/lib/base-oracle/BaseOracle.sol";
import { Slot } from "../../../src/lib/Types.sol";
import { OssifiableProxy } from "../../../src/lib/proxy/OssifiableProxy.sol";

contract V2UpgradeTestBase is Test, Utilities, DeploymentFixtures {
    DeployParamsV1 private deployParams;
    DeployParams private upgradeDeployParams;

    uint256 internal forkIdBeforeUpgrade;
    uint256 internal forkIdAfterUpgrade;

    error UpdateConfigRequired();

    function setUp() public {
        Env memory env = envVars();
        assertNotEq(env.VOTE_PREV_BLOCK, 0, "VOTE_PREV_BLOCK not set");
        forkIdBeforeUpgrade = vm.createFork(env.RPC_URL, env.VOTE_PREV_BLOCK);
        forkIdAfterUpgrade = vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();
        deployParams = parseDeployParamsV1(env.DEPLOY_CONFIG);
        if (_isEmpty(env.UPGRADE_CONFIG)) {
            revert UpdateConfigRequired();
        }
        upgradeDeployParams = parseDeployParams(env.UPGRADE_CONFIG);
    }
}

contract VoteChangesTest is V2UpgradeTestBase {
    function test_csmChanges() public {
        OssifiableProxy csmProxy = OssifiableProxy(payable(address(csm)));

        vm.selectFork(forkIdBeforeUpgrade);
        address implBefore = csmProxy.proxy__getImplementation();
        address verifierBefore = csm.getRoleMember(csm.VERIFIER_ROLE(), 0);
        address gateSealBefore = csm.getRoleMember(csm.PAUSE_ROLE(), 0);

        vm.selectFork(forkIdAfterUpgrade);
        address implAfter = csmProxy.proxy__getImplementation();

        assertNotEq(implBefore, implAfter);
        assertEq(implAfter, address(csmImpl));

        assertTrue(
            csm.hasRole(csm.CREATE_NODE_OPERATOR_ROLE(), address(vettedGate))
        );
        assertTrue(
            csm.hasRole(
                csm.CREATE_NODE_OPERATOR_ROLE(),
                address(permissionlessGate)
            )
        );

        assertFalse(csm.hasRole(csm.VERIFIER_ROLE(), verifierBefore));
        assertTrue(csm.hasRole(csm.VERIFIER_ROLE(), address(verifier)));

        assertFalse(csm.hasRole(csm.PAUSE_ROLE(), gateSealBefore));
        assertTrue(csm.hasRole(csm.PAUSE_ROLE(), address(gateSeal)));

        assertEq(csm.getRoleMemberCount(keccak256("MODULE_MANAGER_ROLE")), 0);

        assertEq(csm.getInitializedVersion(), 2);

        assertFalse(
            csm.depositQueueItem(csm.QUEUE_LEGACY_PRIORITY(), 0).isNil()
        );
    }

    function test_accountingChanges() public {
        OssifiableProxy accountingProxy = OssifiableProxy(
            payable(address(accounting))
        );

        vm.selectFork(forkIdBeforeUpgrade);
        address implBefore = accountingProxy.proxy__getImplementation();
        address gateSealBefore = accounting.getRoleMember(
            accounting.PAUSE_ROLE(),
            0
        );

        vm.selectFork(forkIdAfterUpgrade);
        address implAfter = accountingProxy.proxy__getImplementation();

        assertNotEq(implBefore, implAfter);
        assertEq(implAfter, address(accountingImpl));

        assertTrue(
            accounting.hasRole(
                accounting.SET_BOND_CURVE_ROLE(),
                address(vettedGate)
            )
        );
        assertFalse(
            accounting.hasRole(
                accounting.SET_BOND_CURVE_ROLE(),
                address(permissionlessGate)
            )
        );
        assertFalse(
            accounting.hasRole(accounting.SET_BOND_CURVE_ROLE(), address(csm))
        );

        assertFalse(
            accounting.hasRole(accounting.PAUSE_ROLE(), gateSealBefore)
        );
        assertTrue(
            accounting.hasRole(accounting.PAUSE_ROLE(), address(gateSeal))
        );

        assertEq(
            accounting.getRoleMemberCount(keccak256("ACCOUNTING_MANAGER_ROLE")),
            0
        );
        assertEq(
            accounting.getRoleMemberCount(keccak256("RESET_BOND_CURVE_ROLE")),
            0
        );

        assertEq(accounting.getInitializedVersion(), 2);

        assertTrue(
            burner.hasRole(
                burner.REQUEST_BURN_MY_STETH_ROLE(),
                address(accounting)
            )
        );
    }

    function test_feeDistributorChanges() public {
        OssifiableProxy feeDistributorProxy = OssifiableProxy(
            payable(address(feeDistributor))
        );
        vm.selectFork(forkIdBeforeUpgrade);
        address implBefore = feeDistributorProxy.proxy__getImplementation();

        vm.selectFork(forkIdAfterUpgrade);
        address implAfter = feeDistributorProxy.proxy__getImplementation();

        assertNotEq(implBefore, implAfter);
        assertEq(implAfter, address(feeDistributorImpl));

        assertEq(feeDistributor.getInitializedVersion(), 2);
        assertEq(feeDistributor.rebateRecipient(), locator.treasury());
    }

    function test_feeOracleChanges() public {
        OssifiableProxy oracleProxy = OssifiableProxy(payable(address(oracle)));
        vm.selectFork(forkIdBeforeUpgrade);
        address implBefore = oracleProxy.proxy__getImplementation();
        address gateSealBefore = oracle.getRoleMember(oracle.PAUSE_ROLE(), 0);

        vm.selectFork(forkIdAfterUpgrade);
        address implAfter = oracleProxy.proxy__getImplementation();

        assertNotEq(implBefore, implAfter);
        assertEq(implAfter, address(oracleImpl));

        assertFalse(oracle.hasRole(oracle.PAUSE_ROLE(), gateSealBefore));
        assertTrue(oracle.hasRole(oracle.PAUSE_ROLE(), address(gateSeal)));

        assertEq(address(oracle.strikes()), address(strikes));
        // strikes address is in the retyped 2nd slot
        bytes32 strikesSlotValue = vm.load(
            address(oracle),
            bytes32(uint256(1))
        );
        address strikesSlotAddress = address(
            uint160(uint256(strikesSlotValue))
        );
        bytes12 strikesSlotTail = bytes12(
            uint96(uint256(strikesSlotValue) >> 160)
        );

        assertEq(strikesSlotAddress, address(strikes));
        assertEq(strikesSlotTail, bytes12(0));

        assertEq(oracle.getContractVersion(), 2);
        assertEq(oracle.getConsensusVersion(), 3);

        assertEq(
            oracle.getRoleMemberCount(keccak256("CONTRACT_MANAGER_ROLE")),
            0
        );
    }
}
