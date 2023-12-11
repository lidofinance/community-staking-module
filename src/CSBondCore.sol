// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ILido } from "./interfaces/ILido.sol";
import { IWstETH } from "./interfaces/IWstETH.sol";
import { IWithdrawalQueue } from "./interfaces/IWithdrawalQueue.sol";

contract CSBondCoreBase {
    event BondDeposited(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event BondClaimed(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
    event BondDepositedWstETH(
        uint256 indexed nodeOperatorId,
        address from,
        uint256 amount
    );
    event BondClaimedWstETH(
        uint256 indexed nodeOperatorId,
        address to,
        uint256 amount
    );
    event BondPenalized(
        uint256 indexed nodeOperatorId,
        uint256 penaltyETH,
        uint256 coveringETH
    );
}

abstract contract CSBondCore is CSBondCoreBase {
    ILidoLocator internal immutable LIDO_LOCATOR;
    ILido internal immutable LIDO;
    IWstETH internal immutable WSTETH;

    mapping(uint256 => uint256) internal _bondShares;
    uint256 public totalBondShares;

    constructor(address lidoLocator, address wstETH) {
        require(lidoLocator != address(0), "lido locator is zero address");
        require(wstETH != address(0), "wstETH is zero address");
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        LIDO = ILido(LIDO_LOCATOR.lido());
        WSTETH = IWstETH(wstETH);
    }

    /// @notice Returns the bond shares for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond shares.
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return _bondShares[nodeOperatorId];
    }

    /// @notice Returns the bond amount in ETH (stETH) for the given node operator.
    /// @param nodeOperatorId id of the node operator to get bond for.
    /// @return bond amount.
    function getBond(uint256 nodeOperatorId) public view returns (uint256) {
        return _ethByShares(getBondShares(nodeOperatorId));
    }

    function _depositETH(
        address from,
        uint256 nodeOperatorId
    ) internal returns (uint256) {
        uint256 shares = LIDO.submit{ value: msg.value }(address(0));
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit BondDeposited(nodeOperatorId, from, msg.value);
        return shares;
    }

    function _depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 amount
    ) internal returns (uint256 shares) {
        shares = _sharesByEth(amount);
        LIDO.transferSharesFrom(from, address(this), shares);
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit BondDeposited(nodeOperatorId, from, amount);
    }

    function _depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 amount
    ) internal returns (uint256) {
        WSTETH.transferFrom(from, address(this), amount);
        uint256 stETHAmount = WSTETH.unwrap(amount);
        uint256 shares = _sharesByEth(stETHAmount);
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit BondDepositedWstETH(nodeOperatorId, from, amount);
        return shares;
    }

    /// @dev claim excess bond in ETH by requesting withdrawal from the protocol
    function _requestETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    )
        internal
        returns (
            uint256 /* requestId */,
            uint256 /* requestedETH */,
            uint256 sharesToClaim
        )
    {
        if (claimableShares == 0) {
            emit BondClaimed(nodeOperatorId, to, 0);
            return (0, 0, 0);
        }
        sharesToClaim = amountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(amountToClaim)
            : claimableShares;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _ethByShares(sharesToClaim);
        uint256[] memory requestIds = _withdrawalQueue().requestWithdrawals(
            amounts,
            to
        );
        _bondShares[nodeOperatorId] -= sharesToClaim;
        totalBondShares -= sharesToClaim;
        emit BondClaimed(nodeOperatorId, to, amounts[0]);
        return (requestIds[0], amounts[0], sharesToClaim);
    }

    function _claimStETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) internal returns (uint256 sharesToClaim, uint256 amount) {
        if (claimableShares == 0) {
            emit BondClaimed(nodeOperatorId, to, 0);
            return (0, 0);
        }
        sharesToClaim = amountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(amountToClaim)
            : claimableShares;
        LIDO.transferSharesFrom(address(this), to, sharesToClaim);
        _bondShares[nodeOperatorId] -= sharesToClaim;
        totalBondShares -= sharesToClaim;
        amount = _ethByShares(sharesToClaim);
        emit BondClaimed(nodeOperatorId, to, amount);
    }

    function _claimWstETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) internal returns (uint256 amount) {
        if (claimableShares == 0) {
            emit BondClaimedWstETH(nodeOperatorId, to, 0);
            return 0;
        }
        uint256 sharesToClaim = amountToClaim < claimableShares
            ? amountToClaim
            : claimableShares;
        amount = WSTETH.wrap(_ethByShares(sharesToClaim));
        WSTETH.transferFrom(address(this), to, amount);
        _bondShares[nodeOperatorId] -= amount;
        totalBondShares -= amount;
        emit BondClaimedWstETH(nodeOperatorId, to, amount);
    }

    function _sharesByEth(uint256 ethAmount) internal view returns (uint256) {
        return LIDO.getSharesByPooledEth(ethAmount);
    }

    function _ethByShares(uint256 shares) internal view returns (uint256) {
        return LIDO.getPooledEthByShares(shares);
    }

    function _withdrawalQueue() internal view returns (IWithdrawalQueue) {
        return IWithdrawalQueue(LIDO_LOCATOR.withdrawalQueue());
    }
}
