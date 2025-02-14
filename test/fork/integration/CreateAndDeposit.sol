// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { NodeOperatorManagementProperties } from "../../../src/interfaces/ICSModule.sol";
import { CSModule } from "../../../src/CSModule.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { IWstETH } from "../../../src/interfaces/IWstETH.sol";
import { ILido } from "../../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../../src/interfaces/ILidoLocator.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";
import { Utilities } from "../../helpers/Utilities.sol";
import { PermitHelper } from "../../helpers/Permit.sol";
import { DeploymentFixtures } from "../../helpers/Fixtures.sol";
import { InvariantAsserts } from "../../helpers/InvariantAsserts.sol";
import { MerkleTree } from "../../helpers/MerkleTree.sol";

contract IntegrationTestBase is
    Test,
    Utilities,
    PermitHelper,
    DeploymentFixtures,
    InvariantAsserts
{
    address internal user;
    address internal nodeOperator;
    address internal stranger;
    uint256 internal userPrivateKey;
    uint256 internal strangerPrivateKey;
    MerkleTree internal merkleTree;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertCSMKeys(csm);
        assertCSMEnqueuedCount(csm);
        assertAccountingTotalBondShares(noCount, lido, accounting);
        assertAccountingBurnerApproval(
            lido,
            address(accounting),
            locator.burner()
        );
        assertFeeDistributorClaimableShares(lido, feeDistributor);
        assertFeeDistributorTree(feeDistributor);
        vm.resumeGasMetering();
    }

    function setUp() public virtual {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.RESUME_ROLE(), address(this));
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
        csm.grantRole(csm.STAKING_ROUTER_ROLE(), address(stakingRouter));
        vm.stopPrank();

        vm.startPrank(vettedGate.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        vettedGate.grantRole(vettedGate.SET_TREE_ROOT_ROLE(), address(this));
        vm.stopPrank();

        if (csm.isPaused()) csm.resume();

        handleStakingLimit();
        handleBunkerMode();

        userPrivateKey = 0xa11ce;
        user = vm.addr(userPrivateKey);
        strangerPrivateKey = 0x517a4637;
        stranger = vm.addr(strangerPrivateKey);
        nodeOperator = nextAddress("NodeOperator");

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));
        merkleTree.pushLeaf(abi.encode(stranger));

        vettedGate.setTreeRoot(merkleTree.root());
    }
}

contract PermissionlessCreateNodeOperatorTest is IntegrationTestBase {
    function test_createNodeOperatorETH() public assertInvariants {
        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            permissionlessGate.CURVE_ID()
        );
        vm.deal(nodeOperator, amount);

        uint256 preTotalShares = accounting.totalBondShares();

        uint256 shares = lido.getSharesByPooledEth(amount);

        vm.prank(nodeOperator);
        uint256 noId = permissionlessGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        assertEq(
            accounting.getBondCurveId(noId),
            permissionlessGate.CURVE_ID()
        );
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_createNodeOperatorStETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));

        uint256 preTotalShares = accounting.totalBondShares();

        lido.approve(address(accounting), type(uint256).max);

        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 shares = lido.getSharesByPooledEth(
            accounting.getBondAmountByKeysCount(
                keysCount,
                permissionlessGate.CURVE_ID()
            )
        );

        uint256 noId = permissionlessGate.addNodeOperatorStETH({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            permit: ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            referrer: address(0)
        });

        assertEq(
            accounting.getBondCurveId(noId),
            permissionlessGate.CURVE_ID()
        );
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_createNodeOperatorWstETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 preTotalShares = accounting.totalBondShares();

        wstETH.approve(address(accounting), type(uint256).max);

        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 wstETHAmount = wstETH.wrap(
            accounting.getBondAmountByKeysCount(
                keysCount,
                permissionlessGate.CURVE_ID()
            )
        );

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 noId = permissionlessGate.addNodeOperatorWstETH({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            permit: ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            referrer: address(0)
        });

        assertEq(
            accounting.getBondCurveId(noId),
            permissionlessGate.CURVE_ID()
        );
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }
}

contract VettedGateCreateNodeOperatorTest is IntegrationTestBase {
    function test_createNodeOperatorETH() public assertInvariants {
        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.CURVE_ID()
        );
        vm.deal(nodeOperator, amount);

        uint256 preTotalShares = accounting.totalBondShares();

        uint256 shares = lido.getSharesByPooledEth(amount);

        vm.startPrank(nodeOperator);
        uint256 noId = vettedGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof: merkleTree.getProof(0),
            referrer: address(0)
        });
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.CURVE_ID());
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorStETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));

        uint256 preTotalShares = accounting.totalBondShares();

        lido.approve(address(accounting), type(uint256).max);

        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        uint256 shares = lido.getSharesByPooledEth(
            accounting.getBondAmountByKeysCount(
                keysCount,
                vettedGate.CURVE_ID()
            )
        );
        uint256 noId = vettedGate.addNodeOperatorStETH({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            permit: ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof: merkleTree.getProof(0),
            referrer: address(0)
        });
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.CURVE_ID());
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorWstETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 preTotalShares = accounting.totalBondShares();
        wstETH.approve(address(accounting), type(uint256).max);

        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 wstETHAmount = wstETH.wrap(
            accounting.getBondAmountByKeysCount(
                keysCount,
                vettedGate.CURVE_ID()
            )
        );

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 noId = vettedGate.addNodeOperatorWstETH({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            permit: ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof: merkleTree.getProof(0),
            referrer: address(0)
        });
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.CURVE_ID());
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_claimBondCurve() public {
        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            permissionlessGate.CURVE_ID()
        );
        vm.deal(nodeOperator, amount);

        vm.prank(nodeOperator);
        uint256 noId = permissionlessGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });

        assertEq(
            accounting.getBondCurveId(noId),
            permissionlessGate.CURVE_ID()
        );
        vm.startPrank(nodeOperator);
        vettedGate.claimBondCurve(noId, merkleTree.getProof(0));
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.CURVE_ID());
        assertTrue(accounting.getClaimableBondShares(noId) > 0);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }
}

contract DepositIntegrationTest is IntegrationTestBase {
    uint256 internal defaultNoId;

    function setUp() public override {
        super.setUp();

        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
        vm.deal(nodeOperator, amount);

        vm.prank(nodeOperator);
        defaultNoId = permissionlessGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });
    }

    function test_depositStETH() public assertInvariants {
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        uint256 shares = lido.submit{ value: 32 ether }(address(0));

        uint256 preShares = accounting.getBondShares(defaultNoId);
        uint256 preTotalShares = accounting.totalBondShares();

        lido.approve(address(accounting), type(uint256).max);
        csm.depositStETH(
            defaultNoId,
            32 ether,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(ILido(locator.lido()).balanceOf(user), 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_depositETH() public assertInvariants {
        vm.startPrank(user);
        vm.deal(user, 32 ether);

        uint256 preShares = accounting.getBondShares(defaultNoId);
        uint256 preTotalShares = accounting.totalBondShares();

        uint256 shares = lido.getSharesByPooledEth(32 ether);
        csm.depositETH{ value: 32 ether }(defaultNoId);

        assertEq(user.balance, 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_depositWstETH() public assertInvariants {
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 preShares = accounting.getBondShares(defaultNoId);
        uint256 preTotalShares = accounting.totalBondShares();

        wstETH.approve(address(accounting), type(uint256).max);
        csm.depositWstETH(
            defaultNoId,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_depositStETHWithPermit() public assertInvariants {
        bytes32 digest = stETHPermitDigest(
            user,
            address(accounting),
            32 ether,
            vm.getNonce(user),
            type(uint256).max,
            address(lido)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 shares = lido.submit{ value: 32 ether }(address(0));

        uint256 preShares = accounting.getBondShares(defaultNoId);
        uint256 preTotalShares = accounting.totalBondShares();

        csm.depositStETH(
            defaultNoId,
            32 ether,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );

        assertEq(lido.balanceOf(user), 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_depositWstETHWithPermit() public assertInvariants {
        bytes32 digest = wstETHPermitDigest(
            user,
            address(accounting),
            32 ether,
            vm.getNonce(user),
            type(uint256).max,
            address(wstETH)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 preShares = accounting.getBondShares(defaultNoId);
        uint256 preTotalShares = accounting.totalBondShares();

        csm.depositWstETH(
            defaultNoId,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }
}
