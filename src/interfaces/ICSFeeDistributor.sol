// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

interface ICSFeeDistributor {
    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error FailedInnerCall();
    error FailedToSendEther();
    error FeeSharesDecrease();
    error InvalidInitialization();
    error InvalidProof();
    error InvalidShares();
    error InvalidTreeCID();
    error InvalidTreeRoot();
    error NotAccounting();
    error NotAllowedToRecover();
    error NotEnoughShares();
    error NotInitializing();
    error NotOracle();
    error SafeERC20FailedOperation(address token);
    error ZeroAccountingAddress();
    error ZeroAdminAddress();
    error ZeroOracleAddress();
    error ZeroStEthAddress();

    event DistributionDataUpdated(
        uint256 totalClaimableShares,
        bytes32 treeRoot,
        string treeCid
    );
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
    event FeeDistributed(uint256 indexed nodeOperatorId, uint256 shares);
    event Initialized(uint64 version);
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

    function ACCOUNTING() external view returns (address);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function ORACLE() external view returns (address);

    function RECOVERER_ROLE() external view returns (bytes32);

    function STETH() external view returns (address);

    function distributeFees(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] memory proof
    ) external returns (uint256 sharesToDistribute);

    function distributedShares(uint256) external view returns (uint256);

    function getFeesToDistribute(
        uint256 nodeOperatorId,
        uint256 shares,
        bytes32[] memory proof
    ) external view returns (uint256 sharesToDistribute);

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

    function hashLeaf(
        uint256 nodeOperatorId,
        uint256 shares
    ) external pure returns (bytes32);

    function initialize(address admin) external;

    function pendingSharesToDistribute() external view returns (uint256);

    function processOracleReport(
        bytes32 _treeRoot,
        string memory _treeCid,
        uint256 distributed
    ) external;

    function recoverERC1155(address token, uint256 tokenId) external;

    function recoverERC20(address token, uint256 amount) external;

    function recoverERC721(address token, uint256 tokenId) external;

    function recoverEther() external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function revokeRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function totalClaimableShares() external view returns (uint256);

    function treeCid() external view returns (string memory);

    function treeRoot() external view returns (bytes32);
}
