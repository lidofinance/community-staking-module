// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";

import { CSVerifierBiFork } from "../src/CSVerifierBiFork.sol";
import { GIndex } from "../src/lib/GIndex.sol";

contract DeployElectraVerifierHolesky is Script {
    uint256 private constant CHAIN_ID = 17000;

    error ChainIdMismatch(uint256 actual, uint256 expected);

    function run() public {
        if (CHAIN_ID != block.chainid) {
            revert ChainIdMismatch({
                actual: block.chainid,
                expected: CHAIN_ID
            });
        }

        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(pk);
        vm.label(deployer, "DEPLOYER");

        vm.startBroadcast(pk);
        {
            // FIXME: Fill in the Electra's indices as soon as they will be finalized.
            // CSVerifierBiFork verifier = new CSVerifierBiFork({
            //     locator: 0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8,
            //     module: 0x4562c3e63c2e586cD1651B958C22F88135aCAd4f,
            //     slotsPerEpoch: 32,
            //     gIFirstWithdrawalPrev: GIndex.wrap(),
            //     gIFirstWithdrawalCurr: GIndex.wrap(),
            //     gIFirstValidatorPrev: GIndex.wrap(),
            //     gIFirstValidatorCurr: GIndex.wrap(),
            //     gIHistoricalSummaries: GIndex.wrap(),
            //     firstSupportedSlot: Slot.wrap()
            //     pivotSlot: Slot.wrap()
            // });
            // console.log(address(verifier));
        }
        vm.stopBroadcast();
    }
}
