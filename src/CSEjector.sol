// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSEjector, MarkedUint248 } from "./interfaces/ICSEjector.sol";
import { ExitPenaltyInfo } from "./interfaces/ICSEjector.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { IValidatorsExitBus } from "./interfaces/IValidatorsExitBus.sol";

contract CSEjector is
    ICSEjector,
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUntil
{
    using SafeCast for uint256;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant BAD_PERFORMER_EJECTOR_ROLE =
        keccak256("BAD_PERFORMER_EJECTOR_ROLE");
    uint256 public constant VOLUNTARY_EXIT_TYPE_ID = 0;
    uint256 public constant STRIKES_EXIT_TYPE_ID = 1;
    // TODO reconsider
    uint256 public constant STAKING_MODULE_ID = 0;

    ICSModule public immutable MODULE;
    ICSParametersRegistry public immutable PARAMETERS_REGISTRY;
    ICSAccounting public immutable ACCOUNTING;
    IValidatorsExitBus public immutable VEB;

    mapping(bytes32 => ExitPenaltyInfo) private _exitPenaltyInfo;

    constructor(
        address module,
        address parametersRegistry,
        address accounting
    ) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }
        if (parametersRegistry == address(0)) {
            revert ZeroParametersRegistryAddress();
        }
        if (accounting == address(0)) {
            revert ZeroAccountingAddress();
        }

        MODULE = ICSModule(module);
        PARAMETERS_REGISTRY = ICSParametersRegistry(parametersRegistry);
        ACCOUNTING = ICSAccounting(accounting);
        VEB = IValidatorsExitBus(
            MODULE.LIDO_LOCATOR().validatorsExitBusOracle()
        );
    }

    receive() external payable {}

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
    ) external onlyModule {
        uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);

        uint256 allowedExitDelay = PARAMETERS_REGISTRY.getAllowedExitDelay(
            curveId
        );
        if (eligibleToExitInSec <= allowedExitDelay) {
            revert ValidatorExitDelayNotApplicable();
        }

        bytes32 noPublicKeyPacked = _nodeOperatorPublicKeyPacked(
            nodeOperatorId,
            publicKey
        );
        // It is allowed to send the same report multiple times. The penalty is recorded only once at the first report
        if (!_exitPenaltyInfo[noPublicKeyPacked].delayPenalty.isValue) {
            uint256 delayPenalty = PARAMETERS_REGISTRY.getExitDelayPenalty(
                curveId
            );
            _exitPenaltyInfo[noPublicKeyPacked].delayPenalty = MarkedUint248(
                delayPenalty.toUint248(),
                true
            );
            emit ValidatorExitDelayProcessed(
                nodeOperatorId,
                publicKey,
                delayPenalty.toUint248()
            );
        }
    }

    /// @inheritdoc ICSEjector
    function processTriggeredExit(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 withdrawalRequestPaidFee,
        uint256 exitType
    ) external onlyModule {
        /// assuming exit type == 0 is an exit paid by the node operator
        if (exitType != VOLUNTARY_EXIT_TYPE_ID) {
            bytes32 noPublicKeyPacked = _nodeOperatorPublicKeyPacked(
                nodeOperatorId,
                publicKey
            );
            ExitPenaltyInfo storage exitPenaltyInfo = _exitPenaltyInfo[
                noPublicKeyPacked
            ];
            // don't update the fee if it was already set to prevent hypothetical manipulations
            // with double reporting to get lower/higher fee.
            // it's impossible to set it to zero legitimately
            if (exitPenaltyInfo.withdrawalRequestFee == 0) {
                uint256 maxFee = PARAMETERS_REGISTRY.getMaxWithdrawalRequestFee(
                    ACCOUNTING.getBondCurveId(nodeOperatorId)
                );
                uint256 fee = Math.min(withdrawalRequestPaidFee, maxFee);

                exitPenaltyInfo.withdrawalRequestFee = fee;
                emit TriggeredExitFeeRecorded(
                    nodeOperatorId,
                    exitType,
                    publicKey,
                    fee
                );
            }
        }
    }

    function voluntaryEject(
        uint256 nodeOperatorId,
        uint256 startFrom,
        uint256 keysCount
    ) external payable {
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

        // there is no check that the key is not withdrawn yet to not make it too expensive (esp. for the large batch)
        // and no bad effects for extra eip-7002 exit requests for the node operator can happen.
        // so we need to be sure that the UIs restrict this case.
        // on the other hand, it is crucial to check that the key was deposited already
        if (
            startFrom + keysCount >
            MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }
        bytes memory pubkeys = MODULE.getSigningKeys(
            nodeOperatorId,
            startFrom,
            keysCount
        );
        IValidatorsExitBus.DirectExitData memory exitData = IValidatorsExitBus
            .DirectExitData({
                stakingModuleId: STAKING_MODULE_ID,
                nodeOperatorId: nodeOperatorId,
                validatorsPubkeys: pubkeys
            });

        uint256 excessFee = VEB.triggerExitsDirectly{ value: msg.value }(
            exitData
        );
        if (excessFee != 0) {
            Address.sendValue(payable(msg.sender), excessFee);
        }
    }

    /// @dev this method is intentionally copy-pasted from the voluntaryEject method with keys changes
    function voluntaryEjectByArray(
        uint256 nodeOperatorId,
        uint256[] calldata keyIndices
    ) external payable {
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

        uint256 totalDepositedKeys = MODULE.getNodeOperatorTotalDepositedKeys(
            nodeOperatorId
        );
        bytes memory pubkeys;
        for (uint256 i = 0; i < keyIndices.length; i++) {
            // there is no check that the key is not withdrawn yet to not make it too expensive (esp. for the large batch)
            // and no bad effects for extra eip-7002 exit requests for the node operator can happen.
            // so we need to be sure that the UIs restrict this case.
            // on the other hand, it is crucial to check that the key was deposited already
            if (keyIndices[i] >= totalDepositedKeys) {
                revert SigningKeysInvalidOffset();
            }
            pubkeys = abi.encodePacked(
                pubkeys,
                MODULE.getSigningKeys(nodeOperatorId, keyIndices[i], 1)
            );
        }
        IValidatorsExitBus.DirectExitData memory exitData = IValidatorsExitBus
            .DirectExitData({
                stakingModuleId: STAKING_MODULE_ID,
                nodeOperatorId: nodeOperatorId,
                validatorsPubkeys: pubkeys
            });

        uint256 excessFee = VEB.triggerExitsDirectly{ value: msg.value }(
            exitData
        );
        if (excessFee != 0) {
            Address.sendValue(payable(msg.sender), excessFee);
        }
    }

    /// @inheritdoc ICSEjector
    function ejectBadPerformer(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        uint256 strikes
    ) external payable whenResumed onlyRole(BAD_PERFORMER_EJECTOR_ROLE) {
        /// TODO consider adding a batch processing. It might worth it to rework csstrikes as well to not read keys twice
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
        bytes32 noPubkeyPacked = _nodeOperatorPublicKeyPacked(
            nodeOperatorId,
            pubkey
        );
        if (!_exitPenaltyInfo[noPubkeyPacked].strikesPenalty.isValue) {
            _exitPenaltyInfo[noPubkeyPacked].strikesPenalty = MarkedUint248(
                penalty.toUint248(),
                true
            );
            emit BadPerformancePenaltyProcessed(
                nodeOperatorId,
                pubkey,
                penalty.toUint248()
            );
        }

        IValidatorsExitBus.DirectExitData memory exitData = IValidatorsExitBus
            .DirectExitData({
                stakingModuleId: STAKING_MODULE_ID,
                nodeOperatorId: nodeOperatorId,
                validatorsPubkeys: pubkey
            });
        uint256 excessFee = VEB.triggerExitsDirectly{ value: msg.value }(
            exitData
        );
        if (excessFee != 0) {
            Address.sendValue(payable(msg.sender), excessFee);
        }
    }

    /// @inheritdoc ICSEjector
    function isValidatorExitDelayPenaltyApplicable(
        uint256 nodeOperatorId,
        bytes calldata publicKey,
        uint256 eligibleToExitInSec
    ) external view onlyModule returns (bool) {
        uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);
        uint256 allowedExitDelay = PARAMETERS_REGISTRY.getAllowedExitDelay(
            curveId
        );
        if (eligibleToExitInSec <= allowedExitDelay) {
            return false;
        }
        return
            !_exitPenaltyInfo[
                _nodeOperatorPublicKeyPacked(nodeOperatorId, publicKey)
            ].delayPenalty.isValue;
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

    modifier onlyModule() {
        if (msg.sender != address(MODULE)) {
            revert SenderIsNotModule();
        }

        _;
    }
}
