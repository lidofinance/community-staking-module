// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Script.sol";

import { HashConsensus } from "../lib/base-oracle/oracle/HashConsensus.sol";
import { OssifiableProxy } from "../lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting, IWstETH } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";

contract Deploy is Script {
    // TODO: some contracts of the module probably should be deployed behind a proxy

    ILidoLocator public locator;
    IWstETH public wstETH;

    address public LIDO_LOCATOR_ADDRESS;
    address public WSTETH_ADDRESS;
    uint256 public CL_GENESIS_TIME;
    uint256 public INITIALIZATION_EPOCH;

    address deployer;
    uint256 pk;

    constructor() {
        LIDO_LOCATOR_ADDRESS = vm.envAddress("LIDO_LOCATOR_ADDRESS");
        WSTETH_ADDRESS = vm.envAddress("WSTETH_ADDRESS");
        CL_GENESIS_TIME = vm.envUint("CL_GENESIS_TIME");
        INITIALIZATION_EPOCH = vm.envUint("INITIALIZATION_EPOCH");

        pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(pk);

        vm.label(LIDO_LOCATOR_ADDRESS, "LIDO_LOCATOR");
        vm.label(WSTETH_ADDRESS, "WSTETH");
        vm.label(deployer, "DEPLOYER");

        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);
        wstETH = IWstETH(WSTETH_ADDRESS);
    }

    function run() external {
        address[] memory penalizers = new address[](1);
        penalizers[0] = deployer; // FIXME

        vm.startBroadcast(pk);
        {
            CSModule csm = new CSModule({
                moduleType: "community-staking-module",
                locator: address(locator)
            });
            CSAccounting accounting = new CSAccounting({
                commonBondSize: 2 ether,
                admin: deployer,
                lidoLocator: address(locator),
                communityStakingModule: address(csm),
                wstETH: address(wstETH),
                penalizeRoleMembers: penalizers
            });

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: 12,
                genesisTime: CL_GENESIS_TIME
            });

            CSFeeOracle oracle = CSFeeOracle(
                _deployProxy({
                    admin: deployer,
                    implementation: address(oracleImpl)
                })
            );

            CSFeeDistributor feeDistributor = new CSFeeDistributor({
                _CSM: address(csm),
                stETH: locator.lido(),
                oracle: address(oracle),
                accounting: address(accounting)
            });
            accounting.setFeeDistributor(address(feeDistributor));
            // TODO: csm.setBondManager(address(accounting));

            HashConsensus hashConsensus = new HashConsensus({
                slotsPerEpoch: 32,
                secondsPerSlot: 12,
                genesisTime: CL_GENESIS_TIME,
                epochsPerFrame: 225 * 28, // 28 days
                fastLaneLengthSlots: 0,
                admin: deployer,
                reportProcessor: address(oracle)
            });
            hashConsensus.updateInitialEpoch(INITIALIZATION_EPOCH);

            oracle.initialize({
                admin: deployer,
                feeDistributorContract: address(feeDistributor),
                consensusContract: address(hashConsensus),
                consensusVersion: 1,
                lastProcessingRefSlot: _refSlotFromEpoch(INITIALIZATION_EPOCH)
            });
        }

        vm.stopBroadcast();
    }

    function _deployProxy(
        address admin,
        address implementation
    ) internal returns (address) {
        OssifiableProxy proxy = new OssifiableProxy({
            implementation_: implementation,
            data_: new bytes(0),
            admin_: admin
        });

        return address(proxy);
    }

    function _deployGateSeal() internal returns (address) {
        // PAUSE_ROLE for some contracts should be granted to GateSeals
        revert("Not yet implemented");
    }

    function _refSlotFromEpoch(uint256 epoch) internal pure returns (uint256) {
        return epoch * 32 - 1;
    }
}
