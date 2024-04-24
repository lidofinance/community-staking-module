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
    string NAME;
    uint256 immutable CHAIN_ID;
    uint256 immutable SECONDS_PER_SLOT;
    uint256 immutable SLOTS_PER_EPOCH;
    uint256 immutable CL_GENESIS_TIME;
    uint256 immutable VERIFIER_SUPPORTED_EPOCH;
    uint256 immutable INITIALIZATION_EPOCH;
    address immutable LIDO_LOCATOR_ADDRESS;
    uint256 immutable ORACLE_REPORT_EPOCHS_PER_FRAME;

    ILidoLocator private locator;

    address private deployer;
    uint256 private pk;
    CSModule public csm;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;
    CSVerifier public verifier;
    HashConsensus public hashConsensus;

    error ChainIdMismatch(uint256 actual, uint256 expected);

    constructor(
        string memory name,
        uint256 chainId,
        uint256 secondsPerSlot,
        uint256 slotsPerEpoch,
        uint256 clGenesisTime,
        uint256 verifierSupportedEpoch,
        uint256 initializationEpoch,
        address lidoLocatorAddress,
        uint256 oracleReportEpochsPerFrame
    ) {
        NAME = name;
        CHAIN_ID = chainId;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_EPOCH = slotsPerEpoch;
        CL_GENESIS_TIME = clGenesisTime;
        VERIFIER_SUPPORTED_EPOCH = verifierSupportedEpoch;
        INITIALIZATION_EPOCH = initializationEpoch;

        LIDO_LOCATOR_ADDRESS = lidoLocatorAddress;
        vm.label(LIDO_LOCATOR_ADDRESS, "LIDO_LOCATOR");
        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);

        ORACLE_REPORT_EPOCHS_PER_FRAME = oracleReportEpochsPerFrame;
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
                moduleType: "community-onchain-v1",
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

            csm.grantRole(csm.PAUSE_ROLE(), address(deployer));
            csm.pauseFor(UINT256_MAX);
            csm.revokeRole(csm.PAUSE_ROLE(), address(deployer));
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

            hashConsensus = new HashConsensus({
                slotsPerEpoch: SLOTS_PER_EPOCH,
                secondsPerSlot: SECONDS_PER_SLOT,
                genesisTime: CL_GENESIS_TIME,
                epochsPerFrame: ORACLE_REPORT_EPOCHS_PER_FRAME,
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
                lastProcessingRefSlot: _refSlotFromEpoch(INITIALIZATION_EPOCH),
                _perfThresholdBP: 9500
            });

            verifier = new CSVerifier({
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

            csm.grantRole(
                csm.STAKING_ROUTER_ROLE(),
                address(locator.stakingRouter())
            );

            JsonObj memory deployJson = Json.newObj();
            deployJson.set("ChainId", CHAIN_ID);
            deployJson.set("CSModule", address(csm));
            deployJson.set("CSAccounting", address(accounting));
            deployJson.set("CSFeeOracle", address(oracle));
            deployJson.set("CSFeeDistributor", address(feeDistributor));
            deployJson.set("HashConsensus", address(hashConsensus));
            deployJson.set("CSVerifier", address(verifier));
            deployJson.set("LidoLocator", LIDO_LOCATOR_ADDRESS);
            vm.writeJson(deployJson.str, _deployJsonFilename());
            vm.writeJson(deployJson.str, "./out/latest.json");
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
        return string(abi.encodePacked("./out/", "deploy-", NAME, ".json"));
    }
}
