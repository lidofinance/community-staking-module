// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import { ICSEjector } from "./interfaces/ICSEjector.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { IValidatorsExitBus } from "./interfaces/IValidatorsExitBus.sol";
import { ExitTypes } from "./abstract/ExitTypes.sol";

contract CSEjector is
    ICSEjector,
    ExitTypes,
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUntil
{
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");

    uint256 public immutable STAKING_MODULE_ID;
    ICSModule public immutable MODULE;
    IValidatorsExitBus public immutable VEB;

    address public strikes;

    modifier onlyStrikes() {
        if (msg.sender != strikes) {
            revert SenderIsNotStrikes();
        }

        _;
    }

    constructor(address module, uint256 stakingModuleId) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }

        MODULE = ICSModule(module);
        VEB = IValidatorsExitBus(
            MODULE.LIDO_LOCATOR().validatorsExitBusOracle()
        );
        STAKING_MODULE_ID = stakingModuleId;
    }

    /// @notice initialize the contract from scratch
    function initialize(address admin, address _strikes) external initializer {
        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }
        if (_strikes == address(0)) {
            revert ZeroStrikesAddress();
        }
        strikes = _strikes;

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
    function voluntaryEject(
        uint256 nodeOperatorId,
        uint256 startFrom,
        uint256 keysCount,
        address refundRecipient
    ) external payable whenResumed {
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
            startFrom + keysCount >
            MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }
        for (uint256 i = startFrom; i < startFrom + keysCount; i++) {
            if (MODULE.isValidatorWithdrawn(nodeOperatorId, i)) {
                revert AlreadyWithdrawn();
            }
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

        refundRecipient = refundRecipient == address(0)
            ? msg.sender
            : refundRecipient;

        VEB.triggerExitsDirectly{ value: msg.value }(
            exitData,
            refundRecipient,
            VOLUNTARY_EXIT_TYPE_ID
        );
    }

    /// @dev this method is intentionally copy-pasted from the voluntaryEject method with keys changes
    /// @inheritdoc ICSEjector
    function voluntaryEjectByArray(
        uint256 nodeOperatorId,
        uint256[] calldata keyIndices,
        address refundRecipient
    ) external payable whenResumed {
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
            if (keyIndices[i] >= totalDepositedKeys) {
                revert SigningKeysInvalidOffset();
            }
            if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndices[i])) {
                revert AlreadyWithdrawn();
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

        refundRecipient = refundRecipient == address(0)
            ? msg.sender
            : refundRecipient;

        VEB.triggerExitsDirectly{ value: msg.value }(
            exitData,
            refundRecipient,
            VOLUNTARY_EXIT_TYPE_ID
        );
    }

    /// @inheritdoc ICSEjector
    function ejectBadPerformer(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        address refundRecipient
    ) external payable whenResumed onlyStrikes {
        if (
            keyIndex >= MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }
        if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndex)) {
            revert AlreadyWithdrawn();
        }

        bytes memory publicKey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );
        IValidatorsExitBus.DirectExitData memory exitData = IValidatorsExitBus
            .DirectExitData({
                stakingModuleId: STAKING_MODULE_ID,
                nodeOperatorId: nodeOperatorId,
                validatorsPubkeys: publicKey
            });
        VEB.triggerExitsDirectly{ value: msg.value }(
            exitData,
            refundRecipient,
            STRIKES_EXIT_TYPE_ID
        );
    }
}
