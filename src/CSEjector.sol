// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "./interfaces/ICSEjector.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";

import { ICSEjector, ExitPenaltyInfo } from "./interfaces/ICSEjector.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";

contract CSEjector is
    ICSEjector,
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUntil
{
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant BAD_PERFORMER_EJECTOR_ROLE =
        keccak256("BAD_PERFORMER_EJECTOR_ROLE");
    uint256 public constant DIRECT_EXIT_TYPE_ID = 0;
    uint256 public constant STRIKES_EXIT_TYPE_ID = 1;

    ICSModule public immutable MODULE;
    ICSParametersRegistry public immutable PARAMETERS_REGISTRY;
    ICSAccounting public immutable ACCOUNTING;

    mapping(bytes32 => ExitPenaltyInfo) private _exitPenaltyInfo;

    constructor(address module, address parametersRegistry) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }

        MODULE = ICSModule(module);
        PARAMETERS_REGISTRY = ICSParametersRegistry(parametersRegistry);
        ACCOUNTING = ICSAccounting(MODULE.accounting());
    }

    /// @notice initialize the contract from scratch
    function initialize(address admin) external initializer {
        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc ICSEjector
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc ICSEjector
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    // @inheritdoc ICSEjector
    function processExitDelayReport(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 eligibleToExitInSec
    ) external onlyCSM {
        uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);

        bytes32 noPublicKeyPacked = _nodeOperatorPublicKeyPacked(
            nodeOperatorId,
            publicKey
        );
        uint256 allowedExitDelay = PARAMETERS_REGISTRY.getAllowedExitDelay(
            curveId
        );
        if (eligibleToExitInSec < allowedExitDelay) {
            revert ValidatorExitDelayNotApplicable();
        }
        // it is allowed to send the same report multiple times. Penalty is applied only once
        if (_exitPenaltyInfo[noPublicKeyPacked].penaltyValue == 0) {
            _exitPenaltyInfo[noPublicKeyPacked]
                .penaltyValue = PARAMETERS_REGISTRY.getExitDelayPenalty(
                curveId
            );
            emit ValidatorExitDelayProcessed(
                nodeOperatorId,
                publicKey
            );
        }
    }

    /// @inheritdoc ICSEjector
    function processTriggeredExit(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 withdrawalRequestPaidFee,
        uint256 exitType
    ) external onlyCSM {
        /// assuming exit type == 0 is an exit paid by the node operator
        if (exitType != DIRECT_EXIT_TYPE_ID) {
            bytes32 noPublicKeyPacked = _nodeOperatorPublicKeyPacked(
                nodeOperatorId,
                publicKey
            );
            ExitPenaltyInfo storage exitPenaltyInfo = _exitPenaltyInfo[
                noPublicKeyPacked
            ];
            // don't update the fee if it was already set to prevent hypothetical manipulations
            // with double reporting to get lower/higher fee
            if (exitPenaltyInfo.withdrawalRequestFee == 0) {
                exitPenaltyInfo.withdrawalRequestFee = withdrawalRequestPaidFee;
                emit WithdrawalRequestFeeCompensationReported(
                    nodeOperatorId,
                    publicKey,
                    withdrawalRequestPaidFee
                );
            }
        }

        emit TriggeredExitReported(
            nodeOperatorId,
            exitType,
            publicKey,
            withdrawalRequestPaidFee
        );
    }

    function voluntaryEject(uint256 nodeOperatorId, uint256 keyIndex) public {
        NodeOperatorManagementProperties memory no = MODULE
            .getNodeOperatorManagementProperties(nodeOperatorId);
        if (no.managerAddress == address(0)) {
            revert NodeOperatorDoesNotExist();
        }
        address nodeOperatorAddress = no.extendedManagerPermissions
            ? no.managerAddress
            : no.rewardAddress;
        if (nodeOperatorAddress != msg.sender) {
            revert SenderIsNotEligible();
        }

        if (
            keyIndex >= MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }

        if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndex)) {
            revert AlreadyWithdrawn();
        }

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );
        // TODO: make the function payable and call `requestEjection{ value: msg.value }(pubkey)`. Refund excess fee
        emit EjectionSubmitted(
            DIRECT_EXIT_TYPE_ID,
            nodeOperatorId,
            keyIndex,
            pubkey
        );
    }

    /// @inheritdoc ICSEjector
    function ejectBadPerformer(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 strikes
    ) external whenResumed onlyRole(BAD_PERFORMER_EJECTOR_ROLE) {
        _onlyExistingNodeOperator(nodeOperatorId);

        if (
            keyIndex >= MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }

        if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndex)) {
            revert AlreadyWithdrawn();
        }

        uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);

        (, uint256 threshold) = PARAMETERS_REGISTRY.getStrikesParams(curveId);
        if (strikes < threshold) {
            revert NotEnoughStrikesToEject();
        }

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );
        uint256 penalty = PARAMETERS_REGISTRY.getBadPerformancePenalty(curveId);
        if (penalty > 0) {
            bytes32 noPubkeyPacked = _nodeOperatorPublicKeyPacked(
                nodeOperatorId,
                pubkey
            );
            _exitPenaltyInfo[noPubkeyPacked].strikesPenalty = penalty;
        }

        // TODO: make the function payable and call `requestEjection{ value: msg.value }(pubkey)`

        emit EjectionSubmitted(
            STRIKES_EXIT_TYPE_ID,
            nodeOperatorId,
            keyIndex,
            pubkey
        );
    }

    /// @inheritdoc ICSEjector
    function isValidatorExitDelayPenaltyApplicable(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 eligibleToExitInSec
    ) external view returns (bool) {
        _onlyExistingNodeOperator(nodeOperatorId);
        uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);
        uint256 allowedExitDelay = PARAMETERS_REGISTRY.getAllowedExitDelay(
            curveId
        );
        if (eligibleToExitInSec < allowedExitDelay) {
            return false;
        }
        return _exitPenaltyInfo[_nodeOperatorPublicKeyPacked(nodeOperatorId, publicKey)].penaltyValue == 0;
    }

    /// @inheritdoc ICSEjector
    function getDelayedExitPenaltyInfo(
        uint256 nodeOperatorId,
        bytes calldata publicKey
    ) external view returns (ExitPenaltyInfo memory) {
        bytes32 noPublicKeyPacked = _nodeOperatorPublicKeyPacked(
            nodeOperatorId,
            publicKey
        );
        return _exitPenaltyInfo[noPublicKeyPacked];
    }

    function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view {
        if (
            nodeOperatorId <
            IStakingModule(address(MODULE)).getNodeOperatorsCount()
        ) {
            return;
        }

        revert NodeOperatorDoesNotExist();
    }

    /// @dev Both nodeOperatorId and keyIndex are limited to uint64 by the CSModule.sol
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }

    function _nodeOperatorPublicKeyPacked(
        uint256 nodeOperatorId,
        bytes memory publicKey
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(nodeOperatorId, publicKey));
    }

    modifier onlyCSM() {
        if (msg.sender != address(MODULE)) {
            revert SenderIsNotCSM();
        }

        _;
    }

}
