// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IStakingModule } from "./interfaces/IStakingModule.sol";
import { ICSParametersRegistry } from "./interfaces/ICSParametersRegistry.sol";
import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSEjector } from "./interfaces/ICSEjector.sol";

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

    ICSModule public immutable MODULE;
    ICSAccounting public immutable ACCOUNTING;

    /// @dev see _keyPointer function for details of noKeyIndexPacked structure
    mapping(uint256 noKeyIndexPacked => bool) private _isValidatorEjected;

    constructor(address module) {
        if (module == address(0)) revert ZeroModuleAddress();
        MODULE = ICSModule(module);
        ACCOUNTING = ICSAccounting(MODULE.accounting());
    }

    /// @notice initialize the contract from scratch
    function initialize(address admin) external initializer {
        if (admin == address(0)) revert ZeroAdminAddress();

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

        if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndex))
            revert AlreadyWithdrawn();

        uint256 pointer = _keyPointer(nodeOperatorId, keyIndex);
        if (_isValidatorEjected[pointer]) revert AlreadyEjected();

        uint256 curveId = ACCOUNTING.getBondCurveId(nodeOperatorId);

        ICSParametersRegistry registry = MODULE.PARAMETERS_REGISTRY();

        (, uint256 threshold) = registry.getStrikesParams(curveId);
        if (strikes < threshold) revert NotEnoughStrikesToEject();

        uint256 penalty = registry.getBadPerformancePenalty(curveId);
        if (penalty > 0) ACCOUNTING.penalize(nodeOperatorId, penalty);

        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );
        // TODO: make the function payable and call `requestEjection{ value: msg.value }(pubkey)`

        _isValidatorEjected[pointer] = true;
        emit EjectionSubmitted(nodeOperatorId, keyIndex, pubkey);
    }

    /// @inheritdoc ICSEjector
    function isValidatorEjected(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) external view returns (bool) {
        return _isValidatorEjected[_keyPointer(nodeOperatorId, keyIndex)];
    }

    function _onlyExistingNodeOperator(uint256 nodeOperatorId) internal view {
        if (
            nodeOperatorId <
            IStakingModule(address(MODULE)).getNodeOperatorsCount()
        ) return;
        revert NodeOperatorDoesNotExist();
    }

    /// @dev Both nodeOperatorId and keyIndex are limited to uint64 by the CSModule.sol
    function _keyPointer(
        uint256 nodeOperatorId,
        uint256 keyIndex
    ) internal pure returns (uint256) {
        return (nodeOperatorId << 128) | keyIndex;
    }
}
