// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ICSModule } from "./interfaces/ICSModule.sol";
import { ILido } from "./interfaces/ILido.sol";
import { IWstETH } from "./interfaces/IWstETH.sol";
import { ICSFeeDistributor } from "./interfaces/ICSFeeDistributor.sol";
import { IWithdrawalQueue } from "./interfaces/IWithdrawalQueue.sol";

contract CSAccountingBase {
    event ETHBondDeposited(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event StETHBondDeposited(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event WstETHBondDeposited(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event BondPenalized(
        uint256 indexed nodeOperatorId,
        uint256 penaltyShares,
        uint256 burnedShares
    );
    event StETHRewardsClaimed(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
    event WstETHRewardsClaimed(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
    event ETHRewardsRequested(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
}

contract CSAccounting is CSAccountingBase, AccessControlEnumerable {
    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    error NotOwnerToClaim(address msgSender, address owner);

    bytes32 public constant PENALIZE_BOND_ROLE =
        keccak256("PENALIZE_BOND_ROLE");
    address public FEE_DISTRIBUTOR;

    uint256 public totalBondShares;
    mapping(uint256 => uint256) private bondShares;

    ILidoLocator private immutable LIDO_LOCATOR;
    ICSModule private immutable CSM;
    IWstETH private immutable WSTETH;
    uint256 private immutable COMMON_BOND_SIZE;

    /// @param _commonBondSize common bond size in ETH for all node operators.
    /// @param _admin admin role member address
    /// @param _lidoLocator lido locator contract address
    /// @param _wstETH wstETH contract address
    /// @param _communityStakingModule community staking module contract address
    /// @param _penalizeRoleMembers list of addresses with PENALIZE_BOND_ROLE
    constructor(
        uint256 _commonBondSize,
        address _admin,
        address _lidoLocator,
        address _wstETH,
        address _communityStakingModule,
        address[] memory _penalizeRoleMembers
    ) {
        // check zero addresses
        require(_admin != address(0), "admin is zero address");
        require(_lidoLocator != address(0), "lido locator is zero address");
        require(
            _communityStakingModule != address(0),
            "community staking module is zero address"
        );
        require(_wstETH != address(0), "wstETH is zero address");
        require(
            _penalizeRoleMembers.length > 0,
            "penalize role members is empty"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        for (uint256 i; i < _penalizeRoleMembers.length; ++i) {
            require(
                _penalizeRoleMembers[i] != address(0),
                "penalize role member is zero address"
            );
            _setupRole(PENALIZE_BOND_ROLE, _penalizeRoleMembers[i]);
        }

        LIDO_LOCATOR = ILidoLocator(_lidoLocator);
        CSM = ICSModule(_communityStakingModule);
        WSTETH = IWstETH(_wstETH);

        COMMON_BOND_SIZE = _commonBondSize;
    }

    function setFeeDistributor(
        address _fdAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FEE_DISTRIBUTOR = _fdAddress;
    }

    /// @notice Returns the bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond shares.
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return bondShares[nodeOperatorId];
    }

    /// @notice Returns total rewards (bond + fees) in ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get rewards for.
    /// @return total rewards in ETH
    function getTotalRewardsETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = _bondSharesSummary(
            _getNodeOperatorActiveKeys(nodeOperatorId)
        );
        current += _feeDistributor().getFeesToDistribute(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        uint256 excess = current > required ? current - required : 0;
        return excess > 0 ? _ethByShares(excess) : 0;
    }

    /// @notice Returns total rewards (bond + fees) in stETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get rewards for.
    /// @return total rewards in stETH
    function getTotalRewardsStETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) public view returns (uint256) {
        return
            getTotalRewardsETH(
                rewardsProof,
                nodeOperatorId,
                cumulativeFeeShares
            );
    }

    /// @notice Returns total rewards (bond + fees) in wstETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get rewards for.
    /// @return total rewards in wstETH
    function getTotalRewardsWstETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) public view returns (uint256) {
        return
            WSTETH.getWstETHByStETH(
                getTotalRewardsStETH(
                    rewardsProof,
                    nodeOperatorId,
                    cumulativeFeeShares
                )
            );
    }

    /// @notice Returns excess bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get excess bond for.
    /// @return excess bond ETH.
    function getExcessBondETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = _bondETHSummary(nodeOperatorId);
        return current > required ? current - required : 0;
    }

    /// @notice Returns excess bond stETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get excess bond for.
    /// @return excess bond stETH.
    function getExcessBondStETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return getExcessBondETH(nodeOperatorId);
    }

    /// @notice Returns excess bond wstETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get excess bond for.
    /// @return excess bond wstETH.
    function getExcessBondWstETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return WSTETH.getWstETHByStETH(getExcessBondStETH(nodeOperatorId));
    }

    /// @notice Returns the missing bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get missing bond for.
    /// @return missing bond ETH.
    function getMissingBondETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = _bondETHSummary(nodeOperatorId);
        return required > current ? required - current : 0;
    }

    /// @notice Returns the missing bond stETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get missing bond for.
    /// @return missing bond stETH.
    function getMissingBondStETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return getMissingBondETH(nodeOperatorId);
    }

    /// @notice Returns the missing bond wstETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to get missing bond for.
    /// @return missing bond wstETH.
    function getMissingBondWstETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return WSTETH.getWstETHByStETH(getMissingBondStETH(nodeOperatorId));
    }

    /// @notice Returns the required bond ETH (inc. missed and excess) for the given node operator to upload new keys.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @return required bond ETH.
    function getRequiredBondETH(
        uint256 nodeOperatorId,
        uint256 additionalKeysCount
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = _bondETHSummary(nodeOperatorId);
        uint256 requiredForKeys = getRequiredBondETHForKeys(
            additionalKeysCount
        );

        uint256 missing = required > current ? required - current : 0;
        if (missing > 0) {
            return missing + requiredForKeys;
        }

        uint256 excess = current - required;
        if (excess >= requiredForKeys) {
            return 0;
        }

        return requiredForKeys - excess;
    }

    /// @notice Returns the required bond stETH (inc. missed and excess) for the given node operator to upload new keys.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @return required bond stETH.
    function getRequiredBondStETH(
        uint256 nodeOperatorId,
        uint256 additionalKeysCount
    ) public view returns (uint256) {
        return getRequiredBondETH(nodeOperatorId, additionalKeysCount);
    }

    /// @notice Returns the required bond wstETH (inc. missed and excess) for the given node operator to upload new keys.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @param additionalKeysCount number of new keys to add.
    /// @return required bond wstETH.
    function getRequiredBondWstETH(
        uint256 nodeOperatorId,
        uint256 additionalKeysCount
    ) public view returns (uint256) {
        return
            WSTETH.getWstETHByStETH(
                getRequiredBondStETH(nodeOperatorId, additionalKeysCount)
            );
    }

    /// @notice Returns the required bond ETH for the given number of keys.
    /// @param keysCount number of keys to get required bond for.
    /// @return required ETH.
    function getRequiredBondETHForKeys(
        uint256 keysCount
    ) public view returns (uint256) {
        return keysCount * COMMON_BOND_SIZE;
    }

    /// @notice Returns the required bond stETH for the given number of keys.
    /// @param keysCount number of keys to get required bond for.
    /// @return required stETH.
    function getRequiredBondStETHForKeys(
        uint256 keysCount
    ) public view returns (uint256) {
        return getRequiredBondETHForKeys(keysCount);
    }

    /// @notice Returns the required bond wstETH for the given number of keys.
    /// @param keysCount number of keys to get required bond for.
    /// @return required wstETH.
    function getRequiredBondWstETHForKeys(
        uint256 keysCount
    ) public view returns (uint256) {
        return _getRequiredBondSharesForKeys(keysCount);
    }

    function _getRequiredBondSharesForKeys(
        uint256 keysCount
    ) internal view returns (uint256) {
        return _sharesByEth(getRequiredBondETHForKeys(keysCount));
    }

    /// @dev unbonded meaning amount of keys with no bond at all
    /// @notice Returns the number of unbonded keys
    /// @param nodeOperatorId id of the node operator to get keys count for.
    /// @return unbonded keys count.
    function getUnbondedKeysCount(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return
            getRequiredBondETH(nodeOperatorId, 0) /
            getRequiredBondETHForKeys(1);
    }

    /// @notice Returns the number of keys by the given bond ETH amount
    function getKeysCountByBondETH(
        uint256 ETHAmount
    ) public view returns (uint256) {
        return ETHAmount / getRequiredBondETHForKeys(1);
    }

    /// @notice Returns the number of keys by the given bond stETH amount
    function getKeysCountByBondStETH(
        uint256 stETHAmount
    ) public view returns (uint256) {
        return stETHAmount / getRequiredBondStETHForKeys(1);
    }

    /// @notice Returns the number of keys by the given bond wstETH amount
    function getKeysCountByBondWstETH(
        uint256 wstETHAmount
    ) public view returns (uint256) {
        return wstETHAmount / getRequiredBondWstETHForKeys(1);
    }

    /// @notice Deposits ETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable returns (uint256) {
        from = (from == address(0)) ? msg.sender : from;
        // TODO: should be modifier. condition might be changed as well
        require(
            nodeOperatorId < CSM.getNodeOperatorsCount(),
            "node operator does not exist"
        );
        uint256 shares = _lido().submit{ value: msg.value }(address(0));
        bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit ETHBondDeposited(nodeOperatorId, from, msg.value);
        return shares;
    }

    /// @notice Deposits stETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param stETHAmount amount of stETH to deposit.
    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256) {
        from = (from == address(0)) ? msg.sender : from;
        return _depositStETH(from, nodeOperatorId, stETHAmount);
    }

    /// @notice Deposits stETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param stETHAmount amount of stETH to deposit.
    /// @param permit permit to spend stETH.
    function depositStETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput calldata permit
    ) external returns (uint256) {
        from = (from == address(0)) ? msg.sender : from;
        _lido().permit(
            from,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _depositStETH(from, nodeOperatorId, stETHAmount);
    }

    function _depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) internal returns (uint256) {
        require(
            nodeOperatorId < CSM.getNodeOperatorsCount(),
            "node operator does not exist"
        );
        uint256 shares = _sharesByEth(stETHAmount);
        _lido().transferSharesFrom(from, address(this), shares);
        bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit StETHBondDeposited(nodeOperatorId, from, stETHAmount);
        return shares;
    }

    /// @notice Deposits wstETH to the bond for the given node operator.
    /// @param from address to deposit wstETH from.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param wstETHAmount amount of wstETH to deposit.
    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) external returns (uint256) {
        from = (from == address(0)) ? msg.sender : from;
        return _depositWstETH(from, nodeOperatorId, wstETHAmount);
    }

    /// @notice Deposits wstETH to the bond for the given node operator.
    /// @param from address to deposit wstETH from.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param wstETHAmount amount of wstETH to deposit.
    /// @param permit permit to spend wstETH.
    function depositWstETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput calldata permit
    ) external returns (uint256) {
        WSTETH.permit(
            from,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _depositWstETH(from, nodeOperatorId, wstETHAmount);
    }

    function _depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) internal returns (uint256) {
        require(
            nodeOperatorId < CSM.getNodeOperatorsCount(),
            "node operator does not exist"
        );
        WSTETH.transferFrom(from, address(this), wstETHAmount);
        uint256 stETHAmount = WSTETH.unwrap(wstETHAmount);
        uint256 shares = _sharesByEth(stETHAmount);
        bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit WstETHBondDeposited(nodeOperatorId, from, wstETHAmount);
        return shares;
    }

    /// @notice Claims full reward (fee + bond) for the given node operator with desirable value
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param stETHAmount amount of stETH to claim.
    function claimRewardsStETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 stETHAmount
    ) external {
        (
            address managerAddress,
            address rewardAddress
        ) = _getNodeOperatorAddresses(nodeOperatorId);
        _isSenderEligibleToClaim(managerAddress);
        uint256 claimableShares = _pullFeeRewards(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        if (claimableShares == 0) {
            emit StETHRewardsClaimed(nodeOperatorId, rewardAddress, 0);
            return;
        }
        uint256 toClaim = stETHAmount < _ethByShares(claimableShares)
            ? _sharesByEth(stETHAmount)
            : claimableShares;
        _lido().transferSharesFrom(address(this), rewardAddress, toClaim);
        bondShares[nodeOperatorId] -= toClaim;
        totalBondShares -= toClaim;
        emit StETHRewardsClaimed(
            nodeOperatorId,
            rewardAddress,
            _ethByShares(toClaim)
        );
    }

    /// @notice Claims full reward (fee + bond) for the given node operator available for this moment
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cumulative fee shares for the node operator.
    /// @param wstETHAmount amount of wstETH to claim.
    function claimRewardsWstETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 wstETHAmount
    ) external {
        (
            address managerAddress,
            address rewardAddress
        ) = _getNodeOperatorAddresses(nodeOperatorId);
        _isSenderEligibleToClaim(managerAddress);
        uint256 claimableShares = _pullFeeRewards(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        if (claimableShares == 0) {
            emit WstETHRewardsClaimed(nodeOperatorId, rewardAddress, 0);
            return;
        }
        uint256 toClaim = wstETHAmount < claimableShares
            ? wstETHAmount
            : claimableShares;
        wstETHAmount = WSTETH.wrap(_ethByShares(toClaim));
        WSTETH.transferFrom(address(this), rewardAddress, wstETHAmount);
        bondShares[nodeOperatorId] -= wstETHAmount;
        totalBondShares -= wstETHAmount;
        emit WstETHRewardsClaimed(nodeOperatorId, rewardAddress, wstETHAmount);
    }

    /// @notice Request full reward (fee + bond) in Withdrawal NFT (unstETH) for the given node operator available for this moment.
    /// @dev reverts if amount isn't between MIN_STETH_WITHDRAWAL_AMOUNT and MAX_STETH_WITHDRAWAL_AMOUNT
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to request rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    /// @return requestIds an array of the created withdrawal request ids
    function requestRewardsETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 ETHAmount
    ) external returns (uint256[] memory requestIds) {
        (
            address managerAddress,
            address rewardAddress
        ) = _getNodeOperatorAddresses(nodeOperatorId);
        _isSenderEligibleToClaim(managerAddress);
        uint256 claimableShares = _pullFeeRewards(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        uint256 toClaim = ETHAmount < _ethByShares(claimableShares)
            ? _sharesByEth(ETHAmount)
            : claimableShares;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _lido().getPooledEthByShares(toClaim);
        requestIds = _withdrawalQueue().requestWithdrawals(
            amounts,
            rewardAddress
        );
        bondShares[nodeOperatorId] -= toClaim;
        totalBondShares -= toClaim;
        emit ETHRewardsRequested(nodeOperatorId, rewardAddress, amounts[0]);
        return requestIds;
    }

    /// @notice Penalize bond by burning shares
    /// @param nodeOperatorId id of the node operator to penalize bond for.
    /// @param shares amount shares to burn.
    function penalize(
        uint256 nodeOperatorId,
        uint256 shares
    ) external onlyRole(PENALIZE_BOND_ROLE) {
        uint256 currentBond = getBondShares(nodeOperatorId);
        uint256 coveringShares = shares < currentBond ? shares : currentBond;
        _lido().transferSharesFrom(
            address(this),
            LIDO_LOCATOR.burner(),
            coveringShares
        );
        bondShares[nodeOperatorId] -= coveringShares;
        totalBondShares -= coveringShares;
        emit BondPenalized(nodeOperatorId, shares, coveringShares);
    }

    function _lido() internal view returns (ILido) {
        return ILido(LIDO_LOCATOR.lido());
    }

    function _feeDistributor() internal view returns (ICSFeeDistributor) {
        return ICSFeeDistributor(FEE_DISTRIBUTOR);
    }

    function _withdrawalQueue() internal view returns (IWithdrawalQueue) {
        return IWithdrawalQueue(LIDO_LOCATOR.withdrawalQueue());
    }

    function _getNodeOperatorActiveKeys(
        uint256 nodeOperatorId
    ) internal view returns (uint256) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        return
            nodeOperator.totalAddedValidators -
            nodeOperator.totalWithdrawnValidators;
    }

    function _getNodeOperatorAddresses(
        uint256 nodeOperatorId
    ) internal view returns (address, address) {
        ICSModule.NodeOperatorInfo memory nodeOperator = CSM.getNodeOperator(
            nodeOperatorId
        );
        return (nodeOperator.managerAddress, nodeOperator.rewardAddress);
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
    ) internal returns (uint256 claimableShares) {
        uint256 distributed = _feeDistributor().distributeFees(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        bondShares[nodeOperatorId] += distributed;
        totalBondShares += distributed;
        (uint256 current, uint256 required) = _bondSharesSummary(
            nodeOperatorId
        );
        claimableShares = current > required ? current - required : 0;
    }

    function _bondETHSummary(
        uint256 nodeOperatorId
    ) internal view returns (uint256 current, uint256 required) {
        current = _ethByShares(getBondShares(nodeOperatorId));
        required = getRequiredBondETHForKeys(
            _getNodeOperatorActiveKeys(nodeOperatorId)
        );
    }

    function _bondSharesSummary(
        uint256 nodeOperatorId
    ) internal view returns (uint256 current, uint256 required) {
        current = getBondShares(nodeOperatorId);
        required = _getRequiredBondSharesForKeys(
            _getNodeOperatorActiveKeys(nodeOperatorId)
        );
    }

    function _sharesByEth(uint256 ethAmount) internal view returns (uint256) {
        return _lido().getSharesByPooledEth(ethAmount);
    }

    function _ethByShares(uint256 shares) internal view returns (uint256) {
        return _lido().getPooledEthByShares(shares);
    }
}
