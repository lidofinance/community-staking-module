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

abstract contract DeployBase is Script {
    // TODO: some contracts of the module probably should be deployed behind a proxy
    uint256 immutable CHAIN_ID;
    uint256 immutable SECONDS_PER_SLOT;
    uint256 immutable SLOTS_PER_EPOCH;
    uint256 immutable CL_GENESIS_TIME;
    uint256 immutable INITIALIZATION_EPOCH;
    address immutable LIDO_LOCATOR_ADDRESS;
    address immutable WSTETH_ADDRESS;

    ILidoLocator private locator;
    IWstETH private wstETH;

    address private deployer;
    uint256 private pk;

    error ChainIdMismatch(uint256 actual, uint256 expected);

    constructor(
        uint256 chainId,
        uint256 secondsPerSlot,
        uint256 slotsPerEpoch,
        uint256 clGenesisTime,
        uint256 initializationEpoch,
        address lidoLocatorAddress,
        address wstETHAddress
    ) {
        CHAIN_ID = chainId;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_EPOCH = slotsPerEpoch;
        CL_GENESIS_TIME = clGenesisTime;
        INITIALIZATION_EPOCH = initializationEpoch;
        LIDO_LOCATOR_ADDRESS = lidoLocatorAddress;
        WSTETH_ADDRESS = wstETHAddress;

        vm.label(LIDO_LOCATOR_ADDRESS, "LIDO_LOCATOR");
        vm.label(WSTETH_ADDRESS, "WSTETH");

        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);
        wstETH = IWstETH(WSTETH_ADDRESS);
    }

    function run() external {
        if (CHAIN_ID != block.chainid) {
            revert ChainIdMismatch({
                actual: block.chainid,
                expected: CHAIN_ID
            });
        }

        pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(pk);
        vm.label(deployer, "DEPLOYER");

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
                secondsPerSlot: SECONDS_PER_SLOT,
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
                slotsPerEpoch: SLOTS_PER_EPOCH,
                secondsPerSlot: SECONDS_PER_SLOT,
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

    function _refSlotFromEpoch(uint256 epoch) internal view returns (uint256) {
        return epoch * SLOTS_PER_EPOCH - 1;
    }
}
