// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSAccounting {
    struct BondCurve {
        uint256[] points;
        uint256 trend;
    }

    struct BondLock {
        uint128 amount;
        uint128 retentionUntil;
    }

    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error FailedInnerCall();
    error FailedToSendEther();
    error InvalidBondCurveId();
    error InvalidBondCurveLength();
    error InvalidBondCurveMaxLength();
    error InvalidBondCurveValues();
    error InvalidBondLockAmount();
    error InvalidBondLockRetentionPeriod();
    error InvalidInitialisationCurveId();
    error InvalidInitialization();
    error NodeOperatorDoesNotExist();
    error NotAllowedToRecover();
    error NotInitializing();
    error NothingToClaim();
    error PauseUntilMustBeInFuture();
    error PausedExpected();
    error ResumedExpected();
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SafeERC20FailedOperation(address token);
    error SenderIsNotCSM();
    error ZeroAdminAddress();
    error ZeroChargePenaltyRecipientAddress();
    error ZeroFeeDistributorAddress();
    error ZeroLocatorAddress();
    error ZeroModuleAddress();
    error ZeroPauseDuration();

    event BondBurned(
        uint256 indexed nodeOperatorId,
        uint256 toBurnAmount,
        uint256 burnedAmount
    );
    event BondCharged(
        uint256 indexed nodeOperatorId,
        uint256 toChargeAmount,
        uint256 chargedAmount
    );
    event BondClaimedStETH(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
    event BondClaimedUnstETH(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount,
        uint256 requestId
    );
    event BondClaimedWstETH(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
    event BondCurveAdded(uint256[] bondCurve);
    event BondCurveSet(uint256 indexed nodeOperatorId, uint256 curveId);
    event BondCurveUpdated(uint256 indexed curveId, uint256[] bondCurve);
    event BondDepositedETH(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event BondDepositedStETH(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event BondDepositedWstETH(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event BondLockChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmount,
        uint256 retentionUntil
    );
    event BondLockCompensated(uint256 indexed nodeOperatorId, uint256 amount);
    event BondLockRemoved(uint256 indexed nodeOperatorId);
    event BondLockRetentionPeriodChanged(uint256 retentionPeriod);
    event ChargePenaltyRecipientSet(address chargePenaltyRecipient);
    event ERC1155Recovered(
        address indexed token,
        uint256 tokenId,
        address indexed recipient,
        uint256 amount
    );
    event ERC20Recovered(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event ERC721Recovered(
        address indexed token,
        uint256 tokenId,
        address indexed recipient
    );
    event EtherRecovered(address indexed recipient, uint256 amount);
    event Initialized(uint64 version);
    event Paused(uint256 duration);
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
    event StETHSharesRecovered(address indexed recipient, uint256 shares);

    function ACCOUNTING_MANAGER_ROLE() external view returns (bytes32);

    function CSM() external view returns (address);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DEFAULT_BOND_CURVE_ID() external view returns (uint256);

    function LIDO() external view returns (address);

    function LIDO_LOCATOR() external view returns (address);

    function MANAGE_BOND_CURVES_ROLE() external view returns (bytes32);

    function MAX_BOND_LOCK_RETENTION_PERIOD() external view returns (uint256);

    function MAX_CURVE_LENGTH() external view returns (uint256);

    function MIN_BOND_LOCK_RETENTION_PERIOD() external view returns (uint256);

    function MIN_CURVE_LENGTH() external view returns (uint256);

    function PAUSE_INFINITELY() external view returns (uint256);

    function PAUSE_ROLE() external view returns (bytes32);

    function RECOVERER_ROLE() external view returns (bytes32);

    function RESET_BOND_CURVE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function SET_BOND_CURVE_ROLE() external view returns (bytes32);

    function WITHDRAWAL_QUEUE() external view returns (address);

    function WSTETH() external view returns (address);

    function addBondCurve(
        uint256[] memory bondCurve
    ) external returns (uint256 id);

    function chargeFee(uint256 nodeOperatorId, uint256 amount) external;

    function chargePenaltyRecipient() external view returns (address);

    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        address rewardAddress,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function claimRewardsUnstETH(
        uint256 nodeOperatorId,
        uint256 stEthAmount,
        address rewardAddress,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        address rewardAddress,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function compensateLockedBondETH(uint256 nodeOperatorId) external payable;

    function depositETH(address from, uint256 nodeOperatorId) external payable;

    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput memory permit
    ) external;

    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput memory permit
    ) external;

    function feeDistributor() external view returns (address);

    function getActualLockedBond(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBond(uint256 nodeOperatorId) external view returns (uint256);

    function getBondAmountByKeysCount(
        uint256 keys,
        BondCurve memory curve
    ) external pure returns (uint256);

    function getBondAmountByKeysCount(
        uint256 keys,
        uint256 curveId
    ) external view returns (uint256);

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount,
        uint256 curveId
    ) external view returns (uint256);

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount,
        BondCurve memory curve
    ) external view returns (uint256);

    function getBondCurve(
        uint256 nodeOperatorId
    ) external view returns (BondCurve memory);

    function getBondCurveId(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBondLockRetentionPeriod() external view returns (uint256);

    function getBondShares(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getBondSummary(
        uint256 nodeOperatorId
    ) external view returns (uint256 current, uint256 required);

    function getBondSummaryShares(
        uint256 nodeOperatorId
    ) external view returns (uint256 current, uint256 required);

    function getCurveInfo(
        uint256 curveId
    ) external view returns (BondCurve memory);

    function getKeysCountByBondAmount(
        uint256 amount,
        BondCurve memory curve
    ) external pure returns (uint256);

    function getKeysCountByBondAmount(
        uint256 amount,
        uint256 curveId
    ) external view returns (uint256);

    function getLockedBondInfo(
        uint256 nodeOperatorId
    ) external view returns (BondLock memory);

    function getRequiredBondForNextKeys(
        uint256 nodeOperatorId,
        uint256 additionalKeys
    ) external view returns (uint256);

    function getRequiredBondForNextKeysWstETH(
        uint256 nodeOperatorId,
        uint256 additionalKeys
    ) external view returns (uint256);

    function getResumeSinceTimestamp() external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getUnbondedKeysCount(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getUnbondedKeysCountToEject(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function initialize(
        uint256[] memory bondCurve,
        address admin,
        address _feeDistributor,
        uint256 bondLockRetentionPeriod,
        address _chargePenaltyRecipient
    ) external;

    function isPaused() external view returns (bool);

    function lockBondETH(uint256 nodeOperatorId, uint256 amount) external;

    function pauseFor(uint256 duration) external;

    function penalize(uint256 nodeOperatorId, uint256 amount) external;

    function pullFeeRewards(
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function recoverERC1155(address token, uint256 tokenId) external;

    function recoverERC20(address token, uint256 amount) external;

    function recoverERC721(address token, uint256 tokenId) external;

    function recoverEther() external;

    function recoverStETHShares() external;

    function releaseLockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    ) external;

    function renewBurnerAllowance() external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function resetBondCurve(uint256 nodeOperatorId) external;

    function resume() external;

    function revokeRole(bytes32 role, address account) external;

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external;

    function setChargeRecipient(address _chargePenaltyRecipient) external;

    function setLockedBondRetentionPeriod(uint256 retention) external;

    function settleLockedBondETH(
        uint256 nodeOperatorId
    ) external returns (uint256 settledAmount);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function totalBondShares() external view returns (uint256);

    function updateBondCurve(
        uint256 curveId,
        uint256[] memory bondCurve
    ) external;
}
