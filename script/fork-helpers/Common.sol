// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { DeploymentFixtures } from "test/helpers/Fixtures.sol";
import { OssifiableProxy } from "../../src/lib/proxy/OssifiableProxy.sol";

contract ForkHelpersCommon is Script, DeploymentFixtures {
    function _setUp() internal {
        initializeFromDeployment();
    }

    function _prepareAdmin(
        address contractAddress
    ) internal returns (address admin) {
        AccessControlEnumerableUpgradeable contractInstance = AccessControlEnumerableUpgradeable(
                contractAddress
            );
        admin = payable(
            contractInstance.getRoleMember(
                contractInstance.DEFAULT_ADMIN_ROLE(),
                0
            )
        );
        _setBalance(admin);
    }

    function _prepareProxyAdmin(
        address proxyAddress
    ) internal returns (address admin) {
        OssifiableProxy proxy = OssifiableProxy(payable(proxyAddress));
        admin = payable(proxy.proxy__getAdmin());
        _setBalance(admin);
    }

    function _setBalance(address account) internal {
        uint256 expectedBalance = 1 ether;
        if (account.balance < expectedBalance) {
            vm.rpc(
                "anvil_setBalance",
                string.concat(
                    '["',
                    vm.toString(account),
                    '", ',
                    vm.toString(expectedBalance),
                    "]"
                )
            );
        }
    }
}
