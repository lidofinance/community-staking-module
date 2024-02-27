// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;
import { Test } from "forge-std/Test.sol";
import { BeaconBlockHeader, Validator, Withdrawal } from "../src/lib/Types.sol";
import { SSZ } from "../src/lib/SSZ.sol";

contract SSZTest is Test {
    /// forge-config: default.fuzz.runs = 32
    function test_Fuzz_withdrawalRoot(Withdrawal memory w) public {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "ffi/withdrawal-root.js";
        cmd[2] = toJson(w);
        bytes memory res = vm.ffi(cmd);

        bytes32 expected = abi.decode(res, (bytes32));
        bytes32 actual = SSZ.hashTreeRoot(w);
        assertEq(actual, expected);
    }

    /// forge-config: default.fuzz.runs = 32
    function test_Fuzz_validatorRoot(Validator memory v) public {
        vm.assume(v.pubkey.length == 48);

        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "ffi/validator-root.js";
        cmd[2] = toJson(v);
        bytes memory res = vm.ffi(cmd);

        bytes32 expected = abi.decode(res, (bytes32));
        bytes32 actual = SSZ.hashTreeRoot(v);
        assertEq(actual, expected);
    }

    function toJson(
        Withdrawal memory w
    ) internal noGasMetering returns (string memory json) {
        json = vm.serializeUint("", "index", w.index);
        json = vm.serializeAddress("", "address", w.withdrawalAddress);
        json = vm.serializeUint("", "validator_index", w.validatorIndex);
        json = vm.serializeUint("", "amount", w.amount);
    }

    function toJson(
        Validator memory v
    ) internal noGasMetering returns (string memory json) {
        json = vm.serializeBytes("", "pubkey", v.pubkey);
        json = vm.serializeBytes32(
            "",
            "withdrawal_credentials",
            v.withdrawalCredentials
        );
        json = vm.serializeUint("", "effective_balance", v.effectiveBalance);
        json = vm.serializeBool("", "slashed", v.slashed);
        json = vm.serializeUint(
            "",
            "activation_eligibility_epoch",
            v.activationEligibilityEpoch
        );
        json = vm.serializeUint("", "activation_epoch", v.activationEpoch);
        json = vm.serializeUint("", "exit_epoch", v.exitEpoch);
        json = vm.serializeUint("", "withdrawable_epoch", v.withdrawableEpoch);
    }
}
