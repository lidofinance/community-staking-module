// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";
import { AssetRecovererLib } from "./lib/AssetRecovererLib.sol";

import { PausableUntil } from "./lib/utils/PausableUntil.sol";

import { ICSAccounting } from "./interfaces/ICSAccounting.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";
import { IGovernanceBooster } from "./interfaces/IGovernanceBooster.sol";
import { ILDO } from "./interfaces/ILDO.sol";
import { IDelegation } from "./interfaces/IDelegation.sol";
import { IVoting } from "./interfaces/IVoting.sol";

contract GovernanceBooster is
    IGovernanceBooster,
    AccessControlEnumerableUpgradeable,
    PausableUntil,
    AssetRecoverer
{
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE");

    /// @dev Address of the Staking Module
    ICSModule public immutable MODULE;

    /// @dev Address of the CS Accounting
    ICSAccounting public immutable ACCOUNTING;

    /// @dev Address of the LDO token
    ILDO public immutable LDO;

    /// @dev Snapshot delegation contract
    IDelegation public immutable SNAPSHOT_DELEGATION;

    /// @dev Voting contract
    IVoting public immutable VOTING;

    /// @dev Boosted curve ID
    uint256 public curveId;

    /// @dev Boost deposit amount
    uint256 public boostDeposit;

    /// @dev Delegate address to delegate boost deposits
    address public delegate;

    mapping(uint256 => bool) internal _boostedOperators;
    mapping(uint256 => BoostInfo) internal _boostedOperatorsInfo;

    /// @dev Total amount of LDO tokens used for boosts in the contract
    uint256 public totalBoosts;

    constructor(
        address module,
        address ldo,
        address snapshotDelegation,
        address voting
    ) {
        if (module == address(0)) {
            revert ZeroModuleAddress();
        }
        if (ldo == address(0)) {
            revert ZeroLDOAddress();
        }
        if (snapshotDelegation == address(0)) {
            revert ZeroSnapshotDelegationAddress();
        }
        if (voting == address(0)) {
            revert ZeroVotingAddress();
        }

        LDO = ILDO(ldo);
        MODULE = ICSModule(module);
        ACCOUNTING = ICSAccounting(MODULE.accounting());
        SNAPSHOT_DELEGATION = IDelegation(snapshotDelegation);
        VOTING = IVoting(voting);

        _disableInitializers();
    }

    function initialize(
        uint256 _curveId,
        uint256 _boostDeposit,
        address _delegate,
        address admin
    ) external initializer {
        __AccessControlEnumerable_init();

        if (_curveId == ACCOUNTING.DEFAULT_BOND_CURVE_ID()) {
            revert InvalidCurveId();
        }
        if (_boostDeposit == 0) {
            revert InvalidBoostDeposit();
        }
        if (_delegate == address(0)) {
            revert ZeroDelegateAddress();
        }
        if (admin == address(0)) {
            revert ZeroAdminAddress();
        }

        // @dev there is no check for curve existence as this contract might be created before the curve is added
        curveId = _curveId;
        boostDeposit = _boostDeposit;
        _setDelegate(_delegate);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IGovernanceBooster
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @inheritdoc IGovernanceBooster
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @inheritdoc IGovernanceBooster
    function boostNodeOperator(uint256 nodeOperatorId) external whenResumed {
        _onlyNodeOperatorOwner(nodeOperatorId);

        if (_boostedOperatorsInfo[nodeOperatorId].boosted) {
            revert AlreadyBoosted();
        }

        LDO.transferFrom(msg.sender, address(this), boostDeposit);

        totalBoosts += boostDeposit;

        _boostedOperatorsInfo[nodeOperatorId] = BoostInfo({
            boosted: true,
            oldCurveId: curveId,
            boostDeposit: boostDeposit
        });

        ACCOUNTING.setBondCurve(nodeOperatorId, curveId);

        emit NodeOperatorBoosted(
            msg.sender,
            nodeOperatorId,
            curveId,
            boostDeposit
        );
    }

    /// @inheritdoc IGovernanceBooster
    function unboostNodeOperator(uint256 nodeOperatorId) external whenResumed {
        _onlyNodeOperatorOwner(nodeOperatorId);

        BoostInfo memory boostInfo = _boostedOperatorsInfo[nodeOperatorId];

        if (!boostInfo.boosted) {
            revert NotBoosted();
        }

        LDO.transfer(msg.sender, boostInfo.boostDeposit);

        totalBoosts -= boostInfo.boostDeposit;

        if (ACCOUNTING.getBondCurveId(nodeOperatorId) == curveId) {
            ACCOUNTING.setBondCurve(nodeOperatorId, boostInfo.oldCurveId);
        }

        _boostedOperatorsInfo[nodeOperatorId] = BoostInfo({
            boosted: false,
            oldCurveId: 0,
            boostDeposit: 0
        });

        emit NodeOperatorUnboosted(msg.sender, nodeOperatorId);
    }

    /// @inheritdoc IGovernanceBooster
    function setBoostDeposit(
        uint256 _boostDeposit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_boostDeposit == 0) {
            revert InvalidBoostDeposit();
        }
        if (_boostDeposit == boostDeposit) {
            revert InvalidBoostDeposit();
        }

        boostDeposit = _boostDeposit;

        emit BoostDepositSet(_boostDeposit);
    }

    /// @inheritdoc IGovernanceBooster
    function setCurveId(
        uint256 _curveId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_curveId == ACCOUNTING.DEFAULT_BOND_CURVE_ID()) {
            revert InvalidCurveId();
        }
        if (_curveId == curveId) {
            revert InvalidCurveId();
        }
        if (ACCOUNTING.getCurvesCount() <= _curveId) {
            revert CurveDoesNotExist();
        }
        curveId = _curveId;
        emit CurveIdSet(_curveId);
    }

    /// @inheritdoc IGovernanceBooster
    function setDelegate(
        address _delegate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDelegate(_delegate);
    }

    function _setDelegate(address _delegate) internal {
        if (_delegate == address(0)) {
            revert ZeroDelegateAddress();
        }
        if (_delegate == delegate) {
            revert InvalidDelegateAddress();
        }

        delegate = _delegate;

        emit DelegateSet(_delegate);

        _updateDelegation();
    }

    /// @inheritdoc AssetRecoverer
    function recoverERC20(address token, uint256 amount) external override {
        _onlyRecoverer();
        if (token == address(LDO)) {
            uint256 balance = LDO.balanceOf(address(this));
            uint256 allowedToRecover = balance - totalBoosts;
            if (amount > allowedToRecover) {
                amount = allowedToRecover;
            }
            AssetRecovererLib.recoverERC20(token, amount);
        } else {
            AssetRecovererLib.recoverERC20(token, amount);
        }
    }

    /// @inheritdoc IGovernanceBooster
    function isOperatorBoosted(
        uint256 nodeOperatorId
    ) external view returns (bool) {
        return _boostedOperatorsInfo[nodeOperatorId].boosted;
    }

    /// @inheritdoc IGovernanceBooster
    function getBoostInfo(
        uint256 nodeOperatorId
    ) external view returns (BoostInfo memory) {
        return _boostedOperatorsInfo[nodeOperatorId];
    }

    function _updateDelegation() internal {
        // Set the delegate in the Snapshot delegation contract
        SNAPSHOT_DELEGATION.setDelegate(
            bytes32(0), // Allow voting in all spaces
            delegate
        );

        // Assign the delegate in the Voting contract
        VOTING.assignDelegate(delegate);

        emit DelegationUpdated(delegate);
    }

    /// @dev Verifies that the sender is the owner of the node operator
    function _onlyNodeOperatorOwner(uint256 nodeOperatorId) internal view {
        address owner = MODULE.getNodeOperatorOwner(nodeOperatorId);
        if (owner == address(0)) {
            revert NodeOperatorDoesNotExist();
        }
        if (owner != msg.sender) {
            revert NotAllowedToBoost();
        }
    }

    function _onlyRecoverer() internal view override {
        _checkRole(RECOVERER_ROLE);
    }
}
