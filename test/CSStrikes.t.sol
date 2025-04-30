// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./helpers/mocks/EjectorMock.sol";

import "forge-std/Test.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSStrikes } from "../src/CSStrikes.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { Fixtures } from "./helpers/Fixtures.sol";
import { IAssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { ICSEjector } from "../src/interfaces/ICSEjector.sol";
import { ICSExitPenalties } from "../src/interfaces/ICSExitPenalties.sol";

import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { ICSStrikes } from "../src/interfaces/ICSStrikes.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { InvariantAsserts } from "./helpers/InvariantAsserts.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { ExitPenaltiesMock } from "./helpers/mocks/ExitPenaltiesMock.sol";
import { CSMMock } from "./helpers/mocks/CSMMock.sol";

contract CSStrikesTestBase is Test, Fixtures, Utilities, InvariantAsserts {
    address internal admin;
    address internal stranger;
    address internal refundRecipient;
    address internal oracle;
    CSMMock internal module;
    address internal exitPenalties;
    address internal ejector;
    CSStrikes internal strikes;
    MerkleTree internal tree;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        assertStrikesTree(strikes);
        vm.resumeGasMetering();
    }

    // A bunch of wrapper to test functions with calldata arguments.

    function hashLeaf(
        ICSStrikes.ModuleKeyStrikes calldata keyStrikes,
        bytes memory pubkey
    ) external view returns (bytes32) {
        return strikes.hashLeaf(keyStrikes, pubkey);
    }

    function verifyProof(
        ICSStrikes.ModuleKeyStrikes calldata keyStrikes,
        bytes memory pubkey,
        bytes32[] calldata proof
    ) external view returns (bool) {
        return strikes.verifyProof(keyStrikes, pubkey, proof);
    }

    function verifyMultiProof(
        ICSStrikes.ModuleKeyStrikes[] calldata keyStrikesList,
        bytes[] memory pubkeys,
        bytes32[] calldata proof,
        bool[] calldata proofFlags
    ) external view returns (bool) {
        return
            strikes.verifyMultiProof(
                keyStrikesList,
                pubkeys,
                proof,
                proofFlags
            );
    }

    function processBadPerformanceProof(
        ICSStrikes.ModuleKeyStrikes calldata keyStrikes,
        bytes32[] calldata proof,
        address refundRecipient
    ) external {
        strikes.processBadPerformanceProof(keyStrikes, proof, refundRecipient);
    }
}

contract CSStrikesConstructorTest is CSStrikesTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        oracle = nextAddress("ORACLE");
        module = new CSMMock();
        exitPenalties = address(new ExitPenaltiesMock(address(module)));
        ejector = address(new EjectorMock(address(module)));
    }

    function test_constructor_happyPath() public {
        strikes = new CSStrikes(address(module), oracle, exitPenalties);
        assertEq(address(strikes.MODULE()), address(module));
        assertEq(strikes.ORACLE(), oracle);
        assertEq(address(strikes.EXIT_PENALTIES()), exitPenalties);
    }

    function test_constructor_RevertWhen_ZeroModuleAddress() public {
        vm.expectRevert(ICSStrikes.ZeroModuleAddress.selector);
        new CSStrikes(address(0), oracle, exitPenalties);
    }

    function test_constructor_RevertWhen_ZeroExitPenaltiesAddress() public {
        vm.expectRevert(ICSStrikes.ZeroExitPenaltiesAddress.selector);
        new CSStrikes(address(module), oracle, address(0));
    }

    function test_constructor_RevertWhen_ZeroOracleAddress() public {
        vm.expectRevert(ICSStrikes.ZeroOracleAddress.selector);
        new CSStrikes(exitPenalties, address(0), exitPenalties);
    }

    function test_initialize_happyPath() public {
        strikes = new CSStrikes(address(module), oracle, exitPenalties);
        _enableInitializers(address(strikes));

        vm.expectEmit(address(strikes));
        emit ICSStrikes.EjectorSet(ejector);
        strikes.initialize(admin, ejector);

        assertEq(address(strikes.ejector()), ejector);
        assertTrue(strikes.hasRole(strikes.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_initialize_RevertWhen_ZeroAdminAddress() public {
        strikes = new CSStrikes(address(module), oracle, exitPenalties);
        _enableInitializers(address(strikes));

        vm.expectRevert(ICSStrikes.ZeroAdminAddress.selector);
        strikes.initialize(address(0), ejector);
    }

    function test_initialize_RevertWhen_ZeroEjectorAddress() public {
        strikes = new CSStrikes(address(module), oracle, exitPenalties);
        _enableInitializers(address(strikes));

        vm.expectRevert(ICSStrikes.ZeroEjectorAddress.selector);
        strikes.initialize(admin, address(0));
    }
}

contract CSStrikesTest is CSStrikesTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        refundRecipient = nextAddress("REFUND_RECIPIENT");
        oracle = nextAddress("ORACLE");
        module = new CSMMock();
        exitPenalties = address(new ExitPenaltiesMock(address(module)));
        ejector = address(new EjectorMock(address(module)));

        strikes = new CSStrikes(address(module), oracle, exitPenalties);
        _enableInitializers(address(strikes));
        strikes.initialize(admin, ejector);

        tree = new MerkleTree();

        vm.label(address(strikes), "STRIKES");
    }

    function test_setEjector() public {
        ejector = address(new EjectorMock(address(module)));

        vm.expectEmit(address(strikes));
        emit ICSStrikes.EjectorSet(ejector);

        vm.prank(admin);
        strikes.setEjector(ejector);
        assertEq(address(strikes.ejector()), ejector);
    }

    function test_setEjector_RevertWhen_ZeroEjectorAddress() public {
        vm.expectRevert(ICSStrikes.ZeroEjectorAddress.selector);
        vm.prank(admin);
        strikes.setEjector(address(0));
    }

    function test_hashLeaf() public assertInvariants {
        (bytes memory pubkey, ) = keysSignatures(1);
        assertEq(
            this.hashLeaf(
                ICSStrikes.ModuleKeyStrikes({
                    nodeOperatorId: 42,
                    keyIndex: 0,
                    data: UintArr(100500)
                }),
                pubkey
            ),
            // keccak256(bytes.concat(keccak256(abi.encode(42, pubkey, [100500])))) = 0x3a1e33fb3e7fe10371e522cee19c593a324542e57e4da98719979d7490d2eed7
            0x3a1e33fb3e7fe10371e522cee19c593a324542e57e4da98719979d7490d2eed7
        );
    }

    function test_verifyProof() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = UintArr(1, 0);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        bool isValid = this.verifyProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: 0,
                data: strikesData
            }),
            pubkey,
            proof
        );
        assertTrue(isValid);
    }

    function test_verifyProof_WhenInvalid() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = UintArr(1, 0);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(1);

        bool isValid = this.verifyProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: 0,
                data: strikesData
            }),
            pubkey,
            proof
        );
        assertFalse(isValid);
    }

    function test_processBadPerformanceProof() public {
        uint256 noId = 42;
        uint256 keyIndex = 0;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        bytes memory pubkey = module.getSigningKeys(noId, keyIndex, 1);
        uint256[] memory strikesData = UintArr(1, 1, 1);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.expectCall(
            address(ejector),
            abi.encodeWithSelector(
                ICSEjector.ejectBadPerformer.selector,
                noId,
                pubkey,
                refundRecipient
            )
        );
        vm.expectCall(
            address(exitPenalties),
            abi.encodeWithSelector(
                ICSExitPenalties.processStrikesReport.selector,
                noId,
                pubkey
            )
        );
        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex,
                data: strikesData
            }),
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_defaultRefundRecipient() public {
        uint256 noId = 42;
        uint256 keyIndex = 0;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        bytes memory pubkey = module.getSigningKeys(noId, keyIndex, 1);
        uint256[] memory strikesData = UintArr(1, 1, 1);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.expectCall(
            address(ejector),
            abi.encodeWithSelector(
                ICSEjector.ejectBadPerformer.selector,
                noId,
                pubkey,
                address(this)
            )
        );

        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex,
                data: strikesData
            }),
            proof,
            address(0)
        );
    }

    function test_processBadPerformanceProof_RevertWhen_InvalidProof() public {
        uint256 noId = 42;
        uint256 keyIndex = 0;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        bytes memory pubkey = module.getSigningKeys(noId, keyIndex, 1);
        uint256[] memory strikesData = UintArr(1);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(1);

        vm.expectRevert(ICSStrikes.InvalidProof.selector);
        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex,
                data: strikesData
            }),
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_RevertWhen_NotEnoughStrikesToEject()
        public
    {
        uint256 noId = 42;
        uint256 keyIndex = 0;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = UintArr(1);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.expectRevert(ICSStrikes.NotEnoughStrikesToEject.selector);
        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex,
                data: strikesData
            }),
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_RevertWhen_SigningKeysInvalidOffset()
        public
    {
        uint256 noId = 42;
        uint256 keyIndex = 0;
        module.mock_setNodeOperatorTotalDepositedKeys(keyIndex + 1);
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = UintArr(1, 1, 1);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.expectRevert(ICSStrikes.SigningKeysInvalidOffset.selector);
        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex + 1,
                data: strikesData
            }),
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_Accepts_EmptyProof() public {
        uint256 noId = 42;
        uint256 keyIndex = 0;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = UintArr(1, 1, 1);

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);
        assertEq(proof.length, 0);

        vm.expectCall(
            address(ejector),
            abi.encodeWithSelector(
                ICSEjector.ejectBadPerformer.selector,
                noId,
                pubkey,
                refundRecipient
            )
        );
        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex,
                data: strikesData
            }),
            proof,
            refundRecipient
        );
    }

    function test_processOracleReport() public assertInvariants {
        string memory treeCid = someCIDv0();
        bytes32 treeRoot = someBytes32();

        vm.expectEmit(address(strikes));
        emit ICSStrikes.StrikesDataUpdated(treeRoot, treeCid);

        vm.prank(oracle);
        strikes.processOracleReport(treeRoot, treeCid);

        assertEq(strikes.treeRoot(), treeRoot);
        assertEq(strikes.treeCid(), treeCid);
    }

    function test_processOracleReport_EmptyInitialReport() public {
        vm.recordLogs();
        vm.prank(oracle);
        strikes.processOracleReport(bytes32(0), "");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }

    function test_processOracleReport_EmptySubsequentReport() public {
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), someCIDv0());

        vm.expectEmit(address(strikes));
        emit ICSStrikes.StrikesDataWiped();

        vm.prank(oracle);
        strikes.processOracleReport(bytes32(0), "");

        assertEq(strikes.treeRoot(), bytes32(0));
        assertEq(strikes.treeCid(), "");
    }

    function test_processOracleReport_NonEmptySubsequentReport()
        public
        assertInvariants
    {
        string memory treeCid = someCIDv0();
        bytes32 treeRoot = someBytes32();
        vm.prank(oracle);
        strikes.processOracleReport(treeRoot, treeCid);

        string memory newTreeCid = someCIDv0();
        bytes32 newTreeRoot = someBytes32();

        vm.expectEmit(address(strikes));
        emit ICSStrikes.StrikesDataUpdated(newTreeRoot, newTreeCid);

        vm.prank(oracle);
        strikes.processOracleReport(newTreeRoot, newTreeCid);

        assertEq(strikes.treeRoot(), newTreeRoot);
        assertEq(strikes.treeCid(), newTreeCid);
    }

    function test_processOracleReport_NothingUpdated() public assertInvariants {
        bytes32 root = someBytes32();
        string memory treeCid = someCIDv0();

        vm.prank(oracle);
        strikes.processOracleReport(root, treeCid);

        vm.recordLogs();
        {
            vm.prank(oracle);
            strikes.processOracleReport(root, treeCid);
        }
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);

        assertEq(strikes.treeRoot(), root);
        assertEq(strikes.treeCid(), treeCid);
    }

    function test_processOracleReport_RevertWhen_NotOracle()
        public
        assertInvariants
    {
        vm.expectRevert(ICSStrikes.NotOracle.selector);
        strikes.processOracleReport(bytes32(0), someCIDv0());
    }

    function test_processOracleReport_RevertWhen_OnlyTreeRootEmpty()
        public
        assertInvariants
    {
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), someCIDv0());

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(bytes32(0), someCIDv0());
    }

    function test_processOracleReport_RevertWhen_OnlyTreeCidEmpty()
        public
        assertInvariants
    {
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), someCIDv0());

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), "");
    }

    function test_processOracleReport_RevertWhen_OnlyRootUpdated()
        public
        assertInvariants
    {
        bytes32 root = someBytes32();
        string memory treeCid = someCIDv0();

        vm.prank(oracle);
        strikes.processOracleReport(root, treeCid);

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), treeCid);
    }

    function test_processOracleReport_RevertWhen_OnlyCidUpdated()
        public
        assertInvariants
    {
        bytes32 root = someBytes32();
        string memory treeCid = someCIDv0();

        vm.prank(oracle);
        strikes.processOracleReport(root, treeCid);

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());
    }
}

contract CSStrikesMultiProofTest is CSStrikesTestBase {
    struct Leaf {
        ICSStrikes.ModuleKeyStrikes keyStrikes;
        bytes pubkey;
    }

    Leaf[] internal leaves;

    function setUp() public {
        stranger = nextAddress("STRANGER");
        admin = nextAddress("ADMIN");
        refundRecipient = nextAddress("REFUND_RECIPIENT");
        oracle = nextAddress("ORACLE");
        module = new CSMMock();
        exitPenalties = address(new ExitPenaltiesMock(address(module)));
        ejector = address(new EjectorMock(address(module)));

        strikes = new CSStrikes(address(module), oracle, exitPenalties);
        _enableInitializers(address(strikes));
        strikes.initialize(admin, ejector);

        tree = new MerkleTree();

        vm.label(address(strikes), "STRIKES");
    }

    modifier withTreeOfLeavesCount(uint256 leavesCount) {
        for (uint256 i; i < leavesCount; ++i) {
            uint256[] memory strikesData = UintArr(1, 0, 0);
            (bytes memory pubkey, ) = keysSignatures(1, i);
            leaves.push(
                Leaf(
                    ICSStrikes.ModuleKeyStrikes({
                        nodeOperatorId: i,
                        keyIndex: 0,
                        data: strikesData
                    }),
                    pubkey
                )
            );
            tree.pushLeaf(abi.encode(i, pubkey, strikesData));
        }

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        _;
    }

    function test_verifyMultiProofOneLeaf() public withTreeOfLeavesCount(7) {
        ICSStrikes.ModuleKeyStrikes[]
            memory keyStrikesList = new ICSStrikes.ModuleKeyStrikes[](1);
        keyStrikesList[0] = leaves[0].keyStrikes;

        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = leaves[0].pubkey;

        bytes32[] memory proof = tree.getProof(0);

        bool[] memory proofFlags = new bool[](proof.length);
        for (uint256 i; i < proofFlags.length; ++i) {
            proofFlags[i] = false;
        }

        bool isValid = this.verifyMultiProof(
            keyStrikesList,
            pubkeys,
            proof,
            proofFlags
        );
        assertTrue(isValid);
    }

    function test_verifyMultiProofAllLeaves() public withTreeOfLeavesCount(7) {
        ICSStrikes.ModuleKeyStrikes[]
            memory keyStrikesList = new ICSStrikes.ModuleKeyStrikes[](
                leaves.length
            );
        bytes[] memory pubkeys = new bytes[](leaves.length);

        for (uint256 i; i < leaves.length; ++i) {
            keyStrikesList[i] = leaves[i].keyStrikes;
            pubkeys[i] = leaves[i].pubkey;
        }

        bool[] memory proofFlags = new bool[](leaves.length - 1);
        for (uint256 i; i < proofFlags.length; ++i) {
            proofFlags[i] = true;
        }

        bool isValid = this.verifyMultiProof(
            keyStrikesList,
            pubkeys,
            new bytes32[](0),
            proofFlags
        );
        assertTrue(isValid);
    }

    function test_verifyMultiProofTwoSiblings()
        public
        withTreeOfLeavesCount(7)
    {
        ICSStrikes.ModuleKeyStrikes[]
            memory keyStrikesList = new ICSStrikes.ModuleKeyStrikes[](2);
        keyStrikesList[0] = leaves[0].keyStrikes;
        keyStrikesList[1] = leaves[1].keyStrikes;

        bytes[] memory pubkeys = new bytes[](2);
        pubkeys[0] = leaves[0].pubkey;
        pubkeys[1] = leaves[1].pubkey;

        bytes32[] memory singleLeafProof = tree.getProof(0);
        bytes32[] memory proof = new bytes32[](singleLeafProof.length - 1);
        for (uint256 i; i < proof.length; ++i) {
            proof[i] = singleLeafProof[i + 1];
        }

        bool[] memory proofFlags = new bool[](singleLeafProof.length);
        proofFlags[0] = true; // Start from the sibling leaves
        for (uint256 i = 1; i < proofFlags.length; ++i) {
            proofFlags[i] = false; // The rest from the proof
        }

        bool isValid = this.verifyMultiProof(
            keyStrikesList,
            pubkeys,
            proof,
            proofFlags
        );
        assertTrue(isValid);
    }

    function test_verifyMultiProof_RevertsIfWrongFlagsLength()
        public
        withTreeOfLeavesCount(7)
    {
        ICSStrikes.ModuleKeyStrikes[]
            memory keyStrikesList = new ICSStrikes.ModuleKeyStrikes[](1);
        keyStrikesList[0] = leaves[0].keyStrikes;

        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = leaves[0].pubkey;

        bytes32[] memory proof = tree.getProof(0);

        // Just right
        {
            bool[] memory proofFlags = new bool[](proof.length);
            for (uint256 i; i < proofFlags.length; ++i) {
                proofFlags[i] = false;
            }

            bool isValid = this.verifyMultiProof(
                keyStrikesList,
                pubkeys,
                proof,
                proofFlags
            );
            assertTrue(isValid);
        }

        // Not enough
        {
            bool[] memory proofFlags = new bool[](proof.length - 1);
            for (uint256 i; i < proofFlags.length; ++i) {
                proofFlags[i] = false;
            }

            vm.expectRevert(MerkleProof.MerkleProofInvalidMultiproof.selector);
            this.verifyMultiProof(keyStrikesList, pubkeys, proof, proofFlags);
        }

        // Too much
        {
            bool[] memory proofFlags = new bool[](proof.length + 1);
            for (uint256 i; i < proofFlags.length; ++i) {
                proofFlags[i] = false;
            }

            vm.expectRevert(MerkleProof.MerkleProofInvalidMultiproof.selector);
            this.verifyMultiProof(keyStrikesList, pubkeys, proof, proofFlags);
        }
    }

    function test_verifyMultiProofFails_InvalidProof()
        public
        withTreeOfLeavesCount(7)
    {
        ICSStrikes.ModuleKeyStrikes[]
            memory keyStrikesList = new ICSStrikes.ModuleKeyStrikes[](1);
        keyStrikesList[0] = leaves[0].keyStrikes;

        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = leaves[0].pubkey;

        bytes32[] memory proof = tree.getProof(0);
        assertGt(proof.length, 0);
        proof[0] = bytes32(0);

        bool[] memory proofFlags = new bool[](proof.length);
        for (uint256 i; i < proofFlags.length; ++i) {
            proofFlags[i] = false;
        }

        bool isValid = this.verifyMultiProof(
            keyStrikesList,
            pubkeys,
            proof,
            proofFlags
        );
        assertFalse(isValid);
    }

    function test_verifyMultiProofFails_InvalidLeaf()
        public
        withTreeOfLeavesCount(7)
    {
        ICSStrikes.ModuleKeyStrikes[]
            memory keyStrikesList = new ICSStrikes.ModuleKeyStrikes[](1);
        keyStrikesList[0] = leaves[0].keyStrikes;

        bytes[] memory pubkeys = new bytes[](1);
        pubkeys[0] = leaves[1].pubkey; // <-- error

        bytes32[] memory proof = tree.getProof(0);

        bool[] memory proofFlags = new bool[](proof.length);
        for (uint256 i; i < proofFlags.length; ++i) {
            proofFlags[i] = false;
        }

        bool isValid = this.verifyMultiProof(
            keyStrikesList,
            pubkeys,
            proof,
            proofFlags
        );
        assertFalse(isValid);
    }

    function test_processBadPerformanceMultiProof()
        public
        withTreeOfLeavesCount(7)
    {
        module.mock_setNodeOperatorTotalDepositedKeys(1);

        bytes32[] memory proof = tree.getProof(0);

        vm.expectCall(
            address(ejector),
            abi.encodeWithSelector(
                ICSEjector.ejectBadPerformer.selector,
                noId,
                pubkey,
                refundRecipient
            )
        );
        vm.expectCall(
            address(exitPenalties),
            abi.encodeWithSelector(
                ICSExitPenalties.processStrikesReport.selector,
                noId,
                pubkey
            )
        );
        this.processBadPerformanceProof(
            ICSStrikes.ModuleKeyStrikes({
                nodeOperatorId: noId,
                keyIndex: keyIndex,
                data: strikesData
            }),
            proof,
            refundRecipient
        );
    }
}
