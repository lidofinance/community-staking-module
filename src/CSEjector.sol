// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import { ICSEjector } from "./interfaces/ICSEjector.sol";
import { ICSModule, NodeOperatorManagementProperties } from "./interfaces/ICSModule.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUntil } from "./lib/utils/PausableUntil.sol";
import { SigningKeys } from "./lib/SigningKeys.sol";
import { ITriggerableWithdrawalsGateway, ValidatorData } from "./interfaces/ITriggerableWithdrawalsGateway.sol";
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
    ITriggerableWithdrawalsGateway public immutable TWG;
    address public immutable STRIKES;

    modifier onlyStrikes() {
        if (msg.sender != STRIKES) {
            revert SenderIsNotStrikes();
        }

        _;
    }

    constructor(
        address module,
        address strikes,
        address twg,
        uint256 stakingModuleId
    ) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }
        if (strikes == address(0)) {
            revert ZeroStrikesAddress();
        }
        if (twg == address(0)) {
            revert ZeroTWGAddress();
        }

        STRIKES = strikes;
        MODULE = ICSModule(module);
        TWG = ITriggerableWithdrawalsGateway(twg);
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

        // a key must be deposited to prevent ejecting unvetted keys that can be the ones from other modules
        if (
            startFrom + keysCount >
            MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }
        // a key must be non-withdrawn to restrict unlimited exit requests consuming sanity checker limits
        // although the deposited key can be requested to exit multiple times also, it will eventually be withdrawn
        // so potentially malicious behaviour stops when there are no active keys available
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
        ValidatorData[] memory exitsData = new ValidatorData[](keysCount);
        for (uint256 i; i < keysCount; ++i) {
            bytes memory pk = new bytes(SigningKeys.PUBKEY_LENGTH);
            assembly {
                let keyLen := mload(pk) // SigningKeys.PUBKEY_LENGTH
                let offset := mul(keyLen, i) // SigningKeys.PUBKEY_LENGTH * i
                let keyPos := add(add(pubkeys, 0x20), offset) // pubkeys[offset]
                mcopy(add(pk, 0x20), keyPos, keyLen) // pk = pubkeys[offset]
            }
            exitsData[i] = ValidatorData({
                stakingModuleId: STAKING_MODULE_ID,
                nodeOperatorId: nodeOperatorId,
                pubkey: pk
            });
        }

        TWG.triggerFullWithdrawals{ value: msg.value }(
            exitsData,
            refundRecipient == address(0) ? msg.sender : refundRecipient,
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
        ValidatorData[] memory exitsData = new ValidatorData[](
            keyIndices.length
        );
        for (uint256 i = 0; i < keyIndices.length; i++) {
            // a key must be deposited to prevent ejecting unvetted keys that can be the ones from other modules
            if (keyIndices[i] >= totalDepositedKeys) {
                revert SigningKeysInvalidOffset();
            }
            // a key must be non-withdrawn to restrict unlimited exit requests consuming sanity checker limits
            // although the deposited key can be requested to exit multiple times also, it will eventually be withdrawn
            // so potentially malicious behaviour stops when there are no active keys available
            if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndices[i])) {
                revert AlreadyWithdrawn();
            }
            bytes memory pubkey = MODULE.getSigningKeys(
                nodeOperatorId,
                keyIndices[i],
                1
            );
            exitsData[i] = ValidatorData({
                stakingModuleId: STAKING_MODULE_ID,
                nodeOperatorId: nodeOperatorId,
                pubkey: pubkey
            });
        }

        TWG.triggerFullWithdrawals{ value: msg.value }(
            exitsData,
            refundRecipient == address(0) ? msg.sender : refundRecipient,
            VOLUNTARY_EXIT_TYPE_ID
        );
    }

    /// @inheritdoc ICSEjector
    function ejectBadPerformer(
        uint256 nodeOperatorId,
        uint256 keyIndex,
        address refundRecipient
    ) external payable whenResumed onlyStrikes {
        // a key must be deposited to prevent ejecting unvetted keys that can be the ones from other modules
        if (
            keyIndex >= MODULE.getNodeOperatorTotalDepositedKeys(nodeOperatorId)
        ) {
            revert SigningKeysInvalidOffset();
        }
        // a key must be non-withdrawn to restrict unlimited exit requests consuming sanity checker limits
        // although the deposited key can be requested to exit multiple times also, it will eventually be withdrawn
        // so potentially malicious behaviour stops when there are no active keys available
        if (MODULE.isValidatorWithdrawn(nodeOperatorId, keyIndex)) {
            revert AlreadyWithdrawn();
        }

        ValidatorData[] memory exitsData = new ValidatorData[](1);
        bytes memory pubkey = MODULE.getSigningKeys(
            nodeOperatorId,
            keyIndex,
            1
        );
        exitsData[0] = ValidatorData({
            stakingModuleId: STAKING_MODULE_ID,
            nodeOperatorId: nodeOperatorId,
            pubkey: pubkey
        });

        TWG.triggerFullWithdrawals{ value: msg.value }(
            exitsData,
            refundRecipient == address(0) ? msg.sender : refundRecipient,
            STRIKES_EXIT_TYPE_ID
        );
    }
}
