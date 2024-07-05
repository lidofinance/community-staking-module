// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSFeeOracle {
    struct ReportData {
        uint256 consensusVersion;
        uint256 refSlot;
        bytes32 treeRoot;
        string treeCid;
        uint256 distributed;
    }

    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AddressCannotBeSame();
    error AddressCannotBeZero();
    error HashCannotBeZero();
    error InitialRefSlotCannotBeLessThanProcessingOne(
        uint256 initialRefSlot,
        uint256 processingRefSlot
    );
    error InvalidContractVersionIncrement();
    error InvalidInitialization();
    error InvalidPerfLeeway();
    error NoConsensusReportToProcess();
    error NonZeroContractVersionOnInit();
    error NotAllowedToRecover();
    error NotInitializing();
    error PauseUntilMustBeInFuture();
    error PausedExpected();
    error ProcessingDeadlineMissed(uint256 deadline);
    error RefSlotAlreadyProcessing();
    error RefSlotCannotDecrease(uint256 refSlot, uint256 prevRefSlot);
    error RefSlotMustBeGreaterThanProcessingOne(
        uint256 refSlot,
        uint256 processingRefSlot
    );
    error ResumedExpected();
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SecondsPerSlotCannotBeZero();
    error SenderIsNotTheConsensusContract();
    error SenderNotAllowed();
    error UnexpectedChainConfig();
    error UnexpectedConsensusVersion(
        uint256 expectedVersion,
        uint256 receivedVersion
    );
    error UnexpectedContractVersion(uint256 expected, uint256 received);
    error UnexpectedDataHash(bytes32 consensusHash, bytes32 receivedHash);
    error UnexpectedRefSlot(uint256 consensusRefSlot, uint256 dataRefSlot);
    error VersionCannotBeSame();
    error ZeroAdminAddress();
    error ZeroFeeDistributorAddress();
    error ZeroPauseDuration();

    event ConsensusHashContractSet(
        address indexed addr,
        address indexed prevAddr
    );
    event ConsensusVersionSet(
        uint256 indexed version,
        uint256 indexed prevVersion
    );
    event ContractVersionSet(uint256 version);
    event FeeDistributorContractSet(address feeDistributorContract);
    event Initialized(uint64 version);
    event Paused(uint256 duration);
    event PerfLeewaySet(uint256 valueBP);
    event ProcessingStarted(uint256 indexed refSlot, bytes32 hash);
    event ReportDiscarded(uint256 indexed refSlot, bytes32 hash);
    event ReportSettled(
        uint256 indexed refSlot,
        uint256 distributed,
        bytes32 treeRoot,
        string treeCid
    );
    event ReportSubmitted(
        uint256 indexed refSlot,
        bytes32 hash,
        uint256 processingDeadlineTime
    );
    event Resumed();
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event WarnProcessingMissed(uint256 indexed refSlot);

    function CONTRACT_MANAGER_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function GENESIS_TIME() external view returns (uint256);

    function MANAGE_CONSENSUS_CONTRACT_ROLE() external view returns (bytes32);

    function MANAGE_CONSENSUS_VERSION_ROLE() external view returns (bytes32);

    function PAUSE_INFINITELY() external view returns (uint256);

    function PAUSE_ROLE() external view returns (bytes32);

    function RECOVERER_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function SECONDS_PER_SLOT() external view returns (uint256);

    function SUBMIT_DATA_ROLE() external view returns (bytes32);

    function avgPerfLeewayBP() external view returns (uint256);

    function discardConsensusReport(uint256 refSlot) external;

    function feeDistributor() external view returns (address);

    function getConsensusContract() external view returns (address);

    function getConsensusReport()
        external
        view
        returns (
            bytes32 hash,
            uint256 refSlot,
            uint256 processingDeadlineTime,
            bool processingStarted
        );

    function getConsensusVersion() external view returns (uint256);

    function getContractVersion() external view returns (uint256);

    function getLastProcessingRefSlot() external view returns (uint256);

    function getResumeSinceTimestamp() external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function initialize(
        address admin,
        address feeDistributorContract,
        address consensusContract,
        uint256 consensusVersion,
        uint256 _avgPerfLeewayBP
    ) external;

    function isPaused() external view returns (bool);

    function pauseFor(uint256 duration) external;

    function pauseUntil(uint256 pauseUntilInclusive) external;

    function recoverERC1155(address token, uint256 tokenId) external;

    function recoverERC20(address token, uint256 amount) external;

    function recoverERC721(address token, uint256 tokenId) external;

    function recoverEther() external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function resume() external;

    function revokeRole(bytes32 role, address account) external;

    function setConsensusContract(address addr) external;

    function setConsensusVersion(uint256 version) external;

    function setFeeDistributorContract(address feeDistributorContract) external;

    function setPerformanceLeeway(uint256 valueBP) external;

    function submitConsensusReport(
        bytes32 reportHash,
        uint256 refSlot,
        uint256 deadline
    ) external;

    function submitReportData(
        ReportData memory data,
        uint256 contractVersion
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
