// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSFeeDistributorBase, CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { AssetRecoverer } from "../src/AssetRecoverer.sol";
import { AssetRecovererLib } from "../src/lib/AssetRecovererLib.sol";

import { IStETH } from "../src/interfaces/IStETH.sol";

import { Fixtures } from "./helpers/Fixtures.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { ERC20Testable } from "./helpers/ERCTestable.sol";
import { Utilities } from "./helpers/Utilities.sol";

contract CSFeeDistributorTest is
    Test,
    Fixtures,
    Utilities,
    CSFeeDistributorBase
{
    using stdStorage for StdStorage;

    StETHMock internal stETH;

    address internal stranger;
    address internal oracle;
    CSFeeDistributor internal feeDistributor;
    CommunityStakingModuleMock internal csm;
    Stub internal accounting;
    MerkleTree internal tree;

    function setUp() public {
        stranger = nextAddress("stranger");
        oracle = nextAddress("oracle");
        csm = new CommunityStakingModuleMock();
        accounting = new Stub();

        (, , stETH, ) = initLido();

        feeDistributor = new CSFeeDistributor(
            address(csm),
            address(stETH),
            address(accounting),
            address(this)
        );
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

        stETH.mintShares(address(csm), shares);
        vm.prank(oracle);
        feeDistributor.processTreeData(root, "", shares);

        vm.expectEmit(true, true, false, true, address(feeDistributor));
        emit FeeDistributed(nodeOperatorId, shares);

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });

        assertEq(stETH.sharesOf(address(accounting)), shares);
    }

    function test_RevertIf_NotAccounting() public {
        vm.expectRevert(NotAccounting.selector);

        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: 0
        });
    }

    function test_RevertIf_InvalidProof() public {
        vm.expectRevert(InvalidProof.selector);

        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            nodeOperatorId: 0,
            shares: 0
        });
    }

    function test_RevertIf_InvalidShares() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();

        stETH.mintShares(address(csm), shares);
        vm.prank(oracle);
        feeDistributor.processTreeData(root, "", shares);

        stdstore
            .target(address(feeDistributor))
            .sig("distributedShares(uint256)")
            .with_key(nodeOperatorId)
            .checked_write(shares + 99);

        vm.expectRevert(InvalidShares.selector);
        vm.prank(address(accounting));
        feeDistributor.distributeFees({
            proof: proof,
            nodeOperatorId: nodeOperatorId,
            shares: shares
        });
    }

    function test_Returns0If_NothingToDistribute() public {
        uint256 nodeOperatorId = 42;
        uint256 shares = 100;
        tree.pushLeaf(abi.encode(nodeOperatorId, shares));
        bytes32[] memory proof = tree.getProof(0);
        bytes32 root = tree.root();
        stETH.mintShares(address(csm), shares);
        vm.prank(oracle);
        feeDistributor.processTreeData(root, "", shares);

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

    function test_recoverERC20() public {
        feeDistributor.grantRole(feeDistributor.RECOVERER_ROLE(), stranger);

        ERC20Testable token = new ERC20Testable();
        token.mint(address(feeDistributor), 1000);

        vm.prank(stranger);
        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit AssetRecovererLib.ERC20Recovered(address(token), stranger, 1000);
        feeDistributor.recoverERC20(address(token), 1000);

        assertEq(token.balanceOf(address(feeDistributor)), 0);
        assertEq(token.balanceOf(stranger), 1000);
    }

    function test_recoverERC20_revertWhenStETH() public {
        feeDistributor.grantRole(feeDistributor.RECOVERER_ROLE(), stranger);

        vm.prank(stranger);
        vm.expectRevert(AssetRecoverer.NotAllowedToRecover.selector);
        feeDistributor.recoverERC20(address(stETH), 1000);
    }

    function test_recoverStETHShares() public {
        feeDistributor.grantRole(feeDistributor.RECOVERER_ROLE(), stranger);
        bytes32 root = tree.root();

        stETH.mintShares(address(csm), stETH.getSharesByPooledEth(1 ether));
        uint256 receivedShares = stETH.getSharesByPooledEth(0.3 ether);

        vm.prank(oracle);
        feeDistributor.processTreeData(root, "", receivedShares);
        uint256 sharesToRecover = stETH.sharesOf(address(feeDistributor)) -
            receivedShares;

        vm.prank(stranger);
        vm.expectEmit(true, true, true, true, address(feeDistributor));
        emit AssetRecovererLib.StETHSharesRecovered(stranger, sharesToRecover);
        feeDistributor.recoverStETHShares();

        assertEq(stETH.sharesOf(address(feeDistributor)), receivedShares);
        assertEq(stETH.sharesOf(stranger), sharesToRecover);
    }
}
