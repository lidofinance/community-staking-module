// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import { ILidoLocator } from "../interfaces/ILidoLocator.sol";
import { IStETH } from "../interfaces/IStETH.sol";

contract CommunityStakingFeeDistributorMock {
    ILidoLocator private immutable LIDO_LOCATOR;
    address private BOND_MANAGER_ADDRESS;

    mapping(uint256 => uint256) public distributedFees;

    constructor(address _lidoLocator) {
        LIDO_LOCATOR = ILidoLocator(_lidoLocator);
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

    function setBondManager(address _bondManager) external {
        BOND_MANAGER_ADDRESS = _bondManager;
    }

    function _stETH() internal view returns (IStETH) {
        return IStETH(LIDO_LOCATOR.lido());
    }
}
