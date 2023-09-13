// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ICommunityStakingModule } from "./interfaces/ICommunityStakingModule.sol";
import { ILido } from "./interfaces/ILido.sol";
import { ICommunityStakingFeeDistributor } from "./interfaces/ICommunityStakingFeeDistributor.sol";

interface IWstETH {
    function balanceOf(address account) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);
}

contract CommunityStakingBondManager is AccessControlEnumerable {
    event BondDeposited(
        uint256 nodeOperatorId,
        address indexed from,
        uint256 shares
    );
    event BondPenalized(
        uint256 nodeOperatorId,
        uint256 penaltyShares,
        uint256 burnedShares
    );
    event StETHRewardsClaimed(
        uint256 nodeOperatorId,
        address indexed to,
        uint256 shares
    );
    event WstETHRewardsClaimed(
        uint256 nodeOperatorId,
        address indexed to,
        uint256 wstETHAmount
    );

    error NotOwnerToClaim(address msgSender, address owner);

    bytes32 public constant PENALIZE_BOND_ROLE =
        keccak256("PENALIZE_BOND_ROLE");
    address public FEE_DISTRIBUTOR;

    mapping(uint256 => uint256) private bondShares;

    ILidoLocator private immutable LIDO_LOCATOR;
    ICommunityStakingModule private immutable CSM;
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
        CSM = ICommunityStakingModule(_communityStakingModule);
        WSTETH = IWstETH(_wstETH);

        COMMON_BOND_SIZE = _commonBondSize;
    }

    function setFeeDistributor(
        address _fdAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FEE_DISTRIBUTOR = _fdAddress;
    }

    /// @notice Returns the total bond shares.
    /// @return total bond shares.
    function totalBondShares() public view returns (uint256) {
        return _lido().sharesOf(address(this));
    }

    /// @notice Returns the bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond shares.
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return bondShares[nodeOperatorId];
    }

    /// @notice Returns excess bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond rewards for.
    /// @return excess bond in shares.
    function getExcessBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        uint256 activeKeys = _getNodeOperatorActiveKeys(nodeOperatorId);
        uint256 currentBondShares = getBondShares(nodeOperatorId);
        uint256 requiredBondShares = _lido().getSharesByPooledEth(
            activeKeys * COMMON_BOND_SIZE
        );
        return
            currentBondShares > requiredBondShares
                ? currentBondShares - requiredBondShares
                : 0;
    }

    /// @notice Returns the required bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @return required bond shares.
    function getRequiredBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return _getRequiredBondShares(nodeOperatorId, 0);
    }

    /// @notice Returns the required bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @param newKeysCount number of new keys to add.
    /// @return required bond shares.
    function getRequiredBondShares(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) public view returns (uint256) {
        return _getRequiredBondShares(nodeOperatorId, newKeysCount);
    }

    function _getRequiredBondShares(
        uint256 nodeOperatorId,
        uint256 newKeysCount
    ) internal view returns (uint256) {
        uint256 currentBondShares = getBondShares(nodeOperatorId);
        uint256 requiredBondShares = _lido().getSharesByPooledEth(
            (_getNodeOperatorActiveKeys(nodeOperatorId)) * COMMON_BOND_SIZE
        ) + getRequiredBondSharesForKeys(newKeysCount);
        return
            requiredBondShares > currentBondShares
                ? requiredBondShares - currentBondShares
                : 0;
    }

    /// @notice Returns the required bond shares for the given number of keys.
    /// @param keysCount number of keys to get required bond for.
    /// @return required bond shares.
    function getRequiredBondSharesForKeys(
        uint256 keysCount
    ) public view returns (uint256) {
        return _lido().getSharesByPooledEth(keysCount * COMMON_BOND_SIZE);
    }

    function depositETH(
        uint256 nodeOperatorId
    ) external payable returns (uint256) {
        return _depositETH(msg.sender, nodeOperatorId);
    }

    /// @notice Deposits ETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable returns (uint256) {
        return _depositETH(from, nodeOperatorId);
    }

    function _depositETH(
        address from,
        uint256 nodeOperatorId
    ) internal returns (uint256) {
        // TODO: should be modifier. condition might be changed as well
        require(
            nodeOperatorId < CSM.getNodeOperatorsCount(),
            "node operator does not exist"
        );
        uint256 shares = _lido().submit{ value: msg.value }(address(0));
        bondShares[nodeOperatorId] += shares;
        emit BondDeposited(nodeOperatorId, from, shares);
        return shares;
    }

    function depositStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256) {
        return _depositStETH(msg.sender, nodeOperatorId, stETHAmount);
    }

    /// @notice Deposits stETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param stETHAmount amount of stETH to deposit.
    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount
    ) external returns (uint256) {
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
        uint256 shares = _lido().getSharesByPooledEth(stETHAmount);
        _lido().transferSharesFrom(from, address(this), shares);
        bondShares[nodeOperatorId] += shares;
        emit BondDeposited(nodeOperatorId, from, shares);
        return shares;
    }

    /// @notice Deposits wstETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param wstETHAmount amount of wstETH to deposit.
    function depositWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount
    ) external returns (uint256) {
        return _depositWstETH(msg.sender, nodeOperatorId, wstETHAmount);
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
        uint256 shares = _lido().getSharesByPooledEth(stETHAmount);
        bondShares[nodeOperatorId] += shares;
        emit BondDeposited(nodeOperatorId, msg.sender, shares);
        return shares;
    }

    /// @notice Claims full reward (fee + bond) for the given node operator available for this moment
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    function claimRewardsStETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) external {
        (
            address rewardAddress,
            uint256 rewardShares
        ) = _calculateFinalRewardShares(
                rewardsProof,
                nodeOperatorId,
                cumulativeFeeShares
            );
        _lido().transferSharesFrom(address(this), rewardAddress, rewardShares);
        bondShares[nodeOperatorId] -= rewardShares;
        emit StETHRewardsClaimed(
            nodeOperatorId,
            rewardAddress,
            _lido().getPooledEthByShares(rewardShares)
        );
    }

    /// @notice Claims full reward (fee + bond) for the given node operator with desirable value
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    /// @param stETHAmount amount of stETH to claim.
    function claimRewardsStETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 stETHAmount
    ) external {
        (
            address rewardAddress,
            uint256 rewardShares
        ) = _calculateFinalRewardShares(
                rewardsProof,
                nodeOperatorId,
                cumulativeFeeShares
            );
        uint256 shares = _lido().getSharesByPooledEth(stETHAmount);
        rewardShares = shares < rewardShares ? shares : rewardShares;
        _lido().transferSharesFrom(address(this), rewardAddress, rewardShares);
        bondShares[nodeOperatorId] -= rewardShares;
        emit StETHRewardsClaimed(
            nodeOperatorId,
            rewardAddress,
            _lido().getPooledEthByShares(rewardShares)
        );
    }

    /// @notice Claims full reward (fee + bond) for the given node operator available for this moment
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    function claimRewardsWstETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) external returns (uint256) {
        (
            address rewardAddress,
            uint256 rewardShares
        ) = _calculateFinalRewardShares(
                rewardsProof,
                nodeOperatorId,
                cumulativeFeeShares
            );
        uint256 wstETHAmount = WSTETH.wrap(
            _lido().getPooledEthByShares(rewardShares)
        );
        WSTETH.transferFrom(address(this), rewardAddress, wstETHAmount);
        bondShares[nodeOperatorId] -= rewardShares;
        emit WstETHRewardsClaimed(nodeOperatorId, rewardAddress, wstETHAmount);
        return wstETHAmount;
    }

    /// @notice Claims full reward (fee + bond) for the given node operator available for this moment
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cumulativeFeeShares cummulative fee shares for the node operator.
    /// @param wstETHAmount amount of wstETH to claim.
    function claimRewardsWstETH(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        uint256 wstETHAmount
    ) external returns (uint256) {
        (
            address rewardAddress,
            uint256 rewardShares
        ) = _calculateFinalRewardShares(
                rewardsProof,
                nodeOperatorId,
                cumulativeFeeShares
            );
        rewardShares = wstETHAmount < rewardShares
            ? wstETHAmount
            : rewardShares;
        wstETHAmount = WSTETH.wrap(_lido().getPooledEthByShares(rewardShares));
        WSTETH.transferFrom(address(this), rewardAddress, wstETHAmount);
        bondShares[nodeOperatorId] -= rewardShares;
        emit WstETHRewardsClaimed(nodeOperatorId, rewardAddress, wstETHAmount);
        return wstETHAmount;
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
        emit BondPenalized(nodeOperatorId, shares, coveringShares);
    }

    function _lido() internal view returns (ILido) {
        return ILido(LIDO_LOCATOR.lido());
    }

    function _feeDistributor()
        internal
        view
        returns (ICommunityStakingFeeDistributor)
    {
        return ICommunityStakingFeeDistributor(FEE_DISTRIBUTOR);
    }

    function _getNodeOperatorActiveKeys(
        uint256 nodeOperatorId
    ) internal view returns (uint256) {
        (
            ,
            ,
            ,
            ,
            ,
            uint256 totalWithdrawnValidators,
            uint256 totalAddedValidators,

        ) = CSM.getNodeOperator({
                _nodeOperatorId: nodeOperatorId,
                _fullInfo: false
            });
        return totalAddedValidators - totalWithdrawnValidators;
    }

    function _getNodeOperatorRewardAddress(
        uint256 nodeOperatorId
    ) internal view returns (address) {
        (, , address rewardAddress, , , , , ) = CSM.getNodeOperator({
            _nodeOperatorId: nodeOperatorId,
            _fullInfo: false
        });
        return rewardAddress;
    }

    function _calculateFinalRewardShares(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares
    ) internal returns (address rewardAddress, uint256 rewardShares) {
        rewardAddress = _getNodeOperatorRewardAddress(nodeOperatorId);
        if (msg.sender != rewardAddress) {
            revert NotOwnerToClaim(msg.sender, rewardAddress);
        }
        bondShares[nodeOperatorId] += _feeDistributor().distributeFees(
            rewardsProof,
            nodeOperatorId,
            cumulativeFeeShares
        );
        rewardShares = getExcessBondShares(nodeOperatorId);
    }
}
