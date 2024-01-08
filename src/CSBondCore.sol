// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { ILidoLocator } from "./interfaces/ILidoLocator.sol";
import { ILido } from "./interfaces/ILido.sol";
import { IBurner } from "./interfaces/IBurner.sol";
import { IWstETH } from "./interfaces/IWstETH.sol";
import { IWithdrawalQueue } from "./interfaces/IWithdrawalQueue.sol";

abstract contract CSBondCoreBase {
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
    event BondBurned(
        uint256 indexed nodeOperatorId,
        uint256 toBurnAmount,
        uint256 burnedAmount
    );

    error InvalidClaimableShares();
}

/// @dev Bond core mechanics abstract contract
///
/// It gives basic abilities to manage bond shares of the node operator.
///
/// It contains:
///  - store bond shares
///  - get bond shares and bond amount
///  - deposit ETH/stETH/wstETH
///  - claim ETH/stETH/wstETH
///  - burn
///
/// Should be inherited by Module contract, or Module-related contract.
/// Internal non-view methods should be used in Module contract with additional requirements (if required).
///
/// @author vgorkavenko
abstract contract CSBondCore is CSBondCoreBase {
    ILidoLocator internal immutable LIDO_LOCATOR;
    ILido internal immutable LIDO;
    IBurner internal immutable BURNER;
    IWithdrawalQueue internal immutable WITHDRAWAL_QUEUE;
    IWstETH internal immutable WSTETH;

    mapping(uint256 => uint256) internal _bondShares;
    uint256 public totalBondShares;

    constructor(address lidoLocator, address wstETH) {
        require(lidoLocator != address(0), "lido locator is zero address");
        require(wstETH != address(0), "wstETH is zero address");
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        LIDO = ILido(LIDO_LOCATOR.lido());
        WSTETH = IWstETH(wstETH);
        BURNER = IBurner(LIDO_LOCATOR.burner());
        WITHDRAWAL_QUEUE = IWithdrawalQueue(LIDO_LOCATOR.withdrawalQueue());
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

    /// @dev Stakes user's ETH to the protocol and stores stETH shares as Node Operator's bond shares.
    function _depositETH(
        address from,
        uint256 nodeOperatorId
    ) internal returns (uint256) {
        uint256 shares = LIDO.submit{ value: msg.value }({
            _referal: address(0)
        });
        _bondShares[nodeOperatorId] += shares;
        totalBondShares += shares;
        emit BondDeposited(nodeOperatorId, from, msg.value);
        return shares;
    }

    /// @dev Transfers user's stETH to the contract and stores stETH shares as Node Operator's bond shares.
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

    /// @dev Transfers user's wstETH to the contract, unwrap and stores stETH shares as Node Operator's bond shares.
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

    /// @dev Claims Node Operator's excess bond shares in ETH by requesting withdrawal from the protocol
    ///      As usual request to withdrawal, this claim might be processed on the next stETH rebase
    function _requestETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) internal {
        if (claimableShares > _bondShares[nodeOperatorId]) {
            revert InvalidClaimableShares();
        }
        uint256 sharesToClaim = amountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(amountToClaim)
            : claimableShares;
        if (sharesToClaim < WITHDRAWAL_QUEUE.MIN_STETH_WITHDRAWAL_AMOUNT())
            return;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _ethByShares(sharesToClaim);
        // Reverts if `sharesToClaim` is greater than `MIN_STETH_WITHDRAWAL_AMOUNT`
        WITHDRAWAL_QUEUE.requestWithdrawals(amounts, to);
        _bondShares[nodeOperatorId] -= sharesToClaim;
        totalBondShares -= sharesToClaim;
        emit BondClaimed(nodeOperatorId, to, amounts[0]);
    }

    /// @dev Claims Node Operator's excess bond shares in stETH by transferring shares from the contract
    function _claimStETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) internal {
        if (claimableShares > _bondShares[nodeOperatorId]) {
            revert InvalidClaimableShares();
        }
        uint256 sharesToClaim = amountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(amountToClaim)
            : claimableShares;
        if (sharesToClaim == 0) return;
        LIDO.transferSharesFrom(address(this), to, sharesToClaim);
        _bondShares[nodeOperatorId] -= sharesToClaim;
        totalBondShares -= sharesToClaim;
        emit BondClaimed(nodeOperatorId, to, _ethByShares(sharesToClaim));
    }

    /// @dev Claims Node Operator's excess bond shares in wstETH by wrapping stETH from the contract and transferring wstETH
    function _claimWstETH(
        uint256 nodeOperatorId,
        uint256 claimableShares,
        uint256 amountToClaim,
        address to
    ) internal {
        if (claimableShares > _bondShares[nodeOperatorId]) {
            revert InvalidClaimableShares();
        }
        uint256 sharesToClaim = amountToClaim < claimableShares
            ? amountToClaim
            : claimableShares;
        if (sharesToClaim == 0) return;
        uint256 amount = WSTETH.wrap(_ethByShares(sharesToClaim));
        WSTETH.transferFrom(address(this), to, amount);
        _bondShares[nodeOperatorId] -= amount;
        totalBondShares -= amount;
        emit BondClaimedWstETH(nodeOperatorId, to, amount);
    }

    /// @dev Burn Node Operator's bond shares. Shares will be burned on the next stETH rebase.
    /// @dev The method sender should be granted as `Burner.REQUEST_BURN_SHARES_ROLE` and makes stETH allowance for `Burner`
    /// @param amount amount to burn in ETH.
    function _burn(uint256 nodeOperatorId, uint256 amount) internal {
        uint256 toBurnShares = _sharesByEth(amount);
        uint256 currentShares = getBondShares(nodeOperatorId);
        uint256 burnedShares = toBurnShares < currentShares
            ? toBurnShares
            : currentShares;
        BURNER.requestBurnShares(address(this), burnedShares);
        _bondShares[nodeOperatorId] -= burnedShares;
        totalBondShares -= burnedShares;
        emit BondBurned(
            nodeOperatorId,
            _ethByShares(toBurnShares),
            _ethByShares(burnedShares)
        );
    }

    /// @dev Transfer Node Operator's bond shares to Lido treasury to pay some fee.
    function _chargeFee(uint256 nodeOperatorId, uint256 amount) internal {
        // TODO: implement me
    }

    /// @dev Shortcut for Lido's getSharesByPooledEth
    // TODO: should be removed because of the contract size limit ?
    function _sharesByEth(uint256 ethAmount) internal view returns (uint256) {
        return LIDO.getSharesByPooledEth(ethAmount);
    }

    /// @dev Shortcut for Lido's getPooledEthByShares
    function _ethByShares(uint256 shares) internal view returns (uint256) {
        return LIDO.getPooledEthByShares(shares);
    }
}
