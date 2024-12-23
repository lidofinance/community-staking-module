// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IVettedGate } from "./interfaces/IVettedGate.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";

contract VettedGate is IVettedGate, AccessControlEnumerable, PausableUntil {
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant SET_TREE_ROOT_ROLE =
        keccak256("SET_TREE_ROOT_ROLE");

    /// @dev Address of the Community Staking Module using Early Adoption contract
    ICSModule public immutable CSM;
    /// @dev Id of the bond curve to be assigned for the EA members
    uint256 public immutable CURVE_ID;

    /// @dev Root of the EA members Merkle Tree
    bytes32 public treeRoot;

    mapping(address => bool) internal _consumedAddresses;

    constructor(
        bytes32 _treeRoot,
        uint256 curveId,
        address csm,
        address admin
    ) {
        if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
        if (curveId == 0) revert InvalidCurveId();
        if (csm == address(0)) revert ZeroModuleAddress();
        if (admin == address(0)) revert ZeroAdminAddress();

        CSM = ICSModule(csm);
        CURVE_ID = curveId;

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
    ) external payable {
        _consume(msg.sender, proof);

        uint256 nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );
        CSM.claimBeneficialBondCurve(nodeOperatorId, CURVE_ID);
        CSM.addValidatorKeysETH{ value: msg.value }({
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
    ) external {
        _consume(msg.sender, proof);

        uint256 nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );
        CSM.claimBeneficialBondCurve(nodeOperatorId, CURVE_ID);
        CSM.addValidatorKeysStETH({
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
    ) external {
        _consume(msg.sender, proof);

        uint256 nodeOperatorId = CSM.createNodeOperator(
            msg.sender,
            managementProperties,
            referrer
        );
        CSM.claimBeneficialBondCurve(nodeOperatorId, CURVE_ID);
        CSM.addValidatorKeysWstETH({
            from: msg.sender,
            nodeOperatorId: nodeOperatorId,
            keysCount: keysCount,
            publicKeys: publicKeys,
            signatures: signatures,
            permit: permit
        });
    }

    /// @inheritdoc IVettedGate
    function setTreeRoot(
        bytes32 _treeRoot
    ) external onlyRole(SET_TREE_ROOT_ROLE) {
        if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
        if (_treeRoot == treeRoot) revert InvalidTreeRoot();
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

    function _consume(
        address member,
        bytes32[] calldata proof
    ) internal whenResumed {
        if (isConsumed(msg.sender)) revert AlreadyConsumed();
        if (!verifyProof(msg.sender, proof)) revert InvalidProof();
        _consumedAddresses[member] = true;
        emit Consumed(member);
    }

    function _setTreeRoot(bytes32 _treeRoot) internal {
        treeRoot = _treeRoot;
        emit TreeRootSet(_treeRoot);
    }
}
