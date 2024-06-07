// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { Utilities } from "../../helpers/Utilities.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import "../../helpers/MerkleTree.sol";

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

        // hardcoded address and proof from devnet sources, see artifacts/devnet-1/sources
        nodeOperator = 0xC234dBA03943C9238067cDfBC2761844133DD386;
        proof = new bytes32[](3);
        proof[
            0
        ] = 0xe4a25c2e38607c9a21e0a06702eb838620e53d3e8307f2950255a278938dd346;
        proof[
            1
        ] = 0x2c35e38e604130fee333a3b27af4ce444b54b4898c6155595097772bbd254e33;
        proof[
            2
        ] = 0xea031c80497204f30fdb057a06dccddb9109c9f4c67cf0f198db9f6cb2f7d176;
    }

    function test_createNodeOperatorWithProof() public {
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
        assertEq(accounting.getBondCurveId(noId), earlyAdoption.CURVE_ID());
    }
}
