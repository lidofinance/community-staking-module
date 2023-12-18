// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { CSBondCoreBase, CSBondCore } from "./CSBondCore.sol";
import { CSBondCurve } from "./CSBondCurve.sol";
import { CSBondLock } from "./CSBondLock.sol";

import { ICSModule } from "./interfaces/ICSModule.sol";
import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";

abstract contract CSAccountingBase is CSBondCoreBase {
    event BondLockCompensated(uint256 indexed nodeOperatorId, uint256 amount);
    event BondLockReleased(uint256 indexed nodeOperatorId, uint256 amount);

    error NotOwnerToClaim(address msgSender, address owner);
    error InvalidSender();
}

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

    bytes32 public constant SEAL_ROLE = keccak256("SEAL_ROLE"); // 0x5561eed4f05defaf62a493aaa0919339d3f352fbf2261adb133a0c3655488b4f

    bytes32 public constant INSTANT_PENALIZE_BOND_ROLE =
        keccak256("INSTANT_PENALIZE_BOND_ROLE"); // 0x9909cf24c2d3bafa8c229558d86a1b726ba57c3ef6350848dcf434a4181b56c7
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

    ICSModule private immutable CSM;

    address public FEE_DISTRIBUTOR;

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
        require(admin != address(0), "admin is zero address");
        require(
            communityStakingModule != address(0),
            "community staking module is zero address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        CSM = ICSModule(communityStakingModule);
    }

    /// @notice Sets fee distributor contract address.
    /// @param fdAddress fee distributor contract address.
    function setFeeDistributor(
        address fdAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FEE_DISTRIBUTOR = fdAddress;
    }

    /// @notice Sets bond lock retention period.
    /// @param retention period in seconds to retain bond lock
    function setLockedBondRetentionPeriod(
        uint256 retention
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // todo: is it admin role?
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
        // todo: implement me
    }

    /// @notice Unpauses accounting by DAO decision.
    function resumeAccounting() external onlyRole(RESUME_ROLE) {
        // todo: implement me
    }

    /// @dev can be overridden in child contracts
    /// @notice Returns current and required bond amount in ETH (stETH) for the given node operator.
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
        current = getBond(nodeOperatorId);
        required =
            CSBondCurve.getBondAmountByKeysCount(
                activeKeys,
                CSBondCurve.getBondCurve(nodeOperatorId)
            ) +
            CSBondLock.getActualLockedBond(nodeOperatorId);
    }

    /// @dev can be overridden in child contracts
    /// @notice Returns current and required bond amount in stETH shares for the given node operator.
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
        current = getBondShares(nodeOperatorId);
        required = _sharesByEth(
            CSBondCurve.getBondAmountByKeysCount(
                activeKeys,
                CSBondCurve.getBondCurve(nodeOperatorId)
            ) + CSBondLock.getActualLockedBond(nodeOperatorId)
        );
    }

    /// @notice Returns the excess bond amount in ETH (stETH) for the given node operator.
    /// @param nodeOperatorId id of the node operator to get excess bond for.
    /// @return excess bond amount.
    function getExcessBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = getBondSummary(nodeOperatorId);
        return current > required ? current - required : 0;
    }

    /// @notice Returns the missing bond amount in ETH (stETH) for the given node operator.
    /// @param nodeOperatorId id of the node operator to get missing bond for.
    /// @return missing bond amount.
    function getMissingBond(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = getBondSummary(nodeOperatorId);
        return current < required ? required - current : 0;
    }

    /// @dev can be overridden in child contracts
    /// @notice Returns the number of unbonded keys
    /// @dev unbonded meaning amount of keys with no bond at all
    /// @param nodeOperatorId id of the node operator to get keys count for.
    /// @return unbonded keys count.
    function getUnbondedKeysCount(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        uint256 activeKeys = _getActiveKeys(nodeOperatorId);
        uint256 currentBond = CSBondCore._ethByShares(
            _bondShares[nodeOperatorId]
        );
        uint256 lockedBond = CSBondLock.getActualLockedBond(nodeOperatorId);
        if (currentBond > lockedBond) {
            currentBond -= lockedBond;
            CSBondCurve.BondCurve memory bondCurve = CSBondCurve.getBondCurve(
                nodeOperatorId
            );
            uint256 bondedKeys = CSBondCurve.getKeysCountByBondAmount(
                currentBond,
                bondCurve
            );
            if (
                currentBond >
                CSBondCurve.getBondAmountByKeysCount(bondedKeys, bondCurve)
            ) {
                bondedKeys += 1;
            }
            return activeKeys > bondedKeys ? activeKeys - bondedKeys : 0;
        }
        return activeKeys;
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
        // todo: can it be two functions rather than one with `from` param and condition?
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
        // todo: can it be two functions rather than one with `from` param and condition?
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
        // todo: can it be two functions rather than one with `from` param and condition?
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
        // todo: can it be two functions rather than one with `from` param and condition?
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
            _getExcessBondSummaryShares(
                nodeOperatorId,
                _calcActiveKeys(nodeOperator)
            ),
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
        // todo: reorder ops to use only one func ???
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        _pullFeeRewards(rewardsProof, nodeOperatorId, cumulativeFeeShares);
        CSBondCore._claimStETH(
            nodeOperatorId,
            _getExcessBondSummaryShares(
                nodeOperatorId,
                _calcActiveKeys(nodeOperator)
            ),
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
        CSBondCore._claimWstETH(
            nodeOperatorId,
            _getExcessBondSummaryShares(
                nodeOperatorId,
                _calcActiveKeys(nodeOperator)
            ),
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
            _getExcessBondSummaryShares(
                nodeOperatorId,
                _calcActiveKeys(nodeOperator)
            ),
            wstETHAmount,
            nodeOperator.rewardAddress
        );
    }

    /// @notice Request excess bond in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param ETHAmount amount of ETH to request.
    /// @return requestId id of the withdrawal request.
    function requestExcessBondETH(
        uint256 nodeOperatorId,
        uint256 ETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        (uint256 requestId, , ) = CSBondCore._requestETH(
            nodeOperatorId,
            _getExcessBondSummaryShares(
                nodeOperatorId,
                _calcActiveKeys(nodeOperator)
            ),
            ETHAmount,
            nodeOperator.rewardAddress
        );
        return requestId;
    }

    /// @notice Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    /// @param ETHAmount amount of ETH to request.
    /// @return requestId id of the withdrawal request.
    function requestRewardsETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 ETHAmount
    ) external onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        _isSenderEligibleToClaim(nodeOperator.managerAddress);
        _pullFeeRewards(rewardsProof, nodeOperatorId, cumulativeFeeShares);
        (uint256 requestId, , ) = CSBondCore._requestETH(
            nodeOperatorId,
            _getExcessBondSummaryShares(
                nodeOperatorId,
                _calcActiveKeys(nodeOperator)
            ),
            ETHAmount,
            nodeOperator.rewardAddress
        );
        return requestId;
    }

    function _getExcessBondSummaryShares(
        uint256 nodeOperatorId,
        uint256 ETHAmount,
        uint256 activeKeys
    ) internal view returns (uint256) {
        (uint256 current, uint256 required) = _getBondSummaryShares(
            nodeOperatorId,
            activeKeys
        );
        return current > required ? current - required : 0;
    }

    function lockBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        onlyRole(SET_BOND_LOCK_ROLE)
    {
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
        BondLock memory lockInfo = CSBondLock._get(nodeOperatorId);
        uint256 lockedAmount = getActualLockedBondETH(nodeOperatorId);
        if (lockedAmount > 0) {
            _penalize(nodeOperatorId, lockedAmount);
        }
        CSBondLock._reduceAmount(nodeOperatorId, lockInfo.amount);
    }

    /// @notice Burn all bond and request exits for all node operators' validators.
    /// @dev Called only by DAO. Have lifetime. Once expired can never be called.
    function sealAccounting() external onlyRole(SEAL_ROLE) {
        // todo: implement me
    }

    /// @notice Settles initial slashing penalty for the given node operator.
    /// @param slashingProof merkle proof of the slashing.
    /// @param nodeOperatorId id of the node operator to settle initial slashing penalty for.
    function settleInitialSlashingPenalty(
        bytes32[] memory slashingProof,
        uint256 nodeOperatorId
    ) external onlyExistingNodeOperator(nodeOperatorId) {
        // todo: implement me
    }

    /// @notice Penalize bond by burning shares of the given node operator.
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param amount amount of ETH to penalize.
    function penalize(
        uint256 nodeOperatorId,
        uint256 amount
    ) public onlyRole(INSTANT_PENALIZE_BOND_ROLE) {
        _penalize(nodeOperatorId, amount);
    }

    function _penalize(
        uint256 nodeOperatorId,
        uint256 amount
    ) internal onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        uint256 penaltyShares = _sharesByEth(amount);
        uint256 currentShares = getBondShares(nodeOperatorId);
        uint256 sharesToBurn = penaltyShares < currentShares
            ? penaltyShares
            : currentShares;
        LIDO.transferSharesFrom(
            address(this),
            LIDO_LOCATOR.burner(),
            sharesToBurn
        );
        _bondShares[nodeOperatorId] -= sharesToBurn;
        totalBondShares -= sharesToBurn;
        uint256 penaltyEth = _ethByShares(penaltyShares);
        uint256 coveringEth = _ethByShares(sharesToBurn);
        emit BondPenalized(nodeOperatorId, penaltyEth, coveringEth);
        return penaltyEth - coveringEth;
    }

    function _feeDistributor() internal view returns (ICSFeeDistributor) {
        return ICSFeeDistributor(FEE_DISTRIBUTOR);
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
        uint256 distributed = _feeDistributor().distributeFees(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        _bondShares[nodeOperatorId] += distributed;
        totalBondShares += distributed;
    }

    modifier onlyExistingNodeOperator(uint256 nodeOperatorId) {
        require(
            nodeOperatorId < CSM.getNodeOperatorsCount(),
            "node operator does not exist"
        );
        _;
    }
}
