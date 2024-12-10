// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ICSEarlyAdoption } from "./interfaces/ICSEarlyAdoption.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";

contract CSEarlyAdoption is
    ICSEarlyAdoption,
    AccessControlEnumerable,
    PausableUntil
{
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant SET_TREE_ROOT_ROLE =
        keccak256("SET_TREE_ROOT_ROLE");
    bytes32 public constant SET_CURVE_ID_ROLE = keccak256("SET_CURVE_ID_ROLE");

    /// @dev Address of the Staking Module using Early Adoption contract
    address public immutable MODULE;

    /// @dev Root of the EA members Merkle Tree
    bytes32 public treeRoot;
    /// @dev Id of the bond curve to be assigned for the EA members
    uint256 public curveId;

    mapping(address => bool) internal _consumedAddresses;

    constructor(
        bytes32 _treeRoot,
        uint256 _curveId,
        address module,
        address admin
    ) {
        if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
        if (_curveId == 0) revert InvalidCurveId();
        if (module == address(0)) revert ZeroModuleAddress();
        if (admin == address(0)) revert ZeroAdminAddress();

        if (!ICSModule(module).accounting().curveExists(_curveId))
            revert InvalidCurveId();

        MODULE = module;

        _setTreeRoot(_treeRoot);
        _setCurveId(_curveId);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICSEarlyAdoption
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc ICSEarlyAdoption
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @inheritdoc ICSEarlyAdoption
    function consume(
        address member,
        bytes32[] calldata proof
    ) external whenResumed {
        if (msg.sender != MODULE) revert SenderIsNotModule();
        if (_consumedAddresses[member]) revert AlreadyConsumed();
        if (!verifyProof(member, proof)) revert InvalidProof();
        _consumedAddresses[member] = true;
        emit Consumed(member);
    }

    /// @inheritdoc ICSEarlyAdoption
    function isConsumed(address member) external view returns (bool) {
        return _consumedAddresses[member];
    }

    /// @inheritdoc ICSEarlyAdoption
    function verifyProof(
        address member,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return MerkleProof.verifyCalldata(proof, treeRoot, hashLeaf(member));
    }

    /// @inheritdoc ICSEarlyAdoption
    function hashLeaf(address member) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(member))));
    }

    /// @inheritdoc ICSEarlyAdoption
    function setTreeRoot(
        bytes32 _treeRoot
    ) external onlyRole(SET_TREE_ROOT_ROLE) {
        if (_treeRoot == bytes32(0)) revert InvalidTreeRoot();
        if (_treeRoot == treeRoot) revert InvalidTreeRoot();
        _setTreeRoot(_treeRoot);
    }

    /// @inheritdoc ICSEarlyAdoption
    function setCurveId(uint256 _curveId) external onlyRole(SET_CURVE_ID_ROLE) {
        if (_curveId == 0) revert InvalidCurveId();
        if (_curveId == curveId) revert InvalidCurveId();
        if (!ICSModule(MODULE).accounting().curveExists(_curveId))
            revert InvalidCurveId();

        _setCurveId(_curveId);
    }

    function _setTreeRoot(bytes32 _treeRoot) internal {
        treeRoot = _treeRoot;
        emit TreeRootSet(_treeRoot);
    }

    function _setCurveId(uint256 _curveId) internal {
        curveId = _curveId;
        emit CurveIdSet(_curveId);
    }
}
