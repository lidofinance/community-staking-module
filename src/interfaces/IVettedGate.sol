// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { NodeOperatorManagementProperties } from "./ICSModule.sol";
import { ICSAccounting } from "./ICSAccounting.sol";
import { ICSModule } from "./ICSModule.sol";

interface IVettedGate {
    event TreeRootSet(bytes32 indexed treeRoot);
    event Consumed(address indexed member);
    event ReferrerConsumed(address indexed referrer);
    event ReferralProgramResumed();
    event ReferralProgramPaused();
    event ReferralCurveIdSet(uint256 referralCurveId);

    error InvalidProof();
    error AlreadyConsumed();
    error InvalidTreeRoot();
    error InvalidCurveId();
    error ZeroModuleAddress();
    error ZeroAdminAddress();
    error NotAllowedToClaim();
    error NotEnoughReferrals();
    error ReferralProgramIsPaused();
    error InvalidReferralsThreshold();
    error ReferralCurveIdNotSet();

    function PAUSE_ROLE() external view returns (bytes32);

    function RESUME_ROLE() external view returns (bytes32);

    function SET_TREE_ROOT_ROLE() external view returns (bytes32);

    function MODULE() external view returns (ICSModule);

    function curveId() external view returns (uint256);

    function treeRoot() external view returns (bytes32);

    /// @notice Pause the contract for a given duration
    ///         Pausing the contract prevent creating new node operators using VettedGate
    ///         and claiming beneficial curve for the existing ones
    /// @param duration Duration of the pause
    function pauseFor(uint256 duration) external;

    /// @notice Resume the contract
    function resume() external;

    /// @notice Pause referral program bond curve claims
    function pauseReferralProgram() external;

    /// @notice Resume referral program bond curve claims
    function resumeReferralProgram() external;

    /// @notice Add a new Node Operator using ETH as a bond.
    ///         At least one deposit data and corresponding bond should be provided
    /// @param keysCount Signing keys count
    /// @param publicKeys Public keys to submit
    /// @param signatures Signatures of `(deposit_message_root, domain)` tuples
    ///                   https://github.com/ethereum/consensus-specs/blob/v1.4.0/specs/phase0/beacon-chain.md#signingdata
    /// @param managementProperties Optional. Management properties to be used for the Node Operator.
    ///                             managerAddress: Used as `managerAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             rewardAddress: Used as `rewardAddress` for the Node Operator. If not passed `msg.sender` will be used.
    ///                             extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param proof Merkle proof of the sender being eligible for the beneficial curve
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    /// @return nodeOperatorId Id of the created Node Operator
    function addNodeOperatorETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        bytes32[] memory proof,
        address referrer
    ) external payable returns (uint256 nodeOperatorId);

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
    ///                             extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param permit Optional. Permit to use stETH as bond
    /// @param proof Merkle proof of the sender being eligible for the beneficial curve
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    /// @return nodeOperatorId Id of the created Node Operator
    function addNodeOperatorStETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        ICSAccounting.PermitInput memory permit,
        bytes32[] memory proof,
        address referrer
    ) external returns (uint256 nodeOperatorId);

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
    ///                             extendedManagerPermissions: Flag indicating that `managerAddress` will be able to change `rewardAddress`.
    ///                                                         If set to true `resetNodeOperatorManagerAddress` method will be disabled
    /// @param permit Optional. Permit to use wstETH as bond
    /// @param proof Merkle proof of the sender being eligible for the beneficial curve
    /// @param referrer Optional. Referrer address. Should be passed when Node Operator is created using partners integration
    /// @return nodeOperatorId Id of the created Node Operator
    function addNodeOperatorWstETH(
        uint256 keysCount,
        bytes memory publicKeys,
        bytes memory signatures,
        NodeOperatorManagementProperties memory managementProperties,
        ICSAccounting.PermitInput memory permit,
        bytes32[] memory proof,
        address referrer
    ) external returns (uint256 nodeOperatorId);

    /// @notice Claim the bond curve for the eligible Node Operator
    /// @param nodeOperatorId Id of the Node Operator
    /// @param proof Merkle proof of the sender being eligible for the beneficial curve
    /// @dev Should be called by the reward address of the Node Operator
    ///      In case of the extended manager permissions, should be called by the manager address
    function claimBondCurve(
        uint256 nodeOperatorId,
        bytes32[] calldata proof
    ) external;

    /// @notice Claim the referral program bond curve for the eligible Node Operator
    /// @param nodeOperatorId Id of the Node Operator
    function claimReferrerBondCurve(uint256 nodeOperatorId) external;

    /// @notice Check is the address is eligible to consume beneficial curve
    /// @param member Address to check
    /// @param proof Merkle proof of the beneficial curve eligibility
    /// @return Boolean flag if the proof is valid or not
    function verifyProof(
        address member,
        bytes32[] calldata proof
    ) external view returns (bool);

    /// @notice Check if the address has already consumed the curve
    /// @param member Address to check
    /// @return Consumed flag
    function isConsumed(address member) external view returns (bool);

    /// @notice Check if the address has already consumed referral program bond curve
    /// @param referrer Address to check
    /// @return Consumed flag
    function isReferrerConsumed(address referrer) external view returns (bool);

    /// @notice Get a hash of a leaf in the Merkle tree
    /// @param member eligible member address
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second preimage attacks
    function hashLeaf(address member) external pure returns (bytes32);

    /// @notice Set the root of the eligible members Merkle Tree
    /// @param _treeRoot New root of the Merkle Tree
    function setTreeRoot(bytes32 _treeRoot) external;

    /// @notice Set curve Id to be used as referral curve
    /// @param _referralCurveId Curve Id for the referral curve
    function setReferralCurveId(uint256 _referralCurveId) external;
}
