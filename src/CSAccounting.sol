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
    event ELRewardsStealingPenaltyInitiated(
        uint256 indexed nodeOperatorId,
        uint256 proposedBlockNumber,
        uint256 stolenAmount
    );
    event BlockedBondChanged(
        uint256 indexed nodeOperatorId,
        uint256 newAmountETH,
        uint256 retentionUntil
    );
    event BlockedBondCompensated(
        uint256 indexed nodeOperatorId,
        uint256 amountETH
    );
    event BlockedBondReleased(
        uint256 indexed nodeOperatorId,
        uint256 amountETH
    );
    event BondPenalized(
        uint256 indexed nodeOperatorId,
        uint256 penaltyETH,
        uint256 coveringETH
    );

    error NotOwnerToClaim(address msgSender, address owner);
    error InvalidBlockedBondRetentionPeriod();
    error InvalidStolenAmount();
    error InvalidSender();
    error InvalidMultiplier();
}

contract CSAccounting is CSAccountingBase, AccessControlEnumerable {
    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct BlockedBond {
        uint256 ETHAmount;
        uint256 retentionUntil;
    }

    bytes32 public constant INSTANT_PENALIZE_BOND_ROLE =
        keccak256("INSTANT_PENALIZE_BOND_ROLE");
    bytes32 public constant EL_REWARDS_STEALING_PENALTY_INIT_ROLE =
        keccak256("EL_REWARDS_STEALING_PENALTY_INIT_ROLE");
    bytes32 public constant EL_REWARDS_STEALING_PENALTY_SETTLE_ROLE =
        keccak256("EL_REWARDS_STEALING_PENALTY_SETTLE_ROLE");
    bytes32 public constant SET_BOND_MULTIPLIER_ROLE =
        keccak256("SET_BOND_MULTIPLIER_ROLE");

    // todo: should be reconsidered
    uint256 public constant MIN_BLOCKED_BOND_RETENTION_PERIOD = 4 weeks;
    uint256 public constant MAX_BLOCKED_BOND_RETENTION_PERIOD = 365 days;
    uint256 public constant MIN_BLOCKED_BOND_MANAGEMENT_PERIOD = 1 days;
    uint256 public constant MAX_BLOCKED_BOND_MANAGEMENT_PERIOD = 7 days;

    uint256 public constant TOTAL_BASIS_POINTS = 10000;

    uint256 public immutable COMMON_BOND_SIZE;

    ILidoLocator private immutable LIDO_LOCATOR;
    ICSModule private immutable CSM;
    IWstETH private immutable WSTETH;

    address public FEE_DISTRIBUTOR;
    uint256 public totalBondShares;

    uint256 public blockedBondRetentionPeriod;
    uint256 public blockedBondManagementPeriod;

    mapping(uint256 => uint256) internal _bondShares;
    mapping(uint256 => BlockedBond) internal _blockedBondEther;
    /// This mapping contains bond multiplier points (in basis points) for Node Operator's bond.
    /// By default, all Node Operators have x1 multiplier (10000 basis points).
    mapping(uint256 => uint256) internal _bondMultiplierBasisPoints;

    /// @param commonBondSize common bond size in ETH for all node operators.
    /// @param admin admin role member address
    /// @param lidoLocator lido locator contract address
    /// @param wstETH wstETH contract address
    /// @param communityStakingModule community staking module contract address
    /// @param _blockedBondRetentionPeriod retention period for blocked bond in seconds
    /// @param _blockedBondManagementPeriod management period for blocked bond in seconds
    constructor(
        uint256 commonBondSize,
        address admin,
        address lidoLocator,
        address wstETH,
        address communityStakingModule,
        uint256 _blockedBondRetentionPeriod,
        uint256 _blockedBondManagementPeriod
    ) {
        // check zero addresses
        require(admin != address(0), "admin is zero address");
        require(lidoLocator != address(0), "lido locator is zero address");
        require(
            communityStakingModule != address(0),
            "community staking module is zero address"
        );
        require(wstETH != address(0), "wstETH is zero address");
        _validateBlockedBondPeriods(
            _blockedBondRetentionPeriod,
            _blockedBondManagementPeriod
        );
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        CSM = ICSModule(communityStakingModule);
        WSTETH = IWstETH(wstETH);

        COMMON_BOND_SIZE = commonBondSize;

        blockedBondRetentionPeriod = _blockedBondRetentionPeriod;
        blockedBondManagementPeriod = _blockedBondManagementPeriod;
    }

    function setFeeDistributor(
        address fdAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FEE_DISTRIBUTOR = fdAddress;
    }

    function setBlockedBondPeriods(
        uint256 retention,
        uint256 management
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _validateBlockedBondPeriods(retention, management);
        blockedBondRetentionPeriod = retention;
        blockedBondManagementPeriod = management;
    }

    function _validateBlockedBondPeriods(
        uint256 retention,
        uint256 management
    ) internal pure {
        if (
            retention < MIN_BLOCKED_BOND_RETENTION_PERIOD ||
            retention > MAX_BLOCKED_BOND_RETENTION_PERIOD ||
            management < MIN_BLOCKED_BOND_MANAGEMENT_PERIOD ||
            management > MAX_BLOCKED_BOND_MANAGEMENT_PERIOD
        ) {
            revert InvalidBlockedBondRetentionPeriod();
        }
    }

    /// @notice Returns the bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond shares.
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return _bondShares[nodeOperatorId];
    }

    /// @notice Returns basis points of the bond multiplier for the given node operator.
    function getBondMultiplier(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        uint256 basisPoints = _bondMultiplierBasisPoints[nodeOperatorId];
        return basisPoints > 0 ? basisPoints : TOTAL_BASIS_POINTS;
    }

    /// @notice Sets basis points of the bond multiplier for the given node operator.
    function setBondMultiplier(
        uint256 nodeOperatorId,
        uint256 basisPoints
    ) external onlyRole(SET_BOND_MULTIPLIER_ROLE) {
        if (basisPoints > TOTAL_BASIS_POINTS) revert InvalidMultiplier();
        _bondMultiplierBasisPoints[nodeOperatorId] = basisPoints;
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
    ) public view onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
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

    /// @notice Returns the amount of ETH blocked by the given node operator.
    function getBlockedBondETH(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        if (
            _blockedBondEther[nodeOperatorId].retentionUntil >= block.timestamp
        ) {
            return _blockedBondEther[nodeOperatorId].ETHAmount;
        }
        return 0;
    }

    /// @notice Returns the required bond ETH (inc. missed and excess) for the given node operator to upload new keys.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @return required bond ETH.
    function getRequiredBondETH(
        uint256 nodeOperatorId,
        uint256 additionalKeysCount
    ) public view returns (uint256) {
        (uint256 current, uint256 required) = _bondETHSummary(nodeOperatorId);
        uint256 requiredForKeys = (getRequiredBondETHForKeys(
            additionalKeysCount
        ) * getBondMultiplier(nodeOperatorId)) / TOTAL_BASIS_POINTS;

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

    /// @notice Stake user's ETH to Lido and make deposit in stETH to the bond
    /// @return stETH shares amount
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable returns (uint256) {
        from = _validateDepositSender(from);
        return _depositETH(from, nodeOperatorId);
    }

    function _depositETH(
        address from,
        uint256 nodeOperatorId
    ) internal onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        uint256 shares = _lido().submit{ value: msg.value }(address(0));
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit ETHBondDeposited(nodeOperatorId, from, msg.value);
        return shares;
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator
    /// @return stETH shares amount
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256) {
        // todo: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        return _depositStETH(from, nodeOperatorId, stETHAmount);
    }

    /// @notice Deposit user's stETH to the bond for the given Node Operator using the proper permit for the contract
    /// @return stETH shares amount
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    function depositStETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput calldata permit
    ) external returns (uint256) {
        // todo: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        // preventing revert for already used permit
        if (_lido().allowance(from, address(this)) < permit.value) {
            // solhint-disable-next-line func-named-parameters
            _lido().permit(
                from,
                address(this),
                permit.value,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            );
        }
        return _depositStETH(from, nodeOperatorId, stETHAmount);
    }

    function _depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) internal onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        // todo: should we check that `from` is manager\reward address ???
        uint256 shares = _sharesByEth(stETHAmount);
        _lido().transferSharesFrom(from, address(this), shares);
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit StETHBondDeposited(nodeOperatorId, from, stETHAmount);
        return shares;
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator
    /// @return stETH shares amount
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) external returns (uint256) {
        // todo: can it be two functions rather than one with `from` param and condition?
        from = _validateDepositSender(from);
        return _depositWstETH(from, nodeOperatorId, wstETHAmount);
    }

    /// @notice Unwrap user's wstETH and make deposit in stETH to the bond for the given Node Operator using the proper permit for the contract
    /// @return stETH shares amount
    /// @dev if `from` is not the same as `msg.sender`, then `msg.sender` should be CSM
    function depositWstETHWithPermit(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput calldata permit
    ) external returns (uint256) {
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
        return _depositWstETH(from, nodeOperatorId, wstETHAmount);
    }

    function _depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) internal onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        // todo: should we check that `from` is manager\reward address ???
        WSTETH.transferFrom(from, address(this), wstETHAmount);
        uint256 stETHAmount = WSTETH.unwrap(wstETHAmount);
        uint256 shares = _sharesByEth(stETHAmount);
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit WstETHBondDeposited(nodeOperatorId, from, wstETHAmount);
        return shares;
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
    ) external onlyExistingNodeOperator(nodeOperatorId) {
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
        _bondShares[nodeOperatorId] -= toClaim;
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
    ) external onlyExistingNodeOperator(nodeOperatorId) {
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
        _bondShares[nodeOperatorId] -= wstETHAmount;
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
    )
        external
        onlyExistingNodeOperator(nodeOperatorId)
        returns (uint256[] memory requestIds)
    {
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
            emit ETHRewardsRequested(nodeOperatorId, rewardAddress, 0);
            return requestIds;
        }
        uint256 toClaim = ETHAmount < _ethByShares(claimableShares)
            ? _sharesByEth(ETHAmount)
            : claimableShares;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _lido().getPooledEthByShares(toClaim);
        requestIds = _withdrawalQueue().requestWithdrawals(
            amounts,
            rewardAddress
        );
        _bondShares[nodeOperatorId] -= toClaim;
        totalBondShares -= toClaim;
        emit ETHRewardsRequested(nodeOperatorId, rewardAddress, amounts[0]);
        return requestIds;
    }

    /// @notice Reports EL rewards stealing for the given node operator.
    /// @param nodeOperatorId id of the node operator to report EL rewards stealing for.
    /// @param blockNumber consensus layer block number of the proposed block with EL rewards stealing.
    /// @param amount amount of stolen EL rewards.
    function initELRewardsStealingPenalty(
        uint256 nodeOperatorId,
        uint256 blockNumber,
        uint256 amount
    )
        external
        onlyRole(EL_REWARDS_STEALING_PENALTY_INIT_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        if (amount == 0) {
            revert InvalidStolenAmount();
        }
        emit ELRewardsStealingPenaltyInitiated(
            nodeOperatorId,
            blockNumber,
            amount
        );
        _changeBlockedBondState({
            nodeOperatorId: nodeOperatorId,
            ETHAmount: _blockedBondEther[nodeOperatorId].ETHAmount + amount,
            retentionUntil: block.timestamp + blockedBondRetentionPeriod
        });
    }

    /// @notice Releases blocked bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to release blocked bond for.
    /// @param amount amount of ETH to release.
    function releaseBlockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    )
        external
        onlyRole(EL_REWARDS_STEALING_PENALTY_INIT_ROLE)
        onlyExistingNodeOperator(nodeOperatorId)
    {
        emit BlockedBondReleased(nodeOperatorId, amount);
        _reduceBlockedBondETH(nodeOperatorId, amount);
    }

    /// @notice Compensates blocked bond ETH for the given node operator.
    /// @param nodeOperatorId id of the node operator to compensate blocked bond for.
    function compensateBlockedBondETH(
        uint256 nodeOperatorId
    ) external payable onlyExistingNodeOperator(nodeOperatorId) {
        require(msg.value > 0, "value should be greater than zero");
        payable(LIDO_LOCATOR.elRewardsVault()).transfer(msg.value);
        emit BlockedBondCompensated(nodeOperatorId, msg.value);
        _reduceBlockedBondETH(nodeOperatorId, msg.value);
    }

    function _reduceBlockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    ) internal {
        uint256 blocked = getBlockedBondETH(nodeOperatorId);
        require(blocked > 0, "no blocked bond to release");
        require(
            _blockedBondEther[nodeOperatorId].ETHAmount >= amount,
            "blocked bond is less than amount to release"
        );
        _changeBlockedBondState(
            nodeOperatorId,
            _blockedBondEther[nodeOperatorId].ETHAmount - amount,
            _blockedBondEther[nodeOperatorId].retentionUntil
        );
    }

    /// @dev Should be called by the committee. Doesn't settle blocked bond if it is in the safe frame (1 day)
    /// @notice Settles blocked bond for the given node operators.
    /// @param nodeOperatorIds ids of the node operators to settle blocked bond for.
    function settleBlockedBondETH(
        uint256[] memory nodeOperatorIds
    ) external onlyRole(EL_REWARDS_STEALING_PENALTY_SETTLE_ROLE) {
        for (uint256 i; i < nodeOperatorIds.length; ++i) {
            uint256 nodeOperatorId = nodeOperatorIds[i];
            BlockedBond storage blockedBond = _blockedBondEther[nodeOperatorId];
            if (
                block.timestamp +
                    blockedBondRetentionPeriod -
                    blockedBond.retentionUntil <
                blockedBondManagementPeriod
            ) {
                // blocked bond in safe frame to manage it by committee or node operator
                continue;
            }
            uint256 uncovered;
            if (
                blockedBond.ETHAmount > 0 &&
                blockedBond.retentionUntil >= block.timestamp
            ) {
                uncovered = _penalize(nodeOperatorId, blockedBond.ETHAmount);
            }
            _changeBlockedBondState({
                nodeOperatorId: nodeOperatorId,
                ETHAmount: uncovered,
                retentionUntil: blockedBond.retentionUntil
            });
        }
    }

    function _changeBlockedBondState(
        uint256 nodeOperatorId,
        uint256 ETHAmount,
        uint256 retentionUntil
    ) internal {
        if (ETHAmount == 0) {
            delete _blockedBondEther[nodeOperatorId];
            emit BlockedBondChanged(nodeOperatorId, 0, 0);
            return;
        }
        _blockedBondEther[nodeOperatorId] = BlockedBond({
            ETHAmount: ETHAmount,
            retentionUntil: retentionUntil
        });
        emit BlockedBondChanged(nodeOperatorId, ETHAmount, retentionUntil);
    }

    /// @notice Penalize bond by burning shares of the given node operator.
    function penalize(
        uint256 nodeOperatorId,
        uint256 ETHAmount
    ) public onlyRole(INSTANT_PENALIZE_BOND_ROLE) {
        _penalize(nodeOperatorId, ETHAmount);
    }

    function _penalize(
        uint256 nodeOperatorId,
        uint256 ETHAmount
    ) internal onlyExistingNodeOperator(nodeOperatorId) returns (uint256) {
        uint256 penaltyShares = _sharesByEth(ETHAmount);
        uint256 currentShares = getBondShares(nodeOperatorId);
        uint256 sharesToBurn = penaltyShares < currentShares
            ? penaltyShares
            : currentShares;
        _lido().transferSharesFrom(
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
        _bondShares[nodeOperatorId] += distributed;
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
        required =
            ((getRequiredBondETHForKeys(
                _getNodeOperatorActiveKeys(nodeOperatorId)
            ) * getBondMultiplier(nodeOperatorId)) / TOTAL_BASIS_POINTS) +
            getBlockedBondETH(nodeOperatorId);
    }

    function _bondSharesSummary(
        uint256 nodeOperatorId
    ) internal view returns (uint256 current, uint256 required) {
        current = getBondShares(nodeOperatorId);
        required =
            ((_getRequiredBondSharesForKeys(
                _getNodeOperatorActiveKeys(nodeOperatorId)
            ) * getBondMultiplier(nodeOperatorId)) / TOTAL_BASIS_POINTS) +
            _sharesByEth(getBlockedBondETH(nodeOperatorId));
    }

    function _sharesByEth(uint256 ethAmount) internal view returns (uint256) {
        return _lido().getSharesByPooledEth(ethAmount);
    }

    function _ethByShares(uint256 shares) internal view returns (uint256) {
        return _lido().getPooledEthByShares(shares);
    }

    modifier onlyExistingNodeOperator(uint256 nodeOperatorId) {
        require(
            nodeOperatorId < CSM.getNodeOperatorsCount(),
            "node operator does not exist"
        );
        _;
    }
}
