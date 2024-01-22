// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line one-contract-per-file
pragma solidity 0.8.21;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { CSBondCore } from "./CSBondCore.sol";
import { CSBondCurve } from "./CSBondCurve.sol";
import { CSBondLock } from "./CSBondLock.sol";

import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";

abstract contract CSAccountingBase {
    event BondLockCompensated(uint256 indexed nodeOperatorId, uint256 amount);
    event BondLockReleased(uint256 indexed nodeOperatorId, uint256 amount);

    error NotOwnerToClaim(address msgSender, address owner);
    error InvalidSender();
    error NodeOperatorDoesNotExist();
}

/// @author vgorkavenko
contract CSAccounting is
    CSBondCore,
    CSBondCurve,
    CSBondLock,
    CSAccountingBase,
    AccessControlEnumerable
{
    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE"); // 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
    bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE"); // 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7

    bytes32 public constant INSTANT_PENALIZE_BOND_ROLE =
        keccak256("INSTANT_PENALIZE_BOND_ROLE"); // 0x9909cf24c2d3bafa8c229558d86a1b726ba57c3ef6350848dcf434a4181b56c7
    bytes32 public constant INSTANT_CHARGE_FEE_FROM_BOND_ROLE =
        keccak256("INSTANT_CHARGE_FEE_FROM_BOND_ROLE");
    bytes32 public constant SET_BOND_LOCK_ROLE =
        keccak256("SET_BOND_LOCK_ROLE"); // 0x36ff2e3971b3c54917aa7f53b6db795a06950983343e75040614a29e789e7bae
    bytes32 public constant RELEASE_BOND_LOCK_ROLE =
        keccak256("RELEASE_BOND_LOCK_ROLE"); // 0xc2978b4baa6c8ed096f1f65a0b92abc3771cb669afce20daa9a5f3fbcd13dea1
    bytes32 public constant SETTLE_BOND_LOCK_ROLE =
        keccak256("SETTLE_BOND_LOCK_ROLE");
    bytes32 public constant ADD_BOND_CURVE_ROLE =
        keccak256("ADD_BOND_CURVE_ROLE");
    bytes32 public constant SET_DEFAULT_BOND_CURVE_ROLE =
        keccak256("SET_DEFAULT_BOND_CURVE_ROLE");
    bytes32 public constant SET_BOND_CURVE_ROLE =
        keccak256("SET_BOND_CURVE_ROLE");
    bytes32 public constant RESET_BOND_CURVE_ROLE =
        keccak256("RESET_BOND_CURVE_ROLE");

    uint256 public constant TOTAL_BASIS_POINTS = 10_000; // 100%
    // TODO: should be reconsidered. is it should be absolute value or percent?
    uint256 public constant BONDED_KEY_THRESHOLD_PERCENT_BP = 2000; // 20%

    ICSModule private immutable CSM;

    address public feeDistributor;

    /// @param bondCurve initial bond curve
    /// @param admin admin role member address
    /// @param lidoLocator lido locator contract address
    /// @param wstETH wstETH contract address
    /// @param communityStakingModule community staking module contract address
    /// @param bondLockRetentionPeriod retention period for locked bond in seconds
    constructor(
        uint256[] memory bondCurve,
        address admin,
        address lidoLocator,
        address wstETH,
        address communityStakingModule,
        uint256 bondLockRetentionPeriod
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

        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        CSM = ICSModule(communityStakingModule);
    }

    /// @notice Sets fee distributor contract address.
    /// @param fdAddress fee distributor contract address.
    function setFeeDistributor(
        address fdAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDistributor = fdAddress;
    }

    /// @notice Sets bond lock retention period.
    /// @param retention period in seconds to retain bond lock
    function setLockedBondRetentionPeriod(
        uint256 retention
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: is it admin role?
        CSBondLock._setBondLockRetentionPeriod(retention);
    }

    /// @notice Add new bond curve.
    /// @param bondCurve bond curve to add.
    function addBondCurve(
        uint256[] memory bondCurve
    ) external onlyRole(ADD_BOND_CURVE_ROLE) {
        CSBondCurve._addBondCurve(bondCurve);
    }

    /// @notice Sets default bond curve.
    /// @param curveId id of the bond curve to set as default.
    function setDefaultBondCurve(
        uint256 curveId
    ) external onlyRole(SET_DEFAULT_BOND_CURVE_ROLE) {
        CSBondCurve._setDefaultBondCurve(curveId);
    }

    /// @notice Sets basis points of the bond multiplier for the given node operator.
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

    /// @notice Pauses accounting by DAO decision.
    function pauseAccounting() external onlyRole(PAUSE_ROLE) {
        // TODO: implement me
    }

    /// @notice Unpauses accounting by DAO decision.
    function resumeAccounting() external onlyRole(RESUME_ROLE) {
        // TODO: implement me
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

    /// @dev unbonded meaning amount of keys with bond less than threshold
    function _getUnbondedKeysCount(
        uint256 nodeOperatorId,
        bool accountLockedBond
    ) internal view returns (uint256) {
        uint256 activeKeys = _getActiveKeys(nodeOperatorId);
        uint256 currentBond = CSBondCore._ethByShares(
            _bondShares[nodeOperatorId]
        );
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
        uint256 amountForBondedKeys = CSBondCurve.getBondAmountByKeysCount(
            bondedKeys,
            bondCurve
        );
        uint256 bondForNextKey = CSBondCurve.getBondAmountByKeysCount(
            bondedKeys + 1,
            bondCurve
        ) - amountForBondedKeys;
        uint256 keyBondPercent = ((TOTAL_BASIS_POINTS *
            (currentBond - amountForBondedKeys)) / bondForNextKey);
        if (keyBondPercent < BONDED_KEY_THRESHOLD_PERCENT_BP)
            return activeKeys - bondedKeys;
        return activeKeys - bondedKeys - 1;
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
    /// @return stETH shares amount
    function depositETH(
        address from,
        uint256 nodeOperatorId
    )
        external
        payable
        onlyExistingNodeOperator(nodeOperatorId)
        returns (uint256)
    {
        from = _validateDepositSender(from);
        return CSBondCore._depositETH(from, nodeOperatorId);
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to deposit stETH from
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param stETHAmount amount of stETH to deposit
    /// @return stETH shares amount
    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        // TODO: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        return CSBondCore._depositStETH(from, nodeOperatorId, stETHAmount);
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator using the proper permit for the contract
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to deposit stETH from
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param stETHAmount amount of stETH to deposit
    /// @param permit stETH permit for the contract
    /// @return stETH shares amount
    function depositStETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput calldata permit
    ) external onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        // TODO: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        // preventing revert for already used permit
        if (LIDO.allowance(from, address(this)) < permit.value) {
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
        return CSBondCore._depositStETH(from, nodeOperatorId, stETHAmount);
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to unwrap wstETH from
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param wstETHAmount amount of wstETH to deposit
    /// @return stETH shares amount
    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        // TODO: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        return CSBondCore._depositWstETH(from, nodeOperatorId, wstETHAmount);
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator using the proper permit for the contract
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    /// @param from address to unwrap wstETH from
    /// @param nodeOperatorId id of the node operator to deposit stETH for
    /// @param wstETHAmount amount of wstETH to deposit
    /// @param permit wstETH permit for the contract
    /// @return stETH shares amount
    function depositWstETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput calldata permit
    ) external onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        // TODO: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        // preventing revert for already used permit
        if (WSTETH.allowance(from, address(this)) < permit.value) {
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
        return CSBondCore._depositWstETH(from, nodeOperatorId, wstETHAmount);
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

    /// @notice Claims excess bond in ETH for the given node operator with desirable value
    /// @param nodeOperatorId id of the node operator to claim excess bond for.
    /// @param stETHAmount amount of stETH to claim.
    function claimExcessBondStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        CSBondCore._claimStETH(
            nodeOperatorId,
            _getExcessBondShares(nodeOperatorId, _calcActiveKeys(nodeOperator)),
            stETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Claims full reward (fee + bond) in stETH for the given node operator with desirable value
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param stETHAmount amount of stETH to claim.
    function claimRewardsStETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 stETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        // TODO: reorder ops to use only one func (first is pull) ???
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        _pullFeeRewards(rewardsProof, nodeOperatorId, cumulativeFeeShares);
        if (stETHAmount == 0) return;
        uint256 claimableShares = _getExcessBondShares(
            nodeOperatorId,
            _calcActiveKeys(nodeOperator)
        );
        if (claimableShares == 0) return;
        CSBondCore._claimStETH(
            nodeOperatorId,
            claimableShares,
            stETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Claims excess bond in wstETH for the given node operator with desirable value
    /// @param nodeOperatorId id of the node operator to claim excess bond for.
    /// @param wstETHAmount amount of wstETH to claim.
    function claimExcessBondWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        if (wstETHAmount == 0) return;
        uint256 claimableShares = _getExcessBondShares(
            nodeOperatorId,
            _calcActiveKeys(nodeOperator)
        );
        if (claimableShares == 0) return;
        CSBondCore._claimWstETH(
            nodeOperatorId,
            claimableShares,
            wstETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Claims full reward (fee + bond) in wstETH for the given node operator available for this moment
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param wstETHAmount amount of wstETH to claim.
    function claimRewardsWstETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 wstETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        _pullFeeRewards(rewardsProof, nodeOperatorId, cumulativeFeeShares);
        CSBondCore._claimWstETH(
            nodeOperatorId,
            _getExcessBondShares(nodeOperatorId, _calcActiveKeys(nodeOperator)),
            wstETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Request excess bond in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param ethAmount amount of ETH to request.
    function requestExcessBondETH(
        uint256 nodeOperatorId,
        uint256 ethAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        CSBondCore._requestETH(
            nodeOperatorId,
            _getExcessBondShares(nodeOperatorId, _calcActiveKeys(nodeOperator)),
            ethAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    /// @param ethAmount amount of ETH to request.
    function requestRewardsETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 ethAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        _pullFeeRewards(rewardsProof, nodeOperatorId, cumulativeFeeShares);
        if (ethAmount == 0) return;
        uint256 claimableShares = _getExcessBondShares(
            nodeOperatorId,
            _calcActiveKeys(nodeOperator)
        );
        if (claimableShares == 0) return;
        CSBondCore._requestETH(
            nodeOperatorId,
            claimableShares,
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
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyRole(SET_BOND_LOCK_ROLE)
    {
        // TODO: should it be CSModule only?
        CSBondLock._lock(nodeOperatorId, amount);
    }

    /// @notice Releases locked bond in ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to release locked bond for.
    /// @param amount amount of ETH to release.
    function releaseLockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    )
        external
        onlyRole(RELEASE_BOND_LOCK_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        CSBondLock._reduceAmount(nodeOperatorId, amount);
        emit BondLockReleased(nodeOperatorId, amount);
    }

    /// @notice Compensates locked bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to compensate locked bond for.
    function compensateLockedBondETH(
        uint256 nodeOperatorId
    ) external payable onlyExistingNodeOperator(nodeOperatorId) {
        payable(LIDO_LOCATOR.elRewardsVault()).transfer(msg.value);
        CSBondLock._reduceAmount(nodeOperatorId, msg.value);
        emit BondLockCompensated(nodeOperatorId, msg.value);
    }

    /// @notice Settles locked bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to settle locked bond for.
    function settleLockedBondETH(
        uint256 nodeOperatorId
    ) external onlyRole(SETTLE_BOND_LOCK_ROLE) {
        uint256 lockedAmount = CSBondLock.getActualLockedBond(nodeOperatorId);
        if (lockedAmount > 0) {
            CSBondCore._burn(nodeOperatorId, lockedAmount);
        }
        // reduce all locked bond even if bond isn't covered lock fully
        CSBondLock._remove(nodeOperatorId);
    }

    /// @notice Penalize bond by burning shares of the given node operator.
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to penalize.
    function penalize(
        uint256 nodeOperatorId,
        uint256 amount
    ) public onlyRole(INSTANT_PENALIZE_BOND_ROLE) {
        CSBondCore._burn(nodeOperatorId, amount);
    }

    /// @notice Charge fee from bond by transferring shares of the given node operator to the treasury.
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to charge.
    function chargeFee(
        uint256 nodeOperatorId,
        uint256 amount
    ) external onlyRole(INSTANT_CHARGE_FEE_FROM_BOND_ROLE) {
        CSBondCore._charge(nodeOperatorId, amount);
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

    function _isSenderEligibleToClaim(address rewardAddress) internal view {
        if (msg.sender != rewardAddress) {
            revert NotOwnerToClaim(msg.sender, rewardAddress);
        }
    }

    function _pullFeeRewards(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) internal {
        uint256 distributed = ICSFeeDistributor(feeDistributor).distributeFees(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        _bondShares[nodeOperatorId] += distributed;
        totalBondShares += distributed;
    }

    modifier onlyExistingNodeOperator(uint256 nodeOperatorId) {
        if (nodeOperatorId >= CSM.getNodeOperatorsCount()) {
            revert NodeOperatorDoesNotExist();
        }
        _;
    }
}
