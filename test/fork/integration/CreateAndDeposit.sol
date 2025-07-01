// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { NodeOperator, NodeOperatorManagementProperties } from "../../../src/interfaces/ICSModule.sol";
import { CSModule } from "../../../src/CSModule.sol";
import { Batch, IQueueLib } from "../../../src/lib/QueueLib.sol";
import { CSAccounting } from "../../../src/CSAccounting.sol";
import { IWstETH } from "../../../src/interfaces/IWstETH.sol";
import { ILido } from "../../../src/interfaces/ILido.sol";
import { ILidoLocator } from "../../../src/interfaces/ILidoLocator.sol";
import { ICSAccounting } from "../../../src/interfaces/ICSAccounting.sol";
import { ICSParametersRegistry } from "../../../src/interfaces/ICSParametersRegistry.sol";
import { IVettedGate } from "../../../src/interfaces/IVettedGate.sol";
import { ICSBondCurve } from "../../../src/interfaces/ICSBondCurve.sol";
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
    address internal anotherNodeOperator;
    address internal stranger;
    uint256 internal userPrivateKey;
    uint256 internal strangerPrivateKey;
    MerkleTree internal merkleTree;
    string internal cid;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        uint256 noCount = csm.getNodeOperatorsCount();
        assertCSMKeys(csm);
        assertCSMEnqueuedCount(csm);
        assertCSMUnusedStorageSlots(csm);
        assertAccountingTotalBondShares(noCount, lido, accounting);
        assertAccountingBurnerApproval(
            lido,
            address(accounting),
            locator.burner()
        );
        assertAccountingUnusedStorageSlots(accounting);
        assertFeeDistributorClaimableShares(lido, feeDistributor);
        assertFeeDistributorTree(feeDistributor);
        assertFeeOracleUnusedStorageSlots(oracle);
        vm.resumeGasMetering();
    }

    function setUp() public virtual {
        Env memory env = envVars();
        vm.createSelectFork(env.RPC_URL);
        initializeFromDeployment();

        vm.startPrank(csm.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), address(this));
        vm.stopPrank();

        vm.startPrank(vettedGate.getRoleMember(csm.DEFAULT_ADMIN_ROLE(), 0));
        vettedGate.grantRole(vettedGate.SET_TREE_ROLE(), address(this));
        vm.stopPrank();

        handleStakingLimit();
        handleBunkerMode();

        userPrivateKey = 0xa11ce;
        user = vm.addr(userPrivateKey);
        strangerPrivateKey = 0x517a4637;
        stranger = vm.addr(strangerPrivateKey);
        nodeOperator = nextAddress("NodeOperator");
        anotherNodeOperator = nextAddress("AnotherNodeOperator");

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));
        merkleTree.pushLeaf(abi.encode(anotherNodeOperator));
        merkleTree.pushLeaf(abi.encode(stranger));

        cid = "someOtherCid";

        vettedGate.setTreeParams(merkleTree.root(), cid);
    }
}

contract PermissionlessCreateNodeOperatorTest is IntegrationTestBase {
    uint256 internal immutable keysCount;

    constructor() {
        keysCount = 1;
    }

    function test_createNodeOperatorETH() public assertInvariants {
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

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("PermissionlessGate.addNodeOperatorETH");
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
        vm.stopSnapshotGas();

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

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 shares = lido.getSharesByPooledEth(
            accounting.getBondAmountByKeysCount(
                keysCount,
                permissionlessGate.CURVE_ID()
            )
        );

        vm.startSnapshotGas("PermissionlessGate.addNodeOperatorStETH");
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
        vm.stopSnapshotGas();

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

        vm.startSnapshotGas("PermissionlessGate.addNodeOperatorWstETH");
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
        vm.stopSnapshotGas();

        assertEq(
            accounting.getBondCurveId(noId),
            permissionlessGate.CURVE_ID()
        );
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }
}

contract PermissionlessCreateNodeOperator10KeysTest is
    PermissionlessCreateNodeOperatorTest
{
    constructor() {
        keysCount = 10;
    }
}

contract VettedGateCreateNodeOperatorTest is IntegrationTestBase {
    uint256 internal immutable keysCount;

    constructor() {
        keysCount = 1;
    }

    function test_createNodeOperatorETH() public assertInvariants {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.curveId()
        );
        vm.deal(nodeOperator, amount);

        uint256 preTotalShares = accounting.totalBondShares();

        uint256 shares = lido.getSharesByPooledEth(amount);

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("VettedGate.addNodeOperatorETH");
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
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.curveId());
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorETH_revertWhen_InvalidProof()
        public
        assertInvariants
    {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.curveId()
        );
        vm.deal(nodeOperator, amount);

        uint256 preTotalShares = accounting.totalBondShares();

        bytes32[] memory proof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof: proof,
            referrer: address(0)
        });

        assertEq(accounting.totalBondShares(), preTotalShares);
        assertFalse(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorStETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));

        uint256 preTotalShares = accounting.totalBondShares();

        lido.approve(address(accounting), type(uint256).max);

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        uint256 shares = lido.getSharesByPooledEth(
            accounting.getBondAmountByKeysCount(keysCount, vettedGate.curveId())
        );
        vm.startSnapshotGas("VettedGate.addNodeOperatorStETH");
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
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.curveId());
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorStETH_revertWhen_InvalidProof()
        public
        assertInvariants
    {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));

        uint256 preTotalShares = accounting.totalBondShares();

        lido.approve(address(accounting), type(uint256).max);

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        bytes32[] memory proof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorStETH({
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
            proof: proof,
            referrer: address(0)
        });
        vm.stopPrank();

        assertEq(accounting.totalBondShares(), preTotalShares);
        assertFalse(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorWstETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 preTotalShares = accounting.totalBondShares();
        wstETH.approve(address(accounting), type(uint256).max);

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 wstETHAmount = wstETH.wrap(
            accounting.getBondAmountByKeysCount(keysCount, vettedGate.curveId())
        );

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        vm.startSnapshotGas("VettedGate.addNodeOperatorWstETH");
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
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.curveId());
        assertEq(accounting.getBondShares(noId), shares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_createNodeOperatorWstETH_revertWhen_InvalidProof()
        public
        assertInvariants
    {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 preTotalShares = accounting.totalBondShares();
        wstETH.approve(address(accounting), type(uint256).max);

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        bytes32[] memory proof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorWstETH({
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
            proof: proof,
            referrer: address(0)
        });
        vm.stopPrank();

        assertEq(accounting.totalBondShares(), preTotalShares);
        assertFalse(vettedGate.isConsumed(nodeOperator));
    }
}

contract VettedGateCreateNodeOperator10KeysTest is
    VettedGateCreateNodeOperatorTest
{
    constructor() {
        keysCount = 10;
    }
}

contract VettedGateMiscTest is IntegrationTestBase {
    uint256 internal constant keysCount = 2;

    function test_claimBondCurve() public assertInvariants {
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
        vm.startSnapshotGas("VettedGate.claimBondCurve");
        vettedGate.claimBondCurve(noId, merkleTree.getProof(0));
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(accounting.getBondCurveId(noId), vettedGate.curveId());
        assertTrue(accounting.getClaimableBondShares(noId) > 0);
        assertTrue(vettedGate.isConsumed(nodeOperator));
    }

    function test_claimBondCurve_revertWhenInvalidProof()
        public
        assertInvariants
    {
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

        bytes32[] memory proof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vm.startPrank(nodeOperator);
        vettedGate.claimBondCurve(noId, proof);
        vm.stopPrank();

        assertEq(
            accounting.getBondCurveId(noId),
            accounting.DEFAULT_BOND_CURVE_ID()
        );
        assertEq(accounting.getClaimableBondShares(noId), 0);
        assertFalse(vettedGate.isConsumed(nodeOperator));
    }

    function test_setTreeParams() public {
        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(stranger));
        merkleTree.pushLeaf(abi.encode(nodeOperator));
        merkleTree.pushLeaf(abi.encode(anotherNodeOperator));

        cid = "yetAnotherOtherCid";

        vettedGate.setTreeParams(merkleTree.root(), cid);

        assertEq(vettedGate.treeRoot(), merkleTree.root());
        assertEq(vettedGate.treeCid(), cid);
    }

    function test_referralSeason() public assertInvariants {
        // Create a new node operator
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.curveId()
        );
        vm.deal(nodeOperator, amount);

        uint256 shares = lido.getSharesByPooledEth(amount);

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("VettedGate.addNodeOperatorETH");
        uint256 firstNoId = vettedGate.addNodeOperatorETH{ value: amount }({
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
        vm.stopSnapshotGas();
        vm.stopPrank();

        // Start a new referral season
        ICSBondCurve.BondCurveIntervalInput[]
            memory referralBondCurve = new ICSBondCurve.BondCurveIntervalInput[](
                2
            );
        referralBondCurve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 1.2 ether
        });
        referralBondCurve[1] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 2,
            trend: 1 ether
        });

        vm.startPrank(
            accounting.getRoleMember(accounting.DEFAULT_ADMIN_ROLE(), 0)
        );
        accounting.grantRole(
            accounting.MANAGE_BOND_CURVES_ROLE(),
            address(this)
        );
        vm.stopPrank();

        uint256 referralBondCurveId = accounting.addBondCurve(
            referralBondCurve
        );

        vm.startPrank(
            vettedGate.getRoleMember(accounting.DEFAULT_ADMIN_ROLE(), 0)
        );
        vettedGate.grantRole(
            vettedGate.START_REFERRAL_SEASON_ROLE(),
            address(this)
        );
        vm.stopPrank();

        vettedGate.startNewReferralProgramSeason(referralBondCurveId, 1);

        // Create a new node operator with a referrer pointing to the first one
        (keys, signatures) = keysSignatures(keysCount);
        amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.curveId()
        );
        vm.deal(anotherNodeOperator, amount);

        shares = lido.getSharesByPooledEth(amount);

        vm.startPrank(anotherNodeOperator);
        vm.startSnapshotGas("VettedGate.addNodeOperatorETH");
        vettedGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof: merkleTree.getProof(1),
            referrer: nodeOperator
        });
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(vettedGate.getReferralsCount(nodeOperator), 1);

        // Claim the referral bond curve
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vm.startSnapshotGas("VettedGate.claimReferrerBondCurve");
        vettedGate.claimReferrerBondCurve(firstNoId, proof);
        vm.stopSnapshotGas();

        assertEq(accounting.getBondCurveId(firstNoId), referralBondCurveId);
        assertTrue(accounting.getClaimableBondShares(firstNoId) > 0);
        assertTrue(vettedGate.isReferrerConsumed(nodeOperator));

        // Attempt to claim the referral bond curve again
        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.claimReferrerBondCurve(firstNoId, proof);
    }

    function test_referralSeason_noClaimsAfterEnd() public assertInvariants {
        // Create a new node operator
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.curveId()
        );
        vm.deal(nodeOperator, amount);

        uint256 shares = lido.getSharesByPooledEth(amount);

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("VettedGate.addNodeOperatorETH");
        uint256 firstNoId = vettedGate.addNodeOperatorETH{ value: amount }({
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
        vm.stopSnapshotGas();
        vm.stopPrank();

        // Start a new referral season
        ICSBondCurve.BondCurveIntervalInput[]
            memory referralBondCurve = new ICSBondCurve.BondCurveIntervalInput[](
                2
            );
        referralBondCurve[0] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 1,
            trend: 1.2 ether
        });
        referralBondCurve[1] = ICSBondCurve.BondCurveIntervalInput({
            minKeysCount: 2,
            trend: 1 ether
        });

        vm.startPrank(
            accounting.getRoleMember(accounting.DEFAULT_ADMIN_ROLE(), 0)
        );
        accounting.grantRole(
            accounting.MANAGE_BOND_CURVES_ROLE(),
            address(this)
        );
        vm.stopPrank();

        uint256 referralBondCurveId = accounting.addBondCurve(
            referralBondCurve
        );

        vm.startPrank(
            vettedGate.getRoleMember(accounting.DEFAULT_ADMIN_ROLE(), 0)
        );
        vettedGate.grantRole(
            vettedGate.START_REFERRAL_SEASON_ROLE(),
            address(this)
        );
        vm.stopPrank();

        vettedGate.startNewReferralProgramSeason(referralBondCurveId, 1);

        // Create a new node operator with a referrer pointing to the first one
        (keys, signatures) = keysSignatures(keysCount);
        amount = accounting.getBondAmountByKeysCount(
            keysCount,
            vettedGate.curveId()
        );
        vm.deal(anotherNodeOperator, amount);

        shares = lido.getSharesByPooledEth(amount);

        vm.startPrank(anotherNodeOperator);
        vm.startSnapshotGas("VettedGate.addNodeOperatorETH");
        vettedGate.addNodeOperatorETH{ value: amount }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof: merkleTree.getProof(1),
            referrer: nodeOperator
        });
        vm.stopSnapshotGas();
        vm.stopPrank();

        assertEq(vettedGate.getReferralsCount(nodeOperator), 1);

        // End the referral season
        vm.startPrank(
            vettedGate.getRoleMember(accounting.DEFAULT_ADMIN_ROLE(), 0)
        );
        vettedGate.grantRole(
            vettedGate.END_REFERRAL_SEASON_ROLE(),
            address(this)
        );
        vm.stopPrank();

        vettedGate.endCurrentReferralProgramSeason();

        // Attempt to claim the referral bond curve
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(IVettedGate.ReferralProgramIsNotActive.selector);
        vm.prank(nodeOperator);
        vettedGate.claimReferrerBondCurve(firstNoId, proof);
    }
}

contract DepositTest is IntegrationTestBase {
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
        vm.startSnapshotGas("Accounting.depositStETH");
        accounting.depositStETH(
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
        vm.stopSnapshotGas();

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
        vm.startSnapshotGas("Accounting.depositETH");
        accounting.depositETH{ value: 32 ether }(defaultNoId);
        vm.stopSnapshotGas();

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
        vm.startSnapshotGas("Accounting.depositWstETH");
        accounting.depositWstETH(
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
        vm.stopSnapshotGas();

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

        vm.startSnapshotGas("Accounting.depositStETH_permit");
        accounting.depositStETH(
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
        vm.stopSnapshotGas();

        assertEq(lido.balanceOf(user), 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }

    function test_depositWstETHWithPermit() public assertInvariants {
        vm.deal(user, 33 ether);
        vm.startPrank(user);
        lido.submit{ value: 33 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);
        uint256 wstETHAmount = wstETH.wrap(32 ether);

        bytes32 digest = wstETHPermitDigest(
            user,
            address(accounting),
            wstETHAmount + 10 wei,
            vm.getNonce(user),
            type(uint256).max,
            address(wstETH)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        uint256 shares = lido.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        uint256 preShares = accounting.getBondShares(defaultNoId);
        uint256 preTotalShares = accounting.totalBondShares();

        vm.startSnapshotGas("Accounting.depositWstETH_permit");
        accounting.depositWstETH(
            defaultNoId,
            wstETHAmount,
            ICSAccounting.PermitInput({
                value: wstETHAmount + 10 wei,
                deadline: type(uint256).max,
                v: v,
                r: r,
                s: s
            })
        );
        vm.stopSnapshotGas();

        assertEq(wstETH.balanceOf(user), 0);
        assertEq(accounting.getBondShares(defaultNoId), shares + preShares);
        assertEq(accounting.totalBondShares(), shares + preTotalShares);
    }
}

contract AddValidatorKeysTest is IntegrationTestBase {
    uint256 internal defaultNoId;
    uint256 internal initialKeysCount = 2;
    uint256 internal immutable keysCount;

    constructor() {
        keysCount = 1;
    }

    function setUp() public override {
        super.setUp();
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            initialKeysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            initialKeysCount,
            0
        );
        vm.deal(nodeOperator, amount);

        vm.startPrank(nodeOperator);
        defaultNoId = permissionlessGate.addNodeOperatorETH{ value: amount }({
            keysCount: initialKeysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });
        vm.stopPrank();
    }

    function test_addValidatorKeysETH() public assertInvariants {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
        vm.deal(nodeOperator, amount);

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("CSM.addValidatorKeysETH");
        csm.addValidatorKeysETH{ value: amount }(
            nodeOperator,
            defaultNoId,
            keysCount,
            keys,
            signatures
        );
        vm.stopSnapshotGas();
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(defaultNoId);
        assertEq(no.totalAddedKeys, initialKeysCount + keysCount);
    }

    function test_addValidatorKeysStETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));

        lido.approve(address(accounting), type(uint256).max);

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );

        vm.startSnapshotGas("CSM.addValidatorKeysStETH");
        csm.addValidatorKeysStETH(
            nodeOperator,
            defaultNoId,
            keysCount,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
        vm.stopSnapshotGas();
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(defaultNoId);
        assertEq(no.totalAddedKeys, initialKeysCount + keysCount);
    }

    function test_addValidatorKeysWstETH() public assertInvariants {
        vm.startPrank(nodeOperator);
        vm.deal(nodeOperator, 32 ether);
        lido.submit{ value: 32 ether }(address(0));
        lido.approve(address(wstETH), type(uint256).max);

        wstETH.approve(address(accounting), type(uint256).max);

        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        wstETH.wrap(
            accounting.getBondAmountByKeysCount(
                keysCount,
                permissionlessGate.CURVE_ID()
            )
        );

        vm.startSnapshotGas("CSM.addValidatorKeysWstETH");
        csm.addValidatorKeysWstETH(
            nodeOperator,
            defaultNoId,
            keysCount,
            keys,
            signatures,
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            })
        );
        vm.stopSnapshotGas();
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(defaultNoId);
        assertEq(no.totalAddedKeys, initialKeysCount + keysCount);
    }
}

contract AddValidatorKeys10KeysTest is AddValidatorKeysTest {
    constructor() {
        keysCount = 10;
    }
}

contract RemoveKeysTest is IntegrationTestBase {
    uint256 internal defaultNoId;
    uint256 internal initialKeysCount = 3;

    function setUp() public override {
        super.setUp();
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            initialKeysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(
            initialKeysCount,
            0
        );
        vm.deal(nodeOperator, amount);

        vm.startPrank(nodeOperator);
        defaultNoId = permissionlessGate.addNodeOperatorETH{ value: amount }({
            keysCount: initialKeysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });
        vm.stopPrank();
    }

    function test_removeKeys_withCharge() public assertInvariants {
        uint256 keysCount = 1;

        (uint256 bondBefore, ) = accounting.getBondSummary(defaultNoId);

        uint256 keyRemovalCharge = parametersRegistry.getKeyRemovalCharge(
            accounting.getBondCurveId(defaultNoId)
        );

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("CSM.removeKeys");
        csm.removeKeys(defaultNoId, initialKeysCount - keysCount, keysCount);
        vm.stopSnapshotGas();
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(defaultNoId);
        assertEq(no.totalAddedKeys, initialKeysCount - keysCount);

        (uint256 bondAfter, ) = accounting.getBondSummary(defaultNoId);

        assertApproxEqAbs(bondBefore, bondAfter + keyRemovalCharge, 2 wei);
    }

    function test_removeKeys_withoutCharge() public assertInvariants {
        uint256 keysCount = 1;

        (uint256 bondBefore, ) = accounting.getBondSummary(defaultNoId);

        vm.startPrank(
            parametersRegistry.getRoleMember(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                0
            )
        );
        parametersRegistry.setKeyRemovalCharge(
            accounting.getBondCurveId(defaultNoId),
            0
        );
        vm.stopPrank();

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("CSM.removeKeys");
        csm.removeKeys(defaultNoId, initialKeysCount - keysCount, keysCount);
        vm.stopSnapshotGas();
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(defaultNoId);
        assertEq(no.totalAddedKeys, initialKeysCount - keysCount);

        (uint256 bondAfter, ) = accounting.getBondSummary(defaultNoId);

        assertEq(bondBefore, bondAfter);
    }

    function test_removeKeys_vettingReset() public assertInvariants {
        uint256 keysCount = 2;
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysCount
        );
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
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

        vm.prank(address(stakingRouter));
        csm.decreaseVettedSigningKeysCount(
            bytes.concat(bytes8(uint64(noId))),
            bytes.concat(bytes16(uint128(keysCount - 1)))
        );

        uint256 additionalKeysCount = 2;
        (keys, signatures) = keysSignatures(additionalKeysCount);
        amount = accounting.getRequiredBondForNextKeys(
            noId,
            additionalKeysCount
        );
        vm.deal(nodeOperator, amount);

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("CSM.addValidatorKeysETH");
        csm.addValidatorKeysETH{ value: amount }(
            nodeOperator,
            noId,
            additionalKeysCount,
            keys,
            signatures
        );
        vm.stopSnapshotGas();
        vm.stopPrank();

        uint256 keysCountToRemove = 1;

        vm.startPrank(nodeOperator);
        vm.startSnapshotGas("CSM.removeKeys");
        csm.removeKeys(
            noId,
            keysCount - keysCountToRemove - 1,
            keysCountToRemove
        );
        vm.stopSnapshotGas();
        vm.stopPrank();

        NodeOperator memory no = csm.getNodeOperator(noId);
        assertEq(
            no.totalAddedKeys,
            keysCount + additionalKeysCount - keysCountToRemove
        );

        assertEq(no.totalVettedKeys, no.totalAddedKeys);
    }
}

contract ObtainDepositDataTest is IntegrationTestBase {
    function _addKeys(uint256 noId, uint256 keysToDeposit) internal {
        (bytes memory keys, bytes memory signatures) = keysSignatures(
            keysToDeposit
        );
        uint256 curveId = accounting.getBondCurveId(noId);
        uint256 amount = accounting.getBondAmountByKeysCount(
            keysToDeposit,
            curveId
        );
        address nodeOperatorAddress = csm
            .getNodeOperatorManagementProperties(noId)
            .managerAddress;
        vm.deal(nodeOperatorAddress, amount);

        vm.startPrank(nodeOperatorAddress);
        csm.addValidatorKeysETH{ value: amount }(
            nodeOperatorAddress,
            noId,
            keysToDeposit,
            keys,
            signatures
        );
        vm.stopPrank();
    }

    function _setPriorityQueue(
        uint256 noId,
        uint256 keysWithPriority
    ) internal {
        uint256 curveId = accounting.getBondCurveId(noId);
        NodeOperator memory no = csm.getNodeOperator(noId);
        address agent = stakingRouter.getRoleMember(
            stakingRouter.DEFAULT_ADMIN_ROLE(),
            0
        );
        vm.startPrank(agent);
        parametersRegistry.setQueueConfig(
            curveId,
            0,
            no.totalDepositedKeys + no.enqueuedCount + uint32(keysWithPriority)
        );
        vm.stopPrank();
    }

    function test_withLegacyQueue_AddKeysToPriorityQueue()
        public
        assertInvariants
    {
        (uint128 legacyQueueHeadBefore, uint128 legacyQueueTailBefore) = csm
            .depositQueuePointers(csm.QUEUE_LEGACY_PRIORITY());
        Batch legacyQueueItemBefore = csm.depositQueueItem(
            csm.QUEUE_LEGACY_PRIORITY(),
            legacyQueueHeadBefore
        );

        // No need to run if the legacy queue is empty
        vm.skip(legacyQueueItemBefore.isNil());

        uint256 noId = legacyQueueItemBefore.noId();
        uint256 keysWithPriority = 1;
        uint256 keysWithNoPriority = 2;
        _setPriorityQueue(noId, keysWithPriority);
        _addKeys(noId, keysWithPriority + keysWithNoPriority);

        (, uint128 priorityQueueTailAfterDeposit) = csm.depositQueuePointers(0);
        Batch priorityQueueItemAfterDeposit = csm.depositQueueItem(
            0,
            priorityQueueTailAfterDeposit - 1
        );
        assertEq(
            priorityQueueItemAfterDeposit.keys(),
            keysWithPriority,
            "Priority queue should be filled with new keys"
        );

        (, uint128 lowestQueueTailAfterDeposit) = csm.depositQueuePointers(
            csm.QUEUE_LOWEST_PRIORITY()
        );
        Batch lowestQueueItemAfterDeposit = csm.depositQueueItem(
            csm.QUEUE_LOWEST_PRIORITY(),
            lowestQueueTailAfterDeposit - 1
        );
        assertEq(
            lowestQueueItemAfterDeposit.keys(),
            keysWithNoPriority,
            "Lowest queue should be filled with new keys"
        );

        (
            uint128 legacyQueueHeadAfterDeposit,
            uint128 legacyQueueTailAfterDeposit
        ) = csm.depositQueuePointers(csm.QUEUE_LEGACY_PRIORITY());
        assertEq(
            legacyQueueTailBefore,
            legacyQueueTailAfterDeposit,
            "Legacy queue tail should not be changed after deposit"
        );

        vm.startPrank(address(stakingRouter));
        // Obtain 1 key from the priority queue and last Node Operator's keys batch from the legacy queue.
        // The rest should be in the lowest queue.
        csm.obtainDepositData(
            keysWithPriority + legacyQueueItemBefore.keys(),
            ""
        );
        vm.stopPrank();

        (uint128 priorityQueueHeadAfterObtain, ) = csm.depositQueuePointers(0);
        Batch priorityQueueItemAfterObtain = csm.depositQueueItem(
            0,
            priorityQueueHeadAfterObtain
        );
        assertEq(
            priorityQueueItemAfterObtain.keys(),
            0,
            "Priority queue should be empty"
        );

        (uint256 legacyQueueHeadAfterObtain, ) = csm.depositQueuePointers(
            csm.QUEUE_LEGACY_PRIORITY()
        );
        assertNotEq(
            legacyQueueHeadAfterObtain,
            legacyQueueHeadAfterDeposit,
            "Legacy queue head should be shifted"
        );

        (, uint128 lowestQueueTailAfter) = csm.depositQueuePointers(
            csm.QUEUE_LOWEST_PRIORITY()
        );
        Batch lowestQueueItemAfterObtain = csm.depositQueueItem(
            csm.QUEUE_LOWEST_PRIORITY(),
            lowestQueueTailAfter - 1
        );
        assertEq(
            lowestQueueItemAfterObtain.noId(),
            noId,
            "Node Operator batch should be in the tail of the lowest queue"
        );
        assertEq(
            lowestQueueItemAfterObtain.keys(),
            lowestQueueItemAfterDeposit.keys(),
            "Lowest queue tail item should contain the same keys"
        );
    }
}
