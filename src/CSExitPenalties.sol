// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSExitPenalties, MarkedUint248 } from "./interfaces/ICSExitPenalties.sol";
import { ExitPenaltyInfo } from "./interfaces/ICSExitPenalties.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CSExitPenalties is ICSExitPenalties, Initializable {
    using SafeCast for uint256;

    uint8 public constant VOLUNTARY_EXIT_TYPE_ID = 0;

    ICSModule public immutable MODULE;
    ICSParametersRegistry public immutable PARAMETERS_REGISTRY;
    ICSAccounting public immutable ACCOUNTING;

    address public strikes;
    mapping(bytes32 => ExitPenaltyInfo) private _exitPenaltyInfo;

    modifier onlyModule() {
        if (msg.sender != address(MODULE)) {
            revert SenderIsNotModule();
        }

        _;
    }

    modifier onlyStrikes() {
        if (msg.sender != strikes) {
            revert SenderIsNotStrikes();
        }

        _;
    }

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
    }

    function initialize(address _strikes) external initializer {
        if (_strikes == address(0)) {
            revert ZeroStrikesAddress();
        }
        strikes = _strikes;
    }

    // @inheritdoc ICSExitPenalties
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
        if (_exitPenaltyInfo[noPublicKeyPacked].delayPenalty.isValue) {
            revert ValidatorExitDelayAlreadyReported();
        }

        uint256 delayPenalty = PARAMETERS_REGISTRY.getExitDelayPenalty(curveId);
        _exitPenaltyInfo[noPublicKeyPacked].delayPenalty = MarkedUint248(
            delayPenalty.toUint248(),
            true
        );
        emit ValidatorExitDelayProcessed(
            nodeOperatorId,
            publicKey,
            delayPenalty
        );
    }

    /// @inheritdoc ICSExitPenalties
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
                uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);
                uint256 maxFee = PARAMETERS_REGISTRY.getMaxWithdrawalRequestFee(
                    curveId
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

    /// @inheritdoc ICSExitPenalties
    function processStrikesReport(
        uint256 nodeOperatorId,
        bytes calldata publicKey
    ) external onlyStrikes {
        bytes32 noPubkeyPacked = _nodeOperatorPublicKeyPacked(
            nodeOperatorId,
            publicKey
        );
        if (!_exitPenaltyInfo[noPubkeyPacked].strikesPenalty.isValue) {
            uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);
            uint256 penalty = PARAMETERS_REGISTRY.getBadPerformancePenalty(
                curveId
            );
            _exitPenaltyInfo[noPubkeyPacked].strikesPenalty = MarkedUint248(
                penalty.toUint248(),
                true
            );
            emit StrikesPenaltyProcessed(nodeOperatorId, publicKey, penalty);
        }
    }

    /// @inheritdoc ICSExitPenalties
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

    /// @inheritdoc ICSExitPenalties
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

    function _nodeOperatorPublicKeyPacked(
        uint256 nodeOperatorId,
        bytes memory publicKey
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(nodeOperatorId, publicKey));
    }
}
