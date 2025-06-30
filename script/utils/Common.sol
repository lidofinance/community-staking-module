// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { ICSParametersRegistry } from "../../src/interfaces/ICSParametersRegistry.sol";
import { ICSBondCurve } from "../../src/interfaces/ICSBondCurve.sol";

library CommonScriptUtils {
    function arraysToKeyIndexValueIntervals(
        uint256[2][] memory data
    )
        internal
        pure
        returns (ICSParametersRegistry.KeyNumberValueInterval[] memory)
    {
        ICSParametersRegistry.KeyNumberValueInterval[]
            memory keyIndexValues = new ICSParametersRegistry.KeyNumberValueInterval[](
                data.length
            );
        for (uint256 i = 0; i < data.length; i++) {
            keyIndexValues[i] = ICSParametersRegistry.KeyNumberValueInterval({
                minKeyNumber: data[i][0],
                value: data[i][1]
            });
        }
        return keyIndexValues;
    }

    function arraysToBondCurveIntervalsInputs(
        uint256[2][] memory data
    ) internal pure returns (ICSBondCurve.BondCurveIntervalInput[] memory) {
        ICSBondCurve.BondCurveIntervalInput[]
            memory bondCurveInputs = new ICSBondCurve.BondCurveIntervalInput[](
                data.length
            );
        for (uint256 i = 0; i < data.length; i++) {
            bondCurveInputs[i] = ICSBondCurve.BondCurveIntervalInput({
                minKeysCount: data[i][0],
                trend: data[i][1]
            });
        }
        return bondCurveInputs;
    }
}
