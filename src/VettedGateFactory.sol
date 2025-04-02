// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { IVettedGateFactory } from "./interfaces/IVettedGateFactory.sol";
import { OssifiableProxy } from "./lib/proxy/OssifiableProxy.sol";
import { VettedGate } from "./VettedGate.sol";

contract VettedGateFactory is IVettedGateFactory {
    address public immutable VETTED_GATE_IMPL;

    constructor(address vettedGateImpl) {
        if (vettedGateImpl == address(0)) {
            revert ZeroImplementationAddress();
        }

        VETTED_GATE_IMPL = vettedGateImpl;
    }

    /// @inheritdoc IVettedGateFactory
    function create(
        uint256 curveId,
        bytes32 treeRoot,
        address admin
    ) external returns (address instance) {
        instance = address(
            new OssifiableProxy({
                implementation_: VETTED_GATE_IMPL,
                data_: new bytes(0),
                admin_: admin
            })
        );

        VettedGate(instance).initialize(curveId, treeRoot, admin);

        emit VettedGateCreated(instance);
    }
}
