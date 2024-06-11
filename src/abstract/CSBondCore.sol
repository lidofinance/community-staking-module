// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

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
    using Arrays for uint256[];

    /// @custom:storage-location erc7201:CSAccounting.CSBondCore
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

    event BondDepositedETH(
        uint256 indexed nodeOperatorId,
        address indexed from,
        uint256 amount
    );
    event BondClaimedUnstETH(
        uint256 indexed nodeOperatorId,
        address indexed to,
        uint256 amount,
        uint256 requestId
    );
    event BondDepositedWstETH(
        uint256 indexed nodeOperatorId,
        address indexed from,
        uint256 amount
    );
    event BondClaimedWstETH(
        uint256 indexed nodeOperatorId,
        address indexed to,
        uint256 amount
    );
    event BondDepositedStETH(
        uint256 indexed nodeOperatorId,
        address indexed from,
        uint256 amount
    );
    event BondClaimedStETH(
        uint256 indexed nodeOperatorId,
        address indexed to,
        uint256 amount
    );
    event BondBurned(
        uint256 indexed nodeOperatorId,
        uint256 toBurnAmount,
        uint256 burnedAmount
    );
    event BondCharged(
        uint256 indexed nodeOperatorId,
        uint256 toChargeAmount,
        uint256 chargedAmount
    );

    error ZeroLocatorAddress();

    constructor(address lidoLocator) {
        if (lidoLocator == address(0)) {
            revert ZeroLocatorAddress();
        }
        LIDO_LOCATOR = ILidoLocator(lidoLocator);
        LIDO = ILido(LIDO_LOCATOR.lido());
        WITHDRAWAL_QUEUE = IWithdrawalQueue(LIDO_LOCATOR.withdrawalQueue());
        WSTETH = IWstETH(WITHDRAWAL_QUEUE.WSTETH());
    }

    /// @notice Get total bond shares (stETH) stored on the contract
    /// @return Total bond shares (stETH)
    function totalBondShares() public view returns (uint256) {
        CSBondCoreStorage storage $ = _getCSBondCoreStorage();
        return $.totalBondShares;
    }

    /// @notice Get bond shares (stETH) for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return Bond in stETH shares
    function getBondShares(
        uint256 nodeOperatorId
    ) public view returns (uint256) {
        CSBondCoreStorage storage $ = _getCSBondCoreStorage();
        return $.bondShares[nodeOperatorId];
    }

    /// @notice Get bond amount in ETH (stETH) for the given Node Operator
    /// @param nodeOperatorId ID of the Node Operator
    /// @return bond Bond amount in ETH (stETH)
    function getBond(
        uint256 nodeOperatorId
    ) public view returns (uint256 bond) {
        bond = _ethByShares(getBondShares(nodeOperatorId));
    }

    /// @dev Stake user's ETH with Lido and stores stETH shares as Node Operator's bond shares
    function _depositETH(address from, uint256 nodeOperatorId) internal {
        if (msg.value == 0) return;
        uint256 shares = LIDO.submit{ value: msg.value }({
            _referal: address(0)
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
        if (amount == 0) return;
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
        if (amount == 0) return;
        WSTETH.transferFrom(from, address(this), amount);
        uint256 sharesBefore = LIDO.sharesOf(address(this));
        WSTETH.unwrap(amount);
        uint256 sharesAfter = LIDO.sharesOf(address(this));
        unchecked {
            _increaseBond(nodeOperatorId, sharesAfter - sharesBefore);
        }
        emit BondDepositedWstETH(nodeOperatorId, from, amount);
    }

    function _increaseBond(uint256 nodeOperatorId, uint256 shares) internal {
        if (shares == 0) return;
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
        uint256 amountToClaim,
        address to
    ) internal {
        uint256 claimableShares = _getClaimableBondShares(nodeOperatorId);
        uint256 sharesToClaim = amountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(amountToClaim)
            : claimableShares;
        if (sharesToClaim == 0) return;
        _unsafeReduceBond(nodeOperatorId, sharesToClaim);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _ethByShares(sharesToClaim);
        uint256[] memory requestIds = WITHDRAWAL_QUEUE.requestWithdrawals(
            amounts,
            to
        );
        emit BondClaimedUnstETH(nodeOperatorId, to, amounts[0], requestIds[0]);
    }

    /// @dev Claim Node Operator's excess bond shares (stETH) in stETH by transferring shares from the contract
    function _claimStETH(
        uint256 nodeOperatorId,
        uint256 amountToClaim,
        address to
    ) internal {
        uint256 claimableShares = _getClaimableBondShares(nodeOperatorId);
        uint256 sharesToClaim = amountToClaim < _ethByShares(claimableShares)
            ? _sharesByEth(amountToClaim)
            : claimableShares;
        if (sharesToClaim == 0) return;
        _unsafeReduceBond(nodeOperatorId, sharesToClaim);

        LIDO.transferShares(to, sharesToClaim);
        emit BondClaimedStETH(nodeOperatorId, to, _ethByShares(sharesToClaim));
    }

    /// @dev Claim Node Operator's excess bond shares (stETH) in wstETH by wrapping stETH from the contract and transferring wstETH
    function _claimWstETH(
        uint256 nodeOperatorId,
        uint256 amountToClaim,
        address to
    ) internal {
        uint256 claimableShares = _getClaimableBondShares(nodeOperatorId);
        uint256 sharesToClaim = amountToClaim < claimableShares
            ? amountToClaim
            : claimableShares;
        if (sharesToClaim == 0) return;
        uint256 sharesBefore = LIDO.sharesOf(address(this));
        uint256 amount = WSTETH.wrap(_ethByShares(sharesToClaim));
        uint256 sharesAfter = LIDO.sharesOf(address(this));
        unchecked {
            _unsafeReduceBond(nodeOperatorId, sharesBefore - sharesAfter);
        }
        WSTETH.transfer(to, amount);
        emit BondClaimedWstETH(nodeOperatorId, to, amount);
    }

    /// @dev Burn Node Operator's bond shares (stETH). Shares will be burned on the next stETH rebase
    /// @dev The method sender should be granted as `Burner.REQUEST_BURN_SHARES_ROLE` and make stETH allowance for `Burner`
    /// @param amount Bond amount to burn in ETH (stETH)
    function _burn(uint256 nodeOperatorId, uint256 amount) internal {
        address burner = LIDO_LOCATOR.burner();
        // sanity check for the cases when burner address is updated
        if (LIDO.allowance(address(this), burner) < amount) {
            LIDO.approve(burner, type(uint256).max);
        }
        uint256 toBurnShares = _sharesByEth(amount);
        uint256 burnedShares = _reduceBond(nodeOperatorId, toBurnShares);
        IBurner(burner).requestBurnShares(address(this), burnedShares);
        emit BondBurned(
            nodeOperatorId,
            _ethByShares(toBurnShares),
            _ethByShares(burnedShares)
        );
    }

    /// @dev Transfer Node Operator's bond shares (stETH) to charge recipient to pay some fee
    /// @param amount Bond amount to charge in ETH (stETH)
    function _charge(
        uint256 nodeOperatorId,
        uint256 amount,
        address recipient
    ) internal {
        uint256 toChargeShares = _sharesByEth(amount);
        uint256 chargedShares = _reduceBond(nodeOperatorId, toChargeShares);
        LIDO.transferShares(recipient, chargedShares);
        emit BondCharged(
            nodeOperatorId,
            _ethByShares(toChargeShares),
            _ethByShares(chargedShares)
        );
    }

    /// @dev Must be overridden in case of additional restrictions on a claimable bond amount
    function _getClaimableBondShares(
        uint256 nodeOperatorId
    ) internal view virtual returns (uint256) {
        CSBondCoreStorage storage $ = _getCSBondCoreStorage();
        return $.bondShares[nodeOperatorId];
    }

    /// @dev Shortcut for Lido's getSharesByPooledEth
    function _sharesByEth(
        uint256 ethAmount
    ) internal view returns (uint256 shares) {
        shares = LIDO.getSharesByPooledEth(ethAmount);
    }

    /// @dev Shortcut for Lido's getPooledEthByShares
    function _ethByShares(
        uint256 shares
    ) internal view returns (uint256 amount) {
        amount = LIDO.getPooledEthByShares(shares);
    }

    /// @dev Unsafe reduce bond shares (stETH) (possible underflow). Safety checks should be done outside
    function _unsafeReduceBond(uint256 nodeOperatorId, uint256 shares) private {
        CSBondCoreStorage storage $ = _getCSBondCoreStorage();
        unchecked {
            $.bondShares[nodeOperatorId] -= shares;
            $.totalBondShares -= shares;
        }
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
