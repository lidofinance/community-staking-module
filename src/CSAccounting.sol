// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.24;

import { PausableUntil } from "base-oracle/utils/PausableUntil.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { CSBondCore } from "./abstract/CSBondCore.sol";
import { CSBondCurve } from "./abstract/CSBondCurve.sol";
import { CSBondLock } from "./abstract/CSBondLock.sol";

import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { AssetRecoverer } from "./abstract/AssetRecoverer.sol";
import { AssetRecovererLib } from "./lib/AssetRecovererLib.sol";

abstract contract CSAccountingBase {
    event BondLockCompensated(uint256 indexed nodeOperatorId, uint256 amount);
    event FeeDistributorSet(address feeDistributor);
    event ChargeRecipientSet(address chargeRecipient);

    error AlreadyInitialized();
    error InvalidSender();
    error SenderIsNotCSM();
}

/// @author vgorkavenko
contract CSAccounting is
    CSBondCore,
    CSBondCurve,
    CSBondLock,
    CSAccountingBase,
    PausableUntil,
    AccessControlEnumerable,
    AssetRecoverer
{
    /// @notice This contract stores the node operators' bonds in form of stETH shares,
    /// so it should be considered in the recovery process
    using SafeERC20 for IERC20;
    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE"); // 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE"); // 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7

    bytes32 public constant INITIALIZE_ROLE = keccak256("INITIALIZE_ROLE"); // 0xf1d56a0879c1f3fb7b8db84f8f66a72839440915c8cc40c60b771b23d8349df0
    bytes32 public constant ACCOUNTING_MANAGER_ROLE =
        keccak256("ACCOUNTING_MANAGER_ROLE"); // 0x40579467dba486691cc62fd8536d22c6d4dc9cdc7bc716ef2518422aa554c098
    bytes32 public constant ADD_BOND_CURVE_ROLE =
        keccak256("ADD_BOND_CURVE_ROLE"); // 0xd2becf7ae0eafe4edadee8d89582631d5922eccd2ac7b3fdf4afbef7595f4512
    bytes32 public constant SET_DEFAULT_BOND_CURVE_ROLE =
        keccak256("SET_DEFAULT_BOND_CURVE_ROLE"); // 0xb96689e168af25a79300d9b242da3d0653f6030e5c7a93192007dbd3f520875b
    bytes32 public constant SET_BOND_CURVE_ROLE =
        keccak256("SET_BOND_CURVE_ROLE"); // 0x645c9e6d2a86805cb5a28b1e4751c0dab493df7cf935070ce405489ba1a7bf72
    bytes32 public constant RESET_BOND_CURVE_ROLE =
        keccak256("RESET_BOND_CURVE_ROLE"); // 0xb5dffea014b759c493d63b1edaceb942631d6468998125e1b4fe427c99082134
    bytes32 public constant RECOVERER_ROLE = keccak256("RECOVERER_ROLE"); // 0xb3e25b5404b87e5a838579cb5d7481d61ad96ee284d38ec1e97c07ba64e7f6fc

    ICSModule private immutable CSM;

    address public feeDistributor;
    address public chargeRecipient;

    /// @param bondCurve initial bond curve
    /// @param admin admin role member address
    /// @param lidoLocator lido locator contract address
    /// @param wstETH wstETH contract address
    /// @param communityStakingModule community staking module contract address
    /// @param bondLockRetentionPeriod retention period for locked bond in seconds
    /// @param _chargeRecipient recipient of the charge penalty type
    constructor(
        uint256[] memory bondCurve,
        address admin,
        address lidoLocator,
        address wstETH,
        address communityStakingModule,
        uint256 bondLockRetentionPeriod,
        address _chargeRecipient
    )
        CSBondCore(lidoLocator, wstETH)
        CSBondCurve(bondCurve)
        CSBondLock(bondLockRetentionPeriod)
    {
        // check zero addresses
        if (admin == address(0)) {
            revert ZeroAddress("admin");
        }
        if (communityStakingModule == address(0)) {
            revert ZeroAddress("communityStakingModule");
        }
        if (_chargeRecipient == address(0)) {
            revert ZeroAddress("chargeRecipient");
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        CSM = ICSModule(communityStakingModule);

        chargeRecipient = _chargeRecipient;
        emit ChargeRecipientSet(_chargeRecipient);
    }

    /// @notice Resume accounting
    function resume() external onlyRole(RESUME_ROLE) {
        _resume();
    }

    /// @dev Must be called together with `CSModule.pauseFor`
    /// @notice Pause accounting
    /// @param duration Duration of the pause
    function pauseFor(uint256 duration) external onlyRole(PAUSE_ROLE) {
        _pauseFor(duration);
    }

    /// @notice Sets fee distributor contract address.
    /// @param fdAddress fee distributor contract address.
    function setFeeDistributor(
        address fdAddress
    ) external onlyRole(INITIALIZE_ROLE) {
        if (fdAddress == address(0)) {
            revert ZeroAddress("feeDistributor");
        }
        if (feeDistributor != address(0)) {
            revert AlreadyInitialized();
        }
        feeDistributor = fdAddress;
        emit FeeDistributorSet(fdAddress);
    }

    /// @notice Sets charge recipient address.
    /// @param _chargeRecipient  charge recipient address.
    function setChargeRecipient(
        address _chargeRecipient
    ) external onlyRole(ACCOUNTING_MANAGER_ROLE) {
        if (_chargeRecipient == address(0)) {
            revert ZeroAddress("chargeRecipient");
        }
        chargeRecipient = _chargeRecipient;
        emit ChargeRecipientSet(_chargeRecipient);
    }

    /// @notice Sets bond lock retention period.
    /// @param retention period in seconds to retain bond lock
    function setLockedBondRetentionPeriod(
        uint256 retention
    ) external onlyRole(ACCOUNTING_MANAGER_ROLE) {
        CSBondLock._setBondLockRetentionPeriod(retention);
    }

    /// @notice Add new bond curve.
    /// @param bondCurve bond curve to add.
    function addBondCurve(
        uint256[] memory bondCurve
    ) external onlyRole(ADD_BOND_CURVE_ROLE) returns (uint256) {
        return CSBondCurve._addBondCurve(bondCurve);
    }

    /// @notice Sets default bond curve.
    /// @param curveId id of the bond curve to set as default.
    function setDefaultBondCurve(
        uint256 curveId
    ) external onlyRole(SET_DEFAULT_BOND_CURVE_ROLE) {
        CSBondCurve._setDefaultBondCurve(curveId);
    }

    /// @notice Sets the bond curve for the given node operator.
    /// @param nodeOperatorId id of the node operator to set bond multiplier for.
    /// @param curveId id of the bond curve to set
    function setBondCurve(
        uint256 nodeOperatorId,
        uint256 curveId
    ) external onlyRole(SET_BOND_CURVE_ROLE) {
        CSBondCurve._setBondCurve(nodeOperatorId, curveId);
    }

    /// @notice Resets bond curve for the given node operator.
    /// @param nodeOperatorId id of the node operator to reset bond curve for.
    function resetBondCurve(
        uint256 nodeOperatorId
    ) external onlyRole(RESET_BOND_CURVE_ROLE) {
        CSBondCurve._resetBondCurve(nodeOperatorId);
    }

    /// @notice Returns current and required bond amount in ETH (stETH) for the given node operator.
    /// @dev To calculate excess bond amount subtract `required` from `current` value.
    ///      To calculate missed bond amount subtract `current` from `required` value.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return current bond amount.
    /// @return required bond amount.
    function getBondSummary(
        uint256 nodeOperatorId
    ) public view returns (uint256 current, uint256 required) {
        return _getBondSummary(nodeOperatorId, _getActiveKeys(nodeOperatorId));
    }

    function _getBondSummary(
        uint256 nodeOperatorId,
        uint256 activeKeys
    ) internal view returns (uint256 current, uint256 required) {
        current = CSBondCore.getBond(nodeOperatorId);
        required =
            CSBondCurve.getBondAmountByKeysCount(
                activeKeys,
                CSBondCurve.getBondCurve(nodeOperatorId)
            ) +
            CSBondLock.getActualLockedBond(nodeOperatorId);
    }

    /// @notice Returns current and required bond amount in stETH shares for the given node operator.
    /// @dev To calculate excess bond amount subtract `required` from `current` value.
    ///      To calculate missed bond amount subtract `current` from `required` value.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return current bond amount.
    /// @return required bond amount.
    function getBondSummaryShares(
        uint256 nodeOperatorId
    ) public view returns (uint256 current, uint256 required) {
        return
            _getBondSummaryShares(
                nodeOperatorId,
                _getActiveKeys(nodeOperatorId)
            );
    }

    function _getBondSummaryShares(
        uint256 nodeOperatorId,
        uint256 activeKeys
    ) internal view returns (uint256 current, uint256 required) {
        current = CSBondCore.getBondShares(nodeOperatorId);
        required = _sharesByEth(
            CSBondCurve.getBondAmountByKeysCount(
                activeKeys,
                CSBondCurve.getBondCurve(nodeOperatorId)
            ) + CSBondLock.getActualLockedBond(nodeOperatorId)
        );
    }

    /// @notice Returns the number of unbonded keys
    /// @param nodeOperatorId id of the node operator to get keys count for.
    /// @return unbonded keys count.
    function getUnbondedKeysCount(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return
            _getUnbondedKeysCount({
                nodeOperatorId: nodeOperatorId,
                accountLockedBond: true
            });
    }

    /// @notice Returns the number of unbonded keys to eject from validator set
    /// @param nodeOperatorId id of the node operator to get keys count for.
    /// @return unbonded keys count.
    function getUnbondedKeysCountToEject(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return
            _getUnbondedKeysCount({
                nodeOperatorId: nodeOperatorId,
                accountLockedBond: false
            });
    }

    /// @dev unbonded meaning amount of keys with bond less than required
    function _getUnbondedKeysCount(
        uint256 nodeOperatorId,
        bool accountLockedBond
    ) internal view returns (uint256) {
        uint256 activeKeys = _getActiveKeys(nodeOperatorId);
        /// 10 wei added to account for possible stETH rounding errors
        /// https://github.com/lidofinance/lido-dao/issues/442#issuecomment-1182264205
        /// Should be sufficient for ~ 40 years
        uint256 currentBond = CSBondCore._ethByShares(
            _bondShares[nodeOperatorId]
        ) + 10 wei;
        if (accountLockedBond) {
            uint256 lockedBond = CSBondLock.getActualLockedBond(nodeOperatorId);
            if (currentBond <= lockedBond) return activeKeys;
            currentBond -= lockedBond;
        }
        CSBondCurve.BondCurve memory bondCurve = CSBondCurve.getBondCurve(
            nodeOperatorId
        );
        uint256 bondedKeys = CSBondCurve.getKeysCountByBondAmount(
            currentBond,
            bondCurve
        );
        if (bondedKeys >= activeKeys) return 0;
        return activeKeys - bondedKeys;
    }

    /// @notice Returns the required bond in ETH (inc. missed and excess) for the given node operator to upload new keys.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @param additionalKeys number of new keys to add.
    /// @return required bond in ETH.
    function getRequiredBondForNextKeys(
        uint256 nodeOperatorId,
        uint256 additionalKeys
    ) public view returns (uint256) {
        uint256 activeKeys = _getActiveKeys(nodeOperatorId);
        (uint256 current, uint256 required) = _getBondSummary(
            nodeOperatorId,
            activeKeys
        );
        CSBondCurve.BondCurve memory bondCurve = CSBondCurve.getBondCurve(
            nodeOperatorId
        );
        uint256 requiredForNextKeys = CSBondCurve.getBondAmountByKeysCount(
            activeKeys + additionalKeys,
            bondCurve
        ) - CSBondCurve.getBondAmountByKeysCount(activeKeys, bondCurve);

        uint256 missing = required > current ? required - current : 0;
        if (missing > 0) {
            return missing + requiredForNextKeys;
        }

        uint256 excess = current - required;
        if (excess >= requiredForNextKeys) {
            return 0;
        }

        return requiredForNextKeys - excess;
    }

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount
    ) public view returns (uint256) {
        return
            WSTETH.getWstETHByStETH(
                CSBondCurve.getBondAmountByKeysCount(keysCount)
            );
    }

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount,
        BondCurve memory curve
    ) public view returns (uint256) {
        return
            WSTETH.getWstETHByStETH(
                CSBondCurve.getBondAmountByKeysCount(keysCount, curve)
            );
    }

    /// @notice Returns the required bond in wstETH (inc. missed and excess) for the given node operator to upload new keys.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @param additionalKeys number of new keys to add.
    /// @return required bond in wstETH.
    function getRequiredBondForNextKeysWstETH(
        uint256 nodeOperatorId,
        uint256 additionalKeys
    ) public view returns (uint256) {
        return
            WSTETH.getWstETHByStETH(
                getRequiredBondForNextKeys(nodeOperatorId, additionalKeys)
            );
    }

    /// @notice Stake user's ETH to Lido and make deposit in stETH to the bond
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to stake ETH and deposit stETH from
    /// @param nodeOperatorId id of the node operator to stake ETH and deposit stETH for
    /// @return shares stETH shares amount
    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable whenResumed onlyCSM returns (uint256 shares) {
        shares = CSBondCore._depositETH(from, nodeOperatorId);
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to deposit stETH from
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param stETHAmount amount of stETH to deposit
    /// @param permit stETH permit for the contract
    /// @return shares stETH shares amount
    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput calldata permit
    ) external whenResumed onlyCSM returns (uint256 shares) {
        // preventing revert for already used permit or avoid permit usage in case of value == 0
        if (
            permit.value > 0 &&
            LIDO.allowance(from, address(this)) < permit.value
        ) {
            // solhint-disable-next-line func-named-parameters
            LIDO.permit(
                from,
                address(this),
                permit.value,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            );
        }
        shares = CSBondCore._depositStETH(from, nodeOperatorId, stETHAmount);
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to unwrap wstETH from
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param wstETHAmount amount of wstETH to deposit
    /// @param permit wstETH permit for the contract
    /// @return shares stETH shares amount
    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput calldata permit
    ) external whenResumed onlyCSM returns (uint256 shares) {
        // preventing revert for already used permit or avoid permit usage in case of value == 0
        if (
            permit.value > 0 &&
            WSTETH.allowance(from, address(this)) < permit.value
        ) {
            // solhint-disable-next-line func-named-parameters
            WSTETH.permit(
                from,
                address(this),
                permit.value,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            );
        }
        shares = CSBondCore._depositWstETH(from, nodeOperatorId, wstETHAmount);
    }

    /// @dev only CSM can pass `from` != `msg.sender`
    function _validateDepositSender(
        address from
    ) internal view returns (address) {
        if (from == address(0)) from = msg.sender;
        if (from != msg.sender && msg.sender != address(CSM))
            revert InvalidSender();
        return from;
    }

    /// @notice Claims full reward (fee + bond) in stETH for the given node operator with desirable value.
    /// rewardsProof and cumulativeFeeShares might be empty in order to claim only excess bond
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param stETHAmount amount of stETH to claim.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param rewardsProof merkle proof of the rewards.
    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external whenResumed onlyCSM {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );

        if (rewardsProof.length != 0) {
            _pullFeeRewards(nodeOperatorId, cumulativeFeeShares, rewardsProof);
        }
        if (stETHAmount == 0) return;
        CSBondCore._claimStETH(
            nodeOperatorId,
            _getExcessBondShares(nodeOperatorId, _calcActiveKeys(nodeOperator)),
            stETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Claims full reward (fee + bond) in wstETH for the given node operator available for this moment
    /// rewardsProof and cumulativeFeeShares might be empty in order to claim only excess bond
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param wstETHAmount amount of wstETH to claim.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param rewardsProof merkle proof of the rewards.
    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external whenResumed onlyCSM {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );

        if (rewardsProof.length != 0) {
            _pullFeeRewards(nodeOperatorId, cumulativeFeeShares, rewardsProof);
        }
        CSBondCore._claimWstETH(
            nodeOperatorId,
            _getExcessBondShares(nodeOperatorId, _calcActiveKeys(nodeOperator)),
            wstETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// rewardsProof and cumulativeFeeShares might be empty in order to claim only excess bond
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param ethAmount amount of ETH to request.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param rewardsProof merkle proof of the rewards.
    function requestRewardsETH(
        uint256 nodeOperatorId,
        uint256 ethAmount,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external whenResumed onlyCSM {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );

        if (rewardsProof.length != 0) {
            _pullFeeRewards(nodeOperatorId, cumulativeFeeShares, rewardsProof);
        }
        if (ethAmount == 0) return;
        CSBondCore._requestETH(
            nodeOperatorId,
            _getExcessBondShares(nodeOperatorId, _calcActiveKeys(nodeOperator)),
            ethAmount,
            nodeOperator.rewardAddress
        );
    }

    function _getExcessBondShares(
        uint256 nodeOperatorId,
        uint256 activeKeys
    ) internal view returns (uint256) {
        (uint256 current, uint256 required) = _getBondSummaryShares(
            nodeOperatorId,
            activeKeys
        );
        return current > required ? current - required : 0;
    }

    /// @notice Locks bond in ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to lock bond for.
    /// @param amount amount of ETH to lock.
    function lockBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    ) external onlyCSM {
        CSBondLock._lock(nodeOperatorId, amount);
    }

    /// @notice Releases locked bond in ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to release locked bond for.
    /// @param amount amount of ETH to release.
    function releaseLockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    ) external onlyCSM {
        CSBondLock._reduceAmount(nodeOperatorId, amount);
    }

    /// @notice Compensates locked bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to compensate locked bond for.
    function compensateLockedBondETH(
        uint256 nodeOperatorId
    ) external payable onlyCSM {
        payable(LIDO_LOCATOR.elRewardsVault()).transfer(msg.value);
        CSBondLock._reduceAmount(nodeOperatorId, msg.value);
        emit BondLockCompensated(nodeOperatorId, msg.value);
    }

    /// @notice Settles locked bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to settle locked bond for.
    function settleLockedBondETH(
        uint256 nodeOperatorId
    ) external onlyCSM returns (uint256 lockedAmount) {
        lockedAmount = CSBondLock.getActualLockedBond(nodeOperatorId);
        if (lockedAmount > 0) {
            CSBondCore._burn(nodeOperatorId, lockedAmount);
        }
        // reduce all locked bond even if bond isn't covered lock fully
        CSBondLock._remove(nodeOperatorId);
        return lockedAmount;
    }

    /// @notice Penalize bond by burning shares of the given node operator.
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to penalize.
    function penalize(uint256 nodeOperatorId, uint256 amount) public onlyCSM {
        CSBondCore._burn(nodeOperatorId, amount);
    }

    /// @notice Charge fee from bond by transferring shares of the given node operator to the charge recipient.
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to charge.
    function chargeFee(
        uint256 nodeOperatorId,
        uint256 amount
    ) external onlyCSM {
        CSBondCore._charge(nodeOperatorId, amount, chargeRecipient);
    }

    function recoverERC20(
        address token,
        uint256 amount
    ) external override onlyRecoverer {
        if (token == address(LIDO)) {
            revert NotAllowedToRecover();
        }
        AssetRecovererLib.recoverERC20(token, amount);
    }

    function recoverStETHShares() external onlyRecoverer {
        uint256 shares = LIDO.sharesOf(address(this)) - totalBondShares;
        AssetRecovererLib.recoverStETHShares(address(LIDO), shares);
    }

    modifier onlyRecoverer() override {
        _checkRole(RECOVERER_ROLE);
        _;
    }

    function _getActiveKeys(
        uint256 nodeOperatorId
    ) internal view returns (uint256) {
        return _calcActiveKeys(CSM.getNodeOperator(nodeOperatorId));
    }

    function _calcActiveKeys(
        ICSModule.NodeOperatorInfo memory nodeOperator
    ) private pure returns (uint256) {
        return
            nodeOperator.totalAddedValidators -
            nodeOperator.totalWithdrawnValidators;
    }

    function _pullFeeRewards(
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) internal {
        uint256 distributed = ICSFeeDistributor(feeDistributor).distributeFees(
            nodeOperatorId,
            cumulativeFeeShares,
            rewardsProof
        );
        _increaseBond(nodeOperatorId, distributed);
    }

    modifier onlyCSM() {
        if (msg.sender != address(CSM)) {
            revert SenderIsNotCSM();
        }
        _;
    }
}
