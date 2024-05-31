// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../helpers/Utilities.sol";
import { DeploymentFixtures } from "../helpers/Fixtures.sol";
import "../helpers/MerkleTree.sol";

contract EarlyAdoptionTest is Test, Utilities, DeploymentFixtures {
    address internal nodeOperator;
    bool internal noAvailableAccounts;
    bytes32[] proof;

    function setUp() public {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment(env.DEPLOY_CONFIG);

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        vm.stopPrank();
        if (csm.isPaused()) csm.resume();

        if (vm.isFile("localhost.json")) {
            string memory forkConfig = vm.readFile("localhost.json");
            address[] memory availableAccounts = vm.parseJsonAddressArray(
                forkConfig,
                ".available_accounts"
            );
            nodeOperator = availableAccounts[0];

            MerkleTree tree = new MerkleTree();
            for (uint256 i = 0; i < availableAccounts.length; i++) {
                tree.pushLeaf(abi.encode(availableAccounts[i]));
            }
            proof = tree.getProof(0);
        } else noAvailableAccounts = true;
    }

    function test_createNodeOperatorWithProof() public {
        vm.skip(noAvailableAccounts);

        uint256 keysCount = 1;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            accounting.getCurveInfo(earlyAdoption.CURVE_ID())
        );
        vm.deal(nodeOperator, amount);
        vm.prank(nodeOperator);
        csm.addNodeOperatorETH{ value: amount }(
            keysCount,
            keys,
            signatures,
            nodeOperator,
            nodeOperator,
            proof,
            address(0)
        );
        uint256 noId = csm.getNodeOperatorsCount() - 1;
        assertEq(accounting.getBondCurve(noId).id, earlyAdoption.CURVE_ID());
    }
}
