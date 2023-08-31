// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { FeeDistributorBase } from "../src/FeeDistributorBase.sol";
import { FeeDistributor } from "../src/FeeDistributor.sol";
import { FeeOracle } from "../src/FeeOracle.sol";

import { IFeeOracle } from "../src/interfaces/IFeeOracle.sol";
import { IStETH } from "../src/interfaces/IStETH.sol";

import { MerkleTree } from "./helpers/MerkleTree.sol";
import { OracleMock } from "./mocks/OracleMock.sol";
import { StETHMock } from "./mocks/StETHMock.sol";
import { Stub } from "./mocks/Stub.sol";

contract FeeDistributorTest is Test, FeeDistributorBase {
    using stdStorage for StdStorage;

    FeeDistributor internal feeDistributor;
    OracleMock internal oracle;
    Stub internal bondManager;
    MerkleTree internal tree;
    StETHMock internal stETH;

    function setUp() public {
        oracle = new OracleMock();
        bondManager = new Stub();
        stETH = new StETHMock();

        feeDistributor = new FeeDistributor(
            address(stETH),
            address(oracle),
            address(bondManager)
        );

        tree = oracle.merkleTree();

        vm.label(address(bondManager), "BOND_MANAGER");
    }

    function test_distributeFeesHappyPath() public {
        uint64 noIndex = 42;
        uint64 shares = 100;
        tree.pushLeaf(noIndex, shares);
        bytes32[] memory proof = tree.getProof(0);

        vm.expectEmit(true, true, false, true, address(feeDistributor));
        emit FeeDistributed(noIndex, shares);

        vm.prank(address(bondManager));
        feeDistributor.distributeFees({
            proof: proof,
            noIndex: noIndex,
            shares: shares
        });

        assertEq(stETH.balanceOf(address(bondManager)), shares);
    }

    function test_RevertIf_NotBondManager() public {
        vm.expectRevert(NotBondManager.selector);

        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            noIndex: 0,
            shares: 0
        });
    }

    function test_RevertIf_InvalidProof() public {
        vm.expectRevert(InvalidProof.selector);

        vm.prank(address(bondManager));
        feeDistributor.distributeFees({
            proof: new bytes32[](1),
            noIndex: 0,
            shares: 0
        });
    }

    function test_RevertIf_InvalidShares() public {
        uint64 noIndex = 42;
        uint64 shares = 100;
        tree.pushLeaf(noIndex, shares);
        bytes32[] memory proof = tree.getProof(0);

        stdstore
            .target(address(feeDistributor))
            .sig("distributedShares(uint64)")
            .with_key(noIndex)
            .checked_write(shares + 99);

        vm.expectRevert(InvalidShares.selector);
        vm.prank(address(bondManager));
        uint64 sharesToDistribute = feeDistributor.distributeFees({
            proof: proof,
            noIndex: noIndex,
            shares: shares
        });
    }

    function test_Returns0If_NothingToDistribute() public {
        uint64 noIndex = 42;
        uint64 shares = 100;
        tree.pushLeaf(noIndex, shares);
        bytes32[] memory proof = tree.getProof(0);

        stdstore
            .target(address(feeDistributor))
            .sig("distributedShares(uint64)")
            .with_key(noIndex)
            .checked_write(shares);

        vm.recordLogs();
        vm.prank(address(bondManager));
        uint64 sharesToDistribute = feeDistributor.distributeFees({
            proof: proof,
            noIndex: noIndex,
            shares: shares
        });
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0); // could be changed after resolving https://github.com/foundry-rs/foundry/issues/509
        assertEq(sharesToDistribute, 0);
    }
}
