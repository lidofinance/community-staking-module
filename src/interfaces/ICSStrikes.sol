// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSModule } from "./ICSModule.sol";
import { ICSAccounting } from "./ICSAccounting.sol";
import { ICSParametersRegistry } from "./ICSParametersRegistry.sol";
import { ICSExitPenalties } from "./ICSExitPenalties.sol";
import { ICSEjector } from "./ICSEjector.sol";

interface ICSStrikes {
    /// @dev Emitted when strikes data is updated
    event StrikesDataUpdated(bytes32 treeRoot, string treeCid);
    /// @dev Emitted when strikes is updated from non-empty to empty
    event StrikesDataWiped();
    event EjectorSet(address ejector);

    error ZeroEjectorAddress();
    error ZeroModuleAddress();
    error ZeroOracleAddress();
    error ZeroExitPenaltiesAddress();
    error ZeroAdminAddress();
    error ZeroEjectionFeeAmount();
    error ZeroBadPerformancePenaltyAmount();
    error NotOracle();

    error InvalidReportData();
    error InvalidProof();
    error SigningKeysInvalidOffset();
    error NotEnoughStrikesToEject();

    struct ModuleKeyStrikes {
        uint256 nodeOperatorId;
        uint256 keyIndex;
        uint256[] data;
    }

    function ORACLE() external view returns (address);

    function MODULE() external view returns (ICSModule);

    function ACCOUNTING() external view returns (ICSAccounting);

    function EXIT_PENALTIES() external view returns (ICSExitPenalties);

    function PARAMETERS_REGISTRY()
        external
        view
        returns (ICSParametersRegistry);

    function ejector() external view returns (ICSEjector);

    function treeRoot() external view returns (bytes32);

    function treeCid() external view returns (string calldata);

    /// @notice Set the address of the Ejector contract
    /// @param _ejector Address of the Ejector contract
    function setEjector(address _ejector) external;

    /// @notice Report Node Operator's key as bad performing
    /// @param keyStrikes Strikes of a module's key
    /// @param proof Proof of the strikes
    /// @param refundRecipient Address to send the refund to
    function processBadPerformanceProof(
        ModuleKeyStrikes calldata keyStrikes,
        bytes32[] calldata proof,
        address refundRecipient
    ) external;

    /// @notice Receive the data of the Merkle tree from the Oracle contract and process it
    /// @param _treeRoot Root of the Merkle tree
    /// @param _treeCid an IPFS CID of the tree
    /// @dev New tree might be empty and it is valid value because of `strikesLifetime`
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid
    ) external;

    /// @notice Check if Key is eligible to be ejected
    /// @param keyStrikes Strikes of a module's key
    /// @param proof Merkle proof of the leaf
    function verifyProof(
        ModuleKeyStrikes calldata keyStrikes,
        bytes calldata pubkey,
        bytes32[] calldata proof
    ) external view returns (bool);

    /// @notice Get a hash of a leaf
    /// @param keyStrikes Strikes of a module's key
    /// @param pubkey pubkey of the Node Operator
    /// @return Hash of the leaf
    /// @dev Double hash the leaf to prevent second pre-image attacks
    function hashLeaf(
        ModuleKeyStrikes calldata keyStrikes,
        bytes calldata pubkey
    ) external pure returns (bytes32);

    /// @notice Returns the initialized version of the contract
    function getInitializedVersion() external view returns (uint64);
}
