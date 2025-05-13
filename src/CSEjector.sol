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
    address public immutable STRIKES;

    modifier onlyStrikes() {
        if (msg.sender != STRIKES) {
            revert SenderIsNotStrikes();
        }

        _;
    }

    constructor(address module, address strikes, uint256 stakingModuleId) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }
        if (strikes == address(0)) {
            revert ZeroStrikesAddress();
        }

        STRIKES = strikes;
        MODULE = ICSModule(module);
        VEB = IValidatorsExitBus(
            MODULE.LIDO_LOCATOR().validatorsExitBusOracle()
        );
        STAKING_MODULE_ID = stakingModuleId;
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
        // it must be a valid deposited key
        if (
            keyIndex >= MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
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
