// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Script.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { CommunityStakingModule } from "../src/CommunityStakingModule.sol";
import { CommunityStakingBondManager, IWstETH } from "../src/CommunityStakingBondManager.sol";
import { FeeDistributor } from "../src/FeeDistributor.sol";
import { FeeOracle } from "../src/FeeOracle.sol";

contract Deploy is Script {
    ILidoLocator public locator;
    IWstETH public wstETH;

    address LIDO_LOCATOR_ADDRESS;
    address WSTETH_ADDRESS;

    function run() external {
        // TODO: proxy ???
        LIDO_LOCATOR_ADDRESS = vm.envAddress("LIDO_LOCATOR_ADDRESS");
        WSTETH_ADDRESS = vm.envAddress("WSTETH_ADDRESS");

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address[] memory penalizers = new address[](1);
        penalizers[0] = deployerAddress; // TODO: temporary

        vm.startBroadcast(deployerPrivateKey);
        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);
        wstETH = IWstETH(WSTETH_ADDRESS);
        CommunityStakingModule csm = new CommunityStakingModule(
            "community-staking-module"
        );
        CommunityStakingBondManager bondManager = new CommunityStakingBondManager({
                _commonBondSize: 2 ether,
                _admin: deployerAddress,
                _lidoLocator: address(locator),
                _communityStakingModule: address(csm),
                _wstETH: address(wstETH),
                _penalizeRoleMembers: penalizers
            });
        FeeOracle feeOracle = new FeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: 0 // TODO get from CL by script ?
        });
        FeeDistributor feeDistributor = new FeeDistributor({
            _stETH: locator.lido(),
            _oracle: address(feeOracle),
            _bondManager: address(bondManager)
        });
        bondManager.setFeeDistributor(address(feeDistributor));
        // TODO: csm.setBondManager(address(bondManager));

        vm.stopBroadcast();
    }
}
