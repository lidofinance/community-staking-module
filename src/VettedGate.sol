// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSModule, NodeOperatorManagementProperties, NodeOperator } from "./interfaces/ICSModule.sol";
import { IVettedGate } from "./interfaces/IVettedGate.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";

contract VettedGate is
    IVettedGate,
    AccessControlEnumerableUpgradeable,
    PausableUntil
{
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant SET_TREE_ROOT_ROLE =
        keccak256("SET_TREE_ROOT_ROLE");

    /// @dev Address of the Community Staking Module
    ICSModule public immutable MODULE;

    /// @dev Address of the CSM Accounting
    ICSAccounting public immutable ACCOUNTING;

    /// @dev Id of the bond curve to be assigned for the eligible members
    uint256 public curveId;

    /// @dev Root of the eligible members Merkle Tree
    bytes32 public treeRoot;

    mapping(address => bool) internal _consumedAddresses;

    constructor(address module) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }

        MODULE = ICSModule(module);
        ACCOUNTING = ICSAccounting(MODULE.accounting());

        _disableInitializers();
    }

    function initialize(
        uint256 _curveId,
        bytes32 _treeRoot,
        address admin
    ) external initializer {
        __AccessControlEnumerable_init();

        if (_curveId == ACCOUNTING.DEFAULT_BOND_CURVE_ID()) {
            revert InvalidCurveId();
        }

        /// @dev there is no check for curve existence as this contract might be created before the curve is added
        curveId = _curveId;

        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        _setTreeRoot(_treeRoot);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IVettedGate
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc IVettedGate
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @inheritdoc IVettedGate
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        bytes32[] calldata proof,
        address referrer
    ) external payable returns (uint256 nodeOperatorId) {
        _consume(proof);

        nodeOperatorId = MODULE.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );
        ACCOUNTING.setBondCurve(nodeOperatorId, curveId);
        MODULE.addValidatorKeysETH{ value: msg.value }({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures
        });
    }

    /// @inheritdoc IVettedGate
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata proof,
        address referrer
    ) external returns (uint256 nodeOperatorId) {
        _consume(proof);

        nodeOperatorId = MODULE.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );
        ACCOUNTING.setBondCurve(nodeOperatorId, curveId);
        MODULE.addValidatorKeysStETH({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures,
            permit: permit
        });
    }

    /// @inheritdoc IVettedGate
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes calldata publicKeys,
        bytes calldata signatures,
        NodeOperatorManagementProperties calldata managementProperties,
        ICSAccounting.PermitInput calldata permit,
        bytes32[] calldata proof,
        address referrer
    ) external returns (uint256 nodeOperatorId) {
        _consume(proof);

        nodeOperatorId = MODULE.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );
        ACCOUNTING.setBondCurve(nodeOperatorId, curveId);
        MODULE.addValidatorKeysWstETH({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures,
            permit: permit
        });
    }

    /// @inheritdoc IVettedGate
    function claimBondCurve(
        uint256 nodeOperatorId,
        bytes32[] calldata proof
    ) external {
        NodeOperator memory nodeOperator = MODULE.getNodeOperator(
            nodeOperatorId
        );
        address nodeOperatorAddress = nodeOperator.extendedManagerPermissions
            ? nodeOperator.managerAddress
            : nodeOperator.rewardAddress;
        if (nodeOperatorAddress != msg.sender) {
            revert NotAllowedToClaim();
        }

        _consume(proof);

        ACCOUNTING.setBondCurve(nodeOperatorId, curveId);
    }

    /// @inheritdoc IVettedGate
    function setTreeRoot(
        bytes32 _treeRoot
    ) external onlyRole(SET_TREE_ROOT_ROLE) {
        _setTreeRoot(_treeRoot);
    }

    /// @inheritdoc IVettedGate
    function isConsumed(address member) public view returns (bool) {
        return _consumedAddresses[member];
    }

    /// @inheritdoc IVettedGate
    function verifyProof(
        address member,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return MerkleProof.verifyCalldata(proof, treeRoot, hashLeaf(member));
    }

    /// @inheritdoc IVettedGate
    function hashLeaf(address member) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(member))));
    }

    function _consume(bytes32[] calldata proof) internal whenResumed {
        if (isConsumed(msg.sender)) {
            revert AlreadyConsumed();
        }

        if (!verifyProof(msg.sender, proof)) {
            revert InvalidProof();
        }

        _consumedAddresses[msg.sender] = true;
        emit Consumed(msg.sender);
    }

    function _setTreeRoot(bytes32 _treeRoot) internal {
        if (_treeRoot == bytes32(0)) {
            revert InvalidTreeRoot();
        }

        if (_treeRoot == treeRoot) {
            revert InvalidTreeRoot();
        }

        treeRoot = _treeRoot;
        emit TreeRootSet(_treeRoot);
    }
}
