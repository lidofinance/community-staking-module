// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { ICSAccounting } from "../interfaces/ICSAccounting.sol";
import { ILido } from "../interfaces/ILido.sol";
import { ICSFeeDistributor } from "../interfaces/ICSFeeDistributor.sol";

/// Library for managing FeeSplits
/// @dev the only use of this to be a library is to save CSAccounting contract size via delegatecalls
interface IFeeSplits {
    event FeeSplitsSet(
        uint256 indexed nodeOperatorId,
        ICSAccounting.FeeSplit[] feeSplits
    );

    error PendingOrUndistributedSharesExist();
    error TooManySplits();
    error TooManySplitShares();
    error ZeroSplitRecipient();
    error ZeroSplitShare();
}

library FeeSplits {
    uint256 internal constant MAX_BP = 10_000;
    uint256 public constant MAX_FEE_SPLITS = 5;

    function setFeeSplits(
        mapping(uint256 => ICSAccounting.FeeSplit[]) storage feeSplitsStorage,
        mapping(uint256 => uint256) storage pendingSharesToSplitStorage,
        ICSFeeDistributor feeDistributor,
        uint256 nodeOperatorId,
        uint256 cumulativeFeeShares,
        bytes32[] calldata rewardsProof,
        ICSAccounting.FeeSplit[] calldata feeSplits
    ) external {
        if (feeSplits.length > MAX_FEE_SPLITS) {
            revert IFeeSplits.TooManySplits();
        }
        uint256 feesToDistribute = feeDistributor.getFeesToDistribute(
            nodeOperatorId,
            cumulativeFeeShares,
            rewardsProof
        );
        if (
            pendingSharesToSplitStorage[nodeOperatorId] > 0 ||
            feesToDistribute > 0
        ) {
            revert IFeeSplits.PendingOrUndistributedSharesExist();
        }

        uint256 totalShare = 0;
        for (uint256 i = 0; i < feeSplits.length; i++) {
            totalShare += feeSplits[i].share;
        }
        // totalShare might be lower than MAX_BP. The remainder goes to the Node Operator's bond
        if (totalShare > MAX_BP) {
            revert IFeeSplits.TooManySplitShares();
        }

        delete feeSplitsStorage[nodeOperatorId];
        for (uint256 i = 0; i < feeSplits.length; i++) {
            if (feeSplits[i].recipient == address(0)) {
                revert IFeeSplits.ZeroSplitRecipient();
            }
            if (feeSplits[i].share == 0) {
                revert IFeeSplits.ZeroSplitShare();
            }

            feeSplitsStorage[nodeOperatorId].push(feeSplits[i]);
        }

        emit IFeeSplits.FeeSplitsSet(nodeOperatorId, feeSplits);
    }

    function splitAndTransferFees(
        mapping(uint256 => ICSAccounting.FeeSplit[]) storage feeSplitsStorage,
        mapping(uint256 => uint256) storage pendingSharesToSplitStorage,
        ILido lido,
        uint256 nodeOperatorId,
        uint256 distributed,
        function(uint256)
            external
            view
            returns (uint256, uint256) getBondSummaryShares
    ) external returns (uint256 remainder) {
        ICSAccounting.FeeSplit[] storage splits = feeSplitsStorage[
            nodeOperatorId
        ];
        uint256 len = splits.length;
        if (len == 0) {
            return distributed;
        }

        (uint256 currentBond, uint256 requiredBond) = getBondSummaryShares(
            nodeOperatorId
        );

        uint256 prevPending = pendingSharesToSplitStorage[nodeOperatorId];
        uint256 pendingWithNew = prevPending + distributed;

        currentBond += pendingWithNew;

        uint256 claimableShares;
        if (currentBond > requiredBond) {
            unchecked {
                claimableShares = currentBond - requiredBond;
            }
        }

        if (claimableShares == 0) {
            if (distributed != 0) {
                pendingSharesToSplitStorage[nodeOperatorId] = pendingWithNew;
            }
            return 0;
        }

        if (claimableShares > pendingWithNew) {
            claimableShares = pendingWithNew;
        }

        remainder = pendingWithNew;

        for (uint256 i; i < len; ++i) {
            ICSAccounting.FeeSplit storage feeSplit = splits[i];
            uint256 amount = (claimableShares * feeSplit.share) / MAX_BP;
            if (amount != 0) {
                lido.transferShares(feeSplit.recipient, amount);
                unchecked {
                    remainder -= amount;
                }
            }
        }

        uint256 newPending = pendingWithNew - claimableShares;
        if (newPending != prevPending) {
            pendingSharesToSplitStorage[nodeOperatorId] = newPending;
        }
    }
}
