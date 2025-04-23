// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

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
        strikesData[0] = 1;

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
        strikesData[0] = 1;

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
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        bytes memory pubkey = module.getSigningKeys(0, 0, 1);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 1;
        strikesData[2] = 1;

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
        strikes.processBadPerformanceProof(
            noId,
            0,
            strikesData,
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_defaultRefundRecipient() public {
        uint256 noId = 42;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        bytes memory pubkey = module.getSigningKeys(0, 0, 1);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 1;
        strikesData[2] = 1;

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
        strikes.processBadPerformanceProof(
            noId,
            0,
            strikesData,
            proof,
            address(0)
        );
    }

    function test_processBadPerformanceProof_RevertWhen_InvalidProof() public {
        uint256 noId = 42;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        bytes memory pubkey = module.getSigningKeys(0, 0, 1);
        uint256[] memory strikesData = new uint256[](1);
        strikesData[0] = 1;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(1);

        vm.expectRevert(ICSStrikes.InvalidProof.selector);
        strikes.processBadPerformanceProof(
            noId,
            0,
            strikesData,
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_RevertWhen_NotEnoughStrikesToEject()
        public
    {
        uint256 noId = 42;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](1);
        strikesData[0] = 1;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.expectRevert(ICSStrikes.NotEnoughStrikesToEject.selector);
        strikes.processBadPerformanceProof(
            noId,
            0,
            strikesData,
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_RevertWhen_SigningKeysInvalidOffset()
        public
    {
        uint256 noId = 42;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        (bytes memory pubkey, ) = keysSignatures(1, 1);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 1;
        strikesData[2] = 1;

        tree.pushLeaf(abi.encode(noId, pubkey, strikesData));
        tree.pushLeaf(abi.encode(noId + 1, pubkey, strikesData));

        bytes32 root = tree.root();
        vm.prank(oracle);
        strikes.processOracleReport(root, someCIDv0());

        bytes32[] memory proof = tree.getProof(0);

        vm.expectRevert(ICSStrikes.SigningKeysInvalidOffset.selector);
        strikes.processBadPerformanceProof(
            noId,
            1,
            strikesData,
            proof,
            refundRecipient
        );
    }

    function test_processBadPerformanceProof_Accepts_EmptyProof() public {
        uint256 noId = 42;
        module.mock_setNodeOperatorTotalDepositedKeys(1);
        (bytes memory pubkey, ) = keysSignatures(1);
        uint256[] memory strikesData = new uint256[](3);
        strikesData[0] = 1;
        strikesData[1] = 1;
        strikesData[2] = 1;

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
        strikes.processBadPerformanceProof(
            noId,
            0,
            strikesData,
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
