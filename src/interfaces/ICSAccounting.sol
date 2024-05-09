// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSBondCore } from "./ICSBondCore.sol";
import { ICSBondCurve } from "./ICSBondCurve.sol";
import { ICSBondLock } from "./ICSBondLock.sol";

interface ICSAccounting is ICSBondCore, ICSBondCurve, ICSBondLock {
    struct PermitInput {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function feeDistributor() external view returns (address);

    function getRequiredBondForNextKeys(
        uint256 nodeOperatorId,
        uint256 additionalKeys
    ) external view returns (uint256);

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount
    ) external view returns (uint256);

    function getBondAmountByKeysCountWstETH(
        uint256 keysCount,
        BondCurve memory curve
    ) external view returns (uint256);

    function getRequiredBondForNextKeysWstETH(
        uint256 nodeOperatorId,
        uint256 additionalKeys
    ) external view returns (uint256);

    function getUnbondedKeysCount(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function getUnbondedKeysCountToEject(
        uint256 nodeOperatorId
    ) external view returns (uint256);

    function depositWstETH(
        address from,
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        PermitInput calldata permit
    ) external returns (uint256);

    function depositStETH(
        address from,
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        PermitInput calldata permit
    ) external returns (uint256);

    function depositETH(
        address from,
        uint256 nodeOperatorId
    ) external payable returns (uint256);

    function claimRewardsStETH(
        uint256 nodeOperatorId,
        uint256 stETHAmount,
        address rewardAddress,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function claimRewardsWstETH(
        uint256 nodeOperatorId,
        uint256 wstETHAmount,
        address rewardAddress,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function requestRewardsETH(
        uint256 nodeOperatorId,
        uint256 ethAmount,
        address rewardAddress,
        uint256 cumulativeFeeShares,
        bytes32[] memory rewardsProof
    ) external;

    function lockBondETH(uint256 nodeOperatorId, uint256 amount) external;

    function releaseLockedBondETH(
        uint256 nodeOperatorId,
        uint256 amount
    ) external;

    function settleLockedBondETH(
        uint256 nodeOperatorId
    ) external returns (uint256);

    function compensateLockedBondETH(uint256 nodeOperatorId) external payable;

    function setBondCurve(uint256 nodeOperatorId, uint256 curveId) external;

    function resetBondCurve(uint256 nodeOperatorId) external;

    function penalize(uint256 nodeOperatorId, uint256 amount) external;

    function chargeFee(uint256 nodeOperatorId, uint256 amount) external;
}
