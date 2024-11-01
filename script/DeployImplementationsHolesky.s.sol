// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { DeployImplementationsBase } from "./DeployImplementationsBase.s.sol";
import { DeployHolesky } from "./DeployHolesky.s.sol";
import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { CSEarlyAdoption } from "../src/CSEarlyAdoption.sol";

contract DeployImplementationsHolesky is
    DeployImplementationsBase,
    DeployHolesky
{
    constructor() DeployHolesky() {
        csm = CSModule(0x4562c3e63c2e586cD1651B958C22F88135aCAd4f);
        earlyAdoption = CSEarlyAdoption(
            0x71E92eA77C198a770d9f33A03277DbeB99989660
        );
        accounting = CSAccounting(0xc093e53e8F4b55A223c18A2Da6fA00e60DD5EFE1);
        oracle = CSFeeOracle(0xaF57326C7d513085051b50912D51809ECC5d98Ee);
        feeDistributor = CSFeeDistributor(
            0xD7ba648C8F72669C6aE649648B516ec03D07c8ED
        );
        hashConsensus = HashConsensus(
            0xbF38618Ea09B503c1dED867156A0ea276Ca1AE37
        );
        gateSeal = 0x41F2677fae0222cF1f08Cd1c0AAa607B469654Ce;
    }
}
