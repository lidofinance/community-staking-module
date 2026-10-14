// SPDX-FileCopyrightText: 2026 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.33;

import { Script } from "forge-std/Script.sol";
import { VmSafe } from "forge-std/Vm.sol";

abstract contract DeployConfirmation is Script {
    error DeployAborted();

    function _confirmDeploy(string memory question) internal {
        if (!vm.isContext(VmSafe.ForgeContext.ScriptBroadcast) || vm.envOr("SKIP_DEPLOY_PROMPT", false)) return;
        string memory answer = vm.prompt(string.concat(question, " [y/N]"));
        if (keccak256(bytes(answer)) != keccak256("y")) revert DeployAborted();
    }
}
