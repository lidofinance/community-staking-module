// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { IAssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IStETH } from "../src/interfaces/IStETH.sol";
import { ICSFeeDistributor } from "../src/interfaces/ICSFeeDistributor.sol";

import { Fixtures } from "./helpers/Fixtures.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { InvariantAsserts } from "./helpers/InvariantAsserts.sol";

using stdStorage for StdStorage;

contract CSFeeDistributorTestBase is
    Test,
    Fixtures,
    Utilities,
    InvariantAsserts
{
    StETHMock internal stETH;

    address internal stranger;
    address internal oracle;
    CSFeeDistributor internal feeDistributor;
    Stub internal csm;
    Stub internal accounting;
    MerkleTree internal tree;

    modifier assertInvariants() {
        _;
        vm.pauseGasMetering();
        assertFeeDistributorClaimableShares(stETH, feeDistributor);
        assertFeeDistributorTree(feeDistributor);
        vm.resumeGasMetering();
    }
}

contract CSFeeDistributorConstructorTest is CSFeeDistributorTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        csm = new Stub();
        accounting = new Stub();

        (, , stETH, , ) = initLido();
    }

    function test_constructor_happyPath() public {
        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting),
            oracle
        );

        assertEq(feeDistributor.ACCOUNTING(), address(accounting));
        assertEq(address(feeDistributor.STETH()), address(stETH));
        assertEq(feeDistributor.ORACLE(), oracle);
    }

    function test_constructor_RevertWhen_InitOnImpl() public {
        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting),
            oracle
        );

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        feeDistributor.initialize(address(this));
    }

    function test_initialize_RevertWhen_ZeroAccountingAddress() public {
        vm.expectRevert(ICSFeeDistributor.ZeroAccountingAddress.selector);
        new CSFeeDistributor(address(stETH), address(0), oracle);
    }

    function test_initialize_RevertWhen_ZeroStEthAddress() public {
        vm.expectRevert(ICSFeeDistributor.ZeroStEthAddress.selector);
        new CSFeeDistributor(address(0), address(accounting), oracle);
    }

    function test_initialize_RevertWhen_ZeroOracleAddress() public {
        vm.expectRevert(ICSFeeDistributor.ZeroOracleAddress.selector);
        new CSFeeDistributor(address(stETH), address(accounting), address(0));
    }
}

contract CSFeeDistributorInitTest is CSFeeDistributorTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        csm = new Stub();
        accounting = new Stub();

        (, , stETH, , ) = initLido();

        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting),
            oracle
        );
    }

    function test_initialize_RevertWhen_zeroAdmin() public {
        _enableInitializers(address(feeDistributor));

        vm.expectRevert(ICSFeeDistributor.ZeroAdminAddress.selector);
        feeDistributor.initialize(address(0));
    }
}

contract CSFeeDistributorTest is CSFeeDistributorTestBase {
    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        csm = new Stub();
        accounting = new Stub();

        (, , stETH, , ) = initLido();

        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting),
            oracle
        );

        _enableInitializers(address(feeDistributor));
        feeDistributor.initialize(address(this));

        tree = new MerkleTree();

        vm.label(address(accounting), "ACCOUNTING");
        vm.label(address(stETH), "STETH");
        vm.label(address(csm), "CSM");
    }

    function test_distributeFeesHappyPath() public assertInvariants {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );

        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit ICSFeeDistributor.OperatorFeeDistributed(nodeOperatorId, shares);

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        assertEq(stETH.sharesOf(address(accounting)), shares);
    }

    function test_getFeesToDistribute_notDistributedYet()
        public
        assertInvariants
    {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );

        uint256 sharesToDistribute = feeDistributor.getFeesToDistribute({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        assertEq(sharesToDistribute, shares);
    }

    function test_getFeesToDistribute_alreadyDistributed()
        public
        assertInvariants
    {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        uint256 sharesToDistribute = feeDistributor.getFeesToDistribute({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        assertEq(sharesToDistribute, 0);
    }

    function test_getFeesToDistribute_RevertWhenEmptyProof() public {
        uint256 shares = 1337;
        uint256 noId = 42;

        // Put a vulnerable `treeRoot` to make sure we provided the valid, but empty proof.
        stdstore
            .target(address(feeDistributor))
            .sig("treeRoot()")
            .checked_write(feeDistributor.hashLeaf(noId, shares));

        vm.expectRevert(ICSFeeDistributor.InvalidProof.selector);
        feeDistributor.getFeesToDistribute({
            proof: new bytes32[](0),
            nodeOperatorId: noId,
            shares: shares
        });
    }

    function test_getHistoricalDistributionData() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32 root = tree.root();
        string memory treeCid = someCIDv0();
        string memory logCid = someCIDv0();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            treeCid,
            logCid,
            shares,
            refSlot
        );

        ICSFeeDistributor.DistributionData memory data = feeDistributor
            .getHistoricalDistributionData(0);

        assertEq(data.refSlot, refSlot);
        assertEq(data.treeRoot, root);
        assertEq(data.treeCid, treeCid);
        assertEq(data.logCid, logCid);
        assertEq(data.distributed, shares);
    }

    function test_getHistoricalDistributionData_multipleRecords() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32 root = tree.root();
        string memory treeCid = someCIDv0();
        string memory logCid = someCIDv0();
        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            treeCid,
            logCid,
            shares,
            refSlot
        );

        nodeOperatorId = 4;
        shares = 120;
        refSlot = 155;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        root = tree.root();
        treeCid = someCIDv0();
        logCid = someCIDv0();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            treeCid,
            logCid,
            shares,
            refSlot
        );

        uint256 historyLength = feeDistributor.distributionDataHistoryCount();

        ICSFeeDistributor.DistributionData memory data = feeDistributor
            .getHistoricalDistributionData(historyLength - 1);

        assertEq(data.refSlot, refSlot);
        assertEq(data.treeRoot, root);
        assertEq(data.treeCid, treeCid);
        assertEq(data.logCid, logCid);
        assertEq(data.distributed, shares);
    }

    function test_hashLeaf() public assertInvariants {
        //  keccak256(bytes.concat(keccak256(abi.encode(1, 1000)))) == 0xe2ad525aaaf1fb7709959cc06e210437a97f34a5833e3a5c90d2099c5373116a
        assertEq(
            feeDistributor.hashLeaf(1, 1000),
            0xe2ad525aaaf1fb7709959cc06e210437a97f34a5833e3a5c90d2099c5373116a
        );
    }

    function test_distributeFees_RevertWhen_NotAccounting()
        public
        assertInvariants
    {
        vm.expectRevert(ICSFeeDistributor.NotAccounting.selector);

        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: 0
        });
    }

    function test_distributeFees_RevertWhen_InvalidProof()
        public
        assertInvariants
    {
        vm.expectRevert(ICSFeeDistributor.InvalidProof.selector);

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: 0
        });
    }

    function test_distributeFees_RevertWhen_InvalidShares()
        public
        assertInvariants
    {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );

        stdstore
            .target(address(feeDistributor))
            .sig("distributedShares(uint256)")
            .with_key(nodeOperatorId)
            .checked_write(shares + 99);

        vm.expectRevert(ICSFeeDistributor.FeeSharesDecrease.selector);
        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });
    }

    function test_distributeFees_RevertWhen_NotEnoughShares()
        public
        assertInvariants
    {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares - 1);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares - 1,
            refSlot
        );

        vm.expectRevert(ICSFeeDistributor.NotEnoughShares.selector);
        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });
    }

    function test_distributeFees_Returns0If_NothingToDistribute()
        public
        assertInvariants
    {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );

        stdstore
            .target(address(feeDistributor))
            .sig("distributedShares(uint256)")
            .with_key(nodeOperatorId)
            .checked_write(shares);

        vm.recordLogs();
        vm.prank(address(accounting));
        uint256 sharesToDistribute = feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0); // could be changed after resolving https://github.com/foundry-rs/foundry/issues/509
        assertEq(sharesToDistribute, 0);
    }

    function test_pendingSharesToDistribute() public assertInvariants {
        uint256 totalShares = 1000;
        uint256 refSlot = 154;
        stETH.mintShares(address(feeDistributor), totalShares);

        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            someCIDv0(),
            someCIDv0(),
            899,
            refSlot
        );

        assertEq(feeDistributor.pendingSharesToDistribute(), 101);
    }

    function test_processOracleReport_HappyPath() public assertInvariants {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        stETH.mintShares(address(feeDistributor), shares);

        string memory treeCid = someCIDv0();
        string memory logCid = someCIDv0();
        bytes32 treeRoot = someBytes32();

        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit ICSFeeDistributor.DistributionDataUpdated(
            shares,
            treeRoot,
            treeCid
        );

        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit ICSFeeDistributor.ModuleFeeDistributed(shares);

        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit ICSFeeDistributor.DistributionLogUpdated(logCid);

        vm.prank(oracle);
        feeDistributor.processOracleReport(
            treeRoot,
            treeCid,
            logCid,
            shares,
            refSlot
        );

        assertEq(feeDistributor.treeRoot(), treeRoot);
        assertEq(feeDistributor.treeCid(), treeCid);
        assertEq(feeDistributor.logCid(), logCid);
        assertEq(feeDistributor.pendingSharesToDistribute(), 0);
        assertEq(feeDistributor.totalClaimableShares(), shares);
    }

    function test_processOracleReport_EmptyInitialReport() public {
        string memory logCid = someCIDv0();
        uint256 refSlot = 154;

        vm.prank(oracle);
        feeDistributor.processOracleReport(bytes32(0), "", logCid, 0, refSlot);

        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(feeDistributor.treeCid(), "");
        assertEq(feeDistributor.logCid(), logCid);
    }

    function test_processOracleReport_EmptySubsequentReport() public {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        string memory lastTreeCid = feeDistributor.treeCid();
        bytes32 lastRoot = feeDistributor.treeRoot();
        string memory newLogCid = someCIDv0();

        vm.prank(oracle);
        feeDistributor.processOracleReport(
            lastRoot,
            lastTreeCid,
            newLogCid,
            0,
            refSlot
        );

        assertEq(feeDistributor.treeRoot(), lastRoot);
        assertEq(feeDistributor.treeCid(), lastTreeCid);
        assertEq(feeDistributor.logCid(), newLogCid);
        assertEq(feeDistributor.totalClaimableShares(), shares);
    }

    function test_processOracleReport_RevertWhen_InvalidShares()
        public
        assertInvariants
    {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        uint256 refSlot = 154;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));

        stETH.mintShares(address(feeDistributor), shares);

        bytes32 root = tree.root();

        vm.expectRevert(ICSFeeDistributor.InvalidShares.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares + 1,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_TreeRootEmpty()
        public
        assertInvariants
    {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        stETH.mintShares(address(feeDistributor), shares);

        vm.expectRevert(ICSFeeDistributor.InvalidTreeRoot.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            bytes32(0),
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_SameRootNonZeroShares()
        public
        assertInvariants
    {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        stETH.mintShares(address(feeDistributor), shares);
        bytes32 root = feeDistributor.treeRoot();

        vm.expectRevert(ICSFeeDistributor.InvalidTreeRoot.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            root,
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_ZeroTreeCidNonZeroShares()
        public
        assertInvariants
    {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        stETH.mintShares(address(feeDistributor), shares);

        vm.expectRevert(ICSFeeDistributor.InvalidTreeCID.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            "",
            someCIDv0(),
            shares,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_SameTreeCidNonZeroShares()
        public
        assertInvariants
    {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        stETH.mintShares(address(feeDistributor), shares);
        string memory lastTreeCid = feeDistributor.treeCid();

        vm.expectRevert(ICSFeeDistributor.InvalidTreeCID.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            lastTreeCid,
            someCIDv0(),
            shares,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_ZeroLogCid() public {
        uint256 refSlot = 154;
        vm.expectRevert(ICSFeeDistributor.InvalidLogCID.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            someCIDv0(),
            "",
            0,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_SameLogCid() public {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        string memory lastLogCid = feeDistributor.logCid();

        vm.expectRevert(ICSFeeDistributor.InvalidLogCID.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            someCIDv0(),
            lastLogCid,
            0,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_MoreSharesThanBalance()
        public
        assertInvariants
    {
        uint256 shares = 1_000_000;
        uint256 refSlot = 154;
        _makeInitialReport(shares);

        vm.expectRevert(ICSFeeDistributor.InvalidShares.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            someCIDv0(),
            someCIDv0(),
            1,
            refSlot
        );
    }

    function test_processOracleReport_RevertWhen_NotOracle()
        public
        assertInvariants
    {
        uint256 refSlot = 154;
        vm.expectRevert(ICSFeeDistributor.NotOracle.selector);
        vm.prank(stranger);
        feeDistributor.processOracleReport(
            someBytes32(),
            someCIDv0(),
            someCIDv0(),
            1,
            refSlot
        );
    }

    function _makeInitialReport(uint256 shares) internal {
        stETH.mintShares(address(feeDistributor), shares);
        uint256 refSlot = 154;

        vm.prank(oracle);
        feeDistributor.processOracleReport(
            someBytes32(),
            someCIDv0(),
            someCIDv0(),
            shares,
            refSlot
        );
    }
}

contract CSFeeDistributorAssetRecovererTest is CSFeeDistributorTestBase {
    address internal recoverer;

    function setUp() public {
        Stub accounting = new Stub();

        (, , stETH, , ) = initLido();
        vm.label(address(stETH), "STETH");

        recoverer = nextAddress("RECOVERER");
        stranger = nextAddress("STRANGER");

        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting),
            nextAddress("ORACLE")
        );

        _enableInitializers(address(feeDistributor));

        feeDistributor.initialize(address(this));

        feeDistributor.grantRole(feeDistributor.RECOVERER_ROLE(), recoverer);
    }

    function test_recoverEtherHappyPath() public assertInvariants {
        uint256 amount = 42 ether;
        vm.deal(address(feeDistributor), amount);

        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit IAssetRecovererLib.EtherRecovered(recoverer, amount);

        vm.prank(recoverer);
        feeDistributor.recoverEther();

        assertEq(address(feeDistributor).balance, 0);
        assertEq(address(recoverer).balance, amount);
    }

    function test_recoverEther_RevertWhen_Unauthorized()
        public
        assertInvariants
    {
        expectRoleRevert(stranger, feeDistributor.RECOVERER_ROLE());
        vm.prank(stranger);
        feeDistributor.recoverEther();
    }

    function test_recoverERC20HappyPath() public assertInvariants {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(feeDistributor), 1000);

        vm.prank(recoverer);
        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit IAssetRecovererLib.ERC20Recovered(address(token), recoverer, 1000);
        feeDistributor.recoverERC20(address(token), 1000);

        assertEq(token.balanceOf(address(feeDistributor)), 0);
        assertEq(token.balanceOf(recoverer), 1000);
    }

    function test_recoverERC20_RevertWhen_Unauthorized() public {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(feeDistributor), 1000);

        expectRoleRevert(stranger, feeDistributor.RECOVERER_ROLE());
        vm.prank(stranger);
        feeDistributor.recoverERC20(address(token), 1000);
    }

    function test_recoverERC20_RevertWhen_StETH() public assertInvariants {
        vm.prank(recoverer);
        vm.expectRevert(IAssetRecovererLib.NotAllowedToRecover.selector);
        feeDistributor.recoverERC20(address(stETH), 1000);
    }
}
