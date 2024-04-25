// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { AssetRecoverer } from "../src/abstract/AssetRecoverer.sol";
import { AssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";

import { IStETH } from "../src/interfaces/IStETH.sol";

import { Fixtures } from "./helpers/Fixtures.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { Utilities } from "./helpers/Utilities.sol";

contract CSFeeDistributorInitTest is Test, Fixtures, Utilities {
    using stdStorage for StdStorage;

    StETHMock internal stETH;

    address internal stranger;
    address internal oracle;
    CSFeeDistributor internal feeDistributor;
    Stub internal csm;
    Stub internal accounting;
    MerkleTree internal tree;

    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        csm = new Stub();
        accounting = new Stub();

        (, , stETH, ) = initLido();

        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting)
        );
    }

    function test_initialize_revertWhen_zeroAdmin() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                CSFeeDistributor.ZeroAddress.selector,
                "admin"
            )
        );
        feeDistributor.initialize(address(0));
    }
}

contract CSFeeDistributorTest is Test, Fixtures, Utilities {
    using stdStorage for StdStorage;

    StETHMock internal stETH;

    address internal stranger;
    address internal oracle;
    CSFeeDistributor internal feeDistributor;
    Stub internal csm;
    Stub internal accounting;
    MerkleTree internal tree;

    function setUp() public {
        stranger = nextAddress("STRANGER");
        oracle = nextAddress("ORACLE");
        csm = new Stub();
        accounting = new Stub();

        (, , stETH, ) = initLido();

        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting)
        );
        feeDistributor.initialize(address(this));
        feeDistributor.grantRole(feeDistributor.ORACLE_ROLE(), oracle);

        tree = new MerkleTree();

        vm.label(address(accounting), "ACCOUNTING");
        vm.label(address(stETH), "STETH");
        vm.label(address(csm), "CSM");
    }

    function test_distributeFeesHappyPath() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(root, "Qm", shares);

        vm.expectEmit(true, true, false, true, address(feeDistributor));
        emit CSFeeDistributor.FeeDistributed(nodeOperatorId, shares);

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        assertEq(stETH.sharesOf(address(accounting)), shares);
    }

    function test_getFeesToDistribute_notDistributedYet() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(root, "Qm", shares);

        uint256 sharesToDistribute = feeDistributor.getFeesToDistribute({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        assertEq(sharesToDistribute, shares);
    }

    function test_getFeesToDistribute_alreadyDistributed() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(root, "Qm", shares);

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

    function test_hashLeaf() public {
        //  keccak256(bytes.concat(keccak256(abi.encode(1, 1000)))) == 0xe2ad525aaaf1fb7709959cc06e210437a97f34a5833e3a5c90d2099c5373116a
        assertEq(
            feeDistributor.hashLeaf(1, 1000),
            0xe2ad525aaaf1fb7709959cc06e210437a97f34a5833e3a5c90d2099c5373116a
        );
    }

    function test_distributeFees_RevertIf_NotAccounting() public {
        vm.expectRevert(CSFeeDistributor.NotAccounting.selector);

        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: 0
        });
    }

    function test_distributeFees_RevertIf_InvalidProof() public {
        vm.expectRevert(CSFeeDistributor.InvalidProof.selector);

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: 0
        });
    }

    function test_distributeFees_RevertIf_InvalidShares() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(root, "Qm", shares);

        stdstore
            .target(address(feeDistributor))
            .sig("distributedShares(uint256)")
            .with_key(nodeOperatorId)
            .checked_write(shares + 99);

        vm.expectRevert(CSFeeDistributor.InvalidShares.selector);
        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });
    }

    function test_distributeFees_Returns0If_NothingToDistribute() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
        vm.prank(oracle);
        feeDistributor.processOracleReport(root, "Qm", shares);

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

    function test_PendingToDistribute() public {
        uint256 totalShares = 1000;
        stETH.mintShares(address(feeDistributor), totalShares);

        vm.prank(oracle);
        feeDistributor.processOracleReport(someBytes32(), "Qm", 899);

        assertEq(feeDistributor.pendingToDistribute(), 101);
    }

    function test_processOracleReport_RevertWhen_InvalidShares() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32 root = tree.root();

        stETH.mintShares(address(feeDistributor), shares);
    }

    function test_processOracleReport_EmptyReport() public {
        vm.prank(oracle);
        feeDistributor.processOracleReport(bytes32(0), "", 0);

        assertEq(feeDistributor.treeRoot(), bytes32(0));
        assertEq(feeDistributor.treeCid(), "");
    }

    function test_processOracleReport_RevertWhen_TreeRootEmpty() public {
        uint256 shares = 1_000_000;

        // Deliver initial report.
        {
            stETH.mintShares(address(feeDistributor), shares);

            vm.prank(oracle);
            feeDistributor.processOracleReport(someBytes32(), "Qm", shares);
        }

        stETH.mintShares(address(feeDistributor), shares);

        vm.expectRevert(CSFeeDistributor.InvalidTreeRoot.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(bytes32(0), "Qn", shares);
    }

    function test_processOracleReport_RevertWhen_SameRootNonZeroShares()
        public
    {
        uint256 shares = 1_000_000;

        // Deliver initial report.
        {
            stETH.mintShares(address(feeDistributor), shares);

            vm.prank(oracle);
            feeDistributor.processOracleReport(someBytes32(), "Qm", shares);
        }

        stETH.mintShares(address(feeDistributor), shares);
        bytes32 root = feeDistributor.treeRoot();

        vm.expectRevert(CSFeeDistributor.InvalidTreeRoot.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(root, "Qn", shares);
    }

    function test_processOracleReport_RevertWhen_ZeroCidNonZeroShares() public {
        uint256 shares = 1_000_000;

        // Deliver initial report.
        {
            stETH.mintShares(address(feeDistributor), shares);

            vm.prank(oracle);
            feeDistributor.processOracleReport(someBytes32(), "Qm", shares);
        }

        stETH.mintShares(address(feeDistributor), shares);

        vm.expectRevert(CSFeeDistributor.InvalidTreeCID.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(someBytes32(), "", shares);
    }

    function test_processOracleReport_RevertWhen_MoreSharesThanBalance()
        public
    {
        uint256 shares = 1_000_000;

        // Deliver initial report.
        {
            stETH.mintShares(address(feeDistributor), shares);

            vm.prank(oracle);
            feeDistributor.processOracleReport(someBytes32(), "Qm", shares);
        }

        vm.expectRevert(CSFeeDistributor.InvalidShares.selector);
        vm.prank(oracle);
        feeDistributor.processOracleReport(someBytes32(), "Qn", 1);
    }
}

contract CSFeeDistributorAssetRecovererTest is Test, Fixtures, Utilities {
    StETHMock internal stETH;

    address internal recoverer;
    address internal stranger;

    CSFeeDistributor internal feeDistributor;

    function setUp() public {
        Stub accounting = new Stub();

        (, , stETH, ) = initLido();
        vm.label(address(stETH), "STETH");

        recoverer = nextAddress("RECOVERER");
        stranger = nextAddress("STRANGER");

        feeDistributor = new CSFeeDistributor(
            address(stETH),
            address(accounting)
        );
        feeDistributor.initialize(address(this));

        feeDistributor.grantRole(feeDistributor.RECOVERER_ROLE(), recoverer);
    }

    function test_recoverEtherHappyPath() public {
        uint256 amount = 42 ether;
        vm.deal(address(feeDistributor), amount);

        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit AssetRecovererLib.EtherRecovered(recoverer, amount);

        vm.prank(recoverer);
        feeDistributor.recoverEther();

        assertEq(address(feeDistributor).balance, 0);
        assertEq(address(recoverer).balance, amount);
    }

    function test_recoverEther_RevertWhen_Unauthorized() public {
        expectRoleRevert(stranger, feeDistributor.RECOVERER_ROLE());
        vm.prank(stranger);
        feeDistributor.recoverEther();
    }

    function test_recoverERC20HappyPath() public {
        ERC20Testable token = new ERC20Testable();
        token.mint(address(feeDistributor), 1000);

        vm.prank(recoverer);
        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit AssetRecovererLib.ERC20Recovered(address(token), recoverer, 1000);
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

    function test_recoverERC20_RevertWhenStETH() public {
        vm.prank(recoverer);
        vm.expectRevert(AssetRecoverer.NotAllowedToRecover.selector);
        feeDistributor.recoverERC20(address(stETH), 1000);
    }
}
