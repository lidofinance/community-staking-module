// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { FeeDistributorBase } from "../src/FeeDistributorBase.sol";
import { FeeDistributor } from "../src/FeeDistributor.sol";
import { FeeOracle } from "../src/FeeOracle.sol";

import { IFeeOracle } from "../src/interfaces/IFeeOracle.sol";
import { IStETH } from "../src/interfaces/IStETH.sol";

import { Fixtures } from "./helpers/Fixtures.sol";
import { MerkleTree } from "./helpers/MerkleTree.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { OracleMock } from "./helpers/mocks/OracleMock.sol";
import { StETHMock } from "./helpers/mocks/StETHMock.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

contract FeeDistributorTest is Test, Fixtures, FeeDistributorBase {
    using stdStorage for StdStorage;

    StETHMock internal stETH;

    FeeDistributor internal feeDistributor;
    CommunityStakingModuleMock internal csm;
    OracleMock internal oracle;
    Stub internal bondManager;
    MerkleTree internal tree;

    function setUp() public {
        csm = new CommunityStakingModuleMock();
        oracle = new OracleMock();
        bondManager = new Stub();

        (, , stETH, ) = initLido();

        feeDistributor = new FeeDistributor(
            address(csm),
            address(stETH),
            address(oracle),
            address(bondManager)
        );

        tree = oracle.merkleTree();

        vm.label(address(bondManager), "BOND_MANAGER");
        vm.label(address(oracle), "ORACLE");
        vm.label(address(stETH), "STETH");
        vm.label(address(csm), "CSM");
    }

    function test_distributeFeesHappyPath() public {
        uint64 noIndex = 42;
        uint64 shares = 100;
        tree.pushLeaf(noIndex, shares);
        bytes32[] memory proof = tree.getProof(0);

        stETH.mintShares(address(feeDistributor), shares);

        vm.expectEmit(true, true, false, true, address(feeDistributor));
        emit FeeDistributed(noIndex, shares);

        vm.prank(address(bondManager));
        feeDistributor.distributeFees({
            proof: proof,
            noIndex: noIndex,
            shares: shares
        });

        assertEq(stETH.sharesOf(address(bondManager)), shares);
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
        feeDistributor.distributeFees({
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
