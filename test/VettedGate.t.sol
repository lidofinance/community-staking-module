// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { VettedGate } from "../src/VettedGate.sol";
import { PausableUntil } from "../src/lib/utils/PausableUntil.sol";
import { IVettedGate } from "../src/interfaces/IVettedGate.sol";
import { ICSModule, NodeOperatorManagementProperties, NodeOperator } from "../src/interfaces/ICSModule.sol";
import { ICSAccounting } from "../src/interfaces/ICSAccounting.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { CSMMock } from "./helpers/mocks/CSMMock.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

contract VettedGateTestBase is Test, Utilities, Fixtures {
    VettedGate internal vettedGate;
    address internal csm;
    address internal nodeOperator;
    address internal stranger;
    address internal anotherNodeOperator;
    address internal admin;
    uint256 internal curveId;
    uint256 internal referralsThreshold;
    MerkleTree internal merkleTree;
    bytes32 internal root;
    string internal cid;

    function setUp() public virtual {
        csm = address(new CSMMock());
        nodeOperator = nextAddress("NODE_OPERATOR");
        anotherNodeOperator = nextAddress("ANOTHER_NODE_OPERATOR");
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");

        merkleTree = new MerkleTree();
        merkleTree.pushLeaf(abi.encode(nodeOperator));
        merkleTree.pushLeaf(abi.encode(stranger));
        merkleTree.pushLeaf(abi.encode(anotherNodeOperator));
        cid = "someCid";

        curveId = 1;
        root = merkleTree.root();
        vettedGate = new VettedGate(csm);
        _enableInitializers(address(vettedGate));
        vettedGate.initialize(curveId, merkleTree.root(), cid, admin);
    }

    function _addReferrals() internal {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            stranger
        );

        proof = merkleTree.getProof(2);
        vm.prank(anotherNodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            stranger
        );
    }

    function _consume() internal {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(1);
        vm.prank(stranger);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );
    }
}

contract VettedGateTest is VettedGateTestBase {
    function setUp() public override {
        super.setUp();
    }

    function test_constructor() public {
        vettedGate = new VettedGate(csm);
        assertEq(address(vettedGate.MODULE()), csm);
        assertEq(
            address(vettedGate.ACCOUNTING()),
            address(ICSModule(csm).accounting())
        );
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(IVettedGate.ZeroModuleAddress.selector);
        new VettedGate(address(0));
    }

    function test_initializer() public {
        vettedGate = new VettedGate(csm);
        _enableInitializers(address(vettedGate));

        vm.expectEmit();
        emit IVettedGate.TreeSet(root, cid);
        vettedGate.initialize(curveId, merkleTree.root(), cid, admin);

        assertEq(vettedGate.curveId(), curveId);
        assertEq(vettedGate.treeRoot(), root);
        assertEq(
            vettedGate.getRoleMemberCount(vettedGate.DEFAULT_ADMIN_ROLE()),
            1
        );
        assertEq(
            vettedGate.getRoleMember(vettedGate.DEFAULT_ADMIN_ROLE(), 0),
            admin
        );
        assertEq(vettedGate.getInitializedVersion(), 1);
    }

    function test_initializer_RevertWhen_InvalidCurveId() public {
        vettedGate = new VettedGate(csm);
        _enableInitializers(address(vettedGate));

        vm.expectRevert(IVettedGate.InvalidCurveId.selector);
        vettedGate.initialize(0, root, cid, admin);
    }

    function test_initializer_RevertWhen_InvalidTreeRoot() public {
        vettedGate = new VettedGate(csm);
        _enableInitializers(address(vettedGate));

        vm.expectRevert(IVettedGate.InvalidTreeRoot.selector);
        vettedGate.initialize(curveId, bytes32(0), cid, admin);
    }

    function test_initializer_RevertWhen_InvalidTreeCid() public {
        vettedGate = new VettedGate(csm);
        _enableInitializers(address(vettedGate));

        vm.expectRevert(IVettedGate.InvalidTreeCid.selector);
        vettedGate.initialize(curveId, root, "", admin);
    }

    function test_initializer_RevertWhen_ZeroAdminAddress() public {
        vettedGate = new VettedGate(csm);
        _enableInitializers(address(vettedGate));

        vm.expectRevert(IVettedGate.ZeroAdminAddress.selector);
        vettedGate.initialize(curveId, root, cid, address(0));
    }

    function test_pauseFor() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);

        vm.expectEmit(address(vettedGate));
        emit PausableUntil.Paused(100);
        vettedGate.pauseFor(100);

        vm.stopPrank();
        assertTrue(vettedGate.isPaused());
    }

    function test_pauseFor_revertWhen_noRole() public {
        expectRoleRevert(admin, vettedGate.PAUSE_ROLE());
        vm.prank(admin);
        vettedGate.pauseFor(100);
    }

    function test_resume() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.grantRole(vettedGate.RESUME_ROLE(), admin);
        vettedGate.pauseFor(100);

        vm.expectEmit(address(vettedGate));
        emit PausableUntil.Resumed();
        vettedGate.resume();

        vm.stopPrank();
        assertFalse(vettedGate.isPaused());
    }

    function test_resume_revertWhen_noRole() public {
        expectRoleRevert(admin, vettedGate.RESUME_ROLE());
        vm.prank(admin);
        vettedGate.resume();
    }

    function test_verifyProof() public view {
        assertTrue(
            vettedGate.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(vettedGate.verifyProof(stranger, merkleTree.getProof(0)));
    }

    function test_hashLeaf() public view {
        // keccak256(bytes.concat(keccak256(abi.encode(address(154))))) = 0x0f7ac7a58332324fa3de7b7a4a05de303436d846e292fa579646a7496f0c2c1a
        assertEq(
            vettedGate.hashLeaf(address(154)),
            0x0f7ac7a58332324fa3de7b7a4a05de303436d846e292fa579646a7496f0c2c1a
        );
    }

    function testFuzz_hashLeaf(address addr) public view {
        assertEq(
            vettedGate.hashLeaf(addr),
            keccak256(bytes.concat(keccak256(abi.encode(addr))))
        );
    }

    function test_setTreeParams() public {
        MerkleTree newTree = new MerkleTree();
        newTree.pushLeaf(abi.encode(stranger));
        bytes32 newRoot = newTree.root();
        string memory newCid = "newCid";

        assertTrue(
            vettedGate.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertFalse(vettedGate.verifyProof(stranger, newTree.getProof(0)));

        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROLE(), admin);

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.TreeSet(newRoot, newCid);
        vettedGate.setTreeParams(newRoot, newCid);

        vm.stopPrank();

        assertEq(vettedGate.treeRoot(), newRoot);
        assertEq(
            keccak256(bytes(vettedGate.treeCid())),
            keccak256(bytes(newCid))
        );
        assertFalse(
            vettedGate.verifyProof(nodeOperator, merkleTree.getProof(0))
        );
        assertTrue(vettedGate.verifyProof(stranger, newTree.getProof(0)));
    }

    function test_setTreeParams_revert_zeroRoot() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROLE(), admin);

        vm.expectRevert(IVettedGate.InvalidTreeRoot.selector);
        vettedGate.setTreeParams(bytes32(0), "newCid");

        vm.stopPrank();
    }

    function test_setTreeParams_revert_sameRoot() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROLE(), admin);
        bytes32 currRoot = merkleTree.root();

        vm.expectRevert(IVettedGate.InvalidTreeRoot.selector);
        vettedGate.setTreeParams(currRoot, "newCid");

        vm.stopPrank();
    }

    function test_setTreeParams_revert_zeroCid() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROLE(), admin);

        vm.expectRevert(IVettedGate.InvalidTreeCid.selector);
        vettedGate.setTreeParams(bytes32(randomBytes(32)), "");

        vm.stopPrank();
    }

    function test_setTreeParams_revert_sameCid() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.SET_TREE_ROLE(), admin);

        vm.expectRevert(IVettedGate.InvalidTreeCid.selector);
        vettedGate.setTreeParams(bytes32(randomBytes(32)), cid);

        vm.stopPrank();
    }

    function test_setTreeParams_revert_noRole() public {
        vm.startPrank(admin);
        expectRoleRevert(admin, vettedGate.SET_TREE_ROLE());
        vettedGate.setTreeParams(bytes32(randomBytes(32)), "newCid");
        vm.stopPrank();
    }

    function test_addNodeOperatorETH() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        assertFalse(vettedGate.isConsumed(nodeOperator));
        assertEq(vettedGate.getReferralsCount(stranger), 0);
        assertFalse(vettedGate.isReferralProgramSeasonActive());

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            stranger
        );

        assertTrue(vettedGate.isConsumed(nodeOperator));
        assertEq(vettedGate.getReferralsCount(stranger), 0);
    }

    function test_addNodeOperatorStETH() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        assertFalse(vettedGate.isConsumed(nodeOperator));
        assertEq(vettedGate.getReferralsCount(stranger), 0);
        assertFalse(vettedGate.isReferralProgramSeasonActive());

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            stranger
        );

        assertTrue(vettedGate.isConsumed(nodeOperator));
        assertEq(vettedGate.getReferralsCount(stranger), 0);
    }

    function test_addNodeOperatorWstETH() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);
        assertFalse(vettedGate.isConsumed(nodeOperator));
        assertEq(vettedGate.getReferralsCount(stranger), 0);
        assertFalse(vettedGate.isReferralProgramSeasonActive());

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            stranger
        );

        assertTrue(vettedGate.isConsumed(nodeOperator));
        assertEq(vettedGate.getReferralsCount(stranger), 0);
    }

    function test_addNodeOperatorETH_revertWhen_alreadyConsumed() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorETH_revertWhen_invalidProof() public {
        uint256 keysCount = 1;
        bytes32[] memory invalidProof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            invalidProof,
            address(0)
        );
    }

    function test_addNodeOperatorETH_revertWhen_paused() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.pauseFor(type(uint256).max);
        vm.stopPrank();

        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vettedGate.addNodeOperatorETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorStETH_revertWhen_alreadyConsumed() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorStETH_revertWhen_invalidProof() public {
        uint256 keysCount = 1;
        bytes32[] memory invalidProof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            invalidProof,
            address(0)
        );
    }

    function test_addNodeOperatorStETH_revertWhen_paused() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.pauseFor(type(uint256).max);
        vm.stopPrank();

        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorWstETH_revertWhen_alreadyConsumed() public {
        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(nodeOperator);
        vettedGate.addNodeOperatorStETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_addNodeOperatorWstETH_revertWhen_invalidProof() public {
        uint256 keysCount = 1;
        bytes32[] memory invalidProof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            invalidProof,
            address(0)
        );
    }

    function test_addNodeOperatorWstETH_revertWhen_paused() public {
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.PAUSE_ROLE(), admin);
        vettedGate.pauseFor(type(uint256).max);
        vm.stopPrank();

        uint256 keysCount = 1;
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(PausableUntil.ResumedExpected.selector);
        vettedGate.addNodeOperatorWstETH(
            keysCount,
            randomBytes(48 * keysCount),
            randomBytes(96 * keysCount),
            NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            ICSAccounting.PermitInput({
                value: 0,
                deadline: 0,
                v: 0,
                r: 0,
                s: 0
            }),
            proof,
            address(0)
        );
    }

    function test_claimBondCurve() public {
        NodeOperator memory no;
        no.managerAddress = nodeOperator;
        no.rewardAddress = nodeOperator;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectCall(
            address(vettedGate.ACCOUNTING()),
            abi.encodeWithSelector(
                ICSAccounting.setBondCurve.selector,
                0,
                vettedGate.curveId()
            )
        );
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(nodeOperator);
        vm.prank(nodeOperator);
        vettedGate.claimBondCurve(0, proof);
    }

    function test_claimBondCurve_revertWhen_notRewardAddress() public {
        NodeOperator memory no;
        no.managerAddress = nodeOperator;
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(IVettedGate.NotAllowedToClaim.selector);
        vettedGate.claimBondCurve(0, proof);
    }

    function test_claimBondCurve_revertWhen_notManagerAddress() public {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nodeOperator;
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        vm.expectRevert(IVettedGate.NotAllowedToClaim.selector);
        vettedGate.claimBondCurve(0, proof);
    }
}

contract VettedGateReferralProgramTest is VettedGateTestBase {
    function setUp() public override {
        super.setUp();
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.START_REFERRAL_SEASON_ROLE(), admin);
        vettedGate.grantRole(vettedGate.END_REFERRAL_SEASON_ROLE(), admin);
        vettedGate.startNewReferralProgramSeason(2, 2);
        vm.stopPrank();
    }

    function test_endCurrentReferralProgramSeason() public {
        uint256 season = vettedGate.referralProgramSeasonNumber();

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferralProgramSeasonEnded(season);
        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();

        assertFalse(vettedGate.isReferralProgramSeasonActive());
    }

    function test_endCurrentReferralProgramSeason_revertWhen_noRole() public {
        expectRoleRevert(stranger, vettedGate.END_REFERRAL_SEASON_ROLE());
        vm.prank(stranger);
        vettedGate.endCurrentReferralProgramSeason();
    }

    function test_endCurrentReferralProgramSeason_revertWhen_seasonAlreadyEnded()
        public
    {
        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();

        vm.expectRevert(IVettedGate.ReferralProgramIsNotActive.selector);
        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();
    }

    function test_startNewReferralProgramSeason() public {
        _addReferrals();
        assertEq(vettedGate.getReferralsCount(stranger), 2);

        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();

        uint256 season = vettedGate.referralProgramSeasonNumber() + 1;
        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 3;

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferralProgramSeasonStarted(
            season,
            referralCurveId,
            referralsThreshold
        );
        vm.prank(admin);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );

        assertEq(vettedGate.referralCurveId(), referralCurveId);
        assertEq(vettedGate.referralsThreshold(), referralsThreshold);
        assertEq(vettedGate.referralProgramSeasonNumber(), season);
        assertTrue(vettedGate.isReferralProgramSeasonActive());
        assertEq(vettedGate.getReferralsCount(stranger), 0);
    }

    function test_startNewReferralProgramSeason_revertWhen_noRole() public {
        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();

        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 3;

        expectRoleRevert(stranger, vettedGate.START_REFERRAL_SEASON_ROLE());
        vm.prank(stranger);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );
    }

    function test_startNewReferralProgramSeason_revertWhen_InvalidReferralsThreshold()
        public
    {
        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();

        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 0;

        vm.expectRevert(IVettedGate.InvalidReferralsThreshold.selector);
        vm.prank(admin);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );
    }

    function test_startNewReferralProgramSeason_revertWhen_ReferralProgramIsActive()
        public
    {
        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 3;

        vm.expectRevert(IVettedGate.ReferralProgramIsActive.selector);
        vm.prank(admin);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );
    }

    function test_claimReferrerBondCurve_fromRewardAddress() public {
        NodeOperator memory no;
        no.managerAddress = nextAddress();
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();

        vm.expectCall(
            address(vettedGate.ACCOUNTING()),
            abi.encodeWithSelector(
                ICSAccounting.setBondCurve.selector,
                0,
                vettedGate.referralCurveId()
            )
        );
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(stranger);
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferrerConsumed(stranger);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);

        assertTrue(vettedGate.isReferrerConsumed(stranger));
    }

    function test_claimReferrerBondCurve_fromRewardAddress_joinedViaGateBefore()
        public
    {
        NodeOperator memory no;
        no.managerAddress = nextAddress();
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();
        _consume();

        vm.expectCall(
            address(vettedGate.ACCOUNTING()),
            abi.encodeWithSelector(
                ICSAccounting.setBondCurve.selector,
                0,
                vettedGate.referralCurveId()
            )
        );
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferrerConsumed(stranger);
        vm.recordLogs();
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);

        assertTrue(vettedGate.isReferrerConsumed(stranger));
    }

    function test_claimReferrerBondCurve_fromRewardAddress_revertWhen_NotAllowedToClaim()
        public
    {
        NodeOperator memory no;
        no.managerAddress = nextAddress();
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();

        vm.expectRevert(IVettedGate.NotAllowedToClaim.selector);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);
    }

    function test_claimReferrerBondCurve_fromManagerAddress() public {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nextAddress();
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();

        vm.expectCall(
            address(vettedGate.ACCOUNTING()),
            abi.encodeWithSelector(
                ICSAccounting.setBondCurve.selector,
                0,
                vettedGate.referralCurveId()
            )
        );
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.Consumed(stranger);
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferrerConsumed(stranger);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);

        assertTrue(vettedGate.isReferrerConsumed(stranger));
    }

    function test_claimReferrerBondCurve_fromManagerAddress_joinedViaGateBefore()
        public
    {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nextAddress();
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();
        _consume();

        vm.expectCall(
            address(vettedGate.ACCOUNTING()),
            abi.encodeWithSelector(
                ICSAccounting.setBondCurve.selector,
                0,
                vettedGate.referralCurveId()
            )
        );
        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferrerConsumed(stranger);
        vm.recordLogs();
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);

        assertTrue(vettedGate.isReferrerConsumed(stranger));
    }

    function test_claimReferrerBondCurve_fromManagerAddress_revertWhen_NotAllowedToClaim()
        public
    {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nextAddress();
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();

        vm.expectRevert(IVettedGate.NotAllowedToClaim.selector);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);
    }

    function test_claimReferrerBondCurve_revertWhen_ReferralProgramIsNotActive()
        public
    {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nextAddress();
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();

        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();

        vm.expectRevert(IVettedGate.ReferralProgramIsNotActive.selector);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);
    }

    function test_claimReferrerBondCurve_revertWhen_NotEnoughReferrals()
        public
    {
        NodeOperator memory no;
        no.managerAddress = stranger;
        no.rewardAddress = nextAddress();
        no.extendedManagerPermissions = true;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        vm.expectRevert(IVettedGate.NotEnoughReferrals.selector);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);
    }

    function test_claimReferrerBondCurve_revertWhen_AlreadyConsumed() public {
        NodeOperator memory no;
        no.managerAddress = nextAddress();
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(1);

        _addReferrals();

        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);

        vm.expectRevert(IVettedGate.AlreadyConsumed.selector);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);
    }

    function test_claimReferrerBondCurve_revertWhen_InvalidProof() public {
        NodeOperator memory no;
        no.managerAddress = nextAddress();
        no.rewardAddress = stranger;
        no.extendedManagerPermissions = false;
        CSMMock(csm).mock_setNodeOperator(no);
        bytes32[] memory proof = merkleTree.getProof(0);

        _addReferrals();

        vm.expectRevert(IVettedGate.InvalidProof.selector);
        vm.prank(stranger);
        vettedGate.claimReferrerBondCurve(0, proof);
    }
}

contract VettedGateReferralProgramNoSeasonsTest is VettedGateTestBase {
    function setUp() public override {
        super.setUp();
        vm.startPrank(admin);
        vettedGate.grantRole(vettedGate.START_REFERRAL_SEASON_ROLE(), admin);
        vettedGate.grantRole(vettedGate.END_REFERRAL_SEASON_ROLE(), admin);
        vm.stopPrank();
    }

    function test_startNewReferralProgramSeason() public {
        _addReferrals();
        assertEq(vettedGate.getReferralsCount(stranger), 0);

        uint256 season = vettedGate.referralProgramSeasonNumber() + 1;
        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 3;

        vm.expectEmit(address(vettedGate));
        emit IVettedGate.ReferralProgramSeasonStarted(
            season,
            referralCurveId,
            referralsThreshold
        );
        vm.prank(admin);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );

        assertEq(vettedGate.referralCurveId(), referralCurveId);
        assertEq(vettedGate.referralsThreshold(), referralsThreshold);
        assertEq(vettedGate.referralProgramSeasonNumber(), season);
        assertTrue(vettedGate.isReferralProgramSeasonActive());
        assertEq(vettedGate.getReferralsCount(stranger), 0);
    }

    function test_startNewReferralProgramSeason_revertWhen_noRole() public {
        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 3;

        expectRoleRevert(stranger, vettedGate.START_REFERRAL_SEASON_ROLE());
        vm.prank(stranger);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );
    }

    function test_startNewReferralProgramSeason_revertWhen_InvalidReferralsThreshold()
        public
    {
        uint256 referralCurveId = 3;
        uint256 referralsThreshold = 0;

        vm.expectRevert(IVettedGate.InvalidReferralsThreshold.selector);
        vm.prank(admin);
        vettedGate.startNewReferralProgramSeason(
            referralCurveId,
            referralsThreshold
        );
    }

    function test_endCurrentReferralProgramSeason_revertWhen_noSeasonYet()
        public
    {
        vm.expectRevert(IVettedGate.ReferralProgramIsNotActive.selector);
        vm.prank(admin);
        vettedGate.endCurrentReferralProgramSeason();
    }
}
