// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import { DeployBase } from "./DeployBase.s.sol";
import { GIndex } from "../src/lib/GIndex.sol";
import { DeployImplementationsBase } from "./DeployImplementationsBase.s.sol";
import "./DeployMainnet.s.sol";
import { HashConsensus } from "../src/lib/base-oracle/HashConsensus.sol";
import { CSModule } from "../src/CSModule.sol";
import { CSAccounting } from "../src/CSAccounting.sol";
import { CSFeeDistributor } from "../src/CSFeeDistributor.sol";
import { CSFeeOracle } from "../src/CSFeeOracle.sol";
import { CSVerifier } from "../src/CSVerifier.sol";
import { CSEarlyAdoption } from "../src/CSEarlyAdoption.sol";

contract DeployImplementationsMainnet is
    DeployImplementationsBase,
    DeployMainnet
{
    constructor() DeployMainnet() {
        csm = CSModule(0xdA7dE2ECdDfccC6c3AF10108Db212ACBBf9EA83F);
        earlyAdoption = CSEarlyAdoption(
            0x3D5148ad93e2ae5DedD1f7A8B3C19E7F67F90c0E
        );
        accounting = CSAccounting(0x4d72BFF1BeaC69925F8Bd12526a39BAAb069e5Da);
        oracle = CSFeeOracle(0x4D4074628678Bd302921c20573EEa1ed38DdF7FB);
        feeDistributor = CSFeeDistributor(
            0xD99CC66fEC647E68294C6477B40fC7E0F6F618D0
        );
        hashConsensus = HashConsensus(
            0x71093efF8D8599b5fA340D665Ad60fA7C80688e4
        );
        gateSeal = 0x5cFCa30450B1e5548F140C24A47E36c10CE306F0;
    }
}
