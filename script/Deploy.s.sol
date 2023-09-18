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
    uint256 CL_GENESIS_TIME;
    uint256 INITIALIZATION_EPOCH;

    function run() external {
        // TODO: proxy ???
        LIDO_LOCATOR_ADDRESS = vm.envAddress("LIDO_LOCATOR_ADDRESS");
        WSTETH_ADDRESS = vm.envAddress("WSTETH_ADDRESS");
        CL_GENESIS_TIME = vm.envUint("CL_GENESIS_TIME");
        INITIALIZATION_EPOCH = vm.envUint("INITIALIZATION_EPOCH");

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address[] memory penalizers = new address[](1);
        penalizers[0] = deployerAddress; // TODO: temporary

        vm.startBroadcast(deployerPrivateKey);
        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);
        wstETH = IWstETH(WSTETH_ADDRESS);
        CommunityStakingModule csm = new CommunityStakingModule(
            "community-staking-module",
            address(locator),
            address(90210) // FIXME
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
            genesisTime: uint64(CL_GENESIS_TIME)
        });
        FeeDistributor feeDistributor = new FeeDistributor({
            _CSM: address(csm),
            _stETH: locator.lido(),
            _oracle: address(feeOracle),
            _bondManager: address(bondManager)
        });
        feeOracle.initialize({
            _initializationEpoch: uint64(INITIALIZATION_EPOCH),
            reportInterval: 6300, // 28 days
            _feeDistributor: address(feeDistributor),
            admin: deployerAddress
        });
        bondManager.setFeeDistributor(address(feeDistributor));
        // TODO: csm.setBondManager(address(bondManager));

        vm.stopBroadcast();
    }
}
