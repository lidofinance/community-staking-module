// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity 0.8.21;

interface IStakingRouter {
    error AppAuthLidoFailed();
    error ArraysLengthMismatch(
        uint256 firstArrayLength,
        uint256 secondArrayLength
    );
    error DepositContractZeroAddress();
    error DirectETHTransfer();
    error EmptyWithdrawalsCredentials();
    error ExitedValidatorsCountCannotDecrease();
    error InvalidContractVersionIncrement();
    error InvalidDepositsValue(uint256 etherValue, uint256 depositsCount);
    error InvalidPublicKeysBatchLength(uint256 actual, uint256 expected);
    error InvalidReportData(uint256 code);
    error InvalidSignaturesBatchLength(uint256 actual, uint256 expected);
    error NonZeroContractVersionOnInit();
    error ReportedExitedValidatorsExceedDeposited(
        uint256 reportedExitedValidatorsCount,
        uint256 depositedValidatorsCount
    );
    error StakingModuleAddressExists();
    error StakingModuleNotActive();
    error StakingModuleNotPaused();
    error StakingModuleStatusTheSame();
    error StakingModuleUnregistered();
    error StakingModuleWrongName();
    error StakingModulesLimitExceeded();
    error UnexpectedContractVersion(uint256 expected, uint256 received);
    error UnexpectedCurrentValidatorsCount(
        uint256 currentModuleExitedValidatorsCount,
        uint256 currentNodeOpExitedValidatorsCount,
        uint256 currentNodeOpStuckValidatorsCount
    );
    error UnrecoverableModuleError();
    error ValueOver100Percent(string field);
    error ZeroAddress(string field);
    event ContractVersionSet(uint256 version);
    event ExitedAndStuckValidatorsCountsUpdateFailed(
        uint256 indexed stakingModuleId,
        bytes lowLevelRevertData
    );
    event RewardsMintedReportFailed(
        uint256 indexed stakingModuleId,
        bytes lowLevelRevertData
    );
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
    event StakingModuleAdded(
        uint256 indexed stakingModuleId,
        address stakingModule,
        string name,
        address createdBy
    );
    event StakingModuleExitedValidatorsIncompleteReporting(
        uint256 indexed stakingModuleId,
        uint256 unreportedExitedValidatorsCount
    );
    event StakingModuleFeesSet(
        uint256 indexed stakingModuleId,
        uint256 stakingModuleFee,
        uint256 treasuryFee,
        address setBy
    );
    event StakingModuleStatusSet(
        uint256 indexed stakingModuleId,
        uint8 status,
        address setBy
    );
    event StakingModuleTargetShareSet(
        uint256 indexed stakingModuleId,
        uint256 targetShare,
        address setBy
    );
    event StakingRouterETHDeposited(
        uint256 indexed stakingModuleId,
        uint256 amount
    );
    event WithdrawalCredentialsSet(
        bytes32 withdrawalCredentials,
        address setBy
    );
    event WithdrawalsCredentialsChangeFailed(
        uint256 indexed stakingModuleId,
        bytes lowLevelRevertData
    );

    struct NodeOperatorSummary {
        bool isTargetLimitActive;
        uint256 targetValidatorsCount;
        uint256 stuckValidatorsCount;
        uint256 refundedValidatorsCount;
        uint256 stuckPenaltyEndTimestamp;
        uint256 totalExitedValidators;
        uint256 totalDepositedValidators;
        uint256 depositableValidatorsCount;
    }

    struct NodeOperatorDigest {
        uint256 id;
        bool isActive;
        NodeOperatorSummary summary;
    }

    struct StakingModule {
        uint24 id;
        address stakingModuleAddress;
        uint16 stakingModuleFee;
        uint16 treasuryFee;
        uint16 targetShare;
        uint8 status;
        string name;
        uint64 lastDepositAt;
        uint256 lastDepositBlock;
        uint256 exitedValidatorsCount;
    }

    struct StakingModuleSummary {
        uint256 totalExitedValidators;
        uint256 totalDepositedValidators;
        uint256 depositableValidatorsCount;
    }

    struct StakingModuleDigest {
        uint256 nodeOperatorsCount;
        uint256 activeNodeOperatorsCount;
        StakingModule state;
        StakingModuleSummary summary;
    }

    struct ValidatorsCountsCorrection {
        uint256 currentModuleExitedValidatorsCount;
        uint256 currentNodeOperatorExitedValidatorsCount;
        uint256 currentNodeOperatorStuckValidatorsCount;
        uint256 newModuleExitedValidatorsCount;
        uint256 newNodeOperatorExitedValidatorsCount;
        uint256 newNodeOperatorStuckValidatorsCount;
    }

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DEPOSIT_CONTRACT() external view returns (address);

    function FEE_PRECISION_POINTS() external view returns (uint256);

    function MANAGE_WITHDRAWAL_CREDENTIALS_ROLE()
        external
        view
        returns (bytes32);

    function MAX_STAKING_MODULES_COUNT() external view returns (uint256);

    function MAX_STAKING_MODULE_NAME_LENGTH() external view returns (uint256);

    function REPORT_EXITED_VALIDATORS_ROLE() external view returns (bytes32);

    function REPORT_REWARDS_MINTED_ROLE() external view returns (bytes32);

    function STAKING_MODULE_MANAGE_ROLE() external view returns (bytes32);

    function STAKING_MODULE_PAUSE_ROLE() external view returns (bytes32);

    function STAKING_MODULE_RESUME_ROLE() external view returns (bytes32);

    function TOTAL_BASIS_POINTS() external view returns (uint256);

    function UNSAFE_SET_EXITED_VALIDATORS_ROLE()
        external
        view
        returns (bytes32);

    function addStakingModule(
        string memory _name,
        address _stakingModuleAddress,
        uint256 _targetShare,
        uint256 _stakingModuleFee,
        uint256 _treasuryFee
    ) external;

    function deposit(
        uint256 _depositsCount,
        uint256 _stakingModuleId,
        bytes memory _depositCalldata
    ) external payable;

    function getAllNodeOperatorDigests(
        uint256 _stakingModuleId
    ) external view returns (IStakingRouter.NodeOperatorDigest[] memory);

    function getAllStakingModuleDigests()
        external
        view
        returns (IStakingRouter.StakingModuleDigest[] memory);

    function getContractVersion() external view returns (uint256);

    function getDepositsAllocation(
        uint256 _depositsCount
    ) external view returns (uint256 allocated, uint256[] memory allocations);

    function getLido() external view returns (address);

    function getNodeOperatorDigests(
        uint256 _stakingModuleId,
        uint256[] memory _nodeOperatorIds
    )
        external
        view
        returns (IStakingRouter.NodeOperatorDigest[] memory digests);

    function getNodeOperatorDigests(
        uint256 _stakingModuleId,
        uint256 _offset,
        uint256 _limit
    ) external view returns (IStakingRouter.NodeOperatorDigest[] memory);

    function getNodeOperatorSummary(
        uint256 _stakingModuleId,
        uint256 _nodeOperatorId
    ) external view returns (IStakingRouter.NodeOperatorSummary memory summary);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getStakingFeeAggregateDistribution()
        external
        view
        returns (uint96 modulesFee, uint96 treasuryFee, uint256 basePrecision);

    function getStakingFeeAggregateDistributionE4Precision()
        external
        view
        returns (uint16 modulesFee, uint16 treasuryFee);

    function getStakingModule(
        uint256 _stakingModuleId
    ) external view returns (IStakingRouter.StakingModule memory);

    function getStakingModuleActiveValidatorsCount(
        uint256 _stakingModuleId
    ) external view returns (uint256 activeValidatorsCount);

    function getStakingModuleDigests(
        uint256[] memory _stakingModuleIds
    )
        external
        view
        returns (IStakingRouter.StakingModuleDigest[] memory digests);

    function getStakingModuleIds()
        external
        view
        returns (uint256[] memory stakingModuleIds);

    function getStakingModuleIsActive(
        uint256 _stakingModuleId
    ) external view returns (bool);

    function getStakingModuleIsDepositsPaused(
        uint256 _stakingModuleId
    ) external view returns (bool);

    function getStakingModuleIsStopped(
        uint256 _stakingModuleId
    ) external view returns (bool);

    function getStakingModuleLastDepositBlock(
        uint256 _stakingModuleId
    ) external view returns (uint256);

    function getStakingModuleMaxDepositsCount(
        uint256 _stakingModuleId,
        uint256 _maxDepositsValue
    ) external view returns (uint256);

    function getStakingModuleNonce(
        uint256 _stakingModuleId
    ) external view returns (uint256);

    function getStakingModuleStatus(
        uint256 _stakingModuleId
    ) external view returns (uint8);

    function getStakingModuleSummary(
        uint256 _stakingModuleId
    )
        external
        view
        returns (IStakingRouter.StakingModuleSummary memory summary);

    function getStakingModules()
        external
        view
        returns (IStakingRouter.StakingModule[] memory res);

    function getStakingModulesCount() external view returns (uint256);

    function getStakingRewardsDistribution()
        external
        view
        returns (
            address[] memory recipients,
            uint256[] memory stakingModuleIds,
            uint96[] memory stakingModuleFees,
            uint96 totalFee,
            uint256 precisionPoints
        );

    function getTotalFeeE4Precision() external view returns (uint16 totalFee);

    function getWithdrawalCredentials() external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function hasStakingModule(
        uint256 _stakingModuleId
    ) external view returns (bool);

    function initialize(
        address _admin,
        address _lido,
        bytes32 _withdrawalCredentials
    ) external;

    function onValidatorsCountsByNodeOperatorReportingFinished() external;

    function pauseStakingModule(uint256 _stakingModuleId) external;

    function renounceRole(bytes32 role, address account) external;

    function reportRewardsMinted(
        uint256[] memory _stakingModuleIds,
        uint256[] memory _totalShares
    ) external;

    function reportStakingModuleExitedValidatorsCountByNodeOperator(
        uint256 _stakingModuleId,
        bytes memory _nodeOperatorIds,
        bytes memory _exitedValidatorsCounts
    ) external;

    function reportStakingModuleStuckValidatorsCountByNodeOperator(
        uint256 _stakingModuleId,
        bytes memory _nodeOperatorIds,
        bytes memory _stuckValidatorsCounts
    ) external;

    function resumeStakingModule(uint256 _stakingModuleId) external;

    function revokeRole(bytes32 role, address account) external;

    function setStakingModuleStatus(
        uint256 _stakingModuleId,
        uint8 _status
    ) external;

    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function unsafeSetExitedValidatorsCount(
        uint256 _stakingModuleId,
        uint256 _nodeOperatorId,
        bool _triggerUpdateFinish,
        IStakingRouter.ValidatorsCountsCorrection memory _correction
    ) external;

    function updateExitedValidatorsCountByStakingModule(
        uint256[] memory _stakingModuleIds,
        uint256[] memory _exitedValidatorsCounts
    ) external returns (uint256);

    function updateRefundedValidatorsCount(
        uint256 _stakingModuleId,
        uint256 _nodeOperatorId,
        uint256 _refundedValidatorsCount
    ) external;

    function updateStakingModule(
        uint256 _stakingModuleId,
        uint256 _targetShare,
        uint256 _stakingModuleFee,
        uint256 _treasuryFee
    ) external;

    function updateTargetValidatorsLimits(
        uint256 _stakingModuleId,
        uint256 _nodeOperatorId,
        bool _isTargetLimitActive,
        uint256 _targetLimit
    ) external;

    receive() external payable;
}