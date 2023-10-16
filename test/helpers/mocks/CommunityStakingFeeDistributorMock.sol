// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { ILidoLocator } from "../../../src/interfaces/ILidoLocator.sol";
import { IStETH } from "../../../src/interfaces/IStETH.sol";

contract CommunityStakingFeeDistributorMock {
    ILidoLocator private immutable LIDO_LOCATOR;
    address private BOND_MANAGER_ADDRESS;

    mapping(uint256 => uint256) public distributedFees;

    constructor(address _lidoLocator, address _bondManager) {
        LIDO_LOCATOR = ILidoLocator(_lidoLocator);
        BOND_MANAGER_ADDRESS = _bondManager;
    }

    function getFeesToDistribute(
        bytes32[] calldata /*rewardProof*/,
        uint256 /*noIndex*/,
        uint256 shares
    ) external returns (uint256) {
        return shares;
    }

    function distributeFees(
        bytes32[] calldata /*rewardProof*/,
        uint256 noIndex,
        uint256 shares
    ) external returns (uint256) {
        _stETH().transferSharesFrom(
            address(this),
            BOND_MANAGER_ADDRESS,
            shares
        );
        distributedFees[noIndex] += shares;
        return shares;
    }

    function _stETH() internal view returns (IStETH) {
        return IStETH(LIDO_LOCATOR.lido());
    }
}
