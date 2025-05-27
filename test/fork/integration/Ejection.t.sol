// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "../../../src/interfaces/IWithdrawalVault.sol";

import "forge-std/Test.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { ITriggerableWithdrawalsGateway } from "../../../src/interfaces/ITriggerableWithdrawalsGateway.sol";
import { IWithdrawalVault } from "../../../src/interfaces/IWithdrawalVault.sol";
import { NodeOperatorManagementProperties } from "../../../src/interfaces/ICSModule.sol";
import { Utilities } from "../../helpers/Utilities.sol";

contract EjectionTest is Test, Utilities, DeploymentFixtures {
    uint256 internal nodeOperatorId;

    uint256 internal immutable keysCount;

    constructor() {
        keysCount = 1;
    }

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();

        if (csm.isPaused()) {
            csm.resume();
        }

        nodeOperatorId = getDepositedNodeOperator(nextAddress(), keysCount);
    }

    function _prepareWithdrawalRequestData(
        bytes memory pubkey
    ) internal returns (bytes memory request) {
        request = new bytes(56); // 48 bytes for pubkey + 8 bytes for amount (0)
        assembly {
            let requestPtr := add(request, 0x20)
            let pubkeyPtr := add(pubkey, 0x20)
            mstore(requestPtr, mload(pubkeyPtr))
            mstore(add(requestPtr, 0x20), mload(add(pubkeyPtr, 0x20)))
        }
    }

    function test_voluntaryEject() public {
        uint256 initialBalance = 1 ether;
        NodeOperatorManagementProperties memory noProperties = csm
            .getNodeOperatorManagementProperties(nodeOperatorId);
        vm.deal(noProperties.managerAddress, initialBalance);
        uint256 expectedFee = IWithdrawalVault(locator.withdrawalVault())
            .getWithdrawalRequestFee();

        address withdrawalVault = locator.withdrawalVault();
        uint256 stakingModuleId = ejector.STAKING_MODULE_ID();
        bytes[] memory pubkeys = new bytes[](keysCount);

        for (uint256 i = 0; i < keysCount; i++) {
            pubkeys[i] = csm.getSigningKeys(nodeOperatorId, i, 1);
        }

        for (uint256 i = 0; i < keysCount; i++) {
            vm.expectEmit(withdrawalVault);
            emit IWithdrawalVault.WithdrawalRequestAdded(
                _prepareWithdrawalRequestData(pubkeys[i])
            );
        }

        vm.prank(noProperties.managerAddress);
        vm.startSnapshotGas("Ejector.voluntaryEject");
        ejector.voluntaryEject{ value: initialBalance }(
            nodeOperatorId,
            0,
            keysCount,
            noProperties.managerAddress
        );
        vm.stopSnapshotGas();

        vm.assertEq(
            noProperties.managerAddress.balance,
            initialBalance - expectedFee * keysCount
        );
    }

    function test_voluntaryEjectByArray() public {
        uint256 initialBalance = 1 ether;
        NodeOperatorManagementProperties memory noProperties = csm
            .getNodeOperatorManagementProperties(nodeOperatorId);
        vm.deal(noProperties.managerAddress, initialBalance);
        uint256 expectedFee = IWithdrawalVault(locator.withdrawalVault())
            .getWithdrawalRequestFee();

        address withdrawalVault = locator.withdrawalVault();
        uint256 stakingModuleId = ejector.STAKING_MODULE_ID();
        bytes[] memory pubkeys = new bytes[](keysCount);
        uint256[] memory keyIds = new uint256[](keysCount);
        uint256 expectedWithdrawalFee = IWithdrawalVault(
            locator.withdrawalVault()
        ).getWithdrawalRequestFee();

        for (uint256 i = 0; i < keysCount; i++) {
            keyIds[i] = i;
            pubkeys[i] = csm.getSigningKeys(nodeOperatorId, i, 1);
        }

        for (uint256 i = 0; i < keysCount; i++) {
            vm.expectEmit(withdrawalVault);
            emit IWithdrawalVault.WithdrawalRequestAdded(
                _prepareWithdrawalRequestData(pubkeys[i])
            );
        }
        vm.prank(noProperties.managerAddress);
        vm.startSnapshotGas("Ejector.voluntaryEjectByArray");
        ejector.voluntaryEjectByArray{ value: initialBalance }(
            nodeOperatorId,
            keyIds,
            noProperties.managerAddress
        );
        vm.stopSnapshotGas();

        vm.assertEq(
            noProperties.managerAddress.balance,
            initialBalance - expectedFee * keysCount
        );
    }
}

contract EjectionTest10Keys is EjectionTest {
    constructor() {
        keysCount = 10;
    }
}
