// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ILidoLocator } from "../interfaces/ILidoLocator.sol";
import { ILido } from "../interfaces/ILido.sol";
import { IBurner } from "../interfaces/IBurner.sol";
import { IWstETH } from "../interfaces/IWstETH.sol";
import { IWithdrawalQueue } from "../interfaces/IWithdrawalQueue.sol";
import { ICSBondCore } from "../interfaces/ICSBondCore.sol";

/// @dev Bond core mechanics abstract contract
///
/// It gives basic abilities to manage bond shares (stETH) of the Node Operator.
///
/// It contains:
///  - store bond shares (stETH)
///  - get bond shares (stETH) and bond amount
///  - deposit ETH/stETH/wstETH
///  - claim ETH/stETH/wstETH
///  - burn
///
/// Should be inherited by Module contract, or Module-related contract.
/// Internal non-view methods should be used in Module contract with additional requirements (if any).
///
/// @author vgorkavenko
abstract contract CSBondCore is ICSBondCore {
    /// @custom:storage-location erc7201:CSBondCore
    struct CSBondCoreStorage {
        mapping(uint256 nodeOperatorId => uint256 shares) bondShares;
        uint256 totalBondShares;
    }

    ILidoLocator public immutable LIDO_LOCATOR;
    ILido public immutable LIDO;
    IWithdrawalQueue public immutable WITHDRAWAL_QUEUE;
    IWstETH public immutable WSTETH;

    // keccak256(abi.encode(uint256(keccak256("CSBondCore")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CS_BOND_CORE_STORAGE_LOCATION =
        0x23f334b9eb5378c2a1573857b8f9d9ca79959360a69e73d3f16848e56ec92100;

    constructor(address lidoLocator) {
        if (lidoLocator == address(0)) {
            revert ZeroLocatorAddress();
        }
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        LIDO = ILido(LIDO_LOCATOR.lido());
        WITHDRAWAL_QUEUE = IWithdrawalQueue(LIDO_LOCATOR.withdrawalQueue());
        WSTETH = IWstETH(WITHDRAWAL_QUEUE.WSTETH());
    }

    /// @inheritdoc ICSBondCore
    function totalBondShares() public view returns (uint256) {
        return _getCSBondCoreStorage().totalBondShares;
    }

    /// @inheritdoc ICSBondCore
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        return _getCSBondCoreStorage().bondShares[nodeOperatorId];
    }

    /// @inheritdoc ICSBondCore
    function getBond(uint256 nodeOperatorId) public view returns (uint256) {
        return _ethByShares(getBondShares(nodeOperatorId));
    }

    /// @dev Stake user's ETH with Lido and stores stETH shares as Node Operator's bond shares
    function _depositETH(address from, uint256 nodeOperatorId) internal {
        if (msg.value == 0) {
            return;
        }

        uint256 shares = LIDO.submit{ value: msg.value }({
            _referral: address(0)
        });
        _increaseBond(nodeOperatorId, shares);
        emit BondDepositedETH(nodeOperatorId, from, msg.value);
    }

    /// @dev Transfer user's stETH to the contract and stores stETH shares as Node Operator's bond shares
    function _depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 shares = _sharesByEth(amount);
        LIDO.transferSharesFrom(from, address(this), shares);
        _increaseBond(nodeOperatorId, shares);
        emit BondDepositedStETH(nodeOperatorId, from, amount);
    }

    /// @dev Transfer user's wstETH to the contract, unwrap and store stETH shares as Node Operator's bond shares
    function _depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        WSTETH.transferFrom(from, address(this), amount);
        uint256 sharesBefore = LIDO.sharesOf(address(this));
        WSTETH.unwrap(amount);
        uint256 sharesAfter = LIDO.sharesOf(address(this));
        _increaseBond(nodeOperatorId, sharesAfter - sharesBefore);
        emit BondDepositedWstETH(nodeOperatorId, from, amount);
    }

    function _increaseBond(uint256 nodeOperatorId, uint256 shares) internal {
        if (shares == 0) {
            return;
        }

        CSBondCoreStorage storage $ = _getCSBondCoreStorage();
        unchecked {
            $.bondShares[nodeOperatorId] += shares;
            $.totalBondShares += shares;
        }
    }

    /// @dev Claim Node Operator's excess bond shares (stETH) in ETH by requesting withdrawal from the protocol
    ///      As a usual withdrawal request, this claim might be processed on the next stETH rebase
    function _claimUnstETH(
        uint256 nodeOperatorId,
        uint256 requestedAmountToClaim,
        address to
    ) internal returns (uint256 requestId) {
        uint256 claimableShares = _getClaimableBondShares(nodeOperatorId);
        uint256 sharesToClaim = requestedAmountToClaim <
            _ethByShares(claimableShares)
            ? _sharesByEth(requestedAmountToClaim)
            : claimableShares;
        if (sharesToClaim == 0) {
            revert NothingToClaim();
        }

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _ethByShares(sharesToClaim);

        uint256 sharesBefore = LIDO.sharesOf(address(this));
        requestId = WITHDRAWAL_QUEUE.requestWithdrawals(amounts, to)[0];
        uint256 sharesAfter = LIDO.sharesOf(address(this));

        _unsafeReduceBond(nodeOperatorId, sharesBefore - sharesAfter);
        emit BondClaimedUnstETH(nodeOperatorId, to, amounts[0], requestId);
    }

    /// @dev Claim Node Operator's excess bond shares (stETH) in stETH by transferring shares from the contract
    function _claimStETH(
        uint256 nodeOperatorId,
        uint256 requestedAmountToClaim,
        address to
    ) internal returns (uint256 sharesToClaim) {
        uint256 claimableShares = _getClaimableBondShares(nodeOperatorId);
        sharesToClaim = requestedAmountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(requestedAmountToClaim)
            : claimableShares;
        if (sharesToClaim == 0) {
            revert NothingToClaim();
        }

        _unsafeReduceBond(nodeOperatorId, sharesToClaim);

        uint256 ethAmount = LIDO.transferShares(to, sharesToClaim);
        emit BondClaimedStETH(nodeOperatorId, to, ethAmount);
    }

    /// @dev Claim Node Operator's excess bond shares (stETH) in wstETH by wrapping stETH from the contract and transferring wstETH
    function _claimWstETH(
        uint256 nodeOperatorId,
        uint256 requestedAmountToClaim,
        address to
    ) internal returns (uint256 wstETHAmount) {
        uint256 claimableShares = _getClaimableBondShares(nodeOperatorId);
        uint256 sharesToClaim = requestedAmountToClaim < claimableShares
            ? requestedAmountToClaim
            : claimableShares;
        if (sharesToClaim == 0) {
            revert NothingToClaim();
        }

        uint256 sharesBefore = LIDO.sharesOf(address(this));
        wstETHAmount = WSTETH.wrap(_ethByShares(sharesToClaim));
        uint256 sharesAfter = LIDO.sharesOf(address(this));
        _unsafeReduceBond(nodeOperatorId, sharesBefore - sharesAfter);
        WSTETH.transfer(to, wstETHAmount);
        emit BondClaimedWstETH(nodeOperatorId, to, wstETHAmount);
    }

    /// @dev Burn Node Operator's bond shares (stETH). Shares will be burned on the next stETH rebase
    /// @dev The contract that uses this implementation should be granted `Burner.REQUEST_BURN_SHARES_ROLE` and have stETH allowance for `Burner`
    /// @param amount Bond amount to burn in ETH (stETH)
    function _burn(uint256 nodeOperatorId, uint256 amount) internal {
        uint256 sharesToBurn = _sharesByEth(amount);
        uint256 burnedShares = _reduceBond(nodeOperatorId, sharesToBurn);
        // If no bond already or the amount to burn is zero
        if (burnedShares == 0) {
            return;
        }

        // TODO: Replace with `requestBurnMyShares` (https://github.com/lidofinance/core/pull/1142) in the next major release
        IBurner(LIDO_LOCATOR.burner()).requestBurnShares(
            address(this),
            burnedShares
        );
        emit BondBurned(
            nodeOperatorId,
            _ethByShares(sharesToBurn),
            _ethByShares(burnedShares)
        );
    }

    /// @dev Transfer Node Operator's bond shares (stETH) to charge recipient
    /// @param amount Bond amount to charge in ETH (stETH)
    /// @param recipient Address to send charged shares
    function _charge(
        uint256 nodeOperatorId,
        uint256 amount,
        address recipient
    ) internal {
        uint256 toChargeShares = _sharesByEth(amount);
        uint256 chargedShares = _reduceBond(nodeOperatorId, toChargeShares);
        // If no bond already or the amount to charge is zero
        if (chargedShares == 0) {
            return;
        }

        uint256 chargedEth = LIDO.transferShares(recipient, chargedShares);

        emit BondCharged(
            nodeOperatorId,
            _ethByShares(toChargeShares),
            chargedEth
        );
    }

    /// @dev Must be overridden in case of additional restrictions on a claimable bond amount
    function _getClaimableBondShares(
        uint256 nodeOperatorId
    ) internal view virtual returns (uint256) {
        return _getCSBondCoreStorage().bondShares[nodeOperatorId];
    }

    /// @dev Shortcut for Lido's getSharesByPooledEth
    function _sharesByEth(uint256 ethAmount) internal view returns (uint256) {
        if (ethAmount == 0) {
            return 0;
        }

        return LIDO.getSharesByPooledEth(ethAmount);
    }

    /// @dev Shortcut for Lido's getPooledEthByShares
    function _ethByShares(uint256 shares) internal view returns (uint256) {
        if (shares == 0) {
            return 0;
        }

        return LIDO.getPooledEthByShares(shares);
    }

    /// @dev Unsafe reduce bond shares (stETH) (possible underflow). Safety checks should be done outside
    function _unsafeReduceBond(uint256 nodeOperatorId, uint256 shares) private {
        CSBondCoreStorage storage $ = _getCSBondCoreStorage();
        $.bondShares[nodeOperatorId] -= shares;
        $.totalBondShares -= shares;
    }

    /// @dev Safe reduce bond shares (stETH). The maximum shares to reduce is the current bond shares
    function _reduceBond(
        uint256 nodeOperatorId,
        uint256 shares
    ) private returns (uint256 reducedShares) {
        uint256 currentShares = getBondShares(nodeOperatorId);
        reducedShares = shares < currentShares ? shares : currentShares;
        _unsafeReduceBond(nodeOperatorId, reducedShares);
    }

    function _getCSBondCoreStorage()
        private
        pure
        returns (CSBondCoreStorage storage $)
    {
        assembly {
            $.slot := CS_BOND_CORE_STORAGE_LOCATION
        }
    }
}
