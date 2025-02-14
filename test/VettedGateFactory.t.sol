// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { VettedGateFactory } from "../src/VettedGateFactory.sol";
import { IVettedGateFactory } from "../src/interfaces/IVettedGateFactory.sol";
import { IVettedGate } from "../src/interfaces/IVettedGate.sol";
import { OssifiableProxy } from "../src/lib/proxy/OssifiableProxy.sol";
import { Utilities } from "./helpers/Utilities.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { CSMMock } from "./helpers/mocks/CSMMock.sol";

contract VettedGateFactoryTest is Test, Utilities {
    VettedGateFactory factory;
    CSMMock csm;
    bytes32 root;
    uint256 curveId;

    function setUp() public {
        factory = new VettedGateFactory();
        csm = new CSMMock();
        root = bytes32(randomBytes(32));
        curveId = 1;
    }

    function test_create() public {
        vm.expectEmit(false, false, false, false, address(factory));
        emit IVettedGateFactory.VettedGateCreated(address(0));
        address instance = factory.create(
            address(csm),
            curveId,
            root,
            address(this)
        );
        IVettedGate gate = IVettedGate(instance);
        assertEq(gate.CURVE_ID(), curveId);
        assertEq(address(gate.CSM()), address(csm));
        assertEq(gate.treeRoot(), root);

        AccessControlEnumerableUpgradeable gateAccess = AccessControlEnumerableUpgradeable(
                instance
            );
        assertEq(
            gateAccess.getRoleMemberCount(gateAccess.DEFAULT_ADMIN_ROLE()),
            1
        );
        assertTrue(
            gateAccess.hasRole(gateAccess.DEFAULT_ADMIN_ROLE(), address(this))
        );

        OssifiableProxy proxy = OssifiableProxy(payable(instance));
        assertEq(proxy.proxy__getAdmin(), address(this));
    }
}
