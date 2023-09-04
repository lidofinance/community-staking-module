// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ICommunityStakingModule } from "./interfaces/ICommunityStakingModule.sol";
import { IStETH } from "./interfaces/IStETH.sol";
import { ICommunityStakingFeeDistributor } from "./interfaces/ICommunityStakingFeeDistributor.sol";

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
    event RewardsClaimed(
        uint256 nodeOperatorId,
        address indexed to,
        uint256 shares
    );

    error NotOwnerToClaim(address msgSender, address owner);
    error NothingToClaim();

    bytes32 public constant PENALIZE_BOND_ROLE =
        keccak256("PENALIZE_BOND_ROLE");

    mapping(uint256 => uint256) private bondShares;

    ILidoLocator private immutable LIDO_LOCATOR;
    ICommunityStakingModule private immutable CSM;
    ICommunityStakingFeeDistributor private immutable FEE_DISTRIBUTOR;
    uint256 private immutable COMMON_BOND_SIZE;

    /// @param _commonBondSize common bond size in ETH for all node operators.
    /// @param _admin admin role member address
    /// @param _lidoLocator lido locator contract address
    /// @param _communityStakingModule community staking module contract address
    /// @param _communityStakingFeeDistributor community staking fee distributor contract address
    /// @param _penalizeRoleMembers list of addresses with PENALIZE_BOND_ROLE
    constructor(
        uint256 _commonBondSize,
        address _admin,
        address _lidoLocator,
        address _communityStakingModule,
        address _communityStakingFeeDistributor,
        address[] memory _penalizeRoleMembers
    ) {
        // check zero addresses
        require(_admin != address(0), "admin is zero address");
        require(_lidoLocator != address(0), "lido locator is zero address");
        require(
            _communityStakingModule != address(0),
            "community staking module is zero address"
        );
        require(
            _communityStakingFeeDistributor != address(0),
            "community staking fee distributor is zero address"
        );
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
        FEE_DISTRIBUTOR = ICommunityStakingFeeDistributor(
            _communityStakingFeeDistributor
        );

        COMMON_BOND_SIZE = _commonBondSize;
    }

    /// @notice Returns the total bond shares.
    /// @return total bond shares.
    function totalBondShares() public view returns (uint256) {
        return _stETH().sharesOf(address(this));
    }

    /// @notice Returns the total bond size in ETH.
    /// @return total bond size in ETH.
    function totalBondEth() public view returns (uint256) {
        return _stETH().getPooledEthByShares(totalBondShares());
    }

    /// @notice Returns the bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond shares.
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return bondShares[nodeOperatorId];
    }

    /// @notice Returns the bond size for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond size in ETH.
    function getBondEth(uint256 nodeOperatorId) public view returns (uint256) {
        return _stETH().getPooledEthByShares(getBondShares(nodeOperatorId));
    }

    /// @notice Returns the required bond size for the given node operator.
    /// @param nodeOperatorId id of the node operator to get required bond for.
    /// @return required bond size in ETH.
    function getRequiredBondEth(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        (
            ,
            ,
            ,
            ,
            ,
            uint64 totalWithdrawnValidators,
            uint64 totalAddedValidators,

        ) = CSM.getNodeOperator({
                _nodeOperatorId: nodeOperatorId,
                _fullInfo: false
            });
        return
            (totalAddedValidators - totalWithdrawnValidators) *
            COMMON_BOND_SIZE;
    }

    function getRequiredBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return
            _stETH().getSharesByPooledEth(getRequiredBondEth(nodeOperatorId));
    }

    /// @notice Deposits stETH to the bond for the given node operator.
    /// @param nodeOperatorId id of the node operator to deposit bond for.
    /// @param shares amount of shares to deposit.
    function deposit(uint256 nodeOperatorId, uint256 shares) external {
        _stETH().transferSharesFrom(msg.sender, address(this), shares);
        bondShares[nodeOperatorId] += shares;
        emit BondDeposited(nodeOperatorId, msg.sender, shares);
    }

    /// @notice Claims full reward (fee + bond) for the given node operator with desirable value
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cummulativeFeeShares cummulative fee shares for the node operator.
    /// @param sharesToClaim amount of shares to claim.
    function claimRewards(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cummulativeFeeShares,
        uint256 sharesToClaim
    ) external {
        _claimRewards(
            rewardsProof,
            nodeOperatorId,
            cummulativeFeeShares,
            sharesToClaim
        );
    }

    /// @notice Claims full reward (fee + bond) for the given node operator available for this moment
    /// @param rewardsProof merkle proof of the rewards.
    /// @param nodeOperatorId id of the node operator to claim rewards for.
    /// @param cummulativeFeeShares cummulative fee shares for the node operator.
    function claimRewards(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cummulativeFeeShares
    ) external {
        _claimRewards(
            rewardsProof,
            nodeOperatorId,
            cummulativeFeeShares,
            type(uint256).max
        );
    }

    function _claimRewards(
        bytes32[] memory rewardsProof,
        uint256 nodeOperatorId,
        uint256 cummulativeFeeShares,
        uint256 sharesToClaim
    ) internal {
        (, , address rewardAddress, , , , , ) = CSM.getNodeOperator({
            _nodeOperatorId: nodeOperatorId,
            _fullInfo: false
        });
        if (msg.sender != rewardAddress) {
            revert NotOwnerToClaim(msg.sender, rewardAddress);
        }
        uint256 feeRewards = FEE_DISTRIBUTOR.distributeFees(
            rewardsProof,
            nodeOperatorId,
            cummulativeFeeShares
        );
        bondShares[nodeOperatorId] += feeRewards;
        uint256 claimed = _claimBondRewards(
            nodeOperatorId,
            rewardAddress,
            sharesToClaim
        );
        emit RewardsClaimed(nodeOperatorId, rewardAddress, claimed);
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
        _stETH().transferSharesFrom(
            address(this),
            LIDO_LOCATOR.burner(),
            coveringShares
        );
        bondShares[nodeOperatorId] -= coveringShares;
        emit BondPenalized(nodeOperatorId, shares, coveringShares);
    }

    function _stETH() internal view returns (IStETH) {
        return IStETH(LIDO_LOCATOR.lido());
    }

    function _claimBondRewards(
        uint256 nodeOperatorId,
        address rewardAddress,
        uint256 shares
    ) private returns (uint256) {
        uint256 actualBondShares = getBondShares(nodeOperatorId);
        uint256 requiredBondShares = getRequiredBondShares(nodeOperatorId);
        if (requiredBondShares >= actualBondShares) {
            revert NothingToClaim();
        }
        uint256 claimableShares = actualBondShares - requiredBondShares;
        uint256 sharesToTransfer = shares < claimableShares
            ? shares
            : claimableShares;
        _stETH().transferSharesFrom(
            address(this),
            rewardAddress,
            sharesToTransfer
        );
        bondShares[nodeOperatorId] -= sharesToTransfer;
        return sharesToTransfer;
    }
}
