// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";

import { HashConsensus } from "../lib/base-oracle/oracle/HashConsensus.sol";
import { OssifiableProxy } from "../lib/proxy/OssifiableProxy.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";

import { ILidoLocator } from "../src/interfaces/ILidoLocator.sol";

import { JsonObj, Json } from "./utils/Json.sol";
import { pack } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";

abstract contract DeployBase is Script {
    // TODO: some contracts of the module probably should be deployed behind a proxy
    uint256 immutable CHAIN_ID;
    uint256 immutable SECONDS_PER_SLOT;
    uint256 immutable SLOTS_PER_EPOCH;
    uint256 immutable CL_GENESIS_TIME;
    uint256 immutable VERIFIER_SUPPORTED_EPOCH;
    uint256 immutable INITIALIZATION_EPOCH;
    address immutable LIDO_LOCATOR_ADDRESS;

    ILidoLocator private locator;

    address private deployer;
    uint256 private pk;
    CSModule public csm;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;

    error ChainIdMismatch(uint256 actual, uint256 expected);

    constructor(
        uint256 chainId,
        uint256 secondsPerSlot,
        uint256 slotsPerEpoch,
        uint256 clGenesisTime,
        uint256 verifierSupportedEpoch,
        uint256 initializationEpoch,
        address lidoLocatorAddress
    ) {
        CHAIN_ID = chainId;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_EPOCH = slotsPerEpoch;
        CL_GENESIS_TIME = clGenesisTime;
        VERIFIER_SUPPORTED_EPOCH = verifierSupportedEpoch;
        INITIALIZATION_EPOCH = initializationEpoch;
        LIDO_LOCATOR_ADDRESS = lidoLocatorAddress;

        vm.label(LIDO_LOCATOR_ADDRESS, "LIDO_LOCATOR");

        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);
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

        vm.startBroadcast(pk);
        {
            address treasury = locator.treasury();
            uint256[] memory curve = new uint256[](2);
            curve[0] = 2 ether;
            curve[1] = 4 ether;

            CSModule csmImpl = new CSModule({
                moduleType: "community-staking-module",
                elStealingFine: 0.1 ether,
                maxKeysPerOperatorEA: 10,
                lidoLocator: LIDO_LOCATOR_ADDRESS
            });
            csm = CSModule(_deployProxy(deployer, address(csmImpl)));

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: LIDO_LOCATOR_ADDRESS,
                communityStakingModule: address(csm)
            });
            accounting = CSAccounting(
                _deployProxy(deployer, address(accountingImpl))
            );

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: SECONDS_PER_SLOT,
                genesisTime: CL_GENESIS_TIME
            });
            oracle = CSFeeOracle(_deployProxy(deployer, address(oracleImpl)));

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting)
            });
            feeDistributor = CSFeeDistributor(
                _deployProxy(deployer, address(feeDistributorImpl))
            );

            /// @dev initialize contracts
            csm.initialize({
                _accounting: address(accounting),
                _earlyAdoption: address(0),
                admin: address(deployer)
            });
            accounting.initialize({
                bondCurve: curve,
                admin: deployer,
                _feeDistributor: address(feeDistributor),
                // TODO: arguable. should be discussed
                bondLockRetentionPeriod: 8 weeks,
                _chargeRecipient: treasury
            });
            feeDistributor.initialize({ admin: deployer });

            csm.grantRole(csm.MODULE_MANAGER_ROLE(), address(deployer));
            csm.activatePublicRelease();
            // TODO: deploy early adoption contract

            feeDistributor.grantRole(
                feeDistributor.ORACLE_ROLE(),
                address(oracle)
            );

            accounting.grantRole(
                accounting.SET_BOND_CURVE_ROLE(),
                address(csm)
            );
            accounting.grantRole(
                accounting.RESET_BOND_CURVE_ROLE(),
                address(csm)
            );

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

            CSVerifier verifier = new CSVerifier({
                slotsPerEpoch: uint64(SLOTS_PER_EPOCH),
                // NOTE: Deneb fork gIndexes. Should be updated according to `VERIFIER_SUPPORTED_EPOCH` fork epoch if needed
                gIHistoricalSummaries: pack(0x3b, 5),
                gIFirstWithdrawal: pack(0xe1c0, 4),
                gIFirstValidator: pack(0x560000000000, 40),
                firstSupportedSlot: Slot.wrap(
                    uint64(VERIFIER_SUPPORTED_EPOCH * SLOTS_PER_EPOCH)
                )
            });
            verifier.initialize(address(locator), address(csm));
            csm.grantRole(csm.VERIFIER_ROLE(), address(verifier));

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("CSModule", address(csm));
            deployJson.set("CSAccounting", address(accounting));
            deployJson.set("CSFeeOracle", address(oracle));
            deployJson.set("CSFeeDistributor", address(feeDistributor));
            deployJson.set("HashConsensus", address(hashConsensus));
            deployJson.set("CSVerifier", address(verifier));
            vm.writeJson(deployJson.str, _deployJsonFilename());
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

    function _deployJsonFilename() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "./out/",
                    "deploy-",
                    _deployJsonSuffix(),
                    ".json"
                )
            );
    }

    function _deployJsonSuffix() internal view returns (string memory) {
        // prettier-ignore
        return
            block.chainid == 17000 ? "holesky" :
            block.chainid == 1 ? "mainnet" :
            block.chainid == 5 ? "goerli" :
            /* default: */ "unknown";
    }
}
