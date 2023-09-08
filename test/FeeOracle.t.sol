// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { FeeOracleBase } from "../src/FeeOracleBase.sol";
import { FeeOracle } from "../src/FeeOracle.sol";

import { Utilities } from "./helpers/Utilities.sol";

contract FeeOracleTest is Test, Utilities, FeeOracleBase {
    using stdStorage for StdStorage;

    address internal constant ORACLE_ADMIN =
        address(uint160(uint256(keccak256("oracle admin"))));

    uint64 internal constant SECONDS_PER_EPOCH = 32 * 12;

    address[] internal members;
    FeeOracle internal oracle;

    function setUp() public {
        vm.label(ORACLE_ADMIN, "ORACLE_ADMIN");
    }

    function test_RevertIf_GenesisTimeInFuture() public {
        vm.expectRevert(GenesisTimeNotReached.selector);
        vm.warp(1);
        new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 2 // > block.timestamp
        });
    }

    function test_Initialize() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 42,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        assertTrue(oracle.initialized(), "not initialized");

        assertEq(oracle.lastConsolidatedEpoch(), 42);
        assertEq(oracle.initializationEpoch(), 42);
        assertEq(oracle.reportIntervalEpochs(), 2);
    }

    function test_currentEpoch() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        assertEq(oracle.currentEpoch(), 0);

        _vmSetEpoch(10);
        assertEq(oracle.currentEpoch(), 10);

        _vmSetEpoch(13);
        assertEq(oracle.currentEpoch(), 13);
    }

    function test_nextReportEpoch() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 8,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _vmSetEpoch(8);
        assertEq(oracle.nextReportEpoch(), 10);

        _vmSetEpoch(13);
        assertEq(oracle.nextReportEpoch(), 12);
    }

    function test_RevertIf_LastConsolidationEpochInFuture() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 42,
            reportInterval: 1,
            admin: ORACLE_ADMIN
        });

        _vmSetEpoch(41);
        vm.expectRevert(stdError.arithmeticError);
        oracle.nextReportEpoch();
    }

    function test_reportFrame() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 8,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _vmSetEpoch(8);
        (uint64 start, uint64 end) = oracle.reportFrame();
        assertEq(start, 257);
        assertEq(end, 320);
    }

    function test_setReportInterval() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        vm.expectEmit(true, false, false, true, address(oracle));
        emit ReportIntervalSet(2);

        vm.prank(ORACLE_ADMIN);
        oracle.setReportInterval(2);

        assertEq(oracle.reportIntervalEpochs(), 2);
    }

    function test_submitReport() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(3);
        bytes32 newRoot = keccak256("new root");

        _vmSetEpoch(7);

        // Memeber 0 submits a report
        vm.expectEmit(true, false, false, true, address(oracle));
        emit ReportSubmitted(6, members[0], newRoot, "tree");

        vm.prank(members[0]);
        oracle.submitReport({ epoch: 6, newRoot: newRoot, _treeCid: "tree" });

        // Consensus is not reached yet
        assertEq(oracle.reportRoot(), bytes32(0));

        // Member 1 submits a report
        vm.expectEmit(true, false, false, true, address(oracle));
        emit ReportSubmitted(6, members[1], newRoot, "tree");

        vm.expectEmit(true, false, false, true, address(oracle));
        emit ReportConsolidated(6, newRoot, "tree");

        vm.prank(members[1]);
        oracle.submitReport({ epoch: 6, newRoot: newRoot, _treeCid: "tree" });

        // Consensus is reached
        assertEq(oracle.reportRoot(), newRoot);
    }

    function test_RevertIf_TooEarly() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(3);
        _vmSetEpoch(7);

        vm.prank(members[0]);
        vm.expectRevert(ReportTooEarly.selector);
        oracle.submitReport({
            epoch: 99,
            newRoot: bytes32(0),
            _treeCid: "tree"
        });
    }

    function test_RevertIf_TooLate() public {
        _vmSetEpoch(8);

        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 7,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(3);

        vm.prank(members[0]);
        vm.expectRevert(ReportTooLate.selector);
        oracle.submitReport({
            epoch: 7,
            newRoot: bytes32(0),
            _treeCid: "tree"
        });
    }

    function test_hashLeaf() public {
        uint64 noIndex = 42;
        uint64 shares = 999;

        bytes32 hash = 0x20b6ee98002cfd33f27ed874d1aaebcd4ed99991dc504b273af77a78553c4afe;

        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        assertEq(oracle.hashLeaf(noIndex, shares), hash);
    }

    function test_setQuorum() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(10);

        vm.expectEmit(true, false, false, true, address(oracle));
        emit QuorumSet(8);

        vm.prank(ORACLE_ADMIN);
        oracle.setQuorum(8);
        assertEq(oracle.quorum(), 8);
    }

    function test_RevertIf_SetQuorumNotAdmin() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        vm.expectRevert(
            bytes(
                "AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
            )
        );
        vm.prank(address(1));
        oracle.setQuorum(2);

        assertEq(oracle.quorum(), 0, "quorum is not 0");
    }

    function test_RevertIf_QuorumTooSmall() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(3);

        vm.expectRevert(QuorumTooSmall.selector);
        vm.prank(ORACLE_ADMIN);
        oracle.setQuorum(1);
    }

    function test_addMember() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        uint64 quorum = 17;
        address newMember = nextAddress();

        vm.expectEmit(true, true, false, true, address(oracle));
        emit MemberAdded(newMember);

        vm.expectEmit(true, false, false, true, address(oracle));
        emit QuorumSet(quorum);

        vm.prank(ORACLE_ADMIN);
        oracle.addMember(newMember, quorum);

        bool hasRole = oracle.hasRole(oracle.ORACLE_MEMBER_ROLE(), newMember);
        assertTrue(hasRole, "new member has no role");

        assertEq(oracle.quorum(), quorum, "quorum mismatch");
    }

    function test_RevertIf_NotAdmin_AddMember() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        address newMember = nextAddress();
        vm.expectRevert(
            bytes(
                "AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
            )
        );
        vm.prank(address(1));
        oracle.addMember(newMember, 17);

        bool hasRole = oracle.hasRole(oracle.ORACLE_MEMBER_ROLE(), newMember);
        assertFalse(hasRole);
    }

    function test_removeMember() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(2);

        address churnedMember = _popMember();
        uint64 quorum = 1;

        vm.expectEmit(true, true, false, true, address(oracle));
        emit MemberRemoved(churnedMember);

        vm.expectEmit(true, false, false, true, address(oracle));
        emit QuorumSet(quorum);

        vm.prank(ORACLE_ADMIN);
        oracle.removeMember(churnedMember, quorum);

        bool hasRole = oracle.hasRole(
            oracle.ORACLE_MEMBER_ROLE(),
            churnedMember
        );
        assertFalse(hasRole, "churned member still has role");

        assertEq(oracle.quorum(), quorum, "quorum mismatch");
    }

    function test_RevertIF_NotAdmin_RemoveMember() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(2);

        address churnedMember = _popMember();
        uint64 oldQ = oracle.quorum();
        uint64 newQ = oldQ - 1;

        vm.expectRevert(
            bytes(
                "AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
            )
        );
        vm.prank(address(1));
        oracle.removeMember(churnedMember, newQ);

        bool hasRole = oracle.hasRole(
            oracle.ORACLE_MEMBER_ROLE(),
            churnedMember
        );
        assertTrue(hasRole, "churned member has no role");

        assertEq(oracle.quorum(), oldQ, "quorum has been changed");
    }

    function test_RevertIF_NotExistent_RemoveMember() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        _seedMembers(2);

        address noMember = nextAddress();
        uint64 oldQ = oracle.quorum();
        uint64 newQ = oldQ - 1;

        vm.expectRevert(abi.encodeWithSelector(NotMember.selector, noMember));
        vm.prank(ORACLE_ADMIN);
        oracle.removeMember(noMember, newQ);

        assertEq(oracle.quorum(), oldQ, "quorum has been changed");
    }

    function test_pause() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        vm.expectEmit(true, false, false, true, address(oracle));
        emit Paused(ORACLE_ADMIN);

        vm.prank(ORACLE_ADMIN);
        oracle.pause();

        assertTrue(oracle.paused(), "not paused");
    }

    function test_unpause() public {
        oracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0
        });

        oracle.initialize({
            _initializationEpoch: 0,
            reportInterval: 2,
            admin: ORACLE_ADMIN
        });

        vm.prank(ORACLE_ADMIN);
        oracle.pause();

        vm.expectEmit(true, false, false, true, address(oracle));
        emit Unpaused(ORACLE_ADMIN);

        vm.prank(ORACLE_ADMIN);
        oracle.unpause();

        assertFalse(oracle.paused(), "still paused");
    }

    function _popMember() internal returns (address) {
        address m = members[members.length - 1];
        members.pop();
        return m;
    }

    function _seedMembers(uint64 count) internal {
        for (uint64 i = 0; i < count; i++) {
            uint64 q = (i + 1) / 2 + 1; // 50% + 1
            vm.prank(ORACLE_ADMIN);
            members.push(nextAddress());
            oracle.addMember(members[i], q);
        }
    }

    function _vmSetEpoch(uint64 epoch) internal {
        vm.warp(epoch * SECONDS_PER_EPOCH);
    }
}
