// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// Usage: forge script ./script/DeployCSVerifierElectra.s.sol:DeployCSVerifier[Holesky|Mainnet|DevNet]

pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";
import { console2 as console } from "forge-std/console2.sol";

import { CSVerifier } from "../src/CSVerifier.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { Slot } from "../src/lib/Types.sol";
import { JsonObj, Json } from "./utils/Json.sol";

struct Config {
    address withdrawalVault;
    address module;
    GIndex gIFirstWithdrawalPrev;
    GIndex gIFirstWithdrawalCurr;
    GIndex gIFirstValidatorPrev;
    GIndex gIFirstValidatorCurr;
    GIndex gIHistoricalSummariesPrev;
    GIndex gIHistoricalSummariesCurr;
    Slot firstSupportedSlot;
    Slot pivotSlot;
    uint64 slotsPerEpoch;
    string chainName;
}

// Check the constants below via `yarn run gindex`.

GIndex constant HISTORICAL_SUMMARIES_DENEB = GIndex.wrap(
    0x0000000000000000000000000000000000000000000000000000000000003b00
);
GIndex constant FIRST_WITHDRAWAL_DENEB = GIndex.wrap(
    0x0000000000000000000000000000000000000000000000000000000000e1c004
);
GIndex constant FIRST_VALIDATOR_DENEB = GIndex.wrap(
    0x0000000000000000000000000000000000000000000000000056000000000028
);

GIndex constant HISTORICAL_SUMMARIES_ELECTRA = GIndex.wrap(
    0x0000000000000000000000000000000000000000000000000000000000005b00
);
GIndex constant FIRST_WITHDRAWAL_ELECTRA = GIndex.wrap(
    0x000000000000000000000000000000000000000000000000000000000161c004
);
GIndex constant FIRST_VALIDATOR_ELECTRA = GIndex.wrap(
    0x0000000000000000000000000000000000000000000000000096000000000028
);

abstract contract DeployCSVerifier is Script {
    Config internal config;
    string internal artifactDir;
    address internal deployer;
    uint256 internal pk;

    function run() public {
        artifactDir = string("./artifacts/latest/");
        pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(pk);
        vm.label(deployer, "DEPLOYER");

        vm.startBroadcast(pk);

        CSVerifier verifier = new CSVerifier({
            withdrawalAddress: config.withdrawalVault,
            module: config.module,
            slotsPerEpoch: config.slotsPerEpoch,
            gIFirstWithdrawalPrev: config.gIFirstWithdrawalPrev,
            gIFirstWithdrawalCurr: config.gIFirstWithdrawalCurr,
            gIFirstValidatorPrev: config.gIFirstValidatorPrev,
            gIFirstValidatorCurr: config.gIFirstValidatorCurr,
            gIHistoricalSummariesPrev: config.gIHistoricalSummariesPrev,
            gIHistoricalSummariesCurr: config.gIHistoricalSummariesCurr,
            firstSupportedSlot: config.firstSupportedSlot,
            pivotSlot: config.pivotSlot
        });
        JsonObj memory deployJson = Json.newObj();
        deployJson.set("CSVerifier", address(verifier));
        vm.writeJson(deployJson.str, _deployJsonFilename());
        vm.stopBroadcast();
        console.log("CSVerifier deployed at:", address(verifier));
    }

    function _deployJsonFilename() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(artifactDir, "deploy-verifier-", config.chainName, ".json")
            );
    }
}

contract DeployCSVerifierHolesky is DeployCSVerifier {
    constructor() {
        config = Config({
            withdrawalVault: 0xF0179dEC45a37423EAD4FaD5fCb136197872EAd9,
            module: 0x4562c3e63c2e586cD1651B958C22F88135aCAd4f,
            slotsPerEpoch: 32,
            gIFirstWithdrawalPrev: FIRST_WITHDRAWAL_DENEB,
            gIFirstWithdrawalCurr: FIRST_WITHDRAWAL_ELECTRA,
            gIFirstValidatorPrev: FIRST_VALIDATOR_DENEB,
            gIFirstValidatorCurr: FIRST_VALIDATOR_ELECTRA,
            gIHistoricalSummariesPrev: HISTORICAL_SUMMARIES_DENEB,
            gIHistoricalSummariesCurr: HISTORICAL_SUMMARIES_ELECTRA,
            firstSupportedSlot: Slot.wrap(950272), // 269_568 * 32, @see https://github.com/eth-clients/mainnet/blob/main/metadata/config.yaml#L52
            pivotSlot: Slot.wrap(0), // TODO: Update with Electra slot.
            chainName: "holesky"
        });
    }
}

contract DeployCSVerifierMainnet is DeployCSVerifier {
    constructor() {
        config = Config({
            withdrawalVault: 0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f,
            module: 0xdA7dE2ECdDfccC6c3AF10108Db212ACBBf9EA83F,
            slotsPerEpoch: 32,
            gIFirstWithdrawalPrev: FIRST_WITHDRAWAL_DENEB,
            gIFirstWithdrawalCurr: FIRST_WITHDRAWAL_ELECTRA,
            gIFirstValidatorPrev: FIRST_VALIDATOR_DENEB,
            gIFirstValidatorCurr: FIRST_VALIDATOR_ELECTRA,
            gIHistoricalSummariesPrev: HISTORICAL_SUMMARIES_DENEB,
            gIHistoricalSummariesCurr: HISTORICAL_SUMMARIES_ELECTRA,
            firstSupportedSlot: Slot.wrap(8626176), // 29_696 * 32, @see https://github.com/eth-clients/holesky/blob/main/metadata/config.yaml#L38
            pivotSlot: Slot.wrap(0), // TODO: Update with Electra slot.
            chainName: "mainnet"
        });
    }
}

contract DeployCSVerifierDevNet is DeployCSVerifier {
    constructor() {
        config = Config({
            withdrawalVault: vm.envAddress("CSM_WITHDRAWAL_VAULT"),
            module: vm.envAddress("CSM_MODULE"),
            slotsPerEpoch: 32,
            gIFirstWithdrawalPrev: FIRST_WITHDRAWAL_DENEB,
            gIFirstWithdrawalCurr: FIRST_WITHDRAWAL_ELECTRA,
            gIFirstValidatorPrev: FIRST_VALIDATOR_DENEB,
            gIFirstValidatorCurr: FIRST_VALIDATOR_ELECTRA,
            gIHistoricalSummariesPrev: HISTORICAL_SUMMARIES_DENEB,
            gIHistoricalSummariesCurr: HISTORICAL_SUMMARIES_ELECTRA,
            firstSupportedSlot: Slot.wrap(5 * 32), // epoch 5 // TODO: verify
            pivotSlot: Slot.wrap(5 * 32), // epoch 5 // TODO: verify
            chainName: "devnet"
        });
    }
}