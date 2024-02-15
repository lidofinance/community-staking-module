// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { UnstructuredStorage } from "../lib/base-oracle/lib/UnstructuredStorage.sol";
import { HashConsensus } from "../lib/base-oracle/oracle/HashConsensus.sol";
import { DistributorMock } from "./helpers/mocks/DistributorMock.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { Stub } from "./helpers/mocks/Stub.sol";

contract CSFeeOracleForTest is CSFeeOracle {
    using UnstructuredStorage for bytes32;

    constructor(
        uint256 secondsPerSlot,
        uint256 genesisTime
    ) CSFeeOracle(secondsPerSlot, genesisTime) {
        // Version.sol constructor sets the storage value to uint256.max and effectively
        // prevents the deployed contract from being initialized. To be able to use the
        // contract in tests with no proxy above, we need to set the version to 0.
        CONTRACT_VERSION_POSITION.setStorageUint256(0);
    }
}

contract CSFeeOracleTest is Test, Utilities {
    using Strings for uint256;

    struct ChainConfig {
        uint256 secondsPerSlot;
        uint256 slotsPerEpoch;
        uint256 genesisTime;
    }

    address internal constant ORACLE_ADMIN =
        address(uint160(uint256(keccak256("ORACLE_ADMIN"))));

    uint256 internal constant CONSENSUS_VERSION = 1;
    uint256 internal constant INITIAL_EPOCH = 17;

    CSFeeOracleForTest public oracle;
    HashConsensus public consensus;
    ChainConfig public chainConfig;
    address[] public members;
    uint256 public quorum;

    event ReportReceived(
        uint256 indexed refSlot,
        address indexed member,
        bytes32 report
    );

    event ReportConsolidated(
        uint256 indexed refSlot,
        uint256 distributed,
        bytes32 newRoot,
        string treeCid
    );

    function setUp() public {
        chainConfig = ChainConfig({
            secondsPerSlot: 12,
            slotsPerEpoch: 32,
            genesisTime: 0
        });

        vm.label(ORACLE_ADMIN, "ORACLE_ADMIN");
        _vmSetEpoch(INITIAL_EPOCH);
    }

    function test_happyPath() public {
        {
            _deployFeeOracleAndHashConsensus(_lastSlotOfEpoch(1));
            _grantAllRolesToAdmin();
            _assertNoReportOnInit();
            _setInitialEpoch();
            _seedMembers(3);
        }

        uint256 startSlot;
        uint256 refSlot;

        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        // INITIAL_EPOCH is far above the lastProcessingRefSlot's epoch
        assertNotEq(startSlot, refSlot);

        CSFeeOracle.ReportData memory data = CSFeeOracle.ReportData({
            consensusVersion: oracle.getConsensusVersion(),
            refSlot: refSlot,
            treeRoot: keccak256("root"),
            treeCid: "QmCID0",
            distributed: 1337
        });

        bytes32 reportHash = keccak256(abi.encode(data));
        _reachConsensus(refSlot, reportHash);

        vm.expectEmit(true, true, true, true, address(oracle));
        emit ReportConsolidated(
            refSlot,
            data.distributed,
            data.treeRoot,
            data.treeCid
        );
        vm.prank(members[0]);
        oracle.submitReportData({ data: data, contractVersion: 1 });

        assertEq(oracle.treeRoot(), data.treeRoot);
        assertEq(oracle.treeCid(), data.treeCid);

        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        assertEq(startSlot, refSlot);

        // Advance block.timestamp to the middle of the frame
        _vmSetEpoch(INITIAL_EPOCH + _epochsInDays(14));
        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        assertEq(startSlot, refSlot);

        // Advance block.timestamp to the end of the frame
        _vmSetEpoch(INITIAL_EPOCH + _epochsInDays(28));
        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        assertLt(startSlot, refSlot);
    }

    function test_reportFrame() public {
        {
            _deployFeeOracleAndHashConsensus(_lastSlotOfEpoch(INITIAL_EPOCH));
            _grantAllRolesToAdmin();
            _assertNoReportOnInit();
            _setInitialEpoch();
        }

        uint256 startSlot;
        uint256 refSlot;
        uint256 tmp;

        // Check the startSlot at the very beginning of the frame
        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        assertEq(startSlot, refSlot);

        // Advance block.timestamp to the middle of the frame
        _vmSetEpoch(INITIAL_EPOCH + _epochsInDays(14));
        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        assertEq(startSlot, refSlot);

        // Advance block.timestamp to the end of the frame
        _vmSetEpoch(INITIAL_EPOCH + _epochsInDays(28));
        (, startSlot, , ) = oracle.getConsensusReport();
        (refSlot, ) = consensus.getCurrentFrame();
        assertGt(refSlot, startSlot);

        tmp = startSlot;
        // Advance block.timestamp far above the first frame
        _vmSetEpoch(INITIAL_EPOCH + _epochsInDays(999));
        (, startSlot, , ) = oracle.getConsensusReport();
        assertEq(tmp, startSlot, "startSlot must not change");
    }

    function _deployFeeOracleAndHashConsensus(
        uint256 lastProcessingRefSlot
    ) internal {
        oracle = new CSFeeOracleForTest({
            secondsPerSlot: chainConfig.secondsPerSlot,
            genesisTime: chainConfig.genesisTime
        });

        consensus = new HashConsensus({
            slotsPerEpoch: chainConfig.slotsPerEpoch,
            secondsPerSlot: chainConfig.secondsPerSlot,
            genesisTime: chainConfig.genesisTime,
            epochsPerFrame: _epochsInDays(28),
            fastLaneLengthSlots: 0,
            admin: ORACLE_ADMIN,
            reportProcessor: address(oracle)
        });

        oracle.initialize(
            ORACLE_ADMIN,
            address(new DistributorMock()),
            address(consensus),
            CONSENSUS_VERSION,
            lastProcessingRefSlot
        );
    }

    function _grantAllRolesToAdmin() internal {
        vm.startPrank(ORACLE_ADMIN);
        /* prettier-ignore */
        {
            consensus.grantRole(consensus.MANAGE_MEMBERS_AND_QUORUM_ROLE(), ORACLE_ADMIN);
            consensus.grantRole(consensus.DISABLE_CONSENSUS_ROLE(), ORACLE_ADMIN);
            consensus.grantRole(consensus.MANAGE_FRAME_CONFIG_ROLE(), ORACLE_ADMIN);
            consensus.grantRole(consensus.MANAGE_FAST_LANE_CONFIG_ROLE(), ORACLE_ADMIN);
            consensus.grantRole(consensus.MANAGE_REPORT_PROCESSOR_ROLE(), ORACLE_ADMIN);

            oracle.grantRole(oracle.MANAGE_CONSENSUS_CONTRACT_ROLE(), ORACLE_ADMIN);
            oracle.grantRole(oracle.MANAGE_CONSENSUS_VERSION_ROLE(), ORACLE_ADMIN);
            oracle.grantRole(oracle.PAUSE_ROLE(), ORACLE_ADMIN);
            oracle.grantRole(oracle.RESUME_ROLE(), ORACLE_ADMIN);
        }
        vm.stopPrank();
    }

    function _seedMembers(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            uint256 q = (members.length + 1) / 2 + 1; // 50% + 1
            address newMember = nextAddress();
            vm.label(newMember, string.concat("MEMBER", i.toString()));
            vm.startPrank(ORACLE_ADMIN);
            {
                consensus.addMember(newMember, q);
                oracle.grantRole(oracle.SUBMIT_DATA_ROLE(), newMember);
            }
            vm.stopPrank();
            members.push(newMember);
            quorum = q;
        }
    }

    function _assertNoReportOnInit() internal {
        (
            bytes32 hash, // refSlot
            ,
            uint256 processingDeadlineTime,
            bool processingStarted
        ) = oracle.getConsensusReport();

        // Skips the check for refSlot, see test_reportFrame
        assertEq(hash, bytes32(0));
        assertEq(processingDeadlineTime, 0);
        assertEq(processingStarted, false);
    }

    function _setInitialEpoch() internal {
        vm.prank(ORACLE_ADMIN);
        consensus.updateInitialEpoch(INITIAL_EPOCH);
    }

    function _reachConsensus(uint256 refSlot, bytes32 hash) internal {
        for (uint256 i; i < quorum; i++) {
            vm.expectEmit(true, true, true, true, address(consensus));
            emit ReportReceived(refSlot, members[i], hash);

            vm.prank(members[i]);
            consensus.submitReport(refSlot, hash, CONSENSUS_VERSION);
        }

        (uint256 _refSlot, bytes32 _hash, ) = consensus.getConsensusState();
        assertEq(_refSlot, refSlot, "_reachConsensus: refSlot mismatch");
        assertEq(_hash, hash, "_reachConsensus: hash mismatch");
    }

    function _epochsInDays(uint256 daysCount) internal view returns (uint256) {
        return
            (daysCount * 24 * 60 * 60) /
            chainConfig.secondsPerSlot /
            chainConfig.slotsPerEpoch;
    }

    function _lastSlotOfEpoch(uint256 epoch) internal pure returns (uint256) {
        require(epoch > 0, "epoch must be greater than 0");
        return epoch * 32 - 1;
    }

    function _vmSetEpoch(uint256 epoch) internal {
        /* prettier-ignore */
        vm.warp(
            epoch *
            chainConfig.secondsPerSlot *
            chainConfig.slotsPerEpoch
        );
    }
}
