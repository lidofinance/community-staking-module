// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { IVettedGateFactory } from "./interfaces/IVettedGateFactory.sol";
import { OssifiableProxy } from "./lib/proxy/OssifiableProxy.sol";
import { VettedGate } from "./VettedGate.sol";

contract VettedGateFactory is IVettedGateFactory {
    /// @inheritdoc IVettedGateFactory
    function create(
        address csm,
        uint256 curveId,
        bytes32 treeRoot,
        address admin
    ) external returns (address instance) {
        VettedGate gateImpl = new VettedGate(curveId, csm);

        instance = address(
            new OssifiableProxy({
                implementation_: address(gateImpl),
                data_: new bytes(0),
                admin_: admin
            })
        );

        VettedGate(instance).initialize(treeRoot, admin);

        emit VettedGateCreated(instance);
    }
}
