// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";

import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { OssifiableProxy } from "../src/lib/proxy/OssifiableProxy.sol";
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
    address immutable LIDO_LOCATOR_ADDRESS;
    address immutable VOTING_ADDRESS;
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
        address lidoLocatorAddress,
        address votingAddress,
        uint256 oracleReportEpochsPerFrame
    ) {
        NAME = name;
        CHAIN_ID = chainId;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_EPOCH = slotsPerEpoch;
        CL_GENESIS_TIME = clGenesisTime;
        VERIFIER_SUPPORTED_EPOCH = verifierSupportedEpoch;

        LIDO_LOCATOR_ADDRESS = lidoLocatorAddress;
        vm.label(LIDO_LOCATOR_ADDRESS, "LIDO_LOCATOR");
        locator = ILidoLocator(LIDO_LOCATOR_ADDRESS);
        VOTING_ADDRESS = votingAddress;

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
            csm = CSModule(_deployProxy(VOTING_ADDRESS, address(csmImpl)));

            CSAccounting accountingImpl = new CSAccounting({
                lidoLocator: LIDO_LOCATOR_ADDRESS,
                communityStakingModule: address(csm)
            });
            accounting = CSAccounting(
                _deployProxy(VOTING_ADDRESS, address(accountingImpl))
            );

            CSFeeOracle oracleImpl = new CSFeeOracle({
                secondsPerSlot: SECONDS_PER_SLOT,
                genesisTime: CL_GENESIS_TIME
            });
            oracle = CSFeeOracle(
                _deployProxy(VOTING_ADDRESS, address(oracleImpl))
            );

            CSFeeDistributor feeDistributorImpl = new CSFeeDistributor({
                stETH: locator.lido(),
                accounting: address(accounting)
            });
            feeDistributor = CSFeeDistributor(
                _deployProxy(VOTING_ADDRESS, address(feeDistributorImpl))
            );

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

            /// @dev initialize contracts
            csm.initialize({
                _accounting: address(accounting),
                _earlyAdoption: address(0),
                verifier: address(verifier),
                admin: address(deployer)
            });
            accounting.initialize({
                bondCurve: curve,
                admin: VOTING_ADDRESS,
                _feeDistributor: address(feeDistributor),
                // TODO: arguable. should be discussed
                bondLockRetentionPeriod: 8 weeks,
                _chargeRecipient: treasury
            });
            feeDistributor.initialize({
                admin: VOTING_ADDRESS,
                oracle: address(oracle)
            });
            verifier.initialize(address(locator), address(csm));

            // TODO: deploy early adoption contract
            csm.grantRole(csm.MODULE_MANAGER_ROLE(), address(deployer));
            csm.activatePublicRelease();
            csm.revokeRole(csm.MODULE_MANAGER_ROLE(), address(deployer));

            hashConsensus = new HashConsensus({
                slotsPerEpoch: SLOTS_PER_EPOCH,
                secondsPerSlot: SECONDS_PER_SLOT,
                genesisTime: CL_GENESIS_TIME,
                epochsPerFrame: ORACLE_REPORT_EPOCHS_PER_FRAME,
                fastLaneLengthSlots: 0,
                admin: VOTING_ADDRESS,
                reportProcessor: address(oracle)
            });

            oracle.initialize({
                admin: VOTING_ADDRESS,
                feeDistributorContract: address(feeDistributor),
                consensusContract: address(hashConsensus),
                consensusVersion: 1,
                _perfThresholdBP: 9500
            });

            // TODO: remove these lines after early adoption deployment
            csm.grantRole(csm.DEFAULT_ADMIN_ROLE(), VOTING_ADDRESS);
            csm.revokeRole(csm.DEFAULT_ADMIN_ROLE(), address(deployer));

            // TODO: these roles might be granted to multisig for testing purposes
            //            csm.grantRole(csm.PAUSE_ROLE(), address(0)); GateSeal or multisig

            //            csm.grantRole(csm.REPORT_EL_REWARDS_STEALING_PENALTY_ROLE(), address(0)); EOA or multisig
            //            csm.grantRole(csm.SETTLE_EL_REWARDS_STEALING_PENALTY_ROLE(), address(0)); multisig or EasyTrack

            //            accounting.grantRole(accounting.PAUSE_ROLE(), address(0)); GateSeal or multisig

            //            accounting.grantRole(accounting.SET_BOND_CURVE_ROLE(), address(0)); multisig
            //            accounting.grantRole(accounting.RESET_BOND_CURVE_ROLE(), address(0)); multisig

            //            oracle.grantRole(oracle.PAUSE_ROLE(), address(0)); GateSeal or multisig

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

    function _deployJsonFilename() internal view returns (string memory) {
        return string(abi.encodePacked("./out/", "deploy-", NAME, ".json"));
    }
}
