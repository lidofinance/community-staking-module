// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSStrikes } from "../src/CSStrikes.sol";
import { ICSStrikes } from "../src/interfaces/ICSStrikes.sol";
import { ICSModule } from "../src/interfaces/ICSModule.sol";
import { ICSEjector } from "../src/interfaces/ICSEjector.sol";
import { IAssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Fixtures } from "./helpers/Fixtures.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { InvariantAsserts } from "./helpers/InvariantAsserts.sol";

contract CSStrikesTestBase is Test, Fixtures, Utilities, InvariantAsserts {
    address internal stranger;
    address internal oracle;
    address internal module;
    address internal ejector;
    CSStrikes internal strikes;
    MerkleTree internal tree;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        assertStrikesTree(strikes);
        vm.resumeGasMetering();
    }
}

contract CSStrikesConstructorTest is CSStrikesTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        module = nextAddress("MODULE");
        ejector = nextAddress("EJECTOR");
    }

    function test_constructor_happyPath() public {
        strikes = new CSStrikes(ejector, oracle);
        assertEq(strikes.ORACLE(), oracle);
        assertEq(address(strikes.EJECTOR()), ejector);
    }

    function test_initialize_RevertWhen_ZeroEjectorAddress() public {
        vm.expectRevert(ICSStrikes.ZeroEjectorAddress.selector);
        new CSStrikes(address(0), oracle);
    }

    function test_initialize_RevertWhen_ZeroOracleAddress() public {
        vm.expectRevert(ICSStrikes.ZeroOracleAddress.selector);
        new CSStrikes(ejector, address(0));
    }
}

contract CSStrikesTest is CSStrikesTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        module = nextAddress("MODULE");
        ejector = nextAddress("EJECTOR");

        strikes = new CSStrikes(ejector, oracle);

        tree = new MerkleTree();

        vm.label(address(strikes), "STRIKES");
    }

    function test_hashLeaf() public assertInvariants {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](6);
        strikesData[0] = 100500;
        // keccak256(bytes.concat(keccak256(abi.encode(42, pubkey, [100500])))) = 0x01eba5ed7fb9c5ebb4262844c7125628afcbea15e57bc7f4dd0c80d34d633584
        assertEq(
            strikes.hashLeaf(noId, pubkey, strikesData),
            0x01eba5ed7fb9c5ebb4262844c7125628afcbea15e57bc7f4dd0c80d34d633584
        );
    }

    function test_verifyProof() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](6);
        strikesData[0] = 100500;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        bool isValid = strikes.verifyProof({
            nodeOperatorId: noId,
            pubkey: pubkey,
            strikesData: strikesData,
            proof: proof
        });
        assertTrue(isValid);
    }

    function test_verifyProof_WhenInvalid() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](6);
        strikesData[0] = 100500;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(1);

        bool isValid = strikes.verifyProof({
            nodeOperatorId: noId,
            pubkey: pubkey,
            strikesData: strikesData,
            proof: proof
        });
        assertFalse(isValid);
    }

    function test_processBadPerformanceProof() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 100500;
        strikesData[1] = 100501;
        strikesData[2] = 100502;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.mockCall(
            address(strikes.EJECTOR()),
            abi.encodeWithSelector(ICSEjector.MODULE.selector),
            abi.encode(module)
        );
        vm.mockCall(
            module,
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector),
            abi.encode(pubkey)
        );
        vm.mockCall(
            address(strikes.EJECTOR()),
            abi.encodeWithSelector(ICSEjector.ejectBadPerformer.selector),
            ""
        );

        vm.expectCall(
            address(strikes.EJECTOR()),
            abi.encodeWithSelector(
                ICSEjector.ejectBadPerformer.selector,
                noId,
                0,
                3
            )
        );
        strikes.processBadPerformanceProof(noId, 0, strikesData, proof);
    }

    function test_processBadPerformanceProof_RevertWhen_InvalidProof() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](1);
        strikesData[0] = 100500;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(1);

        vm.mockCall(
            address(strikes.EJECTOR()),
            abi.encodeWithSelector(ICSEjector.MODULE.selector),
            abi.encode(module)
        );
        vm.mockCall(
            module,
            abi.encodeWithSelector(ICSModule.getSigningKeys.selector),
            abi.encode(pubkey)
        );

        vm.expectRevert(ICSStrikes.InvalidProof.selector);
        strikes.processBadPerformanceProof(noId, 0, strikesData, proof);
    }

    function test_processBadPerformanceProof_RevertWhen_EmptyProof() public {
        uint256 noId = 42;
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](6);
        strikesData[0] = 100500;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        vm.expectRevert(ICSStrikes.InvalidProof.selector);
        strikes.processBadPerformanceProof(
            noId,
            0,
            strikesData,
            new bytes32[](0)
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

    function test_processOracleReport_RevertWhen_NotOracle()
        public
        assertInvariants
    {
        vm.expectRevert(ICSStrikes.NotOracle.selector);
        strikes.processOracleReport(bytes32(0), someCIDv0());
    }

    function test_processOracleReport_RevertWhen_TreeRootEmpty()
        public
        assertInvariants
    {
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), someCIDv0());

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(bytes32(0), someCIDv0());
    }

    function test_processOracleReport_RevertWhen_TreeCidEmpty()
        public
        assertInvariants
    {
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), someCIDv0());

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(someBytes32(), "");
    }

    function test_processOracleReport_RevertWhen_NothingUpdated()
        public
        assertInvariants
    {
        bytes32 root = someBytes32();
        string memory treeCid = someCIDv0();

        vm.prank(oracle);
        strikes.processOracleReport(root, treeCid);

        vm.expectRevert(ICSStrikes.InvalidReportData.selector);
        vm.prank(oracle);
        strikes.processOracleReport(root, treeCid);
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
