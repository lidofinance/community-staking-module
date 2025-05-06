// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSExitPenalties } from "./interfaces/ICSExitPenalties.sol";
import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { ICSEjector } from "./interfaces/ICSEjector.sol";
import { ICSStrikes } from "./interfaces/ICSStrikes.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

/// @author vgorkavenko
contract CSStrikes is
    ICSStrikes,
    Initializable,
    AccessControlEnumerableUpgradeable
{
    address public immutable ORACLE;
    ICSModule public immutable MODULE;
    ICSAccounting public immutable ACCOUNTING;
    ICSExitPenalties public immutable EXIT_PENALTIES;
    ICSParametersRegistry public immutable PARAMETERS_REGISTRY;

    ICSEjector public ejector;
    /// @notice The latest Merkle Tree root
    bytes32 public treeRoot;

    /// @notice CID of the last published Merkle tree
    string public treeCid;

    constructor(address module, address oracle, address exitPenalties) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }
        if (oracle == address(0)) {
            revert ZeroOracleAddress();
        }
        if (exitPenalties == address(0)) {
            revert ZeroExitPenaltiesAddress();
        }

        MODULE = ICSModule(module);
        ACCOUNTING = ICSAccounting(MODULE.accounting());
        EXIT_PENALTIES = ICSExitPenalties(exitPenalties);
        ORACLE = oracle;

        _disableInitializers();
    }

    function initialize(address admin, address _ejector) external initializer {
        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        _setEjector(_ejector);

        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICSStrikes
    function setEjector(
        address _ejector
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setEjector(_ejector);
    }

    /// @inheritdoc ICSStrikes
    function processOracleReport(
        bytes32 _treeRoot,
        string calldata _treeCid
    ) external {
        if (msg.sender != ORACLE) {
            revert NotOracle();
        }

        /// @dev should be both empty or not empty
        bool isNewRootEmpty = _treeRoot == bytes32(0);
        bool isNewCidEmpty = bytes(_treeCid).length == 0;
        if (isNewRootEmpty != isNewCidEmpty) {
            revert InvalidReportData();
        }

        if (isNewRootEmpty) {
            if (treeRoot != bytes32(0)) {
                delete treeRoot;
                delete treeCid;
                emit StrikesDataWiped();
            }
            return;
        }

        bool isSameRoot = _treeRoot == treeRoot;
        bool isSameCid = keccak256(bytes(_treeCid)) ==
            keccak256(bytes(treeCid));
        if (isSameRoot != isSameCid) {
            revert InvalidReportData();
        }

        if (!isSameRoot) {
            treeRoot = _treeRoot;
            treeCid = _treeCid;
            emit StrikesDataUpdated(_treeRoot, _treeCid);
        }
    }

    /// @inheritdoc ICSStrikes
    function processBadPerformanceProof(
        ModuleKeyStrikes[] calldata keyStrikesList,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        address refundRecipient
    ) external {
        // NOTE: We allow empty proofs to be delivered because there’s no way to use the tree’s
        // internal nodes without brute-forcing the input data.

        bytes[] memory pubkeys = new bytes[](keyStrikesList.length);
        for (uint256 i; i < pubkeys.length; ++i) {
            pubkeys[i] = _loadPubKey(keyStrikesList[i]);
        }

        if (!verifyProof(keyStrikesList, pubkeys, proof, proofFlags)) {
            revert InvalidProof();
        }

        refundRecipient = refundRecipient == address(0)
            ? msg.sender
            : refundRecipient;

        for (uint256 i; i < keyStrikesList.length; ++i) {
            _ejectByStrikes(keyStrikesList[i], pubkeys[i], refundRecipient);
        }
    }

    /// @inheritdoc ICSStrikes
    function getInitializedVersion() external view returns (uint64) {
        return _getInitializedVersion();
    }

    /// @inheritdoc ICSStrikes
    function verifyProof(
        ModuleKeyStrikes[] calldata keyStrikesList,
        bytes[] memory pubkeys,
        bytes32[] calldata proof,
        bool[] calldata proofFlags
    ) public view returns (bool) {
        bytes32[] memory leaves = new bytes32[](keyStrikesList.length);
        for (uint256 i; i < leaves.length; i++) {
            leaves[i] = hashLeaf(keyStrikesList[i], pubkeys[i]);
        }

        return
            MerkleProof.multiProofVerifyCalldata(
                proof,
                proofFlags,
                treeRoot,
                leaves
            );
    }

    /// @inheritdoc ICSStrikes
    function hashLeaf(
        ModuleKeyStrikes calldata keyStrikes,
        bytes memory pubkey
    ) public pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            keyStrikes.nodeOperatorId,
                            pubkey,
                            keyStrikes.data
                        )
                    )
                )
            );
    }

    function _setEjector(address _ejector) internal {
        if (_ejector == address(0)) {
            revert ZeroEjectorAddress();
        }
        ejector = ICSEjector(_ejector);
        emit EjectorSet(_ejector);
    }

    function _loadPubKey(
        ModuleKeyStrikes calldata keyStrikes
    ) internal view returns (bytes memory pubkey) {
        // Sanity check. This is possible only if there is invalid data in the tree
        if (
            keyStrikes.keyIndex >=
            MODULE.getNodeOperatorTotalDepositedKeys(keyStrikes.nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }

        pubkey = MODULE.getSigningKeys(
            keyStrikes.nodeOperatorId,
            keyStrikes.keyIndex,
            1
        );
    }

    function _ejectByStrikes(
        ModuleKeyStrikes calldata keyStrikes,
        bytes memory pubkey,
        address refundRecipient
    ) internal {
        uint256 strikes = 0;
        for (uint256 i; i < keyStrikes.data.length; ++i) {
            strikes += keyStrikes.data[i];
        }

        uint256 curveId = ACCOUNTING.getBondCurveId(keyStrikes.nodeOperatorId);

        (, uint256 threshold) = MODULE.PARAMETERS_REGISTRY().getStrikesParams(
            curveId
        );
        if (strikes < threshold) {
            revert NotEnoughStrikesToEject();
        }

        ejector.ejectBadPerformer(
            keyStrikes.nodeOperatorId,
            pubkey,
            refundRecipient
        );
        EXIT_PENALTIES.processStrikesReport(keyStrikes.nodeOperatorId, pubkey);
    }
}
