// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Script.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting, IWstETH } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";

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
        CSModule csm = new CSModule(
            "community-staking-module",
            address(locator)
        );
        CSAccounting accounting = new CSAccounting({
            _commonBondSize: 2 ether,
            _admin: deployerAddress,
            _lidoLocator: address(locator),
            _communityStakingModule: address(csm),
            _wstETH: address(wstETH),
            _penalizeRoleMembers: penalizers
        });
        CSFeeOracle feeOracle = new CSFeeOracle({
            secondsPerBlock: 12,
            blocksPerEpoch: 32,
            genesisTime: uint64(CL_GENESIS_TIME)
        });
        CSFeeDistributor feeDistributor = new CSFeeDistributor({
            _CSM: address(csm),
            _stETH: locator.lido(),
            _oracle: address(feeOracle),
            _accounting: address(accounting)
        });
        feeOracle.initialize({
            _initializationEpoch: uint64(INITIALIZATION_EPOCH),
            reportInterval: 6300, // 28 days
            _feeDistributor: address(feeDistributor),
            admin: deployerAddress
        });
        accounting.setFeeDistributor(address(feeDistributor));
        // TODO: csm.setBondManager(address(accounting));

        vm.stopBroadcast();
    }
}
