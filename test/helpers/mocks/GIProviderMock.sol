// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import { ForkVersion } from "../../../src/lib/Types.sol";
import { GIProvider } from "../../../src/GIProvider.sol";
import { pack } from "../../../src/lib/GIndex.sol";

contract GIProviderMock is GIProvider {
    function usePreset() external {
        GIProvider.KV[] memory capella = new GIProvider.KV[](3);
        capella[0] = GIProvider.KV({
            key: "BeaconState.withdrawals[0]",
            value: pack(29120, 4)
        });
        capella[1] = GIProvider.KV({
            key: "BeaconState.validators[0]",
            value: pack(94557999988736, 40)
        });
        capella[2] = GIProvider.KV({
            key: "BeaconState.historical_summaries",
            value: pack(59, 5)
        });

        GIProvider.KV[] memory deneb = new GIProvider.KV[](3);
        // BeaconBlock struct has been changed in deneb.
        deneb[0] = GIProvider.KV({
            key: "BeaconState.withdrawals[0]",
            value: pack(57792, 4)
        });
        deneb[1] = GIProvider.KV({
            key: "BeaconState.validators[0]",
            value: pack(94557999988736, 40)
        });
        deneb[2] = GIProvider.KV({
            key: "BeaconState.historical_summaries",
            value: pack(59, 5)
        });

        this.patchFork(ForkVersion.wrap(0x03001020), capella);
        this.patchFork(ForkVersion.wrap(0x04001020), deneb);
    }
}
