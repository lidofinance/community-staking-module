// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { NodeOperatorManagementProperties } from "./ICSModule.sol";
import { ICSAccounting } from "./ICSAccounting.sol";
import { ICSModule } from "./ICSModule.sol";

interface IVettedGate {
    event TreeRootSet(bytes32 indexed treeRoot);
    event Consumed(address indexed member);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidTreeRoot();
    error InvalidCurveId();
    error ZeroModuleAddress();
    error ZeroAdminAddress();

    function PAUSE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function SET_TREE_ROOT_ROLE() external view returns (bytes32);

    function CSM() external view returns (ICSModule);

    function CURVE_ID() external view returns (uint256);

    function treeRoot() external view returns (bytes32);

    /// @notice Pause the contract for a given duration
    ///         Pausing the contract prevent creating new node operators using EA
    ///         and consuming EA benefits for the existing ones
    /// @param duration Duration of the pause
    function pauseFor(uint256 duration) external;

    /// @notice Resume the contract
    function resume() external;

    /// @notice Add a new Node Operator using ETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        bytes32[] memory eaProof,
        address referrer
    ) external payable;

    /// @notice Add a new Node Operator using stETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param permit Optional. Permit to use stETH as bond
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        ICSAccounting.PermitInput memory permit,
        bytes32[] memory eaProof,
        address referrer
    ) external;

    /// @notice Add a new Node Operator using wstETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @notice Due to the stETH rounding issue make sure to make approval or sign permit with extra 10 wei to avoid revert
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that managerAddress will be able to change rewardAddress.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param permit Optional. Permit to use wstETH as bond
    /// @param eaProof Optional. Merkle proof of the sender being eligible for the Early Adoption
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        ICSAccounting.PermitInput memory permit,
        bytes32[] memory eaProof,
        address referrer
    ) external;

    /// @notice Check is the address is eligible to consume EA access
    /// @param member Address to check
    /// @param proof Merkle proof of EA eligibility
    /// @return Boolean flag if the proof is valid or not
    function verifyProof(
        address member,
        bytes32[] calldata proof
    ) external view returns (bool);

    /// @notice Check if the address has already consumed EA access
    /// @param member Address to check
    /// @return Consumed flag
    function isConsumed(address member) external view returns (bool);

    /// @notice Get a hash of a leaf in EA Merkle tree
    /// @param member EA member address
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second preimage attacks
    function hashLeaf(address member) external pure returns (bytes32);

    /// @notice Set the root of the EA members Merkle Tree
    /// @param _treeRoot New root of the Merkle Tree
    function setTreeRoot(bytes32 _treeRoot) external;
}
